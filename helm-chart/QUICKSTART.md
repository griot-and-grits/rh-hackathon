# Quick Start Guide

## Prerequisites

- Helm 3.0+ installed
- Access to a Kubernetes/OpenShift cluster
- `kubectl` or `oc` CLI configured

## Installation Steps

### 1. Basic Installation

```bash
# Navigate to the chart directory
cd helm-chart

# Install with default values (development)
helm install griot-and-grits . \
  --namespace gng-dev \
  --create-namespace
```

### 2. Production Installation

```bash
# Create a production values file
cp values-production.yaml.example my-production-values.yaml

# Edit the file and update:
# - All passwords (MongoDB, MinIO)
# - Storage classes
# - Resource limits
# - Route hosts (backend, frontend, minio)

# Install with production values
helm install griot-and-grits . \
  --namespace gng-production \
  --create-namespace \
  -f my-production-values.yaml
```

### 3. Verify Installation

```bash
# Check all pods are running
kubectl get pods -n gng-production

# Check services
kubectl get svc -n gng-production

# Check routes
kubectl get routes -n gng-production

# View installation notes
helm get notes griot-and-grits -n gng-production
```

### 4. Access the Application

```bash
# Get frontend URL
kubectl get route frontend -n gng-production -o jsonpath='{.spec.host}'

# Get backend URL
kubectl get route backend -n gng-production -o jsonpath='{.spec.host}'

# Get MinIO console URL
kubectl get route minio-console -n gng-production -o jsonpath='{.spec.host}'
```

### 5. View Logs

```bash
# Backend logs
kubectl logs -f deployment/backend -n gng-production

# Frontend logs
kubectl logs -f deployment/frontend -n gng-production

# MongoDB logs
kubectl logs -f deployment/mongodb -n gng-production

# MinIO logs
kubectl logs -f deployment/minio -n gng-production
```

## Common Operations

### Upgrade

```bash
# Upgrade with new values
helm upgrade griot-and-grits . \
  -n gng-production \
  -f my-production-values.yaml
```

### Uninstall

```bash
# Uninstall the release
helm uninstall griot-and-grits -n gng-production

# Note: Persistent volumes will remain. Delete manually if needed:
kubectl delete pvc -l app.kubernetes.io/instance=griot-and-grits -n gng-production
```

### Enable/Disable Components

```bash
# Disable Whisper
helm upgrade griot-and-grits . \
  -n gng-production \
  --set whisper.enabled=false

# Scale backend
helm upgrade griot-and-grits . \
  -n gng-production \
  --set backend.replicas=5
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n gng-production

# Check events
kubectl get events -n gng-production --sort-by='.lastTimestamp'
```

### Connection Issues

```bash
# Verify services are running
kubectl get svc -n gng-production

# Test connectivity from a pod
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# Then try: wget -O- http://backend:8000
```

### Configuration Issues

```bash
# View ConfigMap
kubectl get configmap backend-config -n gng-production -o yaml

# Edit ConfigMap (requires redeploy)
kubectl edit configmap backend-config -n gng-production
```

## Next Steps

- Review the full [README.md](README.md) for detailed configuration options
- Check the [values.yaml](values.yaml) for all available settings
- See [values-production.yaml.example](values-production.yaml.example) for production recommendations
