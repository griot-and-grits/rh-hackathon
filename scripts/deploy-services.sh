#!/bin/bash
# Deploy MongoDB + MinIO to OpenShift
# Requires: oc CLI logged into OpenShift cluster

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

print_status() { echo -e "${CYAN}▶${NC} ${BOLD}$1${NC}"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} ${DIM}$1${NC}"; }
print_step() { echo -e "\n${MAGENTA}${BOLD}→ $1${NC}"; }
print_header() {
    echo ""
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${CYAN}  $1${NC}"
    echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Default values
NAMESPACE="${NAMESPACE:-griot-grits}"
SKIP_INIT=false
SKIP_VERIFY=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -n, --namespace NAME    OpenShift namespace (default: griot-grits)"
    echo "  --skip-init             Skip initialization jobs"
    echo "  --skip-verify           Skip verification"
    echo "  -d, --delete            Delete all services"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      Deploy MongoDB + MinIO"
    echo "  $0 -n my-project        Deploy to specific namespace"
    echo "  $0 --delete             Remove all deployments"
}

DELETE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        --skip-init)
            SKIP_INIT=true
            shift
            ;;
        --skip-verify)
            SKIP_VERIFY=true
            shift
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

print_header "🚀 Griot & Grits - Service Deployment"

print_info "Cluster: $(oc whoami --show-server)"
print_info "User: $(oc whoami)"
echo -e "${BOLD}Namespace:${NC} ${CYAN}$NAMESPACE${NC}"
echo ""

# Delete if requested
if [ "$DELETE" = true ]; then
    print_step "Deleting All Services"

    # Delete jobs
    print_status "Cleaning up jobs..."
    oc delete job init-mongodb -n "$NAMESPACE" 2>/dev/null || true
    oc delete job init-minio -n "$NAMESPACE" 2>/dev/null || true
    oc delete jobs -l job-name=init-mongodb -n "$NAMESPACE" 2>/dev/null || true
    oc delete jobs -l job-name=init-minio -n "$NAMESPACE" 2>/dev/null || true

    # Delete MongoDB
    print_status "Removing MongoDB..."
    oc delete -k "$ROOT_DIR/infra/mongodb/openshift" -n "$NAMESPACE" 2>/dev/null || true

    # Delete MinIO
    print_status "Removing MinIO..."
    oc delete -k "$ROOT_DIR/infra/minio/openshift" -n "$NAMESPACE" 2>/dev/null || true

    print_success "All services deleted successfully"
    exit 0
fi

# Check/create namespace
if ! oc get namespace "$NAMESPACE" &> /dev/null; then
    print_step "Creating Namespace"
    oc new-project "$NAMESPACE" || oc create namespace "$NAMESPACE"
    print_success "Namespace created"
fi

# Deploy MongoDB
print_step "Deploying MongoDB"
oc apply -k "$ROOT_DIR/infra/mongodb/openshift" -n "$NAMESPACE"

print_status "Waiting for MongoDB to be ready..."
oc rollout status deployment/mongodb -n "$NAMESPACE" --timeout=180s || {
    print_error "MongoDB deployment timeout"
    print_info "Check status: oc get pods -n $NAMESPACE"
    exit 1
}
print_success "MongoDB is ready"

# Deploy MinIO
print_step "Deploying MinIO"
oc apply -k "$ROOT_DIR/infra/minio/openshift" -n "$NAMESPACE"

print_status "Waiting for MinIO to be ready..."
oc rollout status deployment/minio -n "$NAMESPACE" --timeout=180s || {
    print_error "MinIO deployment timeout"
    print_info "Check status: oc get pods -n $NAMESPACE"
    exit 1
}
print_success "MinIO is ready"

# Wait for services to fully start
print_status "Waiting for services to accept connections..."
sleep 10

# Initialize MongoDB if not skipped
if [ "$SKIP_INIT" = false ]; then
    print_step "Initializing MongoDB"

    print_info "Cleaning up old jobs..."
    oc delete job init-mongodb -n "$NAMESPACE" 2>/dev/null || true
    oc delete jobs -l job-name=init-mongodb -n "$NAMESPACE" 2>/dev/null || true

    oc apply -f "$ROOT_DIR/infra/mongodb/openshift/init-job.yaml" -n "$NAMESPACE" > /dev/null

    print_status "Creating collections and sample data..."
    if oc wait --for=condition=complete --timeout=120s job/init-mongodb -n "$NAMESPACE" 2>/dev/null; then
        print_success "MongoDB initialized successfully"
    else
        print_warning "MongoDB init timeout - checking status..."
        oc get job init-mongodb -n "$NAMESPACE"
        print_info "Check logs: oc logs job/init-mongodb -n $NAMESPACE"
    fi
fi

# Initialize MinIO if not skipped
if [ "$SKIP_INIT" = false ]; then
    print_step "Initializing MinIO"

    print_info "Cleaning up old jobs..."
    oc delete job init-minio -n "$NAMESPACE" 2>/dev/null || true
    oc delete jobs -l job-name=init-minio -n "$NAMESPACE" 2>/dev/null || true

    oc apply -f "$ROOT_DIR/infra/minio/openshift/init-job.yaml" -n "$NAMESPACE" > /dev/null

    print_status "Creating storage buckets..."
    if oc wait --for=condition=complete --timeout=120s job/init-minio -n "$NAMESPACE" 2>/dev/null; then
        print_success "MinIO initialized successfully"
    else
        print_warning "MinIO init timeout - checking status..."
        oc get job init-minio -n "$NAMESPACE"
        print_info "Check logs: oc logs job/init-minio -n $NAMESPACE"
    fi
fi

print_header "✅ Deployment Complete!"

print_success "All services are running"
echo ""

echo -e "${BOLD}Services Deployed:${NC}"
echo -e "  ${GREEN}●${NC} MongoDB: ${CYAN}mongodb:27017${NC}"
echo -e "  ${GREEN}●${NC} MinIO API: ${CYAN}minio:9000${NC}"
echo -e "  ${GREEN}●${NC} MinIO Console: ${CYAN}minio:9001${NC}"
echo ""

# Get MinIO console route
MINIO_CONSOLE_URL=$(oc get route minio-console -n "$NAMESPACE" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")

echo -e "${BOLD}Connection Details:${NC}\n"

echo -e "${CYAN}MongoDB:${NC}"
echo -e "  ${DIM}Host:${NC}     mongodb"
echo -e "  ${DIM}Port:${NC}     27017"
echo -e "  ${DIM}Database:${NC} gngdb"
echo -e "  ${DIM}User:${NC}     admin"
echo -e "  ${DIM}Password:${NC} gngdevpass12"
echo -e "  ${DIM}URI:${NC}      ${CYAN}mongodb://admin:gngdevpass12@mongodb:27017/gngdb${NC}"
echo ""

echo -e "${CYAN}MinIO:${NC}"
echo -e "  ${DIM}Endpoint:${NC}    minio:9000"
echo -e "  ${DIM}Access Key:${NC}  minioadmin"
echo -e "  ${DIM}Secret Key:${NC}  minioadmin"
echo -e "  ${DIM}Bucket:${NC}      artifacts"

if [ -n "$MINIO_CONSOLE_URL" ]; then
    echo -e "  ${DIM}Console:${NC}     ${CYAN}https://$MINIO_CONSOLE_URL${NC}"
fi

echo ""
echo -e "${BOLD}🛠  Useful Commands:${NC}\n"
echo -e "  ${CYAN}oc get all -n $NAMESPACE${NC}"
echo -e "    ${DIM}View all resources${NC}\n"
echo -e "  ${CYAN}oc logs -f deployment/mongodb -n $NAMESPACE${NC}"
echo -e "    ${DIM}View MongoDB logs${NC}\n"
echo -e "  ${CYAN}oc logs -f deployment/minio -n $NAMESPACE${NC}"
echo -e "    ${DIM}View MinIO logs${NC}\n"
echo -e "  ${CYAN}$0 --delete -n $NAMESPACE${NC}"
echo -e "    ${DIM}Remove all deployments${NC}\n"

if [ -n "$MINIO_CONSOLE_URL" ]; then
    echo -e "${BOLD}MinIO Console Access:${NC}"
    echo -e "  ${DIM}Open: https://$MINIO_CONSOLE_URL${NC}"
    echo -e "  ${DIM}Login: minioadmin / minioadmin${NC}\n"
fi
