#!/usr/bin/env bash

set -euo pipefail

ENVIRONMENT="${1:?environment requerido}"
NAMESPACE="monitoring-${ENVIRONMENT}"


: "${GRAFANA_ADMIN_USER:?Falta GRAFANA_ADMIN_USER}"
: "${GRAFANA_ADMIN_PASSWORD:?Falta GRAFANA_ADMIN_PASSWORD}"

oc apply -f "openshift/base/namespace.yaml" --dry-run=client -o yaml | sed "s/monitoring-template/${NAMESPACE}/" | oc apply -f -

oc -n "$NAMESPACE" create secret generic grafana-admin \
  --from-literal=username="$GRAFANA_ADMIN_USER" \
  --from-literal=password="$GRAFANA_ADMIN_PASSWORD" \
  --dry-run=client -o yaml | oc apply -f -

oc apply -k "openshift/overlays/${ENVIRONMENT}"

oc -n "$NAMESPACE" rollout restart deployment/grafana
oc -n "$NAMESPACE" rollout status deployment/prometheus --timeout=10m
oc -n "$NAMESPACE" rollout status deployment/grafana --timeout=10m
oc -n "$NAMESPACE" wait --for=condition=Ready pod -l app=prometheus --timeout=5m
oc -n "$NAMESPACE" wait --for=condition=Ready pod -l app=grafana --timeout=5m

printf 'Grafana: https://%s\n' "$(oc -n "$NAMESPACE" get route grafana -o jsonpath='{.spec.host}')"
printf 'Prometheus: https://%s\n' "$(oc -n "$NAMESPACE" get route prometheus -o jsonpath='{.spec.host}')"
