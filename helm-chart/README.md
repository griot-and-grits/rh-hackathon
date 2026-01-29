# Griot & Grits Helm Chart

A Helm chart for deploying the Griot & Grits application - AI-powered preservation of minority history.

## Components

This chart deploys the following components:

- **Backend** - FastAPI application (Python)
- **Frontend** - Next.js application (Node.js)
- **MongoDB** - Database for storing application data
- **MinIO** - Object storage for artifacts
- **Whisper ASR** (Optional) - Speech-to-text transcription service

## Prerequisites

- Kubernetes 1.19+ or OpenShift 4.6+
- Helm 3.0+ (for Helm deployment)
- ArgoCD 2.0+ (for ArgoCD deployment)
- Access to the following container registries:
  - `registry.access.redhat.com` (for UBI images)
  - `quay.io` (for MinIO)
  - `onerahmet/openai-whisper-asr-webservice` (for Whisper, if enabled)

---

## Deployment Methods

This chart can be deployed using two methods:

1. **[Helm CLI](#deploying-with-helm)** - Direct deployment using Helm command-line tool
2. **[ArgoCD](#deploying-with-argocd)** - GitOps-based deployment using ArgoCD

---

## Deploying with Helm

### Step-by-Step Installation Guide

#### Step 1: Prepare Your Environment

1. **Install Helm** (if not already installed):
   ```bash
   # macOS
   brew install helm
   
   # Linux
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

2. **Verify Helm installation**:
   ```bash
   helm version
   ```

3. **Ensure you have cluster access**:
   ```bash
   # For Kubernetes
   kubectl cluster-info
   
   # For OpenShift
   oc cluster-info
   ```

#### Step 2: Create a Custom Values File

Create a `my-values.yaml` file with your configuration:

```bash
cat > my-values.yaml <<EOF
global:
  namespace: ""
  imageRegistry: "registry.access.redhat.com"

backend:
  enabled: true
  replicas: 1
  route:
    enabled: true
    host: "backend-griot-and-grits.apps.mycluster.example.com"  # Must be specified
  config:
    dbUri: "mongodb://admin:CHANGE_ME@mongodb:27017/gngdb?authSource=admin"
    storageEndpoint: "minio:9000"
    storageAccessKey: "minioadmin"
    storageSecretKey: "CHANGE_ME"

frontend:
  enabled: true
  replicas: 1
  route:
    enabled: true
    host: "frontend-griot-and-grits.apps.mycluster.example.com"  # Must be specified

mongodb:
  enabled: true
  auth:
    rootUsername: "admin"
    rootPassword: "CHANGE_ME"  # Change this!
    database: "gngdb"
  persistence:
    enabled: false  # Set to true for production

minio:
  enabled: true
  auth:
    rootUser: "minioadmin"
    rootPassword: "CHANGE_ME"  # Change this!
  persistence:
    enabled: false  # Set to true for production

whisper:
  enabled: false  # Set to true if you need transcription
EOF
```

**Important**: Replace all `CHANGE_ME` values with secure passwords!

#### Step 4: Create Namespace (Optional)

```bash
# Create namespace
kubectl create namespace griot-and-grits

# Or for OpenShift
oc new-project griot-and-grits
```

#### Step 5: Install the Chart

```bash
# Navigate to the chart directory
cd helm-chart

# Install with your custom values
helm install griot-and-grits . \
  --namespace griot-and-grits \
  --create-namespace \
  -f my-values.yaml

# Or install with inline values
helm install griot-and-grits . \
  --namespace griot-and-grits \
  --create-namespace \
  --set backend.route.host=backend-griot-and-grits.apps.mycluster.example.com \
  --set frontend.route.host=frontend-griot-and-grits.apps.mycluster.example.com \
  --set minio.route.host=minio-griot-and-grits.apps.mycluster.example.com \
  --set mongodb.auth.rootPassword=secure-password \
  --set minio.auth.rootPassword=secure-password
```

#### Step 6: Verify Installation

1. **Check release status**:
   ```bash
   helm status griot-and-grits -n griot-and-grits
   ```

2. **Check pod status**:
   ```bash
   kubectl get pods -n griot-and-grits
   ```

3. **Wait for all pods to be ready**:
   ```bash
   kubectl wait --for=condition=ready pod \
     -l app.kubernetes.io/instance=griot-and-grits \
     -n griot-and-grits \
     --timeout=300s
   ```

4. **Get application URLs**:
   ```bash
   # View Helm release notes (includes URLs)
   helm get notes griot-and-grits -n griot-and-grits
   
   # Or get routes directly
   kubectl get routes -n griot-and-grits
   ```

#### Step 7: Access the Application

After installation, access your application:

```bash
# Get backend URL
BACKEND_URL=$(kubectl get route backend -n griot-and-grits -o jsonpath='{.spec.host}')
echo "Backend API: https://${BACKEND_URL}/docs"

# Get frontend URL
FRONTEND_URL=$(kubectl get route frontend -n griot-and-grits -o jsonpath='{.spec.host}')
echo "Frontend: https://${FRONTEND_URL}"

# Get MinIO console URL
MINIO_URL=$(kubectl get route minio-console -n griot-and-grits -o jsonpath='{.spec.host}')
echo "MinIO Console: https://${MINIO_URL}"
```

### Upgrading the Release

```bash
# Upgrade with updated values file
helm upgrade griot-and-grits . \
  --namespace griot-and-grits \
  -f my-values.yaml

# Upgrade with specific values
helm upgrade griot-and-grits . \
  --namespace griot-and-grits \
  --set backend.replicas=3 \
  --set frontend.replicas=2
```

### Uninstalling

```bash
# Uninstall the release
helm uninstall griot-and-grits -n griot-and-grits

# If using persistent volumes, delete them manually:
kubectl delete pvc -l app.kubernetes.io/instance=griot-and-grits -n griot-and-grits
```

---

## Deploying with ArgoCD

ArgoCD provides GitOps-based continuous deployment, automatically syncing your application based on Git repository changes.

### Prerequisites for ArgoCD

1. **ArgoCD installed** in your cluster:
   ```bash
   # Check if ArgoCD is installed
   kubectl get pods -n argocd
   
   # If not installed, install it:
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   ```

2. **ArgoCD CLI installed** (optional but recommended):
   ```bash
   # macOS
   brew install argocd
   
   # Linux
   curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
   chmod +x /usr/local/bin/argocd
   ```

3. **Git repository** containing your Helm chart and values files

### Step-by-Step ArgoCD Deployment Guide

#### Step 1: Prepare Your Git Repository

1. **Create a Git repository** (or use existing) with the following structure:
   ```
   my-gitops-repo/
   ├── applications/
   │   └── griot-and-grits-app.yaml
   ├── values/
   │   ├── development.yaml
   │   ├── staging.yaml
   │   └── production.yaml
   └── helm-chart/  (or reference to chart repository)
       ├── Chart.yaml
       ├── values.yaml
       └── templates/
   ```

2. **Push the Helm chart** to your Git repository:
   ```bash
   git clone https://github.com/your-org/gitops-repo.git
   cd gitops-repo
   
   # Copy the helm chart
   cp -r /path/to/rh-hackathon/helm-chart ./helm-chart
   
   # Commit and push
   git add helm-chart/
   git commit -m "Add Griot & Grits Helm chart"
   git push origin main
   ```

#### Step 2: Create Values Files for Different Environments

Create environment-specific values files in your Git repository:

**`values/development.yaml`**:
```yaml
global:
  namespace: "griot-and-grits-dev"
  imageRegistry: "registry.access.redhat.com"

backend:
  enabled: true
  replicas: 1
  route:
    enabled: true
    host: "backend-griot-dev.apps.mycluster.example.com"

frontend:
  enabled: true
  replicas: 1
  route:
    enabled: true
    host: "frontend-griot-dev.apps.mycluster.example.com"

mongodb:
  enabled: true
  auth:
    rootPassword: "dev-password"  # Use secrets in production!
  persistence:
    enabled: false

minio:
  enabled: true
  auth:
    rootPassword: "dev-password"  # Use secrets in production!
  persistence:
    enabled: false
```

**`values/production.yaml`**:
```yaml
global:
  namespace: "griot-and-grits-prod"
  imageRegistry: "registry.access.redhat.com"

backend:
  enabled: true
  replicas: 3
  resources:
    requests:
      memory: "512Mi"
      cpu: "200m"
    limits:
      memory: "1Gi"
      cpu: "1000m"
  route:
    enabled: true
    host: "backend-griot.apps.mycluster.example.com"

frontend:
  enabled: true
  replicas: 2
  resources:
    requests:
      memory: "2Gi"
      cpu: "500m"
    limits:
      memory: "4Gi"
      cpu: "2000m"
  route:
    enabled: true
    host: "frontend-griot.apps.mycluster.example.com"

mongodb:
  enabled: true
  auth:
    rootPassword: "CHANGE_ME"  # Use ArgoCD secrets!
  persistence:
    enabled: true
    storageClass: "fast-ssd"
    size: 50Gi

minio:
  enabled: true
  auth:
    rootPassword: "CHANGE_ME"  # Use ArgoCD secrets!
  persistence:
    enabled: true
    storageClass: "fast-ssd"
    size: 100Gi
```

#### Step 3: Create ArgoCD Application Manifest

Create `applications/griot-and-grits-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: griot-and-grits
  namespace: argocd
  # Add finalizer to allow cascading deletion
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  # Project name (default project if not specified)
  project: default
  
  # Source: Git repository containing the Helm chart
  source:
    repoURL: https://github.com/your-org/gitops-repo.git
    targetRevision: main  # Branch, tag, or commit SHA
    path: helm-chart  # Path to Helm chart in the repository
    helm:
      # Path to values file within the repository
      valueFiles:
        - ../values/development.yaml  # Adjust path based on your structure
      # Or use inline values:
      # values: |
      #   backend:
      #     replicas: 2
  
  # Destination: Where to deploy
  destination:
    server: https://kubernetes.default.svc  # Current cluster
    namespace: griot-and-grits-dev  # Target namespace
  
  # Sync policy
  syncPolicy:
    automated:
      prune: true  # Delete resources when removed from Git
      selfHeal: true  # Automatically sync when drift is detected
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true  # Create namespace if it doesn't exist
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

#### Step 4: Login to ArgoCD

1. **Get ArgoCD admin password**:
   ```bash
   # Get initial admin password
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

2. **Port-forward ArgoCD server** (if not using Ingress):
   ```bash
   kubectl port-forward svc/argocd-server -n argocd 8080:443
   ```

3. **Login via CLI**:
   ```bash
   argocd login localhost:8080 --username admin --password <password-from-step-1>
   ```

4. **Or access via Web UI**:
   - Open browser: `https://localhost:8080` (if port-forwarding)
   - Or use Ingress URL if configured
   - Username: `admin`
   - Password: (from step 1)

#### Step 5: Create the ArgoCD Application

**Option A: Using ArgoCD CLI**

```bash
# Create application from manifest file
argocd app create -f applications/griot-and-grits-app.yaml

# Or create directly via CLI
argocd app create griot-and-grits \
  --repo https://github.com/your-org/gitops-repo.git \
  --path helm-chart \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace griot-and-grits-dev \
  --values values/development.yaml \
  --sync-policy automated \
  --self-heal \
  --auto-prune
```

**Option B: Using kubectl**

```bash
# Apply the application manifest
kubectl apply -f applications/griot-and-grits-app.yaml

# ArgoCD will automatically detect and process the application
```

**Option C: Using ArgoCD Web UI**

1. Log in to ArgoCD Web UI
2. Click **"New App"**
3. Fill in the form:
   - **Application Name**: `griot-and-grits`
   - **Project Name**: `default`
   - **Sync Policy**: `Automatic` (optional)
   - **Repository URL**: `https://github.com/your-org/gitops-repo.git`
   - **Revision**: `main`
   - **Path**: `helm-chart`
   - **Cluster URL**: `https://kubernetes.default.svc`
   - **Namespace**: `griot-and-grits-dev`
   - **Values Files**: `../values/development.yaml`
4. Click **"Create"**

#### Step 6: Sync the Application

If you didn't enable automatic sync, manually sync:

```bash
# Sync the application
argocd app sync griot-and-grits

# Or sync with specific options
argocd app sync griot-and-grits --prune --force
```

**Via Web UI**:
1. Click on the application
2. Click **"Sync"** button
3. Review changes and click **"Synchronize"**

#### Step 7: Monitor Deployment

**Using CLI**:
```bash
# Check application status
argocd app get griot-and-grits

# Watch application status
argocd app wait griot-and-grits

# View application tree
argocd app tree griot-and-grits

# View application logs
argocd app logs griot-and-grits
```

**Using Web UI**:
- Navigate to the application in ArgoCD UI
- View real-time sync status
- See resource tree and health status
- View logs and events

#### Step 8: Verify Deployment

```bash
# Check pods
kubectl get pods -n griot-and-grits-dev

# Check routes
kubectl get routes -n griot-and-grits-dev

# Get application URLs
kubectl get route backend -n griot-and-grits-dev -o jsonpath='{.spec.host}'
kubectl get route frontend -n griot-and-grits-dev -o jsonpath='{.spec.host}'
```

### Managing Multiple Environments with ArgoCD

Create separate ArgoCD applications for each environment:

**`applications/griot-and-grits-dev.yaml`**:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: griot-and-grits-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/gitops-repo.git
    targetRevision: main
    path: helm-chart
    helm:
      valueFiles:
        - ../values/development.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: griot-and-grits-dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

**`applications/griot-and-grits-prod.yaml`**:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: griot-and-grits-prod
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-org/gitops-repo.git
    targetRevision: main  # Or use a specific tag for production
    path: helm-chart
    helm:
      valueFiles:
        - ../values/production.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: griot-and-grits-prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Using ArgoCD Secrets for Sensitive Values

For production, use ArgoCD secrets instead of storing passwords in Git:

1. **Create a secret in ArgoCD**:
   ```bash
   # Create secret with sensitive values
   kubectl create secret generic griot-and-grits-secrets \
     -n argocd \
     --from-literal=mongodb-password='secure-password' \
     --from-literal=minio-password='secure-password'
   ```

2. **Reference in Application manifest**:
   ```yaml
   spec:
     source:
       helm:
         valueFiles:
           - ../values/production.yaml
         # Reference secret values
         values: |
           mongodb:
             auth:
               rootPassword: $mongodb-password
           minio:
             auth:
               rootPassword: $minio-password
     # Or use Helm secrets plugin
   ```

### Updating the Application

1. **Update values in Git**:
   ```bash
   # Edit values file
   vim values/development.yaml
   
   # Commit and push
   git add values/development.yaml
   git commit -m "Update backend replicas to 3"
   git push origin main
   ```

2. **ArgoCD will automatically sync** (if automated sync is enabled)

3. **Or manually sync**:
   ```bash
   argocd app sync griot-and-grits
   ```

### Troubleshooting ArgoCD Deployment

**Application stuck in "Progressing" state**:
```bash
# Check application details
argocd app get griot-and-grits

# Check pod status
kubectl get pods -n griot-and-grits-dev

# View application events
argocd app events griot-and-grits
```

**Sync failures**:
```bash
# View sync operation details
argocd app history griot-and-grits

# Retry failed sync
argocd app sync griot-and-grits --retry-limit 5
```

**Resource conflicts**:
```bash
# Check for conflicting resources
kubectl get all -n griot-and-grits-dev

# Force sync (use with caution)
argocd app sync griot-and-grits --force
```

**View detailed logs**:
```bash
# ArgoCD application logs
argocd app logs griot-and-grits

# Application pod logs
kubectl logs -l app.kubernetes.io/instance=griot-and-grits -n griot-and-grits-dev
```

### Deleting ArgoCD Application

```bash
# Delete via CLI
argocd app delete griot-and-grits

# Or delete via kubectl
kubectl delete application griot-and-grits -n argocd
```

**Note**: If `cascade` deletion is enabled, this will also delete all application resources. Otherwise, only the ArgoCD application will be deleted.

---

## Configuration Reference

The chart is highly configurable through the `values.yaml` file. Key configuration options:

#### Global Settings

```yaml
global:
  namespace: ""  # Leave empty to use release namespace
  imageRegistry: "registry.access.redhat.com"
```

#### Backend Configuration

```yaml
backend:
  enabled: true
  replicas: 1
  image:
    repository: ubi9/python-311
    tag: latest
  resources:
    requests:
      memory: "256Mi"
      cpu: "100m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  config:
    dbUri: "mongodb://admin:password@mongodb:27017/gngdb?authSource=admin"
    storageEndpoint: "minio:9000"
    # ... other config options
```

#### Frontend Configuration

```yaml
frontend:
  enabled: true
  replicas: 1
  image:
    repository: ubi9/nodejs-20
    tag: latest
  resources:
    requests:
      memory: "1Gi"
      cpu: "200m"
    limits:
      memory: "2Gi"
      cpu: "1000m"
```

#### MongoDB Configuration

```yaml
mongodb:
  enabled: true
  auth:
    rootUsername: "admin"
    rootPassword: "gngdevpass12"  # Change this!
    database: "gngdb"
  persistence:
    enabled: false  # Set to true for production
    storageClass: ""
    size: 10Gi
```

#### MinIO Configuration

```yaml
minio:
  enabled: true
  auth:
    rootUser: "minioadmin"  # Change this!
    rootPassword: "minioadmin"  # Change this!
  persistence:
    enabled: false  # Set to true for production
    storageClass: ""
    size: 20Gi
```

#### Whisper ASR (Optional)

```yaml
whisper:
  enabled: false  # Enable for transcription features
  config:
    model: "base"  # tiny, base, small, medium, large, large-v2, large-v3
    engine: "openai_whisper"
  persistence:
    enabled: true
    size: 10Gi
```

### Advanced Configuration Examples

#### Production Installation with Persistence

```bash
helm install griot-and-grits . \
  --namespace griot-and-grits \
  --create-namespace \
  --set backend.route.host=backend-griot.apps.mycluster.com \
  --set frontend.route.host=frontend-griot.apps.mycluster.com \
  --set minio.route.host=minio-griot.apps.mycluster.com \
  --set mongodb.persistence.enabled=true \
  --set mongodb.persistence.storageClass=fast-ssd \
  --set minio.persistence.enabled=true \
  --set minio.persistence.storageClass=fast-ssd \
  --set mongodb.auth.rootPassword=secure-password \
  --set minio.auth.rootPassword=secure-password \
  --set backend.replicas=3 \
  --set frontend.replicas=2
```

#### Enable Whisper Transcription

```bash
helm install griot-and-grits . \
  --namespace griot-and-grits \
  --create-namespace \
  --set backend.route.host=backend-griot.apps.mycluster.com \
  --set frontend.route.host=frontend-griot.apps.mycluster.com \
  --set whisper.enabled=true \
  --set whisper.config.model=large-v3 \
  --set backend.config.processingEnableTranscription=true
```

---

## Troubleshooting

### Common Issues

#### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n griot-and-grits -l app.kubernetes.io/instance=griot-and-grits

# Describe pod for details
kubectl describe pod <pod-name> -n griot-and-grits

# Check events
kubectl get events -n griot-and-grits --sort-by='.lastTimestamp'
```

#### View Component Logs

```bash
# Backend logs
kubectl logs -l app.kubernetes.io/component=backend -n griot-and-grits -f

# Frontend logs
kubectl logs -l app.kubernetes.io/component=frontend -n griot-and-grits -f

# MongoDB logs
kubectl logs -l app.kubernetes.io/component=mongodb -n griot-and-grits -f

# MinIO logs
kubectl logs -l app.kubernetes.io/component=minio -n griot-and-grits -f

# All application logs
kubectl logs -l app.kubernetes.io/instance=griot-and-grits -n griot-and-grits --all-containers=true
```

#### Routes Not Accessible

```bash
# Check route status
kubectl get routes -n griot-and-grits

# Describe route
kubectl describe route backend -n griot-and-grits
kubectl describe route frontend -n griot-and-grits

# Test connectivity
curl -k https://$(kubectl get route backend -n griot-and-grits -o jsonpath='{.spec.host}')/health
```

#### Database Connection Issues

```bash
# Check MongoDB pod
kubectl get pods -l app.kubernetes.io/component=mongodb -n griot-and-grits

# Test MongoDB connection
kubectl exec -it deployment/mongodb -n griot-and-grits -- mongosh -u admin -p

# Check backend config
kubectl get configmap backend-config -n griot-and-grits -o yaml
```

#### Storage Issues

```bash
# Check MinIO pod
kubectl get pods -l app.kubernetes.io/component=minio -n griot-and-grits

# Check PVCs
kubectl get pvc -n griot-and-grits

# Check storage classes
kubectl get storageclass
```

#### Describe Resources

```bash
# Describe deployments
kubectl describe deployment backend -n griot-and-grits
kubectl describe deployment frontend -n griot-and-grits

# Describe services
kubectl describe service backend -n griot-and-grits
kubectl describe service mongodb -n griot-and-grits

# Describe configmaps
kubectl describe configmap backend-config -n griot-and-grits
```

#### Helm-Specific Issues

```bash
# Check Helm release status
helm status griot-and-grits -n griot-and-grits

# View Helm release history
helm history griot-and-grits -n griot-and-grits

# Rollback to previous version
helm rollback griot-and-grits -n griot-and-grits

# Dry-run to see what would be deployed
helm upgrade griot-and-grits . -n griot-and-grits --dry-run --debug
```

#### ArgoCD-Specific Issues

```bash
# Check ArgoCD application status
argocd app get griot-and-grits

# View sync history
argocd app history griot-and-grits

# Check for sync errors
argocd app diff griot-and-grits

# View application events
argocd app events griot-and-grits

# Retry failed sync
argocd app sync griot-and-grits --retry-limit 5
```

## Security Considerations

⚠️ **Important**: The default values use insecure passwords for development. For production:

1. **Change all default passwords**:
   - MongoDB root password
   - MinIO root credentials

2. **Use Secrets** instead of ConfigMaps for sensitive data:
   ```yaml
   # Create a secret
   kubectl create secret generic backend-secrets \
     --from-literal=db-password=secure-password \
     --from-literal=storage-secret-key=secure-key
   ```

3. **Enable persistence** for production to avoid data loss

4. **Use proper resource limits** based on your workload

5. **Enable network policies** if your cluster supports them

## Customization

### Using Custom Images

```yaml
backend:
  image:
    repository: my-registry.com/gng-backend
    tag: v1.0.0

frontend:
  image:
    repository: my-registry.com/gng-frontend
    tag: v1.0.0
```

### Custom Git Repositories

```yaml
backend:
  git:
    repo: "https://github.com/your-org/gng-backend.git"
    branch: "main"

frontend:
  git:
    repo: "https://github.com/your-org/gng-web.git"
    branch: "main"
```

## Chart Structure

```
helm-chart/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration values
├── README.md               # This file
├── templates/              # Kubernetes manifest templates
│   ├── _helpers.tpl        # Template helpers
│   ├── backend-*.yaml      # Backend resources
│   ├── frontend-*.yaml     # Frontend resources
│   ├── mongodb-*.yaml      # MongoDB resources
│   ├── minio-*.yaml        # MinIO resources
│   └── whisper-*.yaml      # Whisper resources
└── .helmignore             # Files to ignore when packaging
```

---

## Quick Reference

### Helm Commands

```bash
# Install
helm install griot-and-grits . -n griot-and-grits --create-namespace -f values.yaml

# Upgrade
helm upgrade griot-and-grits . -n griot-and-grits -f values.yaml

# Uninstall
helm uninstall griot-and-grits -n griot-and-grits

# Status
helm status griot-and-grits -n griot-and-grits

# List releases
helm list -n griot-and-grits
```

### ArgoCD Commands

```bash
# Create application
argocd app create -f applications/griot-and-grits-app.yaml

# Sync application
argocd app sync griot-and-grits

# Get application status
argocd app get griot-and-grits

# Delete application
argocd app delete griot-and-grits
```

### Kubernetes Commands

```bash
# Get all resources
kubectl get all -n griot-and-grits

# Get routes
kubectl get routes -n griot-and-grits

# Get pods
kubectl get pods -n griot-and-grits

# View logs
kubectl logs -l app.kubernetes.io/instance=griot-and-grits -n griot-and-grits -f
```

### Common Values Overrides

```bash
# Set route hosts (required)
--set backend.route.host=backend-griot.apps.mycluster.com
--set frontend.route.host=frontend-griot.apps.mycluster.com
--set minio.route.host=minio-griot.apps.mycluster.com

# Change replicas
--set backend.replicas=3 --set frontend.replicas=2

# Enable persistence
--set mongodb.persistence.enabled=true --set minio.persistence.enabled=true

# Change passwords
--set mongodb.auth.rootPassword=secure-password --set minio.auth.rootPassword=secure-password

# Enable Whisper
--set whisper.enabled=true --set whisper.config.model=large-v3
```

---

## Support

For issues and questions:
- **GitHub**: https://github.com/griot-and-grits
- **Check application logs**: `kubectl logs -l app.kubernetes.io/instance=griot-and-grits -n griot-and-grits`
- **Review Helm release status**: `helm status griot-and-grits -n griot-and-grits`
- **ArgoCD application status**: `argocd app get griot-and-grits`

## License

See the main project LICENSE file for details.
