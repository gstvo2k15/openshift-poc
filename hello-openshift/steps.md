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






### Artifactory / Helm

Lo que yo haría, cCrearía una aplicación Maven. Por ejemplo:

```bash
demo-openshift

pom.xml

src/
```

Dockerfile
```bash
FROM artifactory.cib.echonet/middleware-docker-local-release/mdw-openjdk-temurin-11-alpine-cib:v3.23

WORKDIR /app

COPY target/demo.jar app.jar

ENTRYPOINT ["java","-jar","app.jar"]
```


El chart Helm que has encontrado:
`tomcat-sample-app-0.1.0.tgz`

Eso es un Helm Chart empaquetado. Puedes comprobar su contenido con:

```bash
helm pull \
https://artifactory.cib.echonet/artifactory/middleware-generic-local-release/helm/tomcat-sample-app/tomcat-sample-app-0.1.0.tgz
```

o simplemente descargar el .tgz. Después:

`tar -xzf tomcat-sample-app-0.1.0.tgz`

Obtendrás algo parecido a:

```bash
tomcat-sample-app/
    Chart.yaml
    values.yaml
    templates/
        deployment.yaml
        service.yaml
        route.yaml
```

Si consigues descargarlo:
`helm show values tomcat-sample-app-0.1.0.tgz`

`helm template tomcat-sample-app-0.1.0.tgz`


Seguramente descubrirás algo muy parecido a tu Deployment:

- Deployment
- Service
- Route
- ConfigMap
- Secret
- PVC





Lo más interesante
El chart y la imagen probablemente están relacionados. Es decir:
```bash
Aplicación Java

↓

Dockerfile

↓

mdw-openjdk-temurin

↓

Artifactory Docker

↓

Helm Chart

↓

OpenShift
```


Siguiente paso que tendría más valor
Con oc, helm y acceso a Artifactory, intentaría desplegar el tomcat-sample-app.

URL:
`https://get.helm.sh/helm-v4.2.3-windows-amd64.zip`

```bash
.\helm.exe version

.\helm.exe repo add middleware https://artifactory.cib.echonet/artifactory/middleware-generic-local-release/helm

.\helm.exe repo update

.\helm.exe search repo

.\helm.exe install tomcat middleware/tomcat-sample-app -n middleware-poc
```

Si el repositorio Helm está accesible, añade el repositorio:

`helm repo add middleware https://artifactory.cib.echonet/artifactory/middleware-generic-local-release/helm`

Actualiza el índice:

`helm repo update`

Busca el chart:

`helm search repo middleware`

Y despliega:

`helm install tomcat-demo middleware/tomcat-sample-app -n middleware-poc`

