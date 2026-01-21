# Griot & Grits - Hackathon Toolkit

Development toolkit for the Griot & Grits project - AI-powered preservation of minority history.

## Quick Start

Choose your development environment:

### Option 1: Local Development (with containers)

**Prerequisites:** Git, Node.js 18+, Python 3.10+, `uv` or `pip`

```bash
cd ~/rh-hackathon
./scripts/setup.sh          # One-time setup (clones repos, installs deps)
./scripts/dev-all.sh        # Start everything
```

**URLs:**
- Frontend: http://localhost:3000
- Backend API: http://localhost:8000/docs
- MinIO Console: http://localhost:9001

**Utility commands:**
```bash
./scripts/status.sh         # Check what's running
./scripts/stop-services.sh  # Stop services
./scripts/clean.sh          # Remove containers
```

---

### Option 2: OpenShift/RHOAI (without containers)

For RHOAI workbenches where containers aren't available.

**Prerequisites:** `oc` CLI, OpenShift cluster access

**Setup:**
```bash
oc login <cluster-url>      # Get login command from web console
cd ~/rh-hackathon
./scripts/setup-openshift.sh
```

This creates:
- Personal namespace: `gng-<username>`
- MongoDB database
- MinIO object storage
- `.env.openshift` file with all connection details

**Using your services:**
```bash
# View resources
oc get all -n gng-<username>

# View logs
oc logs -f deployment/mongodb -n gng-<username>
oc logs -f deployment/minio -n gng-<username>

# Access MinIO console
oc get route minio-console -n gng-<username>

# Delete everything
./scripts/setup-openshift.sh --delete
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
# Option A: Deploy during initial setup
./scripts/setup-openshift.sh --with-code

# Option B: Deploy code after setup
./scripts/deploy-code.sh -n gng-<username>
```

This deploys:
- Backend (FastAPI) with hot-reload at `https://backend-gng-<username>.apps...`
- Frontend (Next.js) with hot-reload at `https://frontend-gng-<username>.apps...`

**Syncing code changes:**

```bash
# Get pod names
oc get pods -n gng-<username>

# Sync your local code changes to running pods
oc rsync ./backend-code/ <backend-pod>:/code -n gng-<username>
oc rsync ./frontend-code/ <frontend-pod>:/code -n gng-<username>

# Changes are auto-detected and reloaded
```

The code will automatically clone from GitHub on first deployment. For development, use `oc rsync` to sync your local changes to the running pods.

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
./scripts/start-services.sh
./scripts/stop-services.sh

# Run backend/frontend separately
./scripts/dev-backend.sh    # Terminal 1
./scripts/dev-frontend.sh   # Terminal 2

# Check status
./scripts/status.sh

# Clean up
./scripts/clean.sh          # Remove containers, keep data
./scripts/clean.sh --all    # Remove everything
```

### OpenShift Development

```bash
# View all resources
oc get all -n gng-<username>

# Deploy application code with hot-reload
./scripts/deploy-code.sh -n gng-<username>

# Sync local code changes to running pods
oc rsync ./backend-code/ $(oc get pod -l app=backend -o name | head -1):/code -n gng-<username>
oc rsync ./frontend-code/ $(oc get pod -l app=frontend -o name | head -1):/code -n gng-<username>

# View application logs
oc logs -f deployment/backend -n gng-<username>
oc logs -f deployment/frontend -n gng-<username>

# Shell into pod
oc rsh deployment/mongodb -n gng-<username>

# Copy files
oc cp file.txt deployment/mongodb:/tmp/ -n gng-<username>

# Clean up old jobs
./scripts/cleanup-jobs.sh

# Redeploy services
./scripts/deploy-services.sh --delete -n gng-<username>
./scripts/deploy-services.sh -n gng-<username>
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
./scripts/status.sh        # Check status
podman ps -a | grep gng    # Check containers
./scripts/clean.sh         # Clean and restart
./scripts/start-services.sh
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
oc get pods -n gng-<username>
oc describe pod <pod-name> -n gng-<username>
oc logs <pod-name> -n gng-<username>
```

**Jobs accumulating:**
```bash
./scripts/cleanup-jobs.sh  # Clean up completed jobs
```

**Start over:**
```bash
./scripts/setup-openshift.sh --delete
./scripts/setup-openshift.sh
```

## Environment Variables

Configuration files are created automatically:

**Local:** `~/griot-and-grits-backend/.env`
**OpenShift:** `.env.openshift`

Key variables:
- `DB_URI` - MongoDB connection string
- `STORAGE_ENDPOINT` - MinIO endpoint
- `STORAGE_ACCESS_KEY/SECRET_KEY` - MinIO credentials
- `PROCESSING_ENABLE_TRANSCRIPTION` - Enable Whisper (optional)

See `env-templates/` for full examples.

## Advanced

### Deploy Whisper ASR (Optional)

For speech-to-text transcription:

```bash
./infra/whisper/deploy.sh --namespace gng-<username>
```

See [INFRA.md](INFRA.md) for details.

### Manual Service Deployment

```bash
# Deploy MongoDB + MinIO only
./scripts/deploy-services.sh --namespace gng-<username>

# Skip initialization
./scripts/deploy-services.sh --skip-init -n gng-<username>
```

## Getting Help

- Check logs: `oc logs -f deployment/<name>`
- View events: `oc get events -n gng-<username>`
- Describe resource: `oc describe deployment/<name>`
- Ask organizers on Slack/Discord

## License

See [LICENSE](LICENSE) for details.
