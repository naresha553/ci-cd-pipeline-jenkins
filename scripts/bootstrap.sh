#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

# Git Bash on Windows rewrites Linux-looking arguments unless this is disabled.
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"

echo "==> Starting CI/CD stack (Jenkins, SonarQube, Gitea, Registry)..."
docker compose up -d --build

echo "==> Waiting for services to become healthy..."
sleep 30

echo "==> Provisioning kind cluster and Kubernetes namespace with Terraform..."
docker compose exec -T jenkins bash -lc '
  set -e
  cd /var/jenkins_home/cicd-lab/terraform
  terraform init -input=false
  terraform apply -auto-approve -input=false
'

echo "==> Wiring registry and Jenkins to kind network..."
docker compose exec -T jenkins bash -lc '
  cd /var/jenkins_home/cicd-lab
  chmod +x scripts/*.sh
  ./scripts/connect-registry-to-kind.sh
  ./scripts/connect-jenkins-to-kind.sh
'

echo ""
echo "Bootstrap complete."
echo "  Jenkins:    http://localhost:8080"
echo "  SonarQube:  http://localhost:9000  (admin / admin)"
echo "  Gitea:      http://localhost:3000"
echo "  Registry:   localhost:5000"
echo ""
echo "Next: follow README.md for one-time UI setup and run the pipeline."
