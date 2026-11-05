#!/usr/bin/env python3
"""Validate and activate only the MCP IAM instance, with rollback."""
import argparse
import datetime
import hashlib
import json
import os
from pathlib import Path
import subprocess
import uuid

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--context', required=True)
parser.add_argument('--activate', action='store_true', required=True)
parser.add_argument('--file', type=Path)
parser.add_argument('--expected-active-sha256', help='Acknowledge the exact live configuration after reviewing editor changes')
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
candidate = (args.file or root / 'manifests/mcp/configuration/iam/iam-mcp.yaml').resolve()
try:
    candidate_bytes = candidate.read_bytes()
except OSError:
    parser.error('Cannot read the candidate configuration file.')
kubectl = ['kubectl', '--context', args.context, '-n', 'mcp']
execute = kubectl + ['exec', 'airlock-iam-0', '-c', 'airlock-iam', '--']

def run(command, *, check=True):
    result = subprocess.run(command, capture_output=True, text=True)
    if check and result.returncode:
        raise RuntimeError('Kubernetes or IAM action failed; no secret-bearing diagnostics displayed.')
    return result

# Compare with the desired StatefulSet image; IAM's validator checks schema compatibility.
workload = json.loads(run(kubectl + ['get', 'statefulset', 'airlock-iam', '-o', 'json']).stdout)
iam_container = next(container for container in workload['spec']['template']['spec']['containers']
                     if container['name'] == 'airlock-iam')
image = run(kubectl + ['get', 'pod', 'airlock-iam-0', '-o',
                      'jsonpath={.spec.containers[?(@.name=="airlock-iam")].image}']).stdout
if image != iam_container['image']:
    parser.error('Wait for the IAM StatefulSet image rollout before activating configuration.')

# Confirm the declared startup environment exists. Native validation checks the
# candidate's schema and its mounted secret-file references before replacement.
environment = dict(item.split('=', 1) for item in run(execute + ['env', '-0']).stdout.split('\0') if '=' in item)
for entry in iam_container.get('env', []):
    if not environment.get(entry['name']):
        raise RuntimeError('Required runtime variable is missing: ' + entry['name'])
folder = root / '.local/mcp'
folder.mkdir(mode=0o700, parents=True, exist_ok=True)
os.chmod(folder, 0o700)
stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '-' + uuid.uuid4().hex[:8]
staged = f'/tmp/iam-mcp-env-{stamp}.yaml'
active = '/home/airlock/iam/instances/auth/iam-config.yaml'
backup = active + '.before-' + stamp
candidate_hash = hashlib.sha256(candidate_bytes).hexdigest()
live_hash = run(execute + ['sha256sum', active]).stdout.split()[0]
record = folder / 'last-deployed-iam.sha256'
recorded_hash = record.read_text().strip() if record.exists() else candidate_hash
if args.expected_active_sha256 and args.expected_active_sha256 != live_hash:
    raise RuntimeError('The reviewed active hash no longer matches the running configuration.')
if live_hash not in (recorded_hash, candidate_hash, args.expected_active_sha256):
    raise RuntimeError('IAM configuration changed outside this deployer. Export/review Config Editor changes first; '
                       'then pass --expected-active-sha256 with the reviewed live hash. Nothing replaced.')
try:
    run(kubectl + ['cp', str(candidate), f'airlock-iam-0:{staged}', '-c', 'airlock-iam'])
    run(execute + ['/opt/airlock-iam/bin/iam', 'config', 'validate', '-f', staged, '--level', 'STANDARD'])
    transaction = f'''set -eu
chmod 600 {staged}
test "$(sha256sum {active} | cut -d ' ' -f 1)" = "{live_hash}" || exit 3
cp {active} {backup}
chmod 600 {backup}
cp {staged} {active}
if /opt/airlock-iam/bin/iam config validate -c /home/airlock/iam -i auth --level STRICT; then
  chmod 600 {active}
else
  cp {backup} {active}
  exit 1
fi
'''
    result = run(execute + ['sh', '-c', transaction], check=False)
    if result.returncode == 3:
        raise RuntimeError('IAM configuration changed while the candidate was staged. Nothing replaced.')
    if result.returncode:
        log = folder / f'validation-{stamp}.log'
        log.write_text(result.stdout + result.stderr)
        log.chmod(0o600)
        raise RuntimeError(f'Strict validation failed; original restored. Private diagnostics: {log}')
    run(kubectl + ['rollout', 'restart', 'statefulset/airlock-iam'])
    result = run(kubectl + ['rollout', 'status', 'statefulset/airlock-iam', '--timeout=180s'], check=False)
    if result.returncode:
        run(execute + ['cp', backup, active])
        run(kubectl + ['rollout', 'restart', 'statefulset/airlock-iam'])
        raise RuntimeError('Candidate rollout failed; previous configuration restored and recovery restart requested.')
    record.write_text(candidate_hash + '\n')
    record.chmod(0o600)
    print('IAM configuration validated and active in mcp. Backup: ' + backup)
finally:
    run(execute + ['rm', '-f', staged], check=False)
