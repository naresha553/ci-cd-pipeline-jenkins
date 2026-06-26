#!/usr/bin/env bash
# Connects the compose-managed local registry to a kind cluster network.
# Run after `terraform apply` creates the kind cluster.

set -euo pipefail

CLUSTER_NAME="${CLUSTER_NAME:-cicd-lab}"
REGISTRY_NAME="${REGISTRY_NAME:-cicd-registry}"
REGISTRY_PORT="${REGISTRY_PORT:-5000}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=connect-registry-to-kind.sh
source "${SCRIPT_DIR}/connect-registry-to-kind.sh"

echo "kind-with-registry wiring finished for cluster ${CLUSTER_NAME}."
