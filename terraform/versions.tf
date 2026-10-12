terraform {
  required_version = ">= 1.5.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }
}
provider "kubernetes" {
  config_path = pathexpand(var.kubeconfig)
}
variable "kubeconfig" {
  type    = string
  default = "~/.kube/config"
}
