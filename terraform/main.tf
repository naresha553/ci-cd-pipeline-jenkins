terraform {
  required_version = ">= 1.5.0"

  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# The kind cluster is provisioned via the kind CLI (baked into the Jenkins image).
# This avoids the tehcyx/kind provider's "docker logs -f" streaming bug that
# fails when Terraform runs inside a container against a mounted Docker socket.
resource "null_resource" "kind_cluster" {
  triggers = {
    cluster_name    = var.cluster_name
    namespace       = var.namespace
    registry_host   = var.registry_host
    node_image      = var.node_image
    kubeconfig_path = var.kubeconfig_path
    config_hash     = filemd5("${path.module}/kind-config.yaml")
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command     = <<-EOT
      set -euo pipefail

      if kind get clusters 2>/dev/null | grep -qx "${var.cluster_name}"; then
        echo "kind cluster '${var.cluster_name}' already exists; reusing it."
      else
        kind create cluster \
          --name "${var.cluster_name}" \
          --image "${var.node_image}" \
          --config "${path.module}/kind-config.yaml" \
          --wait 120s
      fi

      # Internal kubeconfig: API server reachable as <cluster>-control-plane:6443
      # from other containers on the shared "kind" docker network.
      kind get kubeconfig --internal --name "${var.cluster_name}" > "${var.kubeconfig_path}"

      kubectl --kubeconfig="${var.kubeconfig_path}" create namespace "${var.namespace}" \
        --dry-run=client -o yaml | kubectl --kubeconfig="${var.kubeconfig_path}" apply -f -

      kubectl --kubeconfig="${var.kubeconfig_path}" -n "${var.namespace}" \
        create configmap local-registry-hosting \
        --from-literal=localRegistryHosting.v1="host: \"${var.registry_host}\"" \
        --dry-run=client -o yaml | kubectl --kubeconfig="${var.kubeconfig_path}" apply -f -

      echo "kind cluster '${var.cluster_name}' is ready."
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-lc"]
    command     = "kind delete cluster --name ${self.triggers.cluster_name} || true"
  }
}
