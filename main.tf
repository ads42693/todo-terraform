terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "minikube"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "minikube"
  }
}

# Namespace
resource "kubernetes_namespace" "todo_app" {
  metadata {
    name = "todo-app"
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "kubernetes_namespace" "security" {
  metadata {
    name = "security"
  }
}

# ArgoCD Installation
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.35.0"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  set {
    name  = "server.service.type"
    value = "NodePort"
  }
}

# Prometheus & Grafana Installation
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "48.1.2"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  set {
    name  = "grafana.service.type"
    value = "NodePort"
  }
}

# Security Tools
resource "helm_release" "trivy_operator" {
  name       = "trivy-operator"
  repository = "https://aquasecurity.github.io/helm-charts"
  chart      = "trivy-operator"
  version    = "0.18.0"
  namespace  = kubernetes_namespace.security.metadata[0].name
}

# Output the URLs to access the services
output "argocd_url" {
  value = "http://$(minikube ip):$(kubectl get svc argocd-server -n argocd -o jsonpath='{.spec.ports[0].nodePort}')"
}

output "grafana_url" {
  value = "http://$(minikube ip):$(kubectl get svc prometheus-grafana -n monitoring -o jsonpath='{.spec.ports[0].nodePort}')"
}