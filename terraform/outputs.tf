output "cluster_name" {
  value = kind_cluster.default.name
}

output "namespace" {
  value = var.namespace
}

output "kubeconfig_path" {
  value = var.kubeconfig_path
}
