#!/bin/bash
# Deploy PostgreSQL to OpenShift
# Requires: oc CLI logged into OpenShift cluster

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="$SCRIPT_DIR/openshift"

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
    echo "  --skip-init             Skip database initialization job"
    echo "  --skip-verify           Skip database verification job"
    echo "  -v, --verify-only       Only run verification (requires existing deployment)"
    echo "  -d, --delete            Delete PostgreSQL deployment"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      Deploy PostgreSQL with init and verify"
    echo "  $0 -n my-project        Deploy to specific namespace"
    echo "  $0 --skip-init          Deploy without running init job"
    echo "  $0 --verify-only        Verify existing database"
    echo "  $0 --delete             Remove PostgreSQL deployment"
}

DELETE=false
VERIFY_ONLY=false

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
        -v|--verify-only)
            VERIFY_ONLY=true
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

print_header "🗄️  PostgreSQL - OpenShift Deployment"

print_info "Cluster: $(oc whoami --show-server)"
print_info "User: $(oc whoami)"
echo -e "${BOLD}Namespace:${NC} ${CYAN}$NAMESPACE${NC}"
echo ""

# Delete if requested
if [ "$DELETE" = true ]; then
    print_step "Deleting PostgreSQL Deployment"

    # Delete all jobs (including orphaned ones)
    print_status "Cleaning up jobs..."
    oc delete job init-db -n "$NAMESPACE" 2>/dev/null || true
    oc delete job verify-db -n "$NAMESPACE" 2>/dev/null || true
    oc delete jobs -l job-name=init-db -n "$NAMESPACE" 2>/dev/null || true
    oc delete jobs -l job-name=verify-db -n "$NAMESPACE" 2>/dev/null || true

    # Delete deployment and service
    print_status "Removing deployment and service..."
    oc delete -k "$MANIFESTS_DIR" -n "$NAMESPACE" 2>/dev/null || true

    print_success "PostgreSQL deleted successfully"
    exit 0
fi

# Verify only mode
if [ "$VERIFY_ONLY" = true ]; then
    print_status "Running database verification..."

    # Delete old verification job if exists
    oc delete job verify-db -n "$NAMESPACE" 2>/dev/null || true

    # Run verification job
    oc apply -f "$MANIFESTS_DIR/verify-job.yaml" -n "$NAMESPACE"

    print_status "Waiting for verification to complete..."
    oc wait --for=condition=complete --timeout=60s job/verify-db -n "$NAMESPACE" 2>/dev/null || {
        print_warning "Verification job didn't complete in time. Check logs:"
        echo "  oc logs job/verify-db -n $NAMESPACE"
        exit 1
    }

    echo ""
    print_success "Verification logs:"
    oc logs job/verify-db -n "$NAMESPACE"

    exit 0
fi

# Check/create namespace
if ! oc get namespace "$NAMESPACE" &> /dev/null; then
    print_step "Creating Namespace"
    oc new-project "$NAMESPACE" || oc create namespace "$NAMESPACE"
    print_success "Namespace created"
fi

# Deploy PostgreSQL
print_step "Deploying PostgreSQL"
oc apply -k "$MANIFESTS_DIR" -n "$NAMESPACE"

# Wait for deployment
print_status "Waiting for pods to be ready..."
oc rollout status deployment/postgres -n "$NAMESPACE" --timeout=180s || {
    print_error "Deployment timeout"
    print_info "Check status: oc get pods -n $NAMESPACE"
    exit 1
}

# Wait a bit for PostgreSQL to fully start and accept connections
print_status "Waiting for database to accept connections..."
sleep 10
print_success "PostgreSQL is ready"

# Run initialization job if not skipped
if [ "$SKIP_INIT" = false ]; then
    print_step "Initializing Database"

    # Delete all old init jobs (in case there are multiple)
    print_info "Cleaning up old jobs..."
    oc delete job init-db -n "$NAMESPACE" 2>/dev/null || true
    # Also try to delete by label pattern (if any orphaned jobs exist)
    oc delete jobs -l job-name=init-db -n "$NAMESPACE" 2>/dev/null || true

    # Apply init job
    oc apply -f "$MANIFESTS_DIR/init-job.yaml" -n "$NAMESPACE" > /dev/null

    # Wait for it to complete
    print_status "Creating tables and sample data..."
    if oc wait --for=condition=complete --timeout=120s job/init-db -n "$NAMESPACE" 2>/dev/null; then
        print_success "Database initialized successfully"
    else
        print_warning "Init job timeout - checking status..."
        echo ""
        oc get job init-db -n "$NAMESPACE"
        echo ""
        print_info "Logs:"
        oc logs job/init-db -n "$NAMESPACE" 2>/dev/null || echo "No logs available yet"
        echo ""
        print_info "Run this to check: oc logs job/init-db -n $NAMESPACE"
    fi
fi

# Run verification job if not skipped
if [ "$SKIP_VERIFY" = false ]; then
    print_step "Verifying Database"

    # Delete all old verification jobs (in case there are multiple)
    print_info "Cleaning up old jobs..."
    oc delete job verify-db -n "$NAMESPACE" 2>/dev/null || true
    # Also try to delete by label pattern (if any orphaned jobs exist)
    oc delete jobs -l job-name=verify-db -n "$NAMESPACE" 2>/dev/null || true

    # Run verification job
    oc apply -f "$MANIFESTS_DIR/verify-job.yaml" -n "$NAMESPACE" > /dev/null

    print_status "Testing connection and data..."
    if oc wait --for=condition=complete --timeout=120s job/verify-db -n "$NAMESPACE" 2>/dev/null; then
        echo ""
        print_success "Verification successful!"
        echo ""
        echo -e "${BOLD}Verification Results:${NC}"
        oc logs job/verify-db -n "$NAMESPACE" | grep -E "^(✓|✗|Installing|Verifying)" || oc logs job/verify-db -n "$NAMESPACE"
    else
        print_warning "Verification timeout - checking status..."
        echo ""
        oc get job verify-db -n "$NAMESPACE"
        echo ""
        print_info "Logs:"
        oc logs job/verify-db -n "$NAMESPACE" 2>/dev/null || echo "No logs available yet"
        echo ""
        print_info "Run this to check: oc logs job/verify-db -n $NAMESPACE"
    fi
fi

print_header "✅ Deployment Complete!"

# Get service information
SERVICE_IP=$(oc get service postgres -n "$NAMESPACE" -o jsonpath='{.spec.clusterIP}' 2>/dev/null || echo "")

if [ -n "$SERVICE_IP" ]; then
    print_success "PostgreSQL is running"
    echo -e "${BOLD}Service:${NC} ${CYAN}postgres.$NAMESPACE.svc.cluster.local${NC}"
    echo ""

    echo -e "${BOLD}Connection Details:${NC}"
    echo -e "  ${DIM}Host:${NC}     postgres ${DIM}(within cluster)${NC}"
    echo -e "  ${DIM}Port:${NC}     5432"
    echo -e "  ${DIM}Database:${NC} hackathon_db"
    echo -e "  ${DIM}User:${NC}     hackathon"
    echo -e "  ${DIM}Password:${NC} hackathon123"
    echo ""

    echo -e "${BOLD}Connection String:${NC}"
    echo -e "  ${CYAN}postgresql://hackathon:hackathon123@postgres:5432/hackathon_db${NC}"
fi

echo ""
echo -e "${BOLD}🛠  Useful Commands:${NC}\n"
echo -e "  ${CYAN}oc logs -f deployment/postgres -n $NAMESPACE${NC}"
echo -e "    ${DIM}View PostgreSQL logs${NC}\n"
echo -e "  ${CYAN}oc get pods -n $NAMESPACE${NC}"
echo -e "    ${DIM}Check pod status${NC}\n"
echo -e "  ${CYAN}./scripts/test-db.sh $NAMESPACE${NC}"
echo -e "    ${DIM}Quick database test${NC}\n"
echo -e "  ${CYAN}$0 --verify-only -n $NAMESPACE${NC}"
echo -e "    ${DIM}Re-run verification${NC}\n"
echo -e "  ${CYAN}$0 --delete -n $NAMESPACE${NC}"
echo -e "    ${DIM}Remove deployment${NC}\n"

echo -e "${BOLD}Connect Interactively:${NC}"
echo -e "  ${DIM}oc run psql-client --rm -it --image=registry.redhat.io/rhel9/postgresql-15 -n $NAMESPACE -- bash${NC}"
echo -e "  ${DIM}# Then: psql -h postgres -U hackathon -d hackathon_db${NC}\n"
