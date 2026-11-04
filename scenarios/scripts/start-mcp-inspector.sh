#!/usr/bin/env bash
# Keep the Inspector pin in the launcher rather than in the setup guide.
set -euo pipefail
repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
ca_certificate="${1:-$repo_dir/.local/mcp/iam-mcp-ca.crt}"
if [[ ! -r "$ca_certificate" ]]; then
  echo "CA certificate missing. Complete the README certificate trust step first." >&2
  exit 1
fi
export NODE_EXTRA_CA_CERTS="$ca_certificate"
exec npx @modelcontextprotocol/inspector@2.11.0
