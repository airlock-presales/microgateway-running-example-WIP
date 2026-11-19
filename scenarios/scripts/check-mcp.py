#!/usr/bin/env python3
"""Live, read-only API smoke test: IAM PKCE -> gateway -> static or dynamic MCP.

No tokens/cookies are written to disk. This is not a browser/Inspector UI test.
"""
import argparse
import base64
import getpass
import hashlib
import http.cookiejar
import json
import os
from pathlib import Path
import secrets
import ssl
import urllib.error
import urllib.parse
import urllib.request

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--username', default='user2')
parser.add_argument('--dynamic', action='store_true', help='Test authenticated routing to the echo ClusterIP Service')
parser.add_argument('--ca', type=Path, default=Path(__file__).resolve().parents[2] / '.local/mcp/iam-mcp-ca.crt')
parser.add_argument('--samples', type=int, default=16, help='Number of dynamic echo calls to sample backend pods')
args = parser.parse_args()
if not 1 <= args.samples <= 1000:
    parser.error('--samples must be between 1 and 1000')
password = os.environ.get('IAM_TEST_PASSWORD') or getpass.getpass('IAM test account password: ')
origin = 'https://iam-mcp-127-0-0-1.nip.io:8443'
authorization_server = 'mcp-dynamic' if args.dynamic else 'mcp'
client_id = 'mcp-dynamic-demo' if args.dynamic else 'mcp-demo'
issuer = origin + '/auth-login/rest/oauth2/authorization-servers/' + authorization_server
resource = ('https://mcp-iam-127-0-0-1.nip.io:8443/mcp' if args.dynamic else
            'https://github-mcp-iam-127-0-0-1.nip.io:8443/mcp')
callback = 'http://localhost:6274/oauth/callback'
state = secrets.token_urlsafe(24)
verifier = secrets.token_urlsafe(48)
challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).decode().rstrip('=')
opener = urllib.request.build_opener(
    urllib.request.ProxyHandler({}),
    urllib.request.HTTPSHandler(context=ssl.create_default_context(cafile=str(args.ca))),
    urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))

def request(url, data=None, headers=None, method=None):
    req = urllib.request.Request(url, data=data, headers=headers or {}, method=method)
    try:
        response = opener.open(req, timeout=30)
    except urllib.error.HTTPError as error:
        response = error
    return response

def auth(path, data, continuation=False):
    headers = {'Content-Type': 'application/json', 'X-Same-Domain': '1'}
    if continuation:
        headers['X-Continue-Flow'] = 'true'
    with request(origin + '/auth-login/rest' + path, json.dumps(data).encode(), headers) as response:
        return response.status, dict(response.headers), json.loads(response.read() or b'{}')

if args.dynamic:
    with request(resource, json.dumps({'jsonrpc':'2.0','id':0,'method':'initialize'}).encode(),
                 {'Content-Type':'application/json','Accept':'application/json, text/event-stream'}) as response:
        if response.status != 401 or 'resource_metadata=' not in response.headers.get('WWW-Authenticate', ''):
            raise SystemExit('Dynamic endpoint does not enforce the expected IAM challenge.')
        print('PASS: unauthenticated dynamic MCP rejected with metadata challenge.')
    metadata_url = resource.rsplit('/', 1)[0] + '/.well-known/oauth-protected-resource/mcp'
    with request(metadata_url) as response:
        metadata = json.load(response)
        if metadata.get('resource') != resource or metadata.get('authorization_servers') != [issuer]:
            raise SystemExit('Dynamic protected-resource metadata mismatch.')
        print('PASS: dynamic resource discovery identifies its dedicated IAM issuer.')

query = urllib.parse.urlencode({'client_id': client_id, 'redirect_uri': callback,
    'response_type': 'code', 'scope': 'openid profile email', 'state': state,
    'code_challenge': challenge, 'code_challenge_method': 'S256'})
status, _, _ = auth('/public/authentication/oauth2/authorization-servers/' + authorization_server + '/authorize', {'queryString': query})
if status != 401:
    raise SystemExit(f'Unexpected initial IAM flow status: {status}')
status, headers, _ = auth('/public/authentication/password/check',
                          {'username': args.username, 'password': password}, True)
if status != 200:
    raise SystemExit(f'IAM test login failed: HTTP {status}')
forward = next((value for key, value in headers.items() if key.lower() == 'x-forward-url'), '')
redirect = urllib.parse.urlparse(forward)
parameters = urllib.parse.parse_qs(redirect.query)
if redirect.scheme + '://' + redirect.netloc + redirect.path != callback or parameters.get('state') != [state]:
    raise SystemExit('IAM callback or OAuth state did not match.')
form = urllib.parse.urlencode({'client_id': client_id, 'grant_type': 'authorization_code',
    'code': parameters['code'][0], 'redirect_uri': callback, 'code_verifier': verifier}).encode()
with request(issuer + '/token', form, {'Content-Type': 'application/x-www-form-urlencoded',
                                     'Origin': 'http://localhost:6274'}) as response:
    if response.status != 200:
        raise SystemExit(f'PKCE token exchange failed: HTTP {response.status}')
    tokens = json.load(response)
token = tokens['access_token']
segment = token.split('.')[1]
claims = json.loads(base64.urlsafe_b64decode(segment + '=' * (-len(segment) % 4)))
if claims.get('iss') != issuer or claims.get('aud') != resource or claims.get('sub') != args.username:
    raise SystemExit('Unexpected access-token claims.')
print('PASS: IAM authorization-code + S256 PKCE; expected issuer/audience/subject.')
session = None
backend_pods = set()

def rpc(method, params=None, rpc_id=None, tool=None):
    global session
    payload = {'jsonrpc': '2.0', 'method': method}
    if params is not None:
        payload['params'] = params
    if rpc_id is not None:
        payload['id'] = rpc_id
    headers = {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json',
               'Accept': 'application/json, text/event-stream', 'MCP-Protocol-Version': '2025-06-18'}
    if tool:
        headers['mcp-name'] = tool
    if session:
        headers['Mcp-Session-Id'] = session
    with request(resource, json.dumps(payload).encode(), headers) as response:
        if response.status >= 400:
            raise SystemExit(f'MCP {method} failed: HTTP {response.status}')
        if args.dynamic:
            pod = response.headers.get('X-MCP-Backend-Pod')
            if not pod:
                raise SystemExit('Dynamic MCP response is missing its backend pod identifier.')
            backend_pods.add(pod)
        session = response.headers.get('Mcp-Session-Id') or session
        if response.status in (202, 204):
            return None
        if 'text/event-stream' in response.headers.get('Content-Type', ''):
            for raw in response:
                line = raw.decode().strip()
                if line.startswith('data:'):
                    message = json.loads(line[5:].strip())
                    if message.get('id') == rpc_id:
                        break
            else:
                raise SystemExit(f'No JSON-RPC response for {method}')
        else:
            message = json.load(response)
        if 'error' in message:
            raise SystemExit(f'MCP {method} returned JSON-RPC error {message["error"].get("code")}')
        return message['result']

result = rpc('initialize', {'protocolVersion': '2025-06-18', 'capabilities': {},
                         'clientInfo': {'name': 'airlock-iam-smoke-test', 'version': '1'}}, 1)
print('PASS: MCP initialize; server:', result.get('serverInfo', {}).get('name'),
      'protocol:', result.get('protocolVersion'))
rpc('notifications/initialized')
catalog = rpc('tools/list', {}, 2)
tools = catalog.get('tools', [])
print('PASS: MCP tools/list;', len(tools), 'tools returned.')
if args.dynamic:
    names = {tool['name'] for tool in tools}
    if names != {'echo'}:
        raise SystemExit('Unexpected dynamic tool catalog: ' + ', '.join(sorted(names)))
    for rpc_id in range(3, 3 + args.samples):
        marker = 'dynamic-' + secrets.token_hex(10)
        result = rpc('tools/call', {'name': 'echo', 'arguments': {'text': marker}}, rpc_id, 'echo')
        actual = [item.get('text') for item in result.get('content', []) if item.get('type') == 'text']
        if result.get('isError') or actual != [marker]:
            raise SystemExit('Incorrect echo result from the dynamic endpoint.')
    print('PASS:', args.samples, 'fresh echo calls through the ClusterIP backend.')
    print('Observed backend pods:', ', '.join(sorted(backend_pods)))
    unknown = {'jsonrpc': '2.0', 'id': 8, 'method': 'tools/call',
               'params': {'name': 'unknown_echo_tool', 'arguments': {}}}
    headers = {'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json',
               'Accept': 'application/json, text/event-stream'}
    if session:
        headers['Mcp-Session-Id'] = session
    with request(resource, json.dumps(unknown).encode(), headers) as response:
        body = response.read()
        failed = response.status >= 400
        if not failed:
            try:
                message = json.loads(body)
                failed = 'error' in message or message.get('result', {}).get('isError', False)
            except ValueError:
                failed = False
        if not failed:
            raise SystemExit('Unknown echo tool was not rejected.')
        print('PASS: unknown tool rejected; HTTP', response.status)
    with request('https://github-mcp-iam-127-0-0-1.nip.io:8443/mcp',
                 json.dumps({'jsonrpc':'2.0','id':9,'method':'tools/list'}).encode(), headers) as response:
        if response.status != 401:
            raise SystemExit('Dynamic token unexpectedly accepted by the static GitHub resource.')
        print('PASS: dynamic-resource token rejected by the static GitHub endpoint.')
else:
    if not any(tool['name'] == 'get_me' for tool in tools):
        raise SystemExit('Expected read-only get_me tool was not advertised.')
    result = rpc('tools/call', {'name': 'get_me', 'arguments': {}}, 3, 'get_me')
    if result.get('isError'):
        raise SystemExit('GitHub get_me returned a tool error; check PAT validity/permissions.')
    print('PASS: read-only GitHub get_me tool completed through IAM-authenticated Microgateway.')
if session:
    with request(resource, headers={'Authorization': 'Bearer ' + token, 'Mcp-Session-Id': session}, method='DELETE') as response:
        print('Session cleanup HTTP', response.status)
