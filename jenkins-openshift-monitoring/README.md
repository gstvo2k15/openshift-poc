# Jenkins + OpenShift: Grafana y Prometheus

Pipeline declarativo para desplegar Grafana y Prometheus mediante Jenkins usando recursos estándar de OpenShift.

## Alcance

El paquete crea por entorno:

- Namespace `monitoring-<entorno>`.
- Prometheus con configuración, almacenamiento persistente, Service y Route TLS.
- Grafana con almacenamiento persistente, datasource Prometheus, dashboard inicial, Service y Route TLS.
- ServiceAccount y RBAC de descubrimiento limitados al namespace.
- Validaciones previas, espera de rollouts y comprobación de pods Ready.

No existe una garantía técnica del 100 % sin ejecutar contra el clúster real. El resultado depende, como mínimo, de RBAC, políticas SCC, conectividad, registro de imágenes, StorageClass, cuotas, DNS, certificados y versiones del clúster. El pipeline está diseñado para detectar esas incompatibilidades y detenerse con un error concreto.

## Estructura

```text
.
├── Jenkinsfile
├── README.md
├── openshift
│   ├── base
│   └── overlays
│       ├── dev
│       ├── tst
│       ├── stg
│       └── pro
└── scripts
    ├── validate.sh
    ├── preflight.sh
    ├── deploy.sh
    ├── deploy-dashboards.sh
    └── remove.sh
```

## Requisitos del agente Jenkins

El nodo con label `openshift-cli` debe incluir:

- Git.
- OpenShift CLI `oc` compatible con el clúster.
- `jq`.
- `promtool`, recomendado.
- Acceso HTTPS al API de OpenShift y a los registros de imágenes.

Plugins Jenkins:

- Pipeline.
- Credentials Binding.
- AnsiColor.

## Credenciales Jenkins

Crear estas credenciales:

1. `openshift-api-token`, tipo **Secret text**, con un token de ServiceAccount capaz de crear o gestionar los namespaces y recursos del paquete.
2. `grafana-admin`, tipo **Username with password**, usado para crear el Secret `grafana-admin`.

Configurar `OPENSHIFT_API_URL` como variable global, de carpeta o de job:

```text
https://api.cluster.example:6443
```

No guardar tokens ni contraseñas en Git.

## Permisos mínimos

Para crear los namespaces desde Jenkins, la identidad debe poder crear namespaces y gestionar los recursos incluidos. En entornos donde los namespaces se precrean, puede limitarse el acceso a cada namespace.

Comprobaciones útiles:

```bash
oc auth can-i create namespaces --as=system:serviceaccount:ci:jenkins
oc auth can-i create deployments -n monitoring-dev --as=system:serviceaccount:ci:jenkins
oc auth can-i create routes.route.openshift.io -n monitoring-dev --as=system:serviceaccount:ci:jenkins
oc auth can-i create persistentvolumeclaims -n monitoring-dev --as=system:serviceaccount:ci:jenkins
```

## Parámetros

`ENVIRONMENT`:

- `dev`
- `tst`
- `acc`
- `prod`

`ACTION`:

- `deploy`: despliegue completo.
- `dashboards`: actualiza únicamente el dashboard provisionado y reinicia Grafana.
- `remove`: elimina el namespace completo, incluidos PVC y datos.

`remove` es destructivo. En producción requiere aprobación manual.

## Primera ejecución

1. Subir este directorio a un repositorio.
2. Crear un Pipeline o Multibranch Pipeline apuntando al `Jenkinsfile`.
3. Configurar las credenciales y `OPENSHIFT_API_URL`.
4. Ejecutar `ACTION=deploy`, `ENVIRONMENT=dev`.
5. Revisar las URLs de Grafana y Prometheus impresas al final.

## Validación local

Con sesión iniciada en OpenShift:

```bash
scripts/validate.sh dev
scripts/preflight.sh dev deploy
```

Renderizar el manifiesto completo:

```bash
oc kustomize openshift/overlays/dev
```

Validación server-side sin persistir cambios:

```bash
oc apply --server-side --dry-run=server \
  -k openshift/overlays/dev
```

Esta última validación es la más fiable antes del despliegue porque aplica las reglas reales del API server, admission webhooks, CRD y políticas del clúster.

## Imágenes

Versiones fijadas:

```text
quay.io/prometheus/prometheus:v3.4.1
grafana/grafana:12.0.2
```

En clústeres sin acceso a Internet, espejar ambas imágenes en el registro interno y modificar los campos `image`.

## StorageClass

Los PVC no fijan `storageClassName`; usan la StorageClass predeterminada. Si el clúster no tiene una predeterminada, añadirla en:

```text
openshift/base/prometheus-pvc.yaml
openshift/base/grafana-pvc.yaml
```

Ejemplo:

```yaml
spec:
  storageClassName: managed-storage
```

## Seguridad OpenShift

Los contenedores están configurados con:

- `runAsNonRoot: true`.
- `allowPrivilegeEscalation: false`.
- eliminación de todas las capabilities.
- perfil seccomp `RuntimeDefault`.

No se fija UID para permitir que OpenShift asigne uno desde el rango del namespace.

## Dashboards

El dashboard inicial está en:

```text
openshift/base/grafana-dashboard.yaml
```

El JSON debe permanecer dentro de `data.overview.json`. La acción `dashboards` actualiza el ConfigMap y reinicia Grafana.

## Prometheus

La configuración está en:

```text
openshift/base/prometheus-config.yaml
```

Prometheus descubre pods únicamente en su namespace y solo scrapea aquellos con anotaciones:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
```

## Diagnóstico

```bash
oc -n monitoring-dev get all,route,pvc
oc -n monitoring-dev describe deployment prometheus
oc -n monitoring-dev describe deployment grafana
oc -n monitoring-dev logs deployment/prometheus
oc -n monitoring-dev logs deployment/grafana
oc -n monitoring-dev get events --sort-by=.lastTimestamp
```

PVC pendientes:

```bash
oc -n monitoring-dev describe pvc prometheus-data
oc -n monitoring-dev describe pvc grafana-data
oc get storageclass
```

Imágenes no descargables:

```bash
oc -n monitoring-dev get pods
oc -n monitoring-dev describe pod <pod>
```

## Endurecimiento recomendado

Antes de producción:

- Restringir la Route de Prometheus o eliminarla si solo Grafana debe acceder a Prometheus.
- Integrar Grafana con OAuth de OpenShift o el proveedor corporativo de identidad.
- Configurar NetworkPolicy.
- Establecer quotas y LimitRange.
- Enviar backups de PVC o usar almacenamiento respaldado.
- Añadir alertas y reglas de grabación específicas.
- Usar imágenes espejadas y verificadas por digest.
