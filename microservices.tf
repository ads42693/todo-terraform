# microservices.tf

# Namespace para aplicación
resource "kubernetes_namespace" "app" {
  metadata {
    name = "microservices-app"
  }
}

# Configuración de ArgoCD para implementar los microservicios usando GitOps
resource "kubernetes_manifest" "argocd_application" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "microservices-app"
      namespace = "argocd"
    }
    spec = {
      project = "default"
      source = {
        repoURL        = "https://github.com/tu-usuario/infra-gitops-repo.git" # Reemplazar con tu repositorio GitOps
        targetRevision = "HEAD"
        path           = "kubernetes"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "microservices-app"
      }
      syncPolicy = {
        automated = {
          prune       = true
          selfHeal    = true
          allowEmpty  = false
        }
        syncOptions = ["CreateNamespace=true"]
      }
    }
  }

  depends_on = [
    helm_release.argocd,
    kubernetes_namespace.app
  ]
}

# Configuración de monitoreo para microservicios
resource "kubernetes_manifest" "service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "microservices-monitor"
      namespace = "monitoring"
      labels = {
        "release" = "prometheus"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/part-of" = "microservices-app"
        }
      }
      endpoints = [
        {
          port     = "metrics"
          interval = "15s"
          path     = "/metrics"
        }
      ]
      namespaceSelector = {
        matchNames = ["microservices-app"]
      }
    }
  }

  depends_on = [
    helm_release.prometheus,
    kubernetes_namespace.app
  ]
}