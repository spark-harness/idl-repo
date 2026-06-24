#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cd "$ROOT"
buf generate --template buf.gen.openapi.yaml --path vesta/lendora/fides-bff/v1/auth.proto
cp openapi/fides-bff/openapi.yaml "$TMP/openapi.yaml"
if git ls-files --error-unmatch openapi/fides-bff/openapi.yaml >/dev/null 2>&1; then
  git checkout -- openapi/fides-bff/openapi.yaml
else
  rm -f openapi/fides-bff/openapi.yaml
fi
buf generate --template buf.gen.openapi.yaml --path vesta/lendora/fides-bff/v1/auth.proto
diff -u openapi/fides-bff/openapi.yaml "$TMP/openapi.yaml"
