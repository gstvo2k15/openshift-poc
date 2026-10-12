#!/usr/bin/env bash
set -euo pipefail
# Start kubectl port-forward first, or supply the URL of your optional Ingress.
URL="${APP_URL:-http://127.0.0.1:8080}"
RESPONSE="$(curl --fail --silent --show-error --connect-timeout 10 --max-time 30 "${URL%/}/")"
grep -F 'CI/CD working!' <<< "$RESPONSE"
echo "Smoke test passed: ${URL%/}/"
