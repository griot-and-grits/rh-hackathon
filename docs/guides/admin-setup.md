# Admin Setup Guide

> Cluster administrator preparation guide for hosting the Griot & Grits hackathon.

## Pre-Hackathon Setup

### 1. Pre-import Container Images

Avoid 60 users pulling images simultaneously:

```bash
make admin-import-images
```

Imports: MongoDB, MinIO, Python 3.11, Node.js 20, Git into OpenShift internal registry.

Verify:
```bash
oc get imagestreams -n openshift -l app=griot-grits-hackathon
```

### 2. Create User Namespaces

Create namespaces and grant users access:

```bash
make admin-create-namespaces COUNT=60
```

This creates `gng-user1` through `gng-user60` and grants each user admin access to their namespace.

Verify:
```bash
oc get namespaces -l app=griot-grits-hackathon
oc get rolebindings -n gng-user1
```

### 3. Set Resource Quotas

Prevent resource exhaustion:

```bash
for ns in $(oc get ns -o name | grep gng-); do
  cat <<EOF | oc apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: hackathon-quota
  namespace: ${ns#namespace/}
spec:
  hard:
    requests.cpu: "2"
    requests.memory: 4Gi
    limits.cpu: "4"
    limits.memory: 8Gi
    persistentvolumeclaims: "3"
    pods: "10"
EOF
done
```

## Resource Requirements

**Per user (full stack):**
- CPU: 700m request, 3000m limit
- Memory: 2.5Gi request, 5.5Gi limit
- Storage: ~3Gi (MongoDB + MinIO PVCs)

**For 60 users:**
- Total CPU: ~42 cores request, ~180 cores limit
- Total Memory: ~150 GiB request, ~330 GiB limit
- Total Storage: ~180 GiB

## During Hackathon

Monitor cluster:
```bash
oc adm top nodes
oc adm top pods --all-namespaces

# Check quota usage
for ns in $(oc get ns -o name | grep gng-); do
  oc describe quota -n ${ns#namespace/}
done
```

Common fixes:
```bash
# Increase quota
oc patch resourcequota hackathon-quota -n gng-user1 --patch '
spec:
  hard:
    limits.memory: "12Gi"
'

# Check PVCs
oc get pvc --all-namespaces | grep gng-

# Expand PVC
oc patch pvc mongodb-data -n gng-user1 --patch '{"spec":{"resources":{"requests":{"storage":"5Gi"}}}}'
```

## Cleanup After Event

Delete all hackathon namespaces:
```bash
# Verify first
oc get namespaces -l app=griot-grits-hackathon

# Delete
oc delete namespace -l app=griot-grits-hackathon
```

Remove pre-imported images:
```bash
oc delete imagestream -l app=griot-grits-hackathon -n openshift
```

## Troubleshooting

**Users can't create projects:**
```bash
oc adm policy add-cluster-role-to-group self-provisioner system:authenticated:oauth
```

**Internal registry not accessible:**
```bash
oc patch configs.imageregistry.operator.openshift.io/cluster --type merge -p '{"spec":{"defaultRoute":true}}'
```

**Grant registry access:**
```bash
oc policy add-role-to-group system:image-puller system:authenticated -n openshift
```

## Testing Pre-Event

Test the full flow:

```bash
# As admin
make admin-import-images
make admin-create-namespaces COUNT=1  # Create gng-user1

# As user1 (login as user1)
oc login <cluster> -u user1
make setup-openshift USERNAME=user1
make info

# Cleanup test
oc delete namespace gng-user1
```

---

← [Back to Documentation Index](../README.md)
