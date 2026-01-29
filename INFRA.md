# Infrastructure Guide

This guide covers deploying services to OpenShift for the Griot & Grits project.

## For Students/Labbers (RHOAI Workbenches)

If you're working in a Red Hat OpenShift AI workbench where you cannot run containers locally, use the OpenShift setup to create your own namespace with MongoDB and MinIO.

### Quick Start

```bash
# Login to OpenShift
oc login <cluster-url>

# Run setup (will prompt for your username)
./scripts/setup-openshift.sh

# Or specify username directly
./scripts/setup-openshift.sh --username jdoe

# Deploy with hot-reload code (optional)
./scripts/setup-openshift.sh --username jdoe --with-code
```

This will:
- Create a personal namespace: `gng-<username>`
- Deploy MongoDB database
- Deploy MinIO object storage
- Create environment configuration file
- (Optional) Deploy frontend and backend with hot-reload

See [User Namespace Setup](#user-namespace-setup-students) for details.

---

## For Admins

## MongoDB Database Deployment

Deploy MongoDB database on OpenShift for hackathon development.

### Prerequisites

- `oc` CLI installed
- Logged into OpenShift cluster
- Namespace/project created

### Quick Deploy

```bash
# Login to OpenShift
oc login <cluster-url>

# Deploy MongoDB + MinIO together
./scripts/deploy-services.sh --namespace gng-<username>

# Or deploy individually
oc apply -f infra/mongodb/openshift/ -n gng-<username>
```

### Database Configuration

| Setting | Value |
|---------|-------|
| Database | `gngdb` |
| User | `admin` |
| Password | `gngdevpass12` |
| Port | `27017` |
| Service Name | `mongodb` |

### Connection String

Within the cluster:
```
mongodb://admin:gngdevpass12@mongodb:27017/gngdb
```

From outside (using port-forward):
```bash
oc port-forward service/mongodb 27017:27017 -n gng-<username>
# Then connect to: mongodb://admin:gngdevpass12@localhost:27017/gngdb
```

### Troubleshooting

```bash
# Check pod status
oc get pods -n gng-<username>

# View logs
oc logs -f deployment/mongodb -n gng-<username>

# Connect interactively (shell into pod to run mongosh, inspect data, debug)
oc rsh -n gng-<username> deployment/mongodb
# Then: mongosh -u admin -p gngdevpass12 --authenticationDatabase admin
```

---

## MinIO Object Storage Deployment

Deploy MinIO S3-compatible object storage on OpenShift.

### Prerequisites

- `oc` CLI installed
- Logged into OpenShift cluster
- Namespace/project created

### Quick Deploy

```bash
# Deploy MongoDB + MinIO together
./scripts/deploy-services.sh --namespace gng-<username>

# Or deploy individually
oc apply -f infra/minio/openshift/ -n gng-<username>
```

### MinIO Configuration

| Setting | Value |
|---------|-------|
| Access Key | `minioadmin` |
| Secret Key | `minioadmin` |
| API Port | `9000` |
| Console Port | `9001` |
| Service Name | `minio` |
| Default Bucket | `artifacts` |

### Access MinIO

**API Endpoint** (within cluster):
```
minio:9000
```

**Web Console**:
```bash
# Get console URL
oc get route minio-console -n gng-<username>
```

**From outside** (using port-forward):
```bash
# API
oc port-forward service/minio 9000:9000 -n gng-<username>

# Console
oc port-forward service/minio 9001:9001 -n gng-<username>
# Then visit: http://localhost:9001
```

### Python Usage

```python
from minio import Minio

client = Minio(
    "minio:9000",
    access_key="minioadmin",
    secret_key="minioadmin",
    secure=False
)

# Upload file
client.fput_object("artifacts", "test.txt", "/path/to/file.txt")

# Download file
client.fget_object("artifacts", "test.txt", "/path/to/save.txt")
```

---

## Whisper ASR Deployment (Optional)

Deploy OpenAI Whisper speech-to-text service on OpenShift.

### Prerequisites

- `oc` CLI installed
- Logged into OpenShift cluster
- Namespace/project created

### Quick Deploy

```bash
# Login to OpenShift
oc login <cluster-url>

# Deploy with defaults (base model)
./infra/whisper/deploy.sh

# Deploy with a specific model
./infra/whisper/deploy.sh --model small

# Deploy to specific namespace
./infra/whisper/deploy.sh --namespace gng-<username> --model medium

# Remove deployment
./infra/whisper/deploy.sh --delete
```

### Model Options

| Model | RAM | Speed | Accuracy | Best For |
|-------|-----|-------|----------|----------|
| `tiny` | ~1GB | Fastest | Basic | Testing, low resources |
| `base` | ~1GB | Fast | Good | Development (default) |
| `small` | ~2GB | Medium | Better | General use |
| `medium` | ~5GB | Slower | Great | Quality transcription |
| `large-v3` | ~10GB | Slowest | Best | Production |

### API Usage

Once deployed, get the route URL:

```bash
oc get route whisper-asr -n gng-<username>
```

Transcribe audio:

```bash
curl -X POST "https://<route-url>/asr" \
  -H "Content-Type: multipart/form-data" \
  -F "audio_file=@/path/to/audio.mp3" \
  -F "output=json"
```

### Backend Integration

To enable transcription in the Griot & Grits backend, update `.env.openshift`:

```env
PROCESSING_ENABLE_TRANSCRIPTION=true
PROCESSING_TRANSCRIPTION_API_URL=https://<route-url>
```

### GPU Support

For GPU-accelerated transcription, edit `infra/whisper/openshift/deployment.yaml` and uncomment:

```yaml
resources:
  limits:
    nvidia.com/gpu: "1"
```

Requires GPU nodes with NVIDIA GPU Operator installed.

### Troubleshooting

```bash
# Check pod status
oc get pods -n gng-<username>

# View logs
oc logs -f deployment/whisper-asr -n gng-<username>

# Describe deployment for events
oc describe deployment whisper-asr -n gng-<username>

# Check resource usage
oc adm top pods -n gng-<username>
```

---

## Hot-Reload Code Deployment

Deploy the frontend and backend application code with automatic hot-reload.

### Prerequisites

- MongoDB and MinIO deployed (via `setup-openshift.sh` or `deploy-services.sh`)
- Namespace/project created

### Quick Deploy

```bash
# Deploy with code during setup
./scripts/setup-openshift.sh --username jdoe --with-code

# Or deploy code separately
./scripts/deploy-code.sh --namespace gng-<username>
```

This deploys:
- **Backend**: FastAPI with uvicorn --reload
- **Frontend**: Next.js with next dev
- **Auto-sync**: Background watcher that syncs local code changes

### Application Routes

```bash
# Get application URLs
oc get routes -n gng-<username>

# Frontend: https://frontend-gng-<username>.apps...
# Backend API: https://backend-gng-<username>.apps.../docs
```

### Code Synchronization

**Automatic sync** (started with `--with-code`):
```bash
# Check watcher status
./scripts/watch-ctl.sh status

# View sync logs
./scripts/watch-ctl.sh logs

# Stop/restart watcher
./scripts/watch-ctl.sh stop
./scripts/watch-ctl.sh start gng-<username>
```

**Manual sync**:
```bash
# Sync both backend and frontend
./scripts/sync-code.sh

# Sync backend only
./scripts/sync-code.sh -b

# Sync frontend only
./scripts/sync-code.sh -f
```

### Development Workflow

1. Edit code locally in `rh-hackathon/gng-backend` or `rh-hackathon/gng-web`
2. Save files - changes automatically sync to pods (if watcher running)
3. Application reloads automatically (hot-reload)
4. View changes at your route URL

### Troubleshooting

```bash
# Check pod status
oc get pods -n gng-<username>

# View backend logs
oc logs -f deployment/backend -n gng-<username>

# View frontend logs
oc logs -f deployment/frontend -n gng-<username>

# Restart pods
oc rollout restart deployment/backend -n gng-<username>
oc rollout restart deployment/frontend -n gng-<username>
```

---

## User Namespace Setup (Students)

For students/labbers working in RHOAI workbenches where container runtime is not available.

### Setup Your Personal Environment

```bash
# Login to OpenShift (get command from web console)
oc login <cluster-url>

# Run setup - will prompt for your username
./scripts/setup-openshift.sh

# Or specify username
./scripts/setup-openshift.sh --username jdoe

# With hot-reload code deployment
./scripts/setup-openshift.sh --username jdoe --with-code
```

This creates:
- **Namespace**: `gng-<username>` (e.g., `gng-jdoe`)
- **MongoDB**: Database service at `mongodb:27017`
- **MinIO**: Object storage at `minio:9000`
- **Environment file**: `.env.openshift` with connection details
- (Optional) **Backend + Frontend**: With hot-reload

### Using Your Database

From code running in the same namespace:
```python
from pymongo import MongoClient

client = MongoClient("mongodb://admin:gngdevpass12@mongodb:27017/")
db = client["gngdb"]
```

From your local workbench (requires port-forward):
```bash
# In one terminal
oc port-forward service/mongodb 27017:27017 -n gng-<username>

# In another terminal/notebook
from pymongo import MongoClient
client = MongoClient("mongodb://admin:gngdevpass12@localhost:27017/")
db = client["gngdb"]
```

### Using MinIO Storage

From code running in the same namespace:
```python
from minio import Minio

client = Minio(
    "minio:9000",
    access_key="minioadmin",
    secret_key="minioadmin",
    secure=False
)
```

From your local workbench (requires port-forward):
```bash
# In one terminal
oc port-forward service/minio 9000:9000 -n gng-<username>

# In another terminal/notebook
from minio import Minio
client = Minio(
    "localhost:9000",
    access_key="minioadmin",
    secret_key="minioadmin",
    secure=False
)
```

### Managing Your Namespace

```bash
# View all your resources
oc get all -n gng-<username>

# View MongoDB logs
oc logs -f deployment/mongodb -n gng-<username>

# View MinIO logs
oc logs -f deployment/minio -n gng-<username>

# Delete everything (careful!)
./scripts/setup-openshift.sh --delete
```

### Environment Configuration

After setup, your connection details are saved in `.env.openshift`:

```bash
# Source it in your shell
source .env.openshift

# Or use in Python
from dotenv import load_dotenv
load_dotenv('.env.openshift')
```

---

## Resource Requirements

Per-user resource requirements:

**Services only** (MongoDB + MinIO):
- CPU Request: 200m
- CPU Limit: 1000m
- Memory Request: 768Mi
- Memory Limit: 1.5Gi

**Full stack** (Services + Backend + Frontend with hot-reload):
- CPU Request: 700m
- CPU Limit: 3000m
- Memory Request: 2.5Gi
- Memory Limit: 5.5Gi

For 60 users with full stack:
- CPU Request: ~42 cores
- Memory Request: ~150 GiB
