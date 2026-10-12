# Observability deployment (optional, resource intensive)

The base app runs without this stack. For a compact single-node OpenShift cluster, prefer the built-in OpenShift monitoring stack and enable user workload monitoring (requires cluster-admin). This avoids installing a second Prometheus and Alertmanager. `observability/alerts.yaml` is an example PrometheusRule; the built-in stack must expose the required kube-state-metrics series for the rule to fire.

For a separate PoC stack (needs Helm, storage, enough RAM, cluster-admin permissions and chart/SCC validation):

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana-community https://grafana-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack -n poc-observability -f observability/helm-values/prometheus.yaml
helm upgrade --install loki grafana-community/loki -n poc-observability -f observability/helm-values/loki.yaml
helm upgrade --install alloy grafana/alloy -n poc-observability -f observability/helm-values/alloy.yaml
```

**Important:** Chart releases and OpenShift SCC restrictions vary; these values are illustrative and are **not certified as deployable on all OpenShift versions**. The Loki gateway service name must be confirmed (`oc get svc -n poc-observability`) before deploying Alloy. Grafana datasource should point to the Prometheus service and Loki gateway; dashboard provisioning is not automated here. The monitoring chart may conflict with existing cluster monitoring resources. Never expose Grafana with the sample password. No metrics endpoint/JMX exporter is included in the demo WAR; this stack currently observes Kubernetes workload metrics, not Tomcat JVM metrics. Loki requires the Alloy pod-log RBAC granted by its chart.
