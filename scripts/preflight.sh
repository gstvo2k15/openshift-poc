#!/usr/bin/env bash
set -euo pipefail
for c in oc terraform helm git; do command -v "$c" >/dev/null || { echo "Missing: $c" >&2; exit 1; }; done
oc whoami
oc get nodes -o wide
oc get storageclass
oc get clusterversion || true
printf '
GitOps operator status:
'
oc get csv -A 2>/dev/null | grep -i gitops || true
printf '
Monitoring status:
'
oc get pods -n openshift-user-workload-monitoring 2>/dev/null || true
