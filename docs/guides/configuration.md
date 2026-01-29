# Configuration Reference

> Complete reference for all environment variables.

## Backend Environment Variables

Source: `env-templates/backend.env`

### Application

| Variable | Default | Description |
|----------|---------|-------------|
| ENVIRONMENT | development | Environment name |
| DEBUG | true | Enable debug mode |
| APP_NAME | Griot and Grits API | Application name |
| APP_VERSION | 0.1.0 | Application version |

### MongoDB

| Variable | Default | Description |
|----------|---------|-------------|
| DB_URI | mongodb://admin:gngdevpass12@localhost:27017/ | Connection string |
| DB_NAME | gngdb | Database name |
| DB_MAX_POOL_SIZE | 10 | Max connection pool size |
| DB_MIN_POOL_SIZE | 1 | Min connection pool size |

### MinIO Storage

| Variable | Default | Description |
|----------|---------|-------------|
| STORAGE_ENDPOINT | localhost:9000 | MinIO endpoint |
| STORAGE_ACCESS_KEY | minioadmin | Access key |
| STORAGE_SECRET_KEY | minioadmin | Secret key |
| STORAGE_BUCKET | artifacts | Default bucket |
| STORAGE_REGION | us-east-1 | Storage region |
| STORAGE_SECURE | false | Use HTTPS |

### Processing Pipeline

| Variable | Default | Description |
|----------|---------|-------------|
| PROCESSING_MODE | sync | Processing mode (`sync` or `async`) |
| PROCESSING_ENABLE_METADATA_EXTRACTION | true | Enable FFmpeg metadata extraction |
| PROCESSING_ENABLE_TRANSCRIPTION | false | Enable Whisper transcription |
| PROCESSING_TRANSCRIPTION_API_URL | - | Whisper endpoint URL |
| PROCESSING_ENABLE_LLM_ENRICHMENT | false | Enable LLM enrichment |

### Async Processing (Celery)

| Variable | Default | Description |
|----------|---------|-------------|
| PROCESSING_CELERY_BROKER_URL | redis://localhost:6379/0 | Celery broker URL |
| PROCESSING_CELERY_RESULT_BACKEND | redis://localhost:6379/0 | Celery result backend |

### Globus Archive

| Variable | Default | Description |
|----------|---------|-------------|
| GLOBUS_ENABLED | false | Enable Globus integration |
| GLOBUS_ENDPOINT_ID | - | Globus endpoint ID |
| GLOBUS_BASE_PATH | /archive/ | Base path on Globus endpoint |
| GLOBUS_CLIENT_ID | - | Globus client ID |
| GLOBUS_CLIENT_SECRET | - | Globus client secret |

### CORS Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| CORS_ALLOWED_ORIGINS | http://localhost:3000... | Comma-separated allowed origins |
| CORS_ALLOW_CREDENTIALS | true | Allow credentials |
| CORS_ALLOW_METHODS | * | Allowed HTTP methods |
| CORS_ALLOW_HEADERS | * | Allowed HTTP headers |

## Frontend Environment Variables

Source: `env-templates/frontend.env`

### API Connection

| Variable | Default | Description |
|----------|---------|-------------|
| NEXT_PUBLIC_ADMIN_API_BASE_URL | http://localhost:8000 | Backend URL |
| NEXT_PUBLIC_ADMIN_API_TIMEOUT | 30000 | Request timeout (ms) |

### Authentication

| Variable | Default | Description |
|----------|---------|-------------|
| ADMIN_AUTH_DISABLED | true | Disable auth (dev only) |
| ADMIN_DEV_BYPASS | true | Bypass auth check (dev only) |
| ADMIN_DEV_TOKEN | dev-token-12345 | Static token for dev bypass |
| AUTH_SECRET | - | NextAuth secret (production) |
| GITHUB_CLIENT_ID | - | GitHub OAuth Client ID |
| GITHUB_CLIENT_SECRET | - | GitHub OAuth Client Secret |
| ADMIN_ALLOWED_GITHUB_ORG | griot-and-grits | Allowed GitHub Org |
| ADMIN_ALLOWED_EMAILS | - | Allowed email list |
| ADMIN_ALLOWED_GITHUB_LOGINS | - | Allowed GitHub usernames |

### Feature Flags

| Variable | Default | Description |
|----------|---------|-------------|
| FEATURE_ASK_THE_GRIOT | true | Enable "Ask the Griot" chat |
| FEATURE_GOFUNDME | false | Enable GoFundMe widget |

### GoFundMe Integration

| Variable | Default | Description |
|----------|---------|-------------|
| GOFUNDME_CLIENT_ID | - | GoFundMe Client ID |
| GOFUNDME_CLIENT_SECRET | - | GoFundMe Client Secret |
| GOFUNDME_CAMPAIGN_ID | 731313 | Campaign ID to display |
| GOFUNDME_USE_EMBEDDED | false | Use embedded widget |

## Security Note

**⚠️ Warning:** The default credentials provided in `env-templates/` are for **local development only**.

For production deployments:
1. Generate strong secrets for all passwords and keys.
2. Use OpenShift Secrets instead of plain text environment variables.
3. Disable `ADMIN_AUTH_DISABLED` and `ADMIN_DEV_BYPASS`.
4. Configure proper OAuth credentials.

## Local vs OpenShift

| Context | Backend Config | Frontend Config |
|---------|---------------|-----------------|
| Local | `~/gng-backend/.env` | `~/gng-web/.env.local` |
| OpenShift | ConfigMap `backend-config` | ConfigMap `frontend-config` |

---

← [Back to Documentation Index](../README.md)
