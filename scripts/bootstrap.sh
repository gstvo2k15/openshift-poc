#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${KUBECONFIG:?Set KUBECONFIG to an absolute path to one Kubernetes kubeconfig file}"
terraform -chdir=terraform init
terraform -chdir=terraform apply -auto-approve -var="kubeconfig=$KUBECONFIG"
if [[ "${IMAGE:-}" != "" ]]; then
  IMAGE="$IMAGE" ./scripts/update-gitops.sh
  kubectl apply -k gitops/base
  kubectl -n devsecops-demo rollout status deployment/tomcat-demo --timeout=240s
  echo 'Access: kubectl -n devsecops-demo port-forward service/tomcat-demo 8080:8080'
  echo 'Then open http://127.0.0.1:8080 or run ./scripts/smoke-test.sh.'
else
  echo 'Set IMAGE to a published, accessible OCI image and rerun to deploy.'
fi
