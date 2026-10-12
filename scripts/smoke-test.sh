#!/usr/bin/env bash
set -euo pipefail
HOST="$(oc -n devsecops-demo get route tomcat-demo -o jsonpath='{.spec.host}')"
curl --fail --silent --show-error "https://${HOST}/" | tee /tmp/devsecops-poc-response.html | grep -F 'CI/CD working!'
echo "Smoke test passed: https://${HOST}/"
