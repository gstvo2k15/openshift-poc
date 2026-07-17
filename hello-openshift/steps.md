cd hello-openshift

OC="$(realpath ../oc)"
NAMESPACE=middleware-poc

"$OC" project "$NAMESPACE"
"$OC" project -q


"$OC" -n "$NAMESPACE" create configmap hello-tomcat-config \
  --from-literal=APP_MESSAGE='Hello OpenShift POC desde ConfigMap' \
  --dry-run=client \
  -o yaml |
"$OC" -n "$NAMESPACE" apply -f -




"$OC" -n "$NAMESPACE" apply -f -


"$OC" -n "$NAMESPACE" expose deployment hello-tomcat \
  --name=hello-tomcat \
  --port=8080 \
  --target-port=8080



"$OC" -n "$NAMESPACE" expose service hello-tomcat




"$OC" -n "$NAMESPACE" expose service hello-tomcat



"$OC" -n "$NAMESPACE" get \
  buildconfig,build,imagestream,deployment,pods,service,route



"$OC" -n "$NAMESPACE" rollout status deployment/hello-tomcat


"$OC" -n "$NAMESPACE" get route hello-tomcat \
  -o jsonpath='https://{.spec.host}{"\n"}'





oc new-project tomcat-poc


oc new-build \
  --name=hello-tomcat \
  --binary \
  --strategy=docker



oc start-build hello-tomcat \
  --from-dir=. \
  --follow


oc get imagestream
oc describe imagestream hello-tomcat


oc create configmap hello-tomcat-config \
  --from-literal=APP_MESSAGE='Hello OpenShift POC from ConfigMap'


PROJECT="$(oc project -q)"

oc set image deployment/hello-tomcat \
  hello-tomcat="image-registry.openshift-image-registry.svc:5000/${PROJECT}/hello-tomcat:latest"


oc expose deployment hello-tomcat \
  --name=hello-tomcat \
  --port=8080 \
  --target-port=8080



oc expose service hello-tomcat


oc get route hello-tomcat \
  -o jsonpath='https://{.spec.host}{"\n"}'



oc get pods -w





oc get deployment,service,route



oc logs deployment/hello-tomcat



oc rollout status deployment/hello-tomcat






Reconstruir después de modificar código

Desde ~/hello-openshift:

oc start-build hello-tomcat \
  --from-dir=. \
  --follow



oc rollout restart deployment/hello-tomcat
oc rollout status deployment/hello-tomcat










