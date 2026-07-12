#!/usr/bin/env bash

set -euo pipefail

ENVIRONMENT="${1:?Usage: validate.sh <environment>}"


case "$ENVIRONMENT" in
    dev|tst|acc|prod)
        ;;
    *)
        echo "Invalid environment" >&2
        exit 2
        ;;
esac

for cmd in oc jq; do
    if ! command -v "$cmd" >/dev/null
      then
        echo "Missing $cmd" >&2
        exit 1
    fi
done

oc kustomize "openshift/overlays/$ENVIRONMENT" > /tmp/rendered.yaml
oc apply --dry-run=client --validate=false -f /tmp/rendered.yaml >/dev/null

jq -e . < <(sed -n '/overview.json: |/,$p' openshift/base/grafana-dashboard.yaml | tail -n +2 | sed 's/^    //') >/dev/null

if command -v promtool >/dev/null
  then
    sed -n '/prometheus.yml: |/,$p' openshift/base/prometheus-config.yaml | tail -n +2 | sed 's/^    //' > /tmp/prometheus.yml
    promtool check config /tmp/prometheus.yml
  else
    echo "Warning: promtool is not installed; Prometheus validation will be performed when the pod starts" >&2
fi
