# Testing Guide

Automated E2E and API tests for the Griot & Grits project.

## Quick Start

```bash
# Run everything (starts Docker services, runs backend + E2E tests, stops services)
make test-all
```

## Overview

| Layer | Tool | Location | What it tests |
|-------|------|----------|---------------|
| Backend API | pytest + httpx | `gng-backend/tests/` | FastAPI endpoints (health, artifacts, feedback) |
| E2E / UI | Playwright | `gng-web/tests/e2e/` | Upload, artifact status, search, feedback flows |
| Infrastructure | Docker Compose | `rh-hackathon/docker-compose.test.yml` | MongoDB, MinIO, backend, frontend as containers |

## Docker Compose Test Environment

The `docker-compose.test.yml` file spins up 5 services:

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| mongodb | mongo:7 | 27017 | Document database |
| minio | minio/minio | 9000 | S3-compatible object storage |
| minio-init | minio/mc | — | Creates the `artifacts` bucket, then exits |
| backend | Built from `gng-backend/` | 8000 | FastAPI application |
| frontend | Built from `gng-web/` | 3000 | Next.js application |

### Start / Stop

```bash
make test-services-up    # Build and start all containers (waits for healthy)
make test-services-down  # Stop containers and remove volumes
```

### Key environment settings

- `DB_NAME=gngdb_test` — isolated test database
- `PROCESSING_ENABLE_TRANSCRIPTION=false` — skips Whisper (artifacts go straight to READY)
- `PROCESSING_ENABLE_METADATA_EXTRACTION=false` — skips metadata extraction
- `ADMIN_AUTH_DISABLED=true` — disables NextAuth on the frontend
- `GLOBUS_ENABLED=false` — disables Globus archive integration

## Backend API Tests (pytest)

Located in `gng-backend/tests/`:

```
tests/
├── conftest.py                  # httpx AsyncClient fixture
└── test_api/
    ├── test_health.py           # GET /health, GET /
    ├── test_artifacts.py        # POST /artifacts/ingest, GET status, list
    └── test_feedback.py         # POST /feedback/, GET, PATCH status
```

### Running

```bash
# With Docker Compose services running:
cd ~/gng-backend
python -m pytest tests/ -v

# Or via Makefile:
make test-backend
```

The tests use `httpx.AsyncClient` with `ASGITransport` to call the FastAPI app directly. They require MongoDB and MinIO to be available (provided by Docker Compose).

## E2E Tests (Playwright)

Located in `gng-web/tests/e2e/`:

```
tests/e2e/
├── helpers/
│   ├── api-client.ts      # Backend API wrapper for seeding data
│   ├── test-data.ts        # Unique metadata/file generators
│   └── setup.ts            # Global setup: waits for services
├── home.spec.ts             # Homepage smoke tests
├── admin.spec.ts            # Admin sign-in page
├── collection.spec.ts       # Public collection page
├── upload.spec.ts           # Artifact upload via UI form
├── artifact-status.spec.ts  # Artifact status verification
├── search.spec.ts           # Artifact list/search
└── feedback.spec.ts         # Feedback list and filters
```

### Running

```bash
# With Docker Compose services running:
cd ~/gng-web
npx playwright test              # Headless
npx playwright test --headed     # With browser visible
npx playwright test --ui         # Interactive UI mode
npx playwright test --debug      # Step-by-step debugger

# View HTML report after a run:
npx playwright show-report
```

### Test descriptions

| File | Tests |
|------|-------|
| `upload.spec.ts` | Attaches file, fills metadata form, submits, verifies redirect to artifact detail |
| `artifact-status.spec.ts` | Seeds artifact via API, checks status is `ready`, visits detail page |
| `search.spec.ts` | Seeds 3 artifacts, verifies admin artifacts page renders, checks collection page |
| `feedback.spec.ts` | Seeds feedback via API, verifies feedback table renders, checks filter controls |

## Authentication in Tests

The frontend middleware (`middleware.ts`) checks `ADMIN_AUTH_DISABLED`:

```typescript
const authDisabled = process.env.ADMIN_AUTH_DISABLED === 'true';
```

When `ADMIN_AUTH_DISABLED=true`, all `/admin/*` routes are accessible without authentication. This is set automatically in the Docker Compose test environment.

## Mocking Transcription

Whisper transcription is disabled in the test environment via:

- `PROCESSING_ENABLE_TRANSCRIPTION=false`
- `PROCESSING_ENABLE_METADATA_EXTRACTION=false`

This means artifacts go straight from `PROCESSING` to `READY` status after ingestion, without waiting for any background processing.

## CI Pipeline

The GitHub Actions workflow (`.github/workflows/e2e.yml` in gng-web) runs on:

- Pull requests to `main` or `dev`
- Pushes to `main`

### What it does

1. Checks out `gng-web`, `gng-backend`, and `rh-hackathon`
2. Starts all services via `docker compose -f rh-hackathon/docker-compose.test.yml up`
3. Installs Node.js dependencies and Playwright
4. Runs `npx playwright test`
5. Uploads `playwright-report/` as a GitHub Actions artifact
6. Tears down Docker Compose

### Branch protection

To block PRs on test failure, enable branch protection on `main`:

1. Go to **Settings > Branches > Branch protection rules**
2. Add rule for `main`
3. Check **Require status checks to pass before merging**
4. Select the **E2E Tests / e2e** check

## Adding New Tests

### New Playwright test

1. Create `tests/e2e/your-feature.spec.ts`
2. Use helpers from `helpers/api-client.ts` to seed data
3. Use `helpers/test-data.ts` for unique metadata
4. Run `npx playwright test your-feature` to verify

### New pytest test

1. Create `tests/test_api/test_your_feature.py`
2. Use the `client` fixture from `conftest.py`
3. Run `python -m pytest tests/test_api/test_your_feature.py -v`

## Troubleshooting

### Services won't start

```bash
# Check container logs
docker compose -f docker-compose.test.yml logs backend
docker compose -f docker-compose.test.yml logs frontend

# Rebuild from scratch
make test-services-down
make test-services-up
```

### Backend tests fail with connection errors

Ensure Docker Compose services are running and healthy:

```bash
docker compose -f docker-compose.test.yml ps
curl http://localhost:8000/health
```

### Playwright tests time out

1. Check that the frontend is accessible: `curl http://localhost:3000`
2. Check that auth is disabled: the Docker Compose sets `ADMIN_AUTH_DISABLED=true`
3. Run with `--debug` flag to step through: `npx playwright test --debug`

### CI fails but local passes

- CI uses `reuseExistingServer: true` (services started by Docker Compose)
- Locally, Playwright starts `npm run dev` itself
- Ensure `BACKEND_URL` and `CI` env vars are set when mimicking CI locally
