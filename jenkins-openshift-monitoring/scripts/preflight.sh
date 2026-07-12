#!/usr/bin/env bash

set -euo pipefail

ENVIRONMENT="${1:?environment requerido}"
ACTION="${2:?action requerida}"
NAMESPACE="monitoring-${ENVIRONMENT}"


oc whoami >/dev/null
oc api-resources --api-group=route.openshift.io | grep -q '^routes' || { echo "El clúster no expone Route" >&2; exit 1; }

if [[ "$ACTION" == "deploy" ]]
  then
    oc auth can-i create namespace | grep -qx yes || oc get namespace "$NAMESPACE" >/dev/null 2>&1 || {
    echo "Sin permiso para crear namespace y $NAMESPACE no existe" >&2; exit 1;
  }
    oc get storageclass -o name | grep -q . || { echo "No hay StorageClass disponible" >&2; exit 1; }
fi
