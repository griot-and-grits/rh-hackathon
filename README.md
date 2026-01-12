# Griot & Grits - Hackathon Toolkit

Development and infrastructure scripts for the Griot & Grits project - AI-powered preservation of minority history.

## Quick Start (Students/Labbers)

### Prerequisites

- Git
- Node.js 18+
- Python 3.10+
- `uv` (recommended) or `pip`

> **Note:** Podman or Docker will be auto-installed if not present. Works in rootless environments (OpenShift AI workbenches).

### One-Time Setup

```bash
cd ~/rh-hackathon
./scripts/setup.sh
```

The setup script will automatically:
- Clone `github.com/griot-and-grits/gng-web` to `~/gng-web`
- Clone `github.com/griot-and-grits/griot-and-grits-backend` to `~/griot-and-grits-backend`
- Create `.env` files with local development defaults
- Install all dependencies

### Daily Development

```bash
# Option 1: Start everything at once
./scripts/dev-all.sh

# Option 2: Start components separately (recommended)
./scripts/start-services.sh    # Start MongoDB + MinIO
./scripts/dev-backend.sh       # Terminal 1: Backend with hot reload
./scripts/dev-frontend.sh      # Terminal 2: Frontend with hot reload
```

### URLs

| Service | URL |
|---------|-----|
| Frontend | http://localhost:3000 |
| Admin Portal | http://localhost:3000/admin |
| Backend API | http://localhost:8000 |
| API Docs | http://localhost:8000/docs |
| MinIO Console | http://localhost:9001 |

### Utility Commands

```bash
./scripts/status.sh            # Check what's running
./scripts/stop-services.sh     # Stop MongoDB + MinIO
./scripts/clean.sh             # Remove containers (keeps data)
./scripts/clean.sh --all       # Remove containers AND data
```

## Project Structure

```
rh-hackathon/
├── scripts/                   # Student/labber scripts
│   ├── setup.sh              # One-time setup
│   ├── start-services.sh     # Start MongoDB + MinIO
│   ├── stop-services.sh      # Stop services
│   ├── dev-backend.sh        # Run backend (hot reload)
│   ├── dev-frontend.sh       # Run frontend (hot reload)
│   ├── dev-all.sh            # Run everything
│   ├── status.sh             # Check service status
│   └── clean.sh              # Cleanup containers
├── infra/                     # Infrastructure scripts (admins)
│   └── whisper/              # Whisper ASR deployment
│       ├── deploy.sh         # Deploy to OpenShift
│       └── openshift/        # K8s/OpenShift manifests
└── env-templates/            # Environment file templates
    ├── backend.env           # Backend .env template
    └── frontend.env          # Frontend .env.local template
```

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│    Frontend     │────▶│     Backend     │
│   (Next.js)     │     │   (FastAPI)     │
│   Port 3000     │     │   Port 8000     │
└─────────────────┘     └────────┬────────┘
                                 │
                    ┌────────────┼────────────┐
                    ▼            ▼            ▼
              ┌──────────┐ ┌──────────┐ ┌──────────┐
              │ MongoDB  │ │  MinIO   │ │ Whisper  │
              │  :27017  │ │  :9000   │ │ (OpenShift)
              └──────────┘ └──────────┘ └──────────┘
```


## Environment Variables

### Backend (`griot-and-grits-backend/.env`)

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_URI` | `mongodb://admin:gngdevpass12@localhost:27017/` | MongoDB connection |
| `STORAGE_ENDPOINT` | `localhost:9000` | MinIO endpoint |
| `PROCESSING_ENABLE_TRANSCRIPTION` | `false` | Enable Whisper ASR |
| `PROCESSING_TRANSCRIPTION_API_URL` | - | Whisper API URL |

### Frontend (`gng-web/.env.local`)

| Variable | Default | Description |
|----------|---------|-------------|
| `NEXT_PUBLIC_ADMIN_API_BASE_URL` | `http://localhost:8000` | Backend URL |
| `ADMIN_AUTH_DISABLED` | `true` | Disable auth for dev |

Full templates in `env-templates/`.

## Troubleshooting

### No container runtime found
```bash
# Re-run setup to auto-install Podman
./scripts/setup.sh

# Or check what's available
which podman docker
```

### Port already in use
```bash
# Find what's using the port
lsof -i :3000
lsof -i :8000

# Kill the process
kill -9 <PID>
```

### MongoDB/MinIO won't start
```bash
# Check status
./scripts/status.sh

# Check for existing containers (use podman or docker)
podman ps -a | grep gng

# Remove and restart
./scripts/clean.sh
./scripts/start-services.sh
```

### Backend can't connect to MongoDB
```bash
# Check MongoDB is running
podman logs gng-mongodb  # or: docker logs gng-mongodb

# Verify connection string in .env
grep DB_URI ~/griot-and-grits-backend/.env
```

## Contributing

1. Create a feature branch
2. Make your changes
3. Test locally with `./scripts/dev-all.sh`
4. Submit a PR

## License

See [LICENSE](LICENSE) for details.
