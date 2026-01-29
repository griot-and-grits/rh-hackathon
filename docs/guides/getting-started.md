# Getting Started (Local Development)

> Set up a complete local development environment in under 30 minutes.

> ⚠️ **Security Warning**
> This guide sets up a development environment with default credentials.
> **Do not use this configuration for production deployments.**

## Welcome!

Welcome to the Griot & Grits project! This guide will help you get the full stack running on your local machine using containers.

**Total Time Estimate**: ~15-20 minutes

## Prerequisites

Before you begin, ensure you have:

- [ ] **Git** installed
- [ ] **Node.js 18+** installed
- [ ] **Python 3.10+** installed
- [ ] **`make`** installed
- [ ] **Docker** or **Podman** installed and running

## Quick Start (5 commands)

```bash
# 1. Clone the repository (Time: ~1 min)
git clone https://github.com/griot-and-grits/rh-hackathon.git
cd rh-hackathon

# 2. Run setup (Time: ~5-10 mins)
# Clones backend/frontend repos and installs dependencies
make setup-local

# 3. Start all services (Time: ~2 mins)
# Pulls images and starts containers
make dev

# 4. Verify everything is running
make status

# 5. Open the application
open http://localhost:3000
```

## Verify Success

If setup was successful, you should see:
- [ ] Frontend running at http://localhost:3000
- [ ] Backend API docs at http://localhost:8000/docs
- [ ] MinIO Console at http://localhost:9001 (user/pass: `minioadmin` / `minioadmin`)

## What Gets Installed

The `make setup-local` command:
1. Clones `gng-backend` to `~/gng-backend`
2. Clones `gng-web` to `~/gng-web`
3. Creates `.env` files from templates
4. Installs Python dependencies (via `uv` or `pip`)
5. Installs Node.js dependencies (via `npm`)

## Service URLs

| Service | URL | Purpose |
|---------|-----|---------|
| Frontend | http://localhost:3000 | Web application |
| Backend API | http://localhost:8000/docs | Swagger UI |
| MinIO Console | http://localhost:9001 | Object storage UI |

## Default Credentials

> **Note**: These are for local development only.

| Service | Username | Password |
|---------|----------|----------|
| MongoDB | admin | gngdevpass12 |
| MinIO | minioadmin | minioadmin |

## Common Commands

```bash
make status          # Check what's running
make stop-services   # Stop MongoDB + MinIO
make dev-backend     # Run backend only
make dev-frontend    # Run frontend only
make clean-local     # Remove containers
```

## Troubleshooting

### Port already in use
```bash
lsof -i :3000  # Find process using port
kill -9 <PID>  # Kill it
```

### Services won't start
```bash
make status           # Check status
podman ps -a          # Check containers
make clean-local      # Clean and restart
make start-services
```

## Next Steps

- [OpenShift Deployment](./openshift-deployment.md) - Deploy to OpenShift
- [Configuration Reference](./configuration.md) - All environment variables

---

← [Back to Documentation Index](../README.md)
