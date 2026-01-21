# PostgreSQL Database Deployment

Deploy PostgreSQL database on OpenShift for hackathon development when container runtime is not available (e.g., RHOAI workbenches).

## Prerequisites

- `oc` CLI installed
- Logged into OpenShift cluster
- Namespace/project created (or script will create it)

## Quick Deploy

```bash
# Login to OpenShift
oc login <cluster-url>

# Deploy PostgreSQL with initialization and verification
./infra/postgres/deploy.sh

# Deploy to specific namespace
./infra/postgres/deploy.sh --namespace my-project

# Deploy without verification
./infra/postgres/deploy.sh --skip-verify

# Verify existing deployment
./infra/postgres/deploy.sh --verify-only

# Remove deployment
./infra/postgres/deploy.sh --delete
```

## What Gets Deployed

1. **PostgreSQL 15 Deployment** - Single-pod PostgreSQL database
2. **Service** - ClusterIP service named `postgres` on port 5432
3. **Init Job** - Creates `users` table with sample data
4. **Verify Job** - (Optional) Verifies database connectivity and data

## Database Configuration

| Setting | Value |
|---------|-------|
| Database | `hackathon_db` |
| User | `hackathon` |
| Password | `hackathon123` |
| Port | `5432` |
| Service Name | `postgres` |

## Usage from Applications

### Connection String

Within the same OpenShift namespace:
```
postgresql://hackathon:hackathon123@postgres:5432/hackathon_db
```

From a different namespace:
```
postgresql://hackathon:hackathon123@postgres.griot-grits.svc.cluster.local:5432/hackathon_db
```

### Python Example

```python
import psycopg2

conn = psycopg2.connect(
    host="postgres",
    port=5432,
    user="hackathon",
    password="hackathon123",
    database="hackathon_db"
)
cursor = conn.cursor()
cursor.execute("SELECT * FROM users;")
rows = cursor.fetchall()
print(rows)
conn.close()
```

### Environment Variables

For use with backend applications:

```env
DB_URI=postgresql://hackathon:hackathon123@postgres:5432/hackathon_db
DB_NAME=hackathon_db
DB_USER=hackathon
DB_PASSWORD=hackathon123
DB_HOST=postgres
DB_PORT=5432
```

## RHOAI Workbench Usage

When working in a Red Hat OpenShift AI workbench where container runtime is not available:

1. **Login to OpenShift from terminal:**
   ```bash
   oc login <your-cluster-url>
   ```

2. **Deploy PostgreSQL:**
   ```bash
   cd ~/rh-hackathon
   ./infra/postgres/deploy.sh
   ```

3. **Use in your notebooks/code:**
   ```python
   # The database is accessible at: postgres:5432
   import psycopg2
   conn = psycopg2.connect(
       host="postgres",
       user="hackathon",
       password="hackathon123",
       database="hackathon_db"
   )
   ```

## Database Schema

The init job creates a sample `users` table:

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50),
    role VARCHAR(50)
);

-- Sample data
INSERT INTO users (username, role) VALUES ('admin_demo', 'organizer');
```

## Troubleshooting

### Check deployment status
```bash
oc get pods -n griot-grits
oc get deployment postgres -n griot-grits
```

### View PostgreSQL logs
```bash
oc logs -f deployment/postgres -n griot-grits
```

### Check init job
```bash
oc logs job/init-db -n griot-grits
```

### Run verification manually
```bash
./infra/postgres/deploy.sh --verify-only
```

### Connect interactively
```bash
# Start a psql client pod
oc run psql-client --rm -it \
  --image=registry.redhat.io/rhel9/postgresql-15 \
  -n griot-grits -- bash

# Inside the pod, connect to database
psql -h postgres -U hackathon -d hackathon_db
# Password: hackathon123
```

### PostgreSQL won't start

Check events and pod status:
```bash
oc describe deployment postgres -n griot-grits
oc describe pod -l app=postgres -n griot-grits
```

### Init job fails

View job logs:
```bash
oc logs job/init-db -n griot-grits
```

Delete and recreate:
```bash
oc delete job init-db -n griot-grits
oc apply -f infra/postgres/openshift/init-job.yaml -n griot-grits
```

## Storage

Currently uses `emptyDir` for ephemeral storage (data is lost when pod restarts).

For persistent storage, replace the volume in `postgres.yaml`:

```yaml
volumes:
- name: postgres-storage
  persistentVolumeClaim:
    claimName: postgres-pvc
```

And create a PVC:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

## Security Notes

**⚠️ This configuration is for development/hackathon use only!**

- Default credentials are hardcoded (not production-safe)
- No TLS/SSL encryption
- Uses `emptyDir` storage (data is not persistent)
- No backups configured

For production use:
- Use Secrets for credentials
- Enable SSL/TLS
- Use persistent storage with backups
- Configure proper resource limits
- Implement access controls
