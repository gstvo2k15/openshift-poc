#!/usr/bin/env bash

set -euo pipefail

ENVIRONMENT="${1:?environment requerido}"
NAMESPACE="monitoring-${ENVIRONMENT}"


oc get namespace "$NAMESPACE" >/dev/null
oc -n "$NAMESPACE" apply -f openshift/base/grafana-dashboard.yaml
oc -n "$NAMESPACE" rollout restart deployment/grafana
oc -n "$NAMESPACE" rollout status deployment/grafana --timeout=10m
