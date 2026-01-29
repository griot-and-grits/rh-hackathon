# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **hackathon infrastructure toolkit** for the "Griot & Grits" project - an AI-powered platform for preservation of minority history. The repository contains deployment automation for both local container-based development and Red Hat OpenShift environments. **No application code lives here** - backend (FastAPI) and frontend (Next.js) source code is in separate repositories (`gng-backend`, `gng-web`).

## Common Commands

### Local Development

```bash
make setup-local          # One-time setup (clones repos, installs deps)
make dev                  # Start everything (MongoDB + MinIO + Backend + Frontend)
make start-services       # Start MongoDB + MinIO only
make dev-backend          # Start FastAPI backend
make dev-frontend         # Start Next.js frontend
make status               # Check what's running
make stop-services        # Stop services
make clean-local          # Remove containers
```

### OpenShift Development

```bash
# Initial setup
oc login <cluster-url>
make setup-openshift                  # Creates gng-<username> namespace with MongoDB + MinIO
make setup-openshift-with-code        # Same + deploys backend/frontend with hot-reload

# View information
make info                             # Shows URLs, credentials, connection details
make oc-status                        # View all OpenShift resources
make oc-logs-backend                  # Backend logs
make oc-logs-frontend                 # Frontend logs

# Code sync (after setup-openshift-with-code)
make watch-backend                    # Start continuous backend sync (background)
make watch-backend-logs               # View sync activity
make watch-backend-stop               # Stop sync
make sync                             # Manual sync (both backend + frontend)

# Cleanup
make cleanup-jobs                     # Clean completed OpenShift jobs
make clean-openshift                  # Delete namespace + local config files
```

### Admin Commands (cluster-admin only)

```bash
make admin-import-images              # Pre-import container images
make admin-create-namespaces FILE=users.txt   # Bulk namespace creation
make admin-create-namespaces COUNT=60         # Create numbered namespaces
```

## Architecture

```
Frontend (Next.js)  →  Backend (FastAPI)
    :3000                   :8000
                               ↓
                    ┌──────────┼──────────┐
                    ↓          ↓          ↓
                MongoDB    MinIO    Whisper (optional)
                 :27017    :9000
                Database  Storage  Transcription
```

### Repository Structure

```
rh-hackathon/
├── Makefile                  # Main orchestration (all commands route through here)
├── scripts/                  # Bash automation scripts
│   ├── setup.sh              # Local dev environment setup
│   ├── setup-openshift.sh    # OpenShift namespace + services setup
│   ├── deploy-services.sh    # Deploy MongoDB + MinIO to OpenShift
│   ├── deploy-code.sh        # Deploy backend + frontend with hot-reload
│   ├── sync-code.sh          # Manual code sync to pods
│   └── watch-backend.sh      # Continuous backend file watcher
├── infra/                    # Kubernetes/OpenShift YAML manifests
│   ├── mongodb/openshift/    # MongoDB deployment + init job
│   ├── minio/openshift/      # MinIO deployment + init job
│   ├── backend/openshift/    # FastAPI deployment + config
│   ├── frontend/openshift/   # Next.js deployment
│   └── whisper/              # Optional Whisper ASR service
└── env-templates/            # Environment file templates for apps
```

## Key Design Decisions

1. **No pre-built images**: Code is cloned directly in pod init containers, enabling hot-reload with `uvicorn --reload` and `next dev`

2. **Namespace auto-detection**: `.openshift-config` file stores namespace/username; most commands auto-detect from this file

3. **emptyDir volumes**: MongoDB/MinIO use emptyDir (data lost on pod restart) - acceptable for hackathon use, not production

4. **Hardcoded credentials**:
   - MongoDB: `admin` / `gngdevpass12`
   - MinIO: `minioadmin` / `minioadmin`
   - Bucket: `artifacts`

5. **Per-user isolation**: Each participant gets personal namespace `gng-<username>` with RBAC isolation

## Known Issues / Pending Fixes

**MongoDB Service missing (PR #28)**: The `main` branch is missing a Service definition in `infra/mongodb/openshift/mongodb.yaml`. This causes `oc port-forward service/mongodb` to fail. If redeploying MongoDB, either:
- Wait for PR #28 to merge, or
- Cherry-pick from `fix/mongodb-service-missing` branch, or
- Manually apply: `oc apply -f` from that branch

Current OpenShift deployment (`gng-user50`) already has the fix applied directly.

## Git Workflow

This is an active hackathon project:

- **Never push without explicit request** - always wait for user to ask
- **Never push to main** - main is protected; all changes go through PRs
- **Use feature branches** - create a branch when starting work (wait for user direction on branch name/timing)
- **Commits are fine** - commit freely to track progress on branches

## Working with This Repository

When modifying infrastructure:
- **Add new services**: Create `infra/<service>/openshift/` directory with YAML manifests
- **Change default configuration**: Edit relevant script in `scripts/`
- **Adjust resource limits**: Edit CPU/memory in deployment YAML files
- **Add Makefile targets**: Follow the existing pattern with `check-oc` dependency for OpenShift commands

When troubleshooting:
- Use `make info` to see all connection details
- Check `make oc-status` for resource state
- View logs with `make oc-logs-<service>`
- Override namespace: `make <command> NAMESPACE=gng-custom`
