# Conduit Deployment

Automated deployment setup for the containerized Conduit fullstack application.

This repository contains the Docker-based application setup and a GitHub Actions workflow that builds the backend and frontend images, pushes them to GitHub Container Registry, and deploys the application to a Cloud VM via SSH.

## Table of Contents

* [Repository Structure](#repository-structure)
* [Quickstart](#quickstart)
* [Configuration](#configuration)
* [Usage](#usage)
* [Automated Deployment](#automated-deployment)
* [Security Notes](#security-notes)
* [Testing and Verification](#testing-and-verification)
* [Troubleshooting](#troubleshooting)

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│       └── deployment.yaml
├── backend/
│   ├── Dockerfile
│   ├── .dockerignore
│   └── ...
├── frontend/
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── nginx.conf
│   └── ...
├── docker-compose.yaml
├── example.env
├── .gitignore
└── README.md
```

## Quickstart

Create a local `.env` file and start the application:

```bash
cp example.env .env
docker compose pull
docker compose up -d
```

The frontend is available at:

```text
http://<server-ip>:8282
```

## Configuration

Runtime configuration is provided through environment variables. The `example.env` file documents all required variables. The real `.env` file must not be committed.

| Variable                       | Purpose                              |
| ------------------------------ | ------------------------------------ |
| `DJANGO_ALLOWED_HOSTS`         | Allowed hosts for the Django backend |
| `DJANGO_SECRET_KEY`            | Django secret key                    |
| `DJANGO_CORS_ORIGIN_WHITELIST` | Allowed frontend origin              |
| `POSTGRES_DB`                  | PostgreSQL database name             |
| `POSTGRES_USER`                | PostgreSQL database user             |
| `POSTGRES_PASSWORD`            | PostgreSQL database password         |
| `FRONTEND_PORT`                | Host port for the frontend           |
| `GHCR_NAMESPACE`               | GitHub Container Registry namespace  |
| `IMAGE_TAG`                    | Image tag used by Docker Compose     |

## Usage

```bash
# Start the application
docker compose up -d

# Stop the application
docker compose down

# View running containers
docker compose ps

# View logs
docker compose logs --tail=100

# View logs for a single service
docker compose logs --tail=100 frontend
docker compose logs --tail=100 backend
docker compose logs --tail=100 database
```

> [!WARNING]
> `docker compose down -v` removes the database volume and deletes all persisted data. Use it only when a full reset is intended.

## Automated Deployment

The deployment workflow is defined in `.github/workflows/deployment.yaml` and performs the following steps:

1. Builds the backend and frontend Docker images in GitHub Actions
2. Pushes both images to GitHub Container Registry
3. Creates a deployment `.env` file from GitHub Secrets
4. Copies `.env` and `docker-compose.yaml` to the Cloud VM via SSH
5. Pulls the new images and starts or updates the services with Docker Compose
6. Runs a frontend health check on port `8282`

The application is not built on the VM — it only pulls prebuilt images and starts the containers.

### Required GitHub Repository Variable

| Name             | Example                |
| ---------------- | ---------------------- |
| `GHCR_NAMESPACE` | `your-github-username` |

### Required GitHub Repository Secrets

| Name                           | Purpose                            |
| ------------------------------ | ---------------------------------- |
| `SSH_HOST`                     | Cloud VM host                      |
| `SSH_USER`                     | SSH deployment user                |
| `SSH_PRIVATE_KEY`              | Private SSH key for deployment     |
| `SSH_PORT`                     | SSH port                           |
| `DEPLOY_PATH`                  | Deployment directory on the VM     |
| `DJANGO_ALLOWED_HOSTS`         | Django allowed hosts               |
| `DJANGO_SECRET_KEY`            | Django secret key                  |
| `DJANGO_CORS_ORIGIN_WHITELIST` | Allowed frontend origin            |
| `DJANGO_SUPERUSER_USERNAME`    | Django admin username              |
| `DJANGO_SUPERUSER_EMAIL`       | Django admin email                 |
| `DJANGO_SUPERUSER_PASSWORD`    | Django admin password              |
| `POSTGRES_DB`                  | PostgreSQL database name           |
| `POSTGRES_USER`                | PostgreSQL database user           |
| `POSTGRES_PASSWORD`            | PostgreSQL database password       |
| `GHCR_USER`                    | GitHub Container Registry user     |
| `GHCR_TOKEN`                   | Token for pulling images from GHCR |

## Security Notes

* The real `.env` file is not committed.
* All deployment secrets are stored in GitHub Repository Secrets.
* The backend and database are only reachable inside the Docker network.
* The frontend is exposed on port `8282`.

#### Testing and Verification

Check the running containers on the VM:

```bash
cd <deploy-path>
docker compose ps
```

Expected result:

```text
database   Up (healthy)
backend    Up
frontend   Up   0.0.0.0:8282->80/tcp
```

Verify frontend availability from the VM:

```bash
curl -I http://localhost:8282
```

The application should also be reachable in the browser:

```text
http://<server-ip>:8282
```

Verify logs with:

```bash
docker compose logs --tail=100
```

PostgreSQL data is persisted in the named Docker volume `postgres_data`.



## Troubleshooting

**Port already allocated** — another container is using port `8282`:

```bash
sudo ss -tulpn | grep :8282
docker ps
docker stop <container-name>
```

**GHCR pull issues** — verify VM can authenticate to GitHub Container Registry:

```bash
docker login ghcr.io
```

Also check that `GHCR_USER` and `GHCR_TOKEN` are set in GitHub Repository Secrets.

**Application not reachable** — check container status and logs:

```bash
docker compose ps
docker compose logs --tail=100
```