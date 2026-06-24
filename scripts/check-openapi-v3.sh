#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OPENAPI_REPO="${OPENAPI_REPO:-$(cd "$ROOT/../idl-openapi-repo" && pwd)}"
PROTO_PATH="${PROTO_PATH:-vesta/lendora/fides-bff/v1/auth.proto}"
OPENAPI_PATH="${OPENAPI_PATH:-vesta/lendora/fides-bff/v1/openapi.yaml}"
GENERATED="$ROOT/../.generated/openapi/openapi.yaml"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cd "$ROOT"
buf generate --template buf.gen.openapi.yaml --path "$PROTO_PATH"
install -d "$OPENAPI_REPO/$(dirname "$OPENAPI_PATH")"
cp "$GENERATED" "$OPENAPI_REPO/$OPENAPI_PATH"
cp "$OPENAPI_REPO/$OPENAPI_PATH" "$TMP/openapi.yaml"
cd "$OPENAPI_REPO"
if git ls-files --error-unmatch "$OPENAPI_PATH" >/dev/null 2>&1; then
  git checkout -- "$OPENAPI_PATH"
else
  rm -f "$OPENAPI_PATH"
fi
cd "$ROOT"
buf generate --template buf.gen.openapi.yaml --path "$PROTO_PATH"
install -d "$OPENAPI_REPO/$(dirname "$OPENAPI_PATH")"
cp "$GENERATED" "$OPENAPI_REPO/$OPENAPI_PATH"
diff -u "$OPENAPI_REPO/$OPENAPI_PATH" "$TMP/openapi.yaml"
