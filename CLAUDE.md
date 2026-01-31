# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A deployment and development toolkit for the **Griot & Grits** project (AI-powered minority history preservation). This repo contains no application source code — it orchestrates two external repos:

- **Frontend** (`gng-web`): Next.js React app, cloned to `~/gng-web` (local) or `./gng-web` (OpenShift)
- **Backend** (`gng-backend`): FastAPI Python app, cloned to `~/gng-backend` (local) or `./gng-backend` (OpenShift)

Both are cloned from `https://github.com/griot-and-grits/`.

## Architecture

```
Frontend (Next.js :3000) → Backend (FastAPI :8000)
                                ↓
                    ┌───────────┼───────────┐
                    MongoDB    MinIO     Whisper (optional)
                    :27017     :9000     (transcription)
```

- **MongoDB**: Document database (credentials: admin/gngdevpass12, database: gngdb)
- **MinIO**: S3-compatible object storage (credentials: minioadmin/minioadmin, bucket: artifacts)
- **Container runtime**: Podman (preferred, rootless) or Docker, stored in `.container-runtime`

## Common Commands

All orchestration goes through the Makefile:

```bash
# Local development
make setup-local          # One-time: clones repos, checks deps, installs Podman
make dev                  # Start full stack (MongoDB + MinIO + backend + frontend)
make dev-backend          # Backend only (uvicorn --reload on :8000)
make dev-frontend         # Frontend only (next dev on :3000)
make start-services       # Start MongoDB and MinIO containers
make stop-services        # Stop containers
make status               # Check running services
make clean-local          # Remove containers (keep data)
make clean-local-all      # Remove containers and data volumes

# OpenShift deployment
make setup-openshift USERNAME=<name>           # Create namespace gng-<name> with services
make setup-openshift-with-code USERNAME=<name> # Above + deploy apps with hot-reload
make deploy-services      # Deploy MongoDB + MinIO (auto-detects namespace)
make deploy-code          # Deploy backend + frontend with hot-reload
make info                 # Show URLs, credentials, connection details
make oc-status            # View all OpenShift resources

# Code sync to OpenShift
make sync                 # Manual sync (both apps)
make sync-backend         # Sync backend only
make watch-backend        # Continuous background sync (instant + every 2s)
make watch-backend-stop   # Stop background sync
make watch-start          # Auto-sync watcher (both apps)
make watch-stop-all       # Stop all watchers

# Logs
make oc-logs-backend
make oc-logs-frontend
make oc-logs-mongodb
make oc-logs-minio

# Cleanup
make clean-openshift      # Delete namespace + local config files
make cleanup-jobs         # Remove completed OpenShift jobs

# Optional
make deploy-whisper MODEL=base   # Deploy Whisper ASR (tiny/base/small/medium/large-v3)
```

Most OpenShift commands auto-detect the namespace from `.openshift-config`. Override with `NAMESPACE=gng-custom`.

## Repository Structure

- `scripts/` — Bash scripts that implement all Makefile targets (setup, deploy, sync, watch, clean)
- `infra/` — Kubernetes/OpenShift YAML manifests organized by service (`mongodb/`, `minio/`, `backend/`, `frontend/`, `whisper/`)
- `env-templates/` — Template `.env` files for backend and frontend configuration
- `docs/ADMIN_SETUP.md` — Admin-only cluster preparation (namespace creation, image pre-import)
- `INFRA.md` — Detailed infrastructure and deployment reference

## Key Configuration Files (gitignored)

- `.openshift-config` — Stores NAMESPACE and USERNAME for auto-detection
- `.env.openshift` — OpenShift environment connection details
- `.container-runtime` — `podman` or `docker`
- `.watch-backend.pid/.log` — Background watcher state

## Working with Scripts

All scripts are bash. They use color-coded output, auto-detect the container runtime, and handle error cases. When modifying scripts:

- The container runtime (podman/docker) is read from `.container-runtime` or auto-detected
- OpenShift scripts expect `oc` CLI to be available and the user to be logged in
- Scripts use `oc rsync` for code sync, excluding `.git`, `__pycache__`, `node_modules`, `.venv`
- Backend runs via `uvicorn app.server:app --reload` (Python 3.11)
- Frontend runs via `npm run dev` (Node.js 20)

## OpenShift Deployment Model

Pods clone application repos at startup via git, then run in dev mode with hot-reload. Code changes are synced to running pods using `oc rsync`, which triggers uvicorn/Next.js reload. This is not a traditional build-and-deploy pipeline — it's designed for rapid hackathon iteration.
