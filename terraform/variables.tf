variable "cluster_name" {
  description = "kind cluster name"
  type        = string
  default     = "cicd-lab"
}

variable "namespace" {
  description = "Kubernetes namespace for the demo app"
  type        = string
  default     = "demo"
}

variable "kubeconfig_path" {
  description = "Path to kubeconfig written by kind"
  type        = string
  default     = "../kubeconfig"
}

variable "registry_host" {
  description = "Local registry host reachable from kind nodes"
  type        = string
  default     = "host.docker.internal:5000"
}

variable "node_image" {
  description = "kind node image (pin to a known-good Kubernetes version)"
  type        = string
  default     = "kindest/node:v1.29.4"
}
