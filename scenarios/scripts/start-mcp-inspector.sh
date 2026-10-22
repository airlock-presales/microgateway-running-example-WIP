#!/usr/bin/env bash
# Keep the tested Inspector version in the example, not in the README.
set -euo pipefail
ca_certificate="${1:-/tmp/mcp-ca.crt}"
if [[ ! -r "$ca_certificate" ]]; then
  echo "CA certificate not found: $ca_certificate. Export it using the README's certificate setup step." >&2
  exit 1
fi
export NODE_EXTRA_CA_CERTS="$ca_certificate"
exec npx @modelcontextprotocol/inspector@2.11.0
