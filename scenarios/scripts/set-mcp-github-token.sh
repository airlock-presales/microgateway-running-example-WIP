#!/usr/bin/env bash
# Keep the PAT out of repository files and command-line arguments.
set -euo pipefail
: "${GITHUB_PAT:?Set GITHUB_PAT to a GitHub token with the permissions required for the demo}"
python3 - <<'PY' | kubectl -n mcp patch httproute github-mcp --type=json --patch-file=/dev/stdin
import json
import os
print(json.dumps([{"op": "replace", "path": "/spec/rules/0/filters/2/requestHeaderModifier/set/0/value",
                   "value": "Bearer " + os.environ["GITHUB_PAT"]}]))
PY
