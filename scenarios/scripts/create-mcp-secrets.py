#!/usr/bin/env python3
"""Prepare local secrets only. Never contacts Kubernetes or prints values."""
import base64
import json
import os
from pathlib import Path
import secrets
import stat
import tempfile

root = Path(__file__).resolve().parents[2]
folder = root / '.local/mcp'
folder.mkdir(mode=0o700, parents=True, exist_ok=True)
os.chmod(folder, 0o700)

def random_key(size=32):
    return base64.b64encode(secrets.token_bytes(size)).decode()

def secret(name, data):
    return {'apiVersion': 'v1', 'kind': 'Secret',
            'metadata': {'name': name, 'namespace': 'mcp'},
            'type': 'Opaque', 'stringData': data}

data = {'apiVersion': 'v1', 'kind': 'List', 'items': [
    secret('mariadb-credentials', {
        'database': 'airlockiam', 'username': 'airlockiam',
        'password': secrets.token_urlsafe(32), 'root-password': secrets.token_urlsafe(32)}),
    secret('iam-oidc-secrets', {
        'keystore-password': secrets.token_urlsafe(32),
        'login-encryption-key': random_key(), 'login-hmac-key': random_key(64),
        'device-cookie-key': random_key(), 'service-container-secret': secrets.token_urlsafe(32)})]}

path = folder / 'secrets.yaml'
# Publish the complete file without replacing credentials used by existing PVCs.
with tempfile.TemporaryDirectory(dir=folder) as staging:
    staged_path = Path(staging) / path.name
    fd = os.open(staged_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'w') as output:
        json.dump(data, output, indent=2)
        output.write('\n')
    try:
        os.link(staged_path, path)
    except FileExistsError:
        if not stat.S_ISREG(path.lstat().st_mode):
            raise SystemExit('Cannot reuse .local/mcp/secrets.yaml because it is not a regular file.')
        print('Reused .local/mcp/secrets.yaml. Nothing deployed.')
    else:
        print('Prepared .local/mcp/secrets.yaml (mode 600). Nothing deployed. Keep these values with the MCP PVCs.')
