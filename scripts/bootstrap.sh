#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${KUBECONFIG:?Set KUBECONFIG to an absolute path to your OpenShift kubeconfig}"
terraform -chdir=terraform init
terraform -chdir=terraform apply -auto-approve -var="kubeconfig=$KUBECONFIG"
if [[ "${IMAGE:-}" != "" ]]; then
  IMAGE="$IMAGE" ./scripts/update-gitops.sh
  oc apply -k gitops/base
  oc -n devsecops-demo rollout status deployment/tomcat-demo --timeout=240s
  ROUTE="$(oc -n devsecops-demo get route tomcat-demo -o jsonpath='{.spec.host}')"
  echo "Application: https://$ROUTE"
else
  echo 'Set IMAGE to a published, accessible OCI image and rerun to deploy.'
fi
