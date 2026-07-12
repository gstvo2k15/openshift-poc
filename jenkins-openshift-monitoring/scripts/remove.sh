#!/usr/bin/env bash

set -euo pipefail

ENVIRONMENT="${1:?environment required}"
NAMESPACE="monitoring-${ENVIRONMENT}"


case "$NAMESPACE" in
    monitoring-dev|monitoring-tst|monitoring-stg|monitoring-pro)
        ;;
    *)
        echo "Namespace not allowed" >&2
        exit 2
        ;;
esac

oc delete namespace "$NAMESPACE" --ignore-not-found=true
