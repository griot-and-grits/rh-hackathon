#!/bin/bash
# Deploy Whisper ASR to OpenShift
# Requires: oc CLI logged into OpenShift cluster

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="$SCRIPT_DIR/openshift"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
print_error() { echo -e "${RED}[-]${NC} $1"; }

# Default values
NAMESPACE="${NAMESPACE:-griot-grits}"
MODEL="${MODEL:-base}"

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -n, --namespace NAME    OpenShift namespace (default: griot-grits)"
    echo "  -m, --model MODEL       Whisper model size (default: base)"
    echo "                          Options: tiny, base, small, medium, large-v3"
    echo "  -d, --delete            Delete Whisper deployment"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      Deploy with defaults"
    echo "  $0 -n my-project        Deploy to specific namespace"
    echo "  $0 -m small             Deploy with small model"
    echo "  $0 --delete             Remove Whisper deployment"
}

DELETE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -m|--model)
            MODEL="$2"
            shift 2
            ;;
        -d|--delete)
            DELETE=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Check oc CLI
if ! command -v oc &> /dev/null; then
    print_error "oc CLI not found. Install from: https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html"
    exit 1
fi

# Check if logged in
if ! oc whoami &> /dev/null; then
    print_error "Not logged into OpenShift. Run: oc login <cluster-url>"
    exit 1
fi

echo ""
echo "=========================================="
echo "  Whisper ASR - OpenShift Deployment"
echo "=========================================="
echo ""

print_status "Cluster: $(oc whoami --show-server)"
print_status "User: $(oc whoami)"
print_status "Namespace: $NAMESPACE"
echo ""

# Delete if requested
if [ "$DELETE" = true ]; then
    print_status "Deleting Whisper ASR deployment..."

    oc delete -k "$MANIFESTS_DIR" -n "$NAMESPACE" 2>/dev/null || true

    print_success "Whisper ASR deleted"
    exit 0
fi

# Check/create namespace
if ! oc get namespace "$NAMESPACE" &> /dev/null; then
    print_status "Creating namespace: $NAMESPACE"
    oc new-project "$NAMESPACE" || oc create namespace "$NAMESPACE"
fi

# Update model in configmap
print_status "Configuring model: $MODEL"
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/model: \".*\"/model: \"$MODEL\"/" "$MANIFESTS_DIR/configmap.yaml"
else
    sed -i "s/model: \".*\"/model: \"$MODEL\"/" "$MANIFESTS_DIR/configmap.yaml"
fi

# Adjust PVC size based on model
case $MODEL in
    tiny|base)
        PVC_SIZE="2Gi"
        ;;
    small)
        PVC_SIZE="3Gi"
        ;;
    medium)
        PVC_SIZE="6Gi"
        ;;
    large|large-v2|large-v3)
        PVC_SIZE="12Gi"
        ;;
    *)
        PVC_SIZE="5Gi"
        ;;
esac
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/storage: .*/storage: $PVC_SIZE/" "$MANIFESTS_DIR/pvc.yaml"
else
    sed -i "s/storage: .*/storage: $PVC_SIZE/" "$MANIFESTS_DIR/pvc.yaml"
fi

# Deploy using kustomize
print_status "Deploying Whisper ASR..."
oc apply -k "$MANIFESTS_DIR" -n "$NAMESPACE"

# Wait for deployment
print_status "Waiting for deployment to be ready..."
oc rollout status deployment/whisper-asr -n "$NAMESPACE" --timeout=300s || {
    print_warning "Deployment taking longer than expected. Check with: oc get pods -n $NAMESPACE"
}

# Get route URL
ROUTE_URL=$(oc get route whisper-asr -n "$NAMESPACE" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")

echo ""
echo "=========================================="
echo "  Deployment Complete!"
echo "=========================================="
echo ""

if [ -n "$ROUTE_URL" ]; then
    print_success "Whisper ASR URL: https://$ROUTE_URL"
    echo ""
    echo "API Endpoints:"
    echo "  POST https://$ROUTE_URL/asr          - Transcribe audio"
    echo "  GET  https://$ROUTE_URL/             - Health check"
    echo ""
    echo "To use with the backend, set:"
    echo "  PROCESSING_ENABLE_TRANSCRIPTION=true"
    echo "  PROCESSING_TRANSCRIPTION_API_URL=https://$ROUTE_URL"
else
    print_warning "Route not ready yet. Get URL with:"
    echo "  oc get route whisper-asr -n $NAMESPACE"
fi

echo ""
echo "Useful commands:"
echo "  oc logs -f deployment/whisper-asr -n $NAMESPACE    # View logs"
echo "  oc get pods -n $NAMESPACE                          # Check pod status"
echo "  $0 --delete                                        # Remove deployment"
echo ""
