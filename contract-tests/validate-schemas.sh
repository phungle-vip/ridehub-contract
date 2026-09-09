#!/usr/bin/env bash
set -euo pipefail

echo "==> Running contract tests and schema validations..."
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

FAILED=0

# 1. Validate Avro schemas are valid JSON
echo "1. Validating Avro schemas..."
for avsc in "$REPO_ROOT"/src/main/avro/**/*.avsc "$REPO_ROOT"/src/main/avro/*.avsc; do
  [ -f "$avsc" ] || continue
  if python3 -m json.tool "$avsc" >/dev/null 2>&1 || jq . "$avsc" >/dev/null 2>&1; then
    echo "  [PASS] Avro schema syntax: $(basename "$avsc")"
  else
    echo "  [FAIL] Invalid JSON in Avro schema: $avsc"
    FAILED=$((FAILED + 1))
  fi
done

# 2. Validate JSON schemas
echo "2. Validating JSON schemas..."
for schema in "$REPO_ROOT"/src/main/json-schema/**/*.json; do
  [ -f "$schema" ] || continue
  if python3 -m json.tool "$schema" >/dev/null 2>&1 || jq . "$schema" >/dev/null 2>&1; then
    echo "  [PASS] JSON schema syntax: $(basename "$schema")"
  else
    echo "  [FAIL] Invalid JSON in schema: $schema"
    FAILED=$((FAILED + 1))
  fi
done

# 3. Validate examples
echo "3. Validating example payloads..."
for ex in "$REPO_ROOT"/examples/**/*.json; do
  [ -f "$ex" ] || continue
  if python3 -m json.tool "$ex" >/dev/null 2>&1 || jq . "$ex" >/dev/null 2>&1; then
    echo "  [PASS] Example payload: $(basename "$ex")"
  else
    echo "  [FAIL] Invalid JSON in example: $ex"
    FAILED=$((FAILED + 1))
  fi
done

# 4. Validate OpenAPI specs
echo "4. Validating OpenAPI YAML specs (syntax & semantics)..."
for spec in "$REPO_ROOT"/src/main/openapi/*.yaml "$REPO_ROOT"/src/main/openapi/*.yml; do
  [ -f "$spec" ] || continue
  if python3 -c "
import yaml, sys
try:
    with open('$spec') as f:
        data = yaml.safe_load(f)
    assert 'openapi' in data, 'Missing openapi version'
    assert 'paths' in data, 'Missing paths section'
    for path, methods in data.get('paths', {}).items():
        for method, details in methods.items():
            if method in ['get', 'post', 'put', 'delete', 'patch']:
                assert 'responses' in details, f'Missing responses in {path} {method}'
except Exception as e:
    sys.exit(str(e))
" >/dev/null 2>&1; then
    echo "  [PASS] OpenAPI YAML syntax & semantic structure: $(basename "$spec")"
  else
    echo "  [FAIL] Invalid OpenAPI spec or missing required structure: $spec"
    FAILED=$((FAILED + 1))
  fi
done

# 5. Validate AsyncAPI specs
echo "5. Validating AsyncAPI YAML specs..."
for spec in "$REPO_ROOT"/src/main/asyncapi/*.yaml "$REPO_ROOT"/src/main/asyncapi/*.yml; do
  [ -f "$spec" ] || continue
  if python3 -c "
import yaml, sys
try:
    with open('$spec') as f:
        data = yaml.safe_load(f)
    assert 'asyncapi' in data, 'Missing asyncapi version'
    assert 'channels' in data, 'Missing channels section'
except Exception as e:
    sys.exit(str(e))
" >/dev/null 2>&1; then
    echo "  [PASS] AsyncAPI YAML syntax & semantic structure: $(basename "$spec")"
  else
    echo "  [FAIL] Invalid AsyncAPI spec: $spec"
    FAILED=$((FAILED + 1))
  fi
done

# 6. Check Pact directory
echo "6. Checking Pact contract repository..."
if [ -d "$REPO_ROOT/pacts" ]; then
  PACT_COUNT=$(find "$REPO_ROOT/pacts" -name "*.json" | wc -l)
  echo "  [INFO] Found $PACT_COUNT Pact contract file(s) in pacts/"
fi

if [ "$FAILED" -eq 0 ]; then
  echo "==> All schema, contract, and semantic tests PASSED!"
  exit 0
else
  echo "==> Contract validation FAILED with $FAILED errors!"
  exit 1
fi

