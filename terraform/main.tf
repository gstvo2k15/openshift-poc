resource "kubernetes_namespace_v1" "app" {
  metadata {
    name   = "devsecops-demo"
    labels = { "app.kubernetes.io/part-of" = "devsecops-poc" }
  }
}
resource "kubernetes_namespace_v1" "ci" {
  metadata {
    name = "ci-jenkins"
  }
}
resource "kubernetes_namespace_v1" "observability" {
  metadata {
    name = "poc-observability"
  }
}
resource "kubernetes_resource_quota_v1" "app" {
  metadata {
    name      = "demo-quota"
    namespace = kubernetes_namespace_v1.app.metadata[0].name
  }
  spec {
    hard = {
      "requests.cpu"    = "2"
      "requests.memory" = "2Gi"
      "limits.cpu"      = "4"
      "limits.memory"   = "4Gi"
      "pods"            = "8"
    }
  }
}
