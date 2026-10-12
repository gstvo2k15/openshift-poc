# Observability deployment (optional, resource intensive)

The base app runs without this stack. For a small Kubernetes cluster, install this optional stack only if sufficient memory and persistent storage are available. `observability/alerts.yaml` requires the Prometheus Operator CRDs and kube-state-metrics.

For a separate PoC stack (needs Helm, storage, enough RAM, cluster-admin permissions and chart/Pod Security validation):

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana-community https://grafana-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack -n poc-observability -f observability/helm-values/prometheus.yaml
helm upgrade --install loki grafana-community/loki -n poc-observability -f observability/helm-values/loki.yaml
helm upgrade --install alloy grafana/alloy -n poc-observability -f observability/helm-values/alloy.yaml
```

**Important:** Chart releases and Kubernetes Pod Security policies vary; these values are illustrative and are **not certified as deployable on all Kubernetes versions**. The Loki gateway service name must be confirmed (`kubectl get svc -n poc-observability`) before deploying Alloy. Grafana datasource should point to the Prometheus service and Loki gateway; dashboard provisioning is not automated here. The monitoring chart may conflict with existing cluster monitoring resources. Never expose Grafana with the sample password. No metrics endpoint/JMX exporter is included in the demo WAR; this stack currently observes Kubernetes workload metrics, not Tomcat JVM metrics. Loki requires the Alloy pod-log RBAC granted by its chart.
