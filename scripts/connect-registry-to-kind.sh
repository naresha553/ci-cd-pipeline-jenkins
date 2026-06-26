#!/usr/bin/env bash
set -euo pipefail

REGISTRY_CONTAINER="${REGISTRY_CONTAINER:-cicd-registry}"
KIND_NETWORK="${KIND_NETWORK:-kind}"

if ! docker inspect "${REGISTRY_CONTAINER}" >/dev/null 2>&1; then
  echo "Registry container ${REGISTRY_CONTAINER} not found. Start docker compose first."
  exit 1
fi

if ! docker network inspect "${KIND_NETWORK}" >/dev/null 2>&1; then
  echo "Kind network ${KIND_NETWORK} not found. Run terraform apply to create the cluster first."
  exit 1
fi

if docker inspect -f '{{json .NetworkSettings.Networks}}' "${REGISTRY_CONTAINER}" | grep -q "\"${KIND_NETWORK}\""; then
  echo "Registry already connected to ${KIND_NETWORK}"
else
  echo "Connecting ${REGISTRY_CONTAINER} to ${KIND_NETWORK}..."
  docker network connect "${KIND_NETWORK}" "${REGISTRY_CONTAINER}"
fi

echo "Registry wiring complete."
