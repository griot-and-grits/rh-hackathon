# OpenShift Deployment Guide

> Deploy the full stack to Red Hat OpenShift or RHOAI workbenches.

## Prerequisites

- [ ] Access to an OpenShift cluster
- [ ] `oc` CLI installed (auto-installed by `make check-oc`)
- [ ] Logged in: `oc login <cluster-url>`

## Quick Start

```bash
# Login to OpenShift (get command from web console)
oc login <cluster-url>

# Setup namespace with MongoDB + MinIO
make setup-openshift USERNAME=yourname

# Deploy application code with hot-reload
make deploy-code
```

## What Gets Created

| Resource | Name | Purpose |
|----------|------|---------|
| Namespace | gng-yourname | Your personal namespace |
| Deployment | mongodb | MongoDB database |
| Deployment | minio | MinIO object storage |
| Deployment | backend | FastAPI application |
| Deployment | frontend | Next.js application |
| ConfigMap | backend-config | Environment variables |
| Routes | frontend, backend, minio-console | External URLs |

## Accessing Your Services

```bash
# View all URLs and credentials
make info

# Get routes
oc get routes -n gng-yourname
```

## Code Synchronization

Edit code locally and sync automatically:

```bash
# Start background watcher (syncs on file changes)
make watch-backend

# Check watcher status
make watch-backend-status

# View sync logs
make watch-backend-logs

# Stop watcher
make watch-backend-stop
```

## Viewing Logs

```bash
make oc-logs-backend    # Backend logs
make oc-logs-frontend   # Frontend logs
make oc-logs-mongodb    # Database logs
make oc-logs-minio      # Storage logs
```

## Optional: Deploy Whisper (Speech-to-Text)

For audio transcription capabilities:

```bash
make deploy-whisper MODEL=base
```

Then enable it in your backend configuration:
- `PROCESSING_ENABLE_TRANSCRIPTION=true`
- `PROCESSING_TRANSCRIPTION_API_URL=http://whisper-asr:9000`

See [infra/whisper/README.md](../../infra/whisper/README.md) for details on models (tiny, base, small, medium, large) and GPU requirements.

## Troubleshooting

### Login Issues
```bash
oc whoami               # Check current user
oc login <url> -u <user> # Re-login
```

### Namespace Detection Fails
If `make` commands complain about missing namespace:
```bash
# Explicitly set namespace
make deploy-code NAMESPACE=gng-yourname

# Or verify local config exists
cat .openshift-config
```

### Routes Not Created
If `make info` shows "Not deployed":
```bash
oc get routes
# If missing, re-run deployment
make deploy-code
```

### Sync/Watcher Issues
If code changes aren't reflecting:
1. Check watcher logs: `make watch-backend-logs`
2. Restart watcher: `make watch-backend-restart`
3. Force manual sync: `make sync`

## Next Steps

- [Configuration Reference](./configuration.md) - Adjust environment variables
- [API Reference](../api/README.md) - Explore the backend API
- [Admin Setup](./admin-setup.md) - Cluster administration

---

← [Back to Documentation Index](../README.md)
