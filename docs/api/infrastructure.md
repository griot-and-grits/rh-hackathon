# Infrastructure API Reference

> Access MongoDB and MinIO directly for debugging and administration.

> ⚠️ **Development Only Warning**
> The credentials shown below are for the default local development environment. 
> **Never use these default credentials in production.**
> For production deployment, use OpenShift Secrets.

## MongoDB

### Connection Details

| Setting | Value |
|---------|-------|
| Host (local) | localhost:27017 |
| Host (OpenShift) | mongodb:27017 |
| Database | gngdb |
| Username | admin |
| Password | gngdevpass12 |

### Connection String

```
mongodb://admin:gngdevpass12@mongodb:27017/gngdb
```

### Port Forwarding (OpenShift)

```bash
oc port-forward service/mongodb 27017:27017 -n gng-yourname
# Then connect to localhost:27017
```

### Python Example

```python
from pymongo import MongoClient

client = MongoClient("mongodb://admin:gngdevpass12@localhost:27017/")
db = client["gngdb"]
artifacts = db["artifacts"].find()
```

## MinIO (S3-Compatible Storage)

### Connection Details

| Setting | Value |
|---------|-------|
| Endpoint (local) | localhost:9000 |
| Endpoint (OpenShift) | minio:9000 |
| Console Port | 9001 |
| Access Key | minioadmin |
| Secret Key | minioadmin |
| Default Bucket | artifacts |

### Web Console

- **Local**: http://localhost:9001
- **OpenShift**: `oc get route minio-console`

### Python Example

```python
from minio import Minio

client = Minio(
    "localhost:9000",
    access_key="minioadmin",
    secret_key="minioadmin",
    secure=False
)

# List objects
objects = client.list_objects("artifacts")
for obj in objects:
    print(obj.object_name)
```

---

← [Back to Documentation Index](../README.md)
