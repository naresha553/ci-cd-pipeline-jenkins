#!/usr/bin/env bash
set -euo pipefail

JENKINS_CONTAINER="${JENKINS_CONTAINER:-cicd-jenkins}"
KIND_NETWORK="${KIND_NETWORK:-kind}"

if ! docker inspect "${JENKINS_CONTAINER}" >/dev/null 2>&1; then
  echo "Jenkins container ${JENKINS_CONTAINER} not found."
  exit 0
fi

if ! docker network inspect "${KIND_NETWORK}" >/dev/null 2>&1; then
  echo "Kind network ${KIND_NETWORK} not found yet."
  exit 0
fi

if docker inspect -f '{{json .NetworkSettings.Networks}}' "${JENKINS_CONTAINER}" | grep -q "\"${KIND_NETWORK}\""; then
  echo "Jenkins already connected to ${KIND_NETWORK}"
else
  echo "Connecting ${JENKINS_CONTAINER} to ${KIND_NETWORK}..."
  docker network connect "${KIND_NETWORK}" "${JENKINS_CONTAINER}"
fi

echo "Jenkins kind network wiring complete."
