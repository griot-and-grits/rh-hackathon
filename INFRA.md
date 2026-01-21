# Infrastructure Guide

This guide covers deploying services to OpenShift for the Griot & Grits project.

## For Students/Labbers (RHOAI Workbenches)

If you're working in a Red Hat OpenShift AI workbench where you cannot run containers locally, use the OpenShift setup to create your own namespace with a PostgreSQL database.

### Quick Start

```bash
# Login to OpenShift
oc login <cluster-url>

# Run setup (will prompt for your username)
./scripts/setup-openshift.sh

# Or specify username directly
./scripts/setup-openshift.sh --username jdoe
```

This will:
- Create a personal namespace: `gng-<username>`
- Deploy PostgreSQL database
- Create environment configuration file

See [User Namespace Setup](#user-namespace-setup-students) for details.

---

## For Admins

## Whisper ASR Deployment

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
./infra/whisper/deploy.sh --namespace griot-grits --model medium

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
oc get route whisper-asr -n griot-grits
```

Transcribe audio:

```bash
curl -X POST "https://<route-url>/asr" \
  -H "Content-Type: multipart/form-data" \
  -F "audio_file=@/path/to/audio.mp3" \
  -F "output=json"
```

### Backend Integration

To enable transcription in the Griot & Grits backend, update `.env`:

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
oc get pods -n griot-grits

# View logs
oc logs -f deployment/whisper-asr -n griot-grits

# Describe deployment for events
oc describe deployment whisper-asr -n griot-grits

# Check resource usage
oc adm top pods -n griot-grits
```

---

## PostgreSQL Database Deployment

Deploy PostgreSQL database on OpenShift for hackathon development.

### Prerequisites

- `oc` CLI installed
- Logged into OpenShift cluster
- Namespace/project created

### Quick Deploy

```bash
# Login to OpenShift
oc login <cluster-url>

# Deploy with defaults
./infra/postgres/deploy.sh

# Deploy to specific namespace
./infra/postgres/deploy.sh --namespace griot-grits

# Verify deployment
./infra/postgres/deploy.sh --verify-only

# Remove deployment
./infra/postgres/deploy.sh --delete
```

### Database Configuration

| Setting | Value |
|---------|-------|
| Database | `hackathon_db` |
| User | `hackathon` |
| Password | `hackathon123` |
| Port | `5432` |
| Service Name | `postgres` |

### Connection String

Within the cluster:
```
postgresql://hackathon:hackathon123@postgres:5432/hackathon_db
```

From outside (using port-forward):
```bash
oc port-forward service/postgres 5432:5432 -n <namespace>
# Then connect to: postgresql://hackathon:hackathon123@localhost:5432/hackathon_db
```

### Troubleshooting

```bash
# Check pod status
oc get pods -n griot-grits

# View logs
oc logs -f deployment/postgres -n griot-grits

# Run verification
./infra/postgres/deploy.sh --verify-only -n griot-grits

# Connect interactively
oc run psql-client --rm -it \
  --image=registry.redhat.io/rhel9/postgresql-15 \
  -n griot-grits -- bash
# Then: psql -h postgres -U hackathon -d hackathon_db
```

See [infra/postgres/README.md](infra/postgres/README.md) for detailed documentation.

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
```

This creates:
- **Namespace**: `gng-<username>` (e.g., `gng-jdoe`)
- **PostgreSQL**: Database service at `postgres:5432`
- **Environment file**: `.env.openshift` with connection details

### Using Your Database

From code running in the same namespace:
```python
import psycopg2

conn = psycopg2.connect(
    host="postgres",
    user="hackathon",
    password="hackathon123",
    database="hackathon_db"
)
```

From your local workbench (requires port-forward):
```bash
# In one terminal
oc port-forward service/postgres 5432:5432 -n gng-<username>

# In another terminal/notebook
import psycopg2
conn = psycopg2.connect(
    host="localhost",
    user="hackathon",
    password="hackathon123",
    database="hackathon_db"
)
```

### Managing Your Namespace

```bash
# View all your resources
oc get all -n gng-<username>

# View PostgreSQL logs
oc logs -f deployment/postgres -n gng-<username>

# Verify database
./infra/postgres/deploy.sh --verify-only --namespace gng-<username>

# Delete everything (careful!)
./scripts/setup-openshift.sh --delete
```

### Environment Configuration

After setup, your database connection details are saved in `.env.openshift`:

```bash
# Source it in your shell
source .env.openshift

# Or use in Python
from dotenv import load_dotenv
load_dotenv('.env.openshift')
```

---

## Future Infrastructure

Additional shared services to deploy:

- [ ] Shared MongoDB (for multi-user environments)
- [ ] Shared MinIO (for shared object storage)
- [ ] LLM service (for AI enrichment)
