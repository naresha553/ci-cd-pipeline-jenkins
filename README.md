# Local CI/CD Lab (Jenkins) - All Free Tools

A fully local CI/CD practice environment for Windows 11 that mirrors a production-style pipeline:

```
Gitea (GitHub) -> Jenkins -> Build -> Unit Tests -> SonarQube -> Terraform -> Docker -> Registry (ECR) -> kind (EKS) + Helm -> Verify
```

## Prerequisites

| Tool | Purpose |
|------|---------|
| [Docker Desktop](docs/DOCKER_SETUP.md) | Runs Jenkins, SonarQube, Gitea, registry, kind |
| Git | Source control (already installed) |

Recommended: 8+ GB RAM for Docker, 20+ GB free disk.

## Quick start

Use **Git Bash** from the project root:

```bash
# 1. Install and start Docker Desktop (see docs/DOCKER_SETUP.md)

# 2. Bootstrap the lab
./scripts/bootstrap.sh

# 3. Complete one-time UI setup below, then run the pipeline
```

PowerShell is also supported:

```powershell
.\scripts\bootstrap.ps1
```

## Services

| Service | URL | Default credentials |
|---------|-----|---------------------|
| Jenkins | http://localhost:8080 | No wizard (JCasC); create pipeline job manually |
| SonarQube | http://localhost:9000 | `admin` / `admin` (change on first login) |
| Gitea | http://localhost:3000 | Set up on first visit |
| Docker Registry | localhost:5000 | No auth (lab only) |
| Demo app (after deploy) | http://localhost:30080 | — |

## One-time UI setup

### 1. SonarQube token

1. Open http://localhost:9000 and log in (`admin` / `admin`).
2. Change the password when prompted.
3. Go to **My Account** -> **Security** -> **Generate Token**.
4. Copy the token and update Jenkins:

```powershell
# Stop Jenkins, update token, restart
docker compose stop jenkins
# Edit docker-compose.yml: set SONAR_TOKEN=<your-token>
docker compose up -d jenkins
```

Or update **Manage Jenkins** -> **Credentials** -> `sonar-token`.

### 2. Gitea repository

1. Open http://localhost:3000 and complete initial setup.
2. Create a user (e.g. `gitea` / `gitea123` to match defaults).
3. Create repository `demo-app` (private or public).
4. Push this project:

```bash
cd /c/Users/nares/CODE/Week-1-practise/ci-cd-pipeline-jenkins
git init
git add .
git commit -m "Initial CI/CD lab"
git remote add origin http://localhost:3000/gitea/demo-app.git
git push -u origin main
```

### 3. Jenkins pipeline job

1. Open http://localhost:8080.
2. **New Item** -> name: `demo-app-pipeline` -> **Pipeline** -> OK.
3. Under **Pipeline**:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `http://gitea:3000/gitea/demo-app.git` (from Jenkins container) or `http://host.docker.internal:3000/gitea/demo-app.git`
   - Credentials: add Gitea user/password
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
4. Save and **Build Now**.

**Alternative (fastest for first run):**

1. **New Item** -> `demo-app-pipeline` -> **Pipeline**.
2. Check **This project is parameterized** is off.
3. Under **Advanced**, set **Custom workspace** to `/var/jenkins_home/cicd-lab`.
4. Pipeline definition: **Pipeline script** -> paste contents of `Jenkinsfile`.
5. Save and **Build Now** (no Gitea required for first test).

### 4. Gitea webhook (optional)

1. In Gitea repo: **Settings** -> **Webhooks** -> **Add Webhook** -> Gitea.
2. Target URL: `http://jenkins:8080/gitea-webhook/post`
3. Trigger on push.

## Pipeline stages

| Stage | What it does |
|-------|----------------|
| Checkout | Pulls code from Gitea |
| Build | `mvn package` (Spring Boot) |
| Unit Tests | `mvn test` + JUnit report |
| SonarQube Scan | Static analysis via `sonar:sonar` |
| Terraform | Creates kind cluster + `demo` namespace |
| Docker Build | Builds app image from `app/Dockerfile` |
| Push to Registry | Pushes to local registry (`registry:5000`) |
| Deploy to Kubernetes | Helm install to kind cluster |
| Verify Deployment | Rollout status + `curl` health check |

## Project layout

```
ci-cd-pipeline-jenkins/
├── app/                  # Spring Boot sample app
├── docker-compose.yml    # Jenkins, SonarQube, Gitea, registry
├── helm/demo-app/        # Helm chart (EKS equivalent)
├── jenkins/              # Custom Jenkins image + JCasC
├── scripts/              # Bootstrap and kind wiring
├── terraform/            # kind cluster + namespace
├── Jenkinsfile           # Full CI/CD pipeline
└── docs/DOCKER_SETUP.md  # Docker Desktop install guide
```

## Manual commands

Use these from Git Bash:

```bash
# Keep Git Bash from rewriting Linux paths passed into containers.
export MSYS_NO_PATHCONV=1
export MSYS2_ARG_CONV_EXCL="*"

# Start stack
docker compose up -d --build

# Stop stack
docker compose down

# View logs
docker compose logs -f jenkins

# Re-run Terraform only
docker compose exec jenkins bash -lc "cd /var/jenkins_home/cicd-lab/terraform && terraform apply -auto-approve"

# Check Kubernetes
docker compose exec jenkins kubectl --kubeconfig=/var/jenkins_home/cicd-lab/kubeconfig get pods -n demo

# Test app
curl http://localhost:30080/
curl http://localhost:30080/health
```

## Tool mapping (production vs lab)

| Production | Local lab |
|------------|-----------|
| GitHub | Gitea |
| ECR | `registry:2` on port 5000 |
| EKS | kind (Kubernetes in Docker) |
| AWS Terraform | Terraform + kind/kubernetes providers |

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `docker` not found | Start Docker Desktop |
| Jenkins cannot reach SonarQube | Ensure all services are on `cicd-net`: `docker compose ps` |
| Image pull errors in kind | Run `./scripts/bootstrap.sh` again to reconnect registry |
| SonarQube scan fails | Update `SONAR_TOKEN` in docker-compose and recreate project in SonarQube |
| Port 8080/9000/3000 in use | Change ports in `docker-compose.yml` |
| Terraform kind errors | Ensure Docker socket is mounted into Jenkins |

## Tear down

```bash
docker compose down -v
docker compose exec jenkins kind delete cluster --name cicd-lab
# Or from host if kind is installed:
# kind delete cluster --name cicd-lab
```

## License

For learning and practice only. Do not expose this stack to the public internet without securing credentials and registry access.
