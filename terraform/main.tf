terraform {
  required_version = ">= 1.5.0"

  required_providers {
    kind = {
      source  = "tehcyx/kind"
      version = "~> 0.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "kind" {}

resource "kind_cluster" "default" {
  name            = var.cluster_name
  wait_for_ready  = true
  kubeconfig_path = var.kubeconfig_path

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"
      kubeadm_config_patches = [
        "kind: InitConfiguration\nnodeRegistration:\n  kubeletExtraArgs:\n    node-labels: \"ingress-ready=true\"\n"
      ]
      extra_port_mappings {
        container_port = 30080
        host_port      = 30080
        protocol       = "TCP"
      }
      extra_port_mappings {
        container_port = 30443
        host_port      = 30443
        protocol       = "TCP"
      }
    }

    node {
      role = "worker"
    }

    containerd_config_patches = [
      <<-TOML
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors."host.docker.internal:5000"]
        endpoint = ["http://host.docker.internal:5000"]
      [plugins."io.containerd.grpc.v1.cri".registry.configs."host.docker.internal:5000".tls]
        insecure_skip_verify = true
      TOML
    ]
  }
}

resource "null_resource" "bootstrap_kubernetes" {
  depends_on = [kind_cluster.default]

  triggers = {
    cluster_name  = var.cluster_name
    namespace     = var.namespace
    registry_host = var.registry_host
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command     = <<-EOT
      set -euo pipefail
      kind get kubeconfig --internal --name "${var.cluster_name}" > "${var.kubeconfig_path}"
      kubectl --kubeconfig="${var.kubeconfig_path}" create namespace "${var.namespace}" --dry-run=client -o yaml | kubectl --kubeconfig="${var.kubeconfig_path}" apply -f -
      kubectl --kubeconfig="${var.kubeconfig_path}" -n "${var.namespace}" create configmap local-registry-hosting \
        --from-literal=localRegistryHosting.v1='host: "${var.registry_host}"
help: "Connect to local registry from kind nodes"' \
        --dry-run=client -o yaml | kubectl --kubeconfig="${var.kubeconfig_path}" apply -f -
    EOT
  }
}
