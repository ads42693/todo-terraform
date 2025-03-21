# Descripción: Configuración de Terraform para desplegar herramientas DevOps y de seguridad en un clúster de Kubernetes
terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.22.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.10.0"
    }
  }
  required_version = ">= 1.0.0"
}

# Especificar explícitamente el contexto de minikube
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

# Crear namespace para las herramientas DevOps
resource "kubernetes_namespace" "devops_tools" {
  metadata {
    name = "devops-tools"
  }
}

resource "kubernetes_namespace" "security_tools" {
  metadata {
    name = "security-tools"
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

# ArgoCD para GitOps
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.34.6"
  namespace  = kubernetes_namespace.argocd.metadata[0].name

  values = [
    <<-EOT
    server:
      extraArgs:
        - --insecure
      service:
        type: NodePort
        nodePortHttp: 30080
    configs:
      secret:
        argocdServerAdminPassword: "$2a$10$dryiCLHSt5f.v.60KTvsrOyCiqMxAQlZ0COz0ULslv2QbCyjPLEXi" # admin (cambiar en producción)
    dex:
      enabled: false
    notifications:
      enabled: true
    EOT
  ]

  depends_on = [
    kubernetes_namespace.argocd
  ]
}

# Prometheus para monitoreo
resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "45.27.2"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    <<-EOT
    grafana:
      service:
        type: NodePort
        nodePort: 30300
      adminPassword: "admin" # cambiar en producción
    prometheus:
      service:
        type: NodePort
        nodePort: 30090
    alertmanager:
      service:
        type: NodePort
        nodePort: 30093
    EOT
  ]

  depends_on = [
    kubernetes_namespace.monitoring
  ]
}

# OWASP ZAP para DAST
resource "helm_release" "owasp_zap" {
  name       = "owasp-zap"
  repository = "https://advantageous.github.io/charts"
  chart      = "owasp-zap"
  version    = "0.3.5"
  namespace  = kubernetes_namespace.security_tools.metadata[0].name

  values = [
    <<-EOT
    replicaCount: 1
    service:
      type: NodePort
      port: 8080
      nodePort: 30800
    EOT
  ]

  depends_on = [
    kubernetes_namespace.security_tools
  ]
}

# Trivy para escaneo de vulnerabilidades
resource "helm_release" "trivy" {
  name       = "trivy"
  repository = "https://aquasecurity.github.io/helm-charts"
  chart      = "trivy"
  version    = "0.16.0"
  namespace  = kubernetes_namespace.security_tools.metadata[0].name

  values = [
    <<-EOT
    service:
      type: NodePort
      port: 4954
      nodePort: 30954
    trivy:
      debugMode: false
    EOT
  ]

  depends_on = [
    kubernetes_namespace.security_tools
  ]
}

# Dependecy-Track para SCA
resource "helm_release" "dependency_track" {
  name       = "dependency-track"
  repository = "https://dependencytrack.github.io/helm-charts"
  chart      = "dependency-track"
  version    = "0.7.0"
  namespace  = kubernetes_namespace.security_tools.metadata[0].name

  values = [
    <<-EOT
    apiServer:
      service:
        type: NodePort
        nodePort: 30180
    frontendService:
      type: NodePort
      nodePort: 30280
    EOT
  ]

  depends_on = [
    kubernetes_namespace.security_tools
  ]
}