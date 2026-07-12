#!/usr/bin/env bash

set -Eeuo pipefail

ENVIRONMENT="${1:?Environment is required}"
NAMESPACE="monitoring-${ENVIRONMENT}"
BASE_DIR="openshift"
ENV_DIR="environments/${ENVIRONMENT}"

SECRET_NAME="grafana-admin"

oc get namespace "${NAMESPACE}" >/dev/null 2>&1 ||
    oc create namespace "${NAMESPACE}"

if ! oc -n "${NAMESPACE}" get secret "${SECRET_NAME}" >/dev/null 2>&1; then
    GRAFANA_ADMIN_PASSWORD="$(
        openssl rand -base64 32 |
        tr -d '\n'
    )"

    oc -n "${NAMESPACE}" create secret generic "${SECRET_NAME}" \
        --from-literal=admin-user="admin" \
        --from-literal=admin-password="${GRAFANA_ADMIN_PASSWORD}"
fi

oc -n "${NAMESPACE}" apply -f "${BASE_DIR}/prometheus"
oc -n "${NAMESPACE}" apply -f "${BASE_DIR}/grafana"

if [ -d "${ENV_DIR}" ]; then
    oc -n "${NAMESPACE}" apply -f "${ENV_DIR}"
fi

oc -n "${NAMESPACE}" rollout status deployment/prometheus \
    --timeout=300s

oc -n "${NAMESPACE}" rollout status deployment/grafana \
    --timeout=300s