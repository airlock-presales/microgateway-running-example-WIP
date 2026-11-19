#!/usr/bin/env python3
"""Read a PAT file and update only the MCP route; explicit context/action flags required."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--context', required=True)
parser.add_argument('--set-pat', action='store_true', required=True,
                    help='Explicitly patch only the MCP GitHub route')
parser.add_argument('--token-file', type=Path,
                    default=Path(__file__).resolve().parents[2] / 'github_pat.txt',
                    help='PAT file (default: github_pat.txt in the repository root)')
args = parser.parse_args()
try:
    token = args.token_file.read_text().strip()
except (OSError, UnicodeError):
    parser.error('Cannot read the token file; check its path, permissions and text encoding.')
if not token or any(c.isspace() for c in token):
    parser.error('The token file must contain one nonempty token without internal whitespace.')

command = ['kubectl', '--context', args.context, '-n', 'mcp']
result = subprocess.run(command + ['get', 'httproute', 'github-mcp', '-o', 'json'],
                        check=True, capture_output=True, text=True)
route = json.loads(result.stdout)
if route['spec']['hostnames'] != ['github-mcp-iam-127-0-0-1.nip.io']:
    parser.error('MCP route hostname does not match. Refusing to patch.')
filters = route['spec']['rules'][0]['filters']
paths = [f'/spec/rules/0/filters/{i}/requestHeaderModifier/set/{j}/value'
         for i, item in enumerate(filters) if item['type'] == 'RequestHeaderModifier'
         for j, header in enumerate(item['requestHeaderModifier'].get('set', []))
         if header['name'].lower() == 'authorization']
if len(paths) != 1:
    parser.error('Expected exactly one upstream Authorization replacement.')

patch = [{'op': 'test', 'path': '/metadata/resourceVersion',
          'value': route['metadata']['resourceVersion']},
         {'op': 'replace', 'path': paths[0], 'value': 'Bearer ' + token}]
folder = Path(__file__).resolve().parents[2] / '.local/mcp'
folder.mkdir(mode=0o700, parents=True, exist_ok=True)
os.chmod(folder, 0o700)
fd, name = tempfile.mkstemp(prefix='github-pat-', suffix='.json', dir=folder)
try:
    with os.fdopen(fd, 'w') as output:
        json.dump(patch, output)
    # Avoid exposing a patch body or request diagnostics on failure.
    status = subprocess.run(command + ['patch', 'httproute', 'github-mcp',
                            '--type=json', '--patch-file', name, '-o', 'name'],
                            capture_output=True, text=True)
    if status.returncode:
        raise SystemExit('Patch failed; token value and server diagnostics withheld. Check MCP route status and retry deliberately.')
    print('Updated the upstream token on mcp/github-mcp only.')
finally:
    Path(name).unlink(missing_ok=True)
