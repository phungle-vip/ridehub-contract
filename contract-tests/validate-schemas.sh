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
echo "4. Validating OpenAPI YAML specs..."
for spec in "$REPO_ROOT"/src/main/openapi/*.yaml "$REPO_ROOT"/src/main/openapi/*.yml; do
  [ -f "$spec" ] || continue
  if python3 -c "import yaml; yaml.safe_load(open('$spec'))" >/dev/null 2>&1; then
    echo "  [PASS] OpenAPI YAML syntax: $(basename "$spec")"
  else
    echo "  [FAIL] Invalid YAML in OpenAPI spec: $spec"
    FAILED=$((FAILED + 1))
  fi
done

# 5. Validate AsyncAPI specs
echo "5. Validating AsyncAPI YAML specs..."
for spec in "$REPO_ROOT"/src/main/asyncapi/*.yaml "$REPO_ROOT"/src/main/asyncapi/*.yml; do
  [ -f "$spec" ] || continue
  if python3 -c "import yaml; yaml.safe_load(open('$spec'))" >/dev/null 2>&1; then
    echo "  [PASS] AsyncAPI YAML syntax: $(basename "$spec")"
  else
    echo "  [FAIL] Invalid YAML in AsyncAPI spec: $spec"
    FAILED=$((FAILED + 1))
  fi
done

if [ "$FAILED" -eq 0 ]; then
  echo "==> All schema and contract tests PASSED!"
  exit 0
else
  echo "==> Contract validation FAILED with $FAILED errors!"
  exit 1
fi

