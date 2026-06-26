#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
Set-Location $RootDir

function Test-DockerRunning {
    try {
        docker info | Out-Null
        return $true
    } catch {
        return $false
    }
}

Write-Host "==> Local CI/CD Lab bootstrap" -ForegroundColor Cyan

if (-not (Test-DockerRunning)) {
    Write-Host "Docker is not running. Install Docker Desktop and start it first." -ForegroundColor Red
    Write-Host "See docs/DOCKER_SETUP.md"
    exit 1
}

Write-Host "==> Starting CI/CD stack..."
docker compose up -d --build

Write-Host "==> Waiting for services (30s)..."
Start-Sleep -Seconds 30

Write-Host "==> Provisioning kind cluster via Terraform inside Jenkins container..."
docker compose exec -T jenkins bash -lc @"
set -e
cd /var/jenkins_home/cicd-lab/terraform
terraform init -input=false
terraform apply -auto-approve -input=false
"@

Write-Host "==> Connecting registry and Jenkins to kind network..."
docker compose exec -T jenkins bash -lc @"
set -e
cd /var/jenkins_home/cicd-lab
chmod +x scripts/*.sh
./scripts/connect-registry-to-kind.sh
./scripts/connect-jenkins-to-kind.sh
"@

Write-Host ""
Write-Host "Bootstrap complete!" -ForegroundColor Green
Write-Host "  Jenkins:    http://localhost:8080"
Write-Host "  SonarQube:  http://localhost:9000  (default admin / admin)"
Write-Host "  Gitea:      http://localhost:3000"
Write-Host "  Registry:   localhost:5000"
Write-Host ""
Write-Host "Next steps: open README.md for one-time UI setup."
