variable "minikube_profile" {
  description = "Nombre del perfil de Minikube"
  type        = string
  default     = "minikube"
}

variable "argocd_admin_password" {
  description = "Contraseña para el administrador de ArgoCD (predeterminada: admin)"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "monitoring_retention_days" {
  description = "Días de retención para los datos de monitoreo"
  type        = number
  default     = 7
}

# outputs.tf

output "argocd_url" {
  description = "URL para acceder a ArgoCD"
  value       = "http://$(minikube ip -p ${var.minikube_profile}):30080"
}

output "grafana_url" {
  description = "URL para acceder a Grafana"
  value       = "http://$(minikube ip -p ${var.minikube_profile}):30300"
}

output "prometheus_url" {
  description = "URL para acceder a Prometheus"
  value       = "http://$(minikube ip -p ${var.minikube_profile}):30090"
}

output "dependency_track_frontend_url" {
  description = "URL para acceder a Dependency Track Frontend"
  value       = "http://$(minikube ip -p ${var.minikube_profile}):30280"
}

output "owasp_zap_url" {
  description = "URL para acceder a OWASP ZAP"
  value       = "http://$(minikube ip -p ${var.minikube_profile}):30800"
}