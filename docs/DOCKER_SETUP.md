# Docker Desktop Setup (Windows 11)

Docker Desktop is required for this lab. Git is already installed on your machine.

## Install via winget (recommended)

```powershell
winget install --id Docker.DockerDesktop -e --accept-source-agreements --accept-package-agreements
```

## Manual install

1. Download from https://www.docker.com/products/docker-desktop/
2. Run the installer and enable **WSL 2** backend when prompted.
3. Reboot if the installer requests it.

## First launch (required once)

1. Start **Docker Desktop** from the Start menu.
2. Accept the license terms (free for personal/educational/small-business use).
3. Sign in with a Docker Hub account (or skip if allowed).
4. Wait until the whale icon shows **Docker Desktop is running**.
5. Open PowerShell and verify:

```powershell
docker --version
docker compose version
```

## Enable Kubernetes (optional)

This lab uses **kind** instead of Docker Desktop Kubernetes. You do **not** need to enable Kubernetes in Docker Desktop settings.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `docker` not recognized | Reboot after install, then start Docker Desktop |
| WSL 2 required | Run `wsl --install` in an elevated PowerShell, reboot |
| Hyper-V / virtualization errors | Enable virtualization in BIOS; ensure Hyper-V is available |
| Slow first pull | Normal; images are large (Jenkins, SonarQube, Gitea) |

## Resource recommendations

- RAM: 8 GB+ allocated to Docker (you have ~32 GB system RAM)
- CPUs: 4+ cores
- Disk: 20 GB+ free

Settings → Resources → adjust Memory/CPUs if builds are slow.
