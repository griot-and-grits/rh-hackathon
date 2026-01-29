# API Documentation

> The Griot & Grits backend uses FastAPI which auto-generates OpenAPI documentation.

## Accessing API Documentation

### Local Development

After running `make dev`:

| Format | URL |
|--------|-----|
| Swagger UI | http://localhost:8000/docs |
| ReDoc | http://localhost:8000/redoc |
| OpenAPI JSON | http://localhost:8000/openapi.json |

### OpenShift Deployment

After running `make deploy-code`:

```bash
# Get your backend route
oc get route backend -n gng-yourname -o jsonpath='{.spec.host}'

# Access Swagger UI at:
# https://<route-host>/docs
```

## API Overview

The backend provides REST endpoints for:

| Category | Base Path | Description |
|----------|-----------|-------------|
| Artifacts | /artifacts | CRUD for oral history items |
| Search | /search | Full-text and semantic search |
| Processing | /processing | Transcription job management |
| Health | /health | Service health checks |

## Authentication

- **Local Development**: Authentication is disabled by default (`ADMIN_AUTH_DISABLED=true`)
- **Production**: Requires GitHub OAuth or API token

## Example: Upload an Artifact

```bash
curl -X POST "http://localhost:8000/artifacts" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@recording.mp3" \
  -F "title=Interview with Elder"
```

## Infrastructure APIs

For MinIO and MongoDB access, see [Infrastructure Reference](./infrastructure.md).

---

← [Back to Documentation Index](../README.md)
