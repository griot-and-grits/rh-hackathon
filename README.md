# Griot & Grits - Hackathon Toolkit

Development toolkit for the Griot & Grits project - AI-powered preservation of minority history.

## Quick Start

Choose your development environment:

### Option 1: Local Development (with containers)

**Prerequisites:** Git, Node.js 18+, Python 3.10+, `uv` or `pip`, `make`

```bash
cd ~/rh-hackathon
make setup-local            # One-time setup (clones repos, installs deps)
make dev                    # Start everything
```

**URLs:**
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000/docs
- MinIO Console: http://localhost:9001

**Utility commands:**
```bash
make status                 # Check what's running
make stop-services          # Stop services
make clean-local            # Remove containers
```

---

### Option 2: OpenShift/RHOAI (without containers)

For RHOAI workbenches where containers aren't available.

**Prerequisites:** OpenShift cluster access, `make`

The `oc` CLI will be automatically installed if not found.

**Setup:**
```bash
oc login <cluster-url>      # Get login command from web console
cd ~/rh-hackathon
make setup-openshift  # Will prompt for username interactively
```

This creates:
- Personal namespace: `gng-<username>`
- MongoDB database
- MinIO object storage
- `.env.openshift` file with all connection details

**Using your services:**
```bash
# View resources (auto-detects namespace)
make oc-status

# View logs (auto-detects namespace)
make oc-logs-mongodb
make oc-logs-minio

# Access MinIO console
oc get route minio-console -n gng-jdoe

# Clean up OpenShift (deletes namespace + local config files)
make clean-openshift

# Or just delete namespace (keeps local config files)
make delete-namespace
```

**View all connection details:**
```bash
make info  # Shows URLs, credentials, and all important information
```

**Port forwarding (for local access):**
```bash
oc port-forward service/mongodb 27017:27017 -n gng-<username>
oc port-forward service/minio 9000:9000 -n gng-<username>
```

Connection details are in `.env.openshift` - just load and use!

**Deploying application code with hot-reload:**

To deploy the frontend and backend code directly on OpenShift with automatic reload on changes:

```bash
# ONE command does everything!
make setup-openshift-with-code  # Prompts for username
```

This will:
- Deploy backend (FastAPI) with hot-reload at `https://backend-gng-<username>.apps...`
- Deploy frontend (Next.js) with hot-reload at `https://frontend-gng-<username>.apps...`
- Clone repos to `rh-hackathon/gng-backend` and `rh-hackathon/gng-web`
- **Start automatic code sync watcher in background**

**Automatic code sync:**

Once setup is complete, just edit code normally:

```bash
cd gng-backend
vim app/server.py
# Save file... automatically synced to pod within 1 second!
```

The watcher automatically syncs changes when you save files. No manual commands needed!

**Managing the watcher:**

```bash
make watch-status           # Check if running
make watch-logs             # View sync logs
make watch-stop             # Stop auto-sync
make watch-start            # Restart (auto-detects namespace)
```

**Continuous backend sync (for active development):**

```bash
# Syncs on file changes + every 2 seconds (instant updates)
make watch-backend                  # Start in background
make watch-backend-status           # Check if running
make watch-backend-logs             # View sync activity
make watch-backend-stop             # Stop watcher
```

This mode is perfect for backend development - it syncs both on file changes AND periodically, ensuring uvicorn --reload picks up changes instantly. Runs in background so it doesn't block your terminal.

**Stop all watchers:**

```bash
make watch-stop-all         # Stops both main watcher and backend watcher
```

**Manual sync (without watcher):**

```bash
make sync                   # Sync both (auto-detects namespace)
make sync-backend           # Sync backend only
make sync-frontend          # Sync frontend only
```

---

## Architecture

```
Frontend (Next.js)  →  Backend (FastAPI)
    :3000                   :8000
                               ↓
                    ┌──────────┼──────────┐
                    ↓          ↓          ↓
                MongoDB    MinIO    Whisper
                 :27017    :9000   (optional)
                Database  Storage  Transcription
```

## Project Structure

```
rh-hackathon/
├── scripts/
│   ├── setup.sh              # Local: One-time setup
│   ├── setup-openshift.sh    # OpenShift: One-time setup
│   ├── dev-all.sh            # Local: Start everything
│   ├── deploy-services.sh    # OpenShift: Deploy MongoDB + MinIO
│   ├── deploy-code.sh        # OpenShift: Deploy frontend + backend
│   └── ...
├── infra/
│   ├── mongodb/              # MongoDB deployment
│   ├── minio/                # MinIO deployment
│   ├── backend/              # Backend app deployment
│   ├── frontend/             # Frontend app deployment
│   └── whisper/              # Whisper ASR (optional)
└── env-templates/            # Environment file templates
```

## Common Tasks

### Local Development

```bash
# Start/stop services
make start-services
make stop-services

# Run backend/frontend separately
make dev-backend        # Terminal 1
make dev-frontend       # Terminal 2

# Check status
make status

# Clean up
make clean-local        # Remove containers, keep data
make clean-local-all    # Remove everything
```

### OpenShift Development

```bash
# View all URLs, credentials, and connection details
make info

# View all resources (auto-detects namespace)
make oc-status

# Deploy application code with hot-reload
make deploy-code

# Continuous backend sync (for active development)
make watch-backend              # Instant updates, background mode
make watch-backend-logs         # View sync activity

# Manual sync
make sync

# View application logs
make oc-logs-backend
make oc-logs-frontend

# Shell into pod
oc rsh deployment/mongodb -n gng-<username>

# Copy files
oc cp file.txt deployment/mongodb:/tmp/ -n gng-<username>

# Clean up old jobs
make cleanup-jobs

# Redeploy services
make deploy-services
```

## Troubleshooting

### Local Development

**Port already in use:**
```bash
lsof -i :3000  # Find process
kill -9 <PID>  # Kill it
```

**Services won't start:**
```bash
make status                # Check status
podman ps -a | grep gng    # Check containers
make clean-local           # Clean and restart
make start-services
```

**Backend can't connect:**
```bash
podman logs gng-mongodb    # Check MongoDB
grep DB_URI ~/.env         # Verify connection string
```

### OpenShift

**Not logged in:**
```bash
oc whoami  # Check login status
# Get new login command from web console:
# Click username → Copy login command
```

**Pods not running:**
```bash
make oc-status              # View all resources
oc describe pod <pod-name>  # Detailed pod info
make oc-logs-backend        # View backend logs
```

**Jobs accumulating:**
```bash
make cleanup-jobs  # Clean up completed jobs
```

**Start over:**
```bash
make clean-openshift   # Deletes namespace + local config files
make setup-openshift   # Setup fresh
```

## Environment Variables

Configuration files are created automatically:

**Local:** `~/gng-backend/.env`
**OpenShift:** `.env.openshift`

Key variables:
- `DB_URI` - MongoDB connection string
- `STORAGE_ENDPOINT` - MinIO endpoint
- `STORAGE_ACCESS_KEY/SECRET_KEY` - MinIO credentials
- `PROCESSING_ENABLE_TRANSCRIPTION` - Enable Whisper (optional)

See `env-templates/` for full examples.

## Testing

Run the full test suite (backend API tests + Playwright E2E) with a single command:

```bash
make test-all        # Starts Docker services, runs all tests, stops services
```

Individual test commands:

```bash
make test-services-up    # Start test environment (MongoDB, MinIO, backend, frontend)
make test-backend        # Run backend pytest suite
make test-e2e            # Run Playwright E2E tests
make test-services-down  # Stop test environment
```

See [docs/TESTING.md](docs/TESTING.md) for detailed documentation.

---

## Advanced

### Deploy Whisper ASR (Optional)

For speech-to-text transcription:

```bash
make deploy-whisper MODEL=base  # Auto-detects namespace
```

Available models: `tiny`, `base`, `small`, `medium`, `large-v3`

See [INFRA.md](INFRA.md) for details.

### Manual Service Deployment

```bash
# Deploy MongoDB + MinIO only (auto-detects namespace)
make deploy-services
```

### View All Available Commands

```bash
make help       # Show all available targets
make examples   # Show common usage examples
```

## Getting Help

- View all info: `make info` - Shows URLs, credentials, and connection details
- Check logs: `oc logs -f deployment/<name>` or `make oc-logs-backend`
- View events: `oc get events -n gng-<username>`
- Describe resource: `oc describe deployment/<name>`
- Show commands: `make help` or `make examples`
- Ask organizers on Slack/Discord

---

## Notes

### Namespace Auto-Detection

Most commands automatically detect your namespace from `.openshift-config` (created during setup). You don't need to specify it every time.

**If auto-detection doesn't work**, you can override for any command:
```bash
# Examples of overriding namespace
make sync NAMESPACE=gng-custom
make oc-logs-backend NAMESPACE=gng-other
make deploy-code NAMESPACE=gng-test
```

**To check your current namespace:**
```bash
cat .openshift-config  # Shows NAMESPACE and USERNAME
make info              # Shows all configuration
```

### Performance Tips

**Backend sync too slow?** Use the continuous watcher for instant updates:
```bash
make watch-backend  # Syncs on changes + every 2 seconds
```

## License

See [LICENSE](LICENSE) for details.
