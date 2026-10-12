#!/usr/bin/env bash
set -euo pipefail
for c in kubectl terraform git python3 curl; do command -v "$c" >/dev/null || { echo "Missing: $c" >&2; exit 1; }; done
kubectl config current-context
kubectl cluster-info
kubectl get nodes -o wide
kubectl get storageclass
printf '\nArgo CD status (optional):\n'
kubectl get pods -n argocd
printf '\nMonitoring status (optional):\n'
kubectl get pods -n poc-observability
