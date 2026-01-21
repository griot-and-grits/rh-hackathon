#!/bin/bash
# Griot & Grits - OpenShift User Setup
# Sets up a personal namespace for hackathon development on RHOAI/OpenShift

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

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -u, --username NAME     Your username/identifier (default: prompt)"
    echo "  -s, --skip-services     Skip MongoDB + MinIO deployment"
    echo "  -c, --with-code         Deploy frontend and backend code with hot-reload"
    echo "  -d, --delete            Delete your namespace and all resources"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                      Interactive setup (will prompt for username)"
    echo "  $0 -u jdoe              Setup for user 'jdoe'"
    echo "  $0 -u jdoe --with-code  Setup with code deployment"
    echo "  $0 -u jdoe --delete     Delete namespace for user 'jdoe'"
}

USERNAME=""
SKIP_SERVICES=false
WITH_CODE=false
DELETE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--username)
            USERNAME="$2"
            shift 2
            ;;
        -s|--skip-services)
            SKIP_SERVICES=true
            shift
            ;;
        -c|--with-code)
            WITH_CODE=true
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
    print_error "Not logged into OpenShift."
    echo ""
    echo "Please login first:"
    echo "  oc login <cluster-url>"
    echo ""
    echo "Or use the web console login:"
    echo "  1. Go to your OpenShift web console"
    echo "  2. Click your username (top right) → Copy login command"
    echo "  3. Paste and run the command in your terminal"
    exit 1
fi

print_header "🚀 Griot & Grits - OpenShift Setup"

print_info "Cluster: $(oc whoami --show-server)"
print_info "User: $(oc whoami)"
echo ""

# Auto-detect username from oc whoami if not provided
if [ -z "$USERNAME" ]; then
    DETECTED_USER=$(oc whoami)

    print_step "Namespace Selection"
    echo -e "${BOLD}Detected user:${NC} ${GREEN}$DETECTED_USER${NC}"
    echo ""
    echo -e "Use this for your namespace ${CYAN}(gng-$DETECTED_USER)${NC}? ${DIM}[Y/n]${NC}"
    read -p "→ " USE_DETECTED

    if [[ "$USE_DETECTED" =~ ^[Nn] ]]; then
        echo ""
        echo "Enter your preferred username/identifier:"
        echo "This will be used to create your namespace: gng-<username>"
        echo ""
        read -p "Username: " USERNAME

        if [ -z "$USERNAME" ]; then
            print_error "Username cannot be empty"
            exit 1
        fi
    else
        USERNAME="$DETECTED_USER"
    fi
fi

# Clean username (lowercase, alphanumeric and dash only)
USERNAME=$(echo "$USERNAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
NAMESPACE="gng-${USERNAME}"

# Create .openshift-config file to save namespace for future use
CONFIG_FILE="$ROOT_DIR/.openshift-config"

# Delete mode
if [ "$DELETE" = true ]; then
    print_warning "This will DELETE namespace '$NAMESPACE' and ALL resources in it!"
    read -p "Are you sure? (yes/no): " CONFIRM

    if [ "$CONFIRM" != "yes" ]; then
        echo "Cancelled."
        exit 0
    fi

    print_status "Deleting namespace: $NAMESPACE"

    if oc delete namespace "$NAMESPACE" 2>/dev/null; then
        print_success "Namespace deleted: $NAMESPACE"
    else
        print_warning "Namespace not found or already deleted"
    fi

    # Clean up config file
    if [ -f "$CONFIG_FILE" ]; then
        rm "$CONFIG_FILE"
        print_success "Removed local configuration"
    fi

    exit 0
fi

# Create or switch to namespace
print_step "Setting Up Namespace"

echo -e "${BOLD}Namespace:${NC} ${CYAN}$NAMESPACE${NC}"

if oc get namespace "$NAMESPACE" &> /dev/null; then
    print_success "Namespace already exists"
    oc project "$NAMESPACE" > /dev/null 2>&1
else
    print_status "Creating new namespace..."
    if oc new-project "$NAMESPACE" 2>/dev/null; then
        print_success "Created namespace successfully"
    elif oc create namespace "$NAMESPACE" 2>/dev/null; then
        print_success "Created namespace successfully"
        oc project "$NAMESPACE" > /dev/null 2>&1
    else
        print_error "Failed to create namespace. You may not have permission."
        exit 1
    fi
fi

# Save namespace to config
echo "NAMESPACE=$NAMESPACE" > "$CONFIG_FILE"
echo "USERNAME=$USERNAME" >> "$CONFIG_FILE"
print_success "Configuration saved"
print_info "Config file: $CONFIG_FILE"

echo ""

# Set resource quotas (optional, commented out by default)
# print_status "Setting resource quotas..."
# cat <<EOF | oc apply -f - -n "$NAMESPACE"
# apiVersion: v1
# kind: ResourceQuota
# metadata:
#   name: hackathon-quota
# spec:
#   hard:
#     requests.cpu: "4"
#     requests.memory: 8Gi
#     limits.cpu: "8"
#     limits.memory: 16Gi
#     persistentvolumeclaims: "5"
# EOF

# Deploy MongoDB + MinIO if not skipped
if [ "$SKIP_SERVICES" = false ]; then
    print_step "Deploying Backend Services"

    "$ROOT_DIR/scripts/deploy-services.sh" --namespace "$NAMESPACE"

    echo ""
fi

# Create environment configuration for backend
print_step "Creating Environment Configuration"

ENV_FILE="$ROOT_DIR/.env.openshift"
cat > "$ENV_FILE" << EOF
# =============================================================================
# Griot & Grits - OpenShift Environment
# =============================================================================
# Generated for user: $USERNAME
# Namespace: $NAMESPACE
# Generated at: $(date)

# =============================================================================
# Environment
# =============================================================================
ENVIRONMENT=development
DEBUG=true
APP_NAME=Griot and Grits API
APP_VERSION=0.1.0

# =============================================================================
# MongoDB Database
# =============================================================================
DB_URI=mongodb://admin:gngdevpass12@mongodb:27017/gngdb
DB_NAME=gngdb
DB_MAX_POOL_SIZE=10
DB_MIN_POOL_SIZE=1

# If using from outside the cluster (via port-forward):
# oc port-forward service/mongodb 27017:27017 -n $NAMESPACE
# Then use: mongodb://admin:gngdevpass12@localhost:27017/gngdb

# =============================================================================
# MinIO Object Storage
# =============================================================================
STORAGE_ENDPOINT=minio:9000
STORAGE_ACCESS_KEY=minioadmin
STORAGE_SECRET_KEY=minioadmin
STORAGE_BUCKET=artifacts
STORAGE_REGION=us-east-1
STORAGE_SECURE=false

# If using from outside the cluster (via port-forward):
# oc port-forward service/minio 9000:9000 -n $NAMESPACE
# Then use: STORAGE_ENDPOINT=localhost:9000

# =============================================================================
# Globus Archive (disabled for hackathon)
# =============================================================================
GLOBUS_ENABLED=false

# =============================================================================
# Processing Pipeline
# =============================================================================
PROCESSING_MODE=sync
PROCESSING_ENABLE_METADATA_EXTRACTION=true
PROCESSING_ENABLE_TRANSCRIPTION=false
PROCESSING_ENABLE_LLM_ENRICHMENT=false

# To enable Whisper transcription, deploy it and set:
# PROCESSING_ENABLE_TRANSCRIPTION=true
# PROCESSING_TRANSCRIPTION_API_URL=https://<whisper-route>

# =============================================================================
# CORS Settings
# =============================================================================
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
CORS_ALLOW_CREDENTIALS=true
CORS_ALLOW_METHODS=*
CORS_ALLOW_HEADERS=*

# =============================================================================
# OpenShift Metadata
# =============================================================================
OPENSHIFT_NAMESPACE=$NAMESPACE
OPENSHIFT_USERNAME=$USERNAME
EOF

print_success "Environment configuration saved"
print_info "File: $ENV_FILE"

# Deploy application code if requested
if [ "$WITH_CODE" = true ]; then
    echo ""
    print_step "Deploying Application Code"

    "$ROOT_DIR/scripts/deploy-code.sh" --namespace "$NAMESPACE"

    echo ""
fi

print_header "✨ Setup Complete!"

echo -e "${GREEN}${BOLD}✓ Your Environment is Ready!${NC}\n"

echo -e "${BOLD}Namespace:${NC} ${CYAN}$NAMESPACE${NC}"
echo -e "${BOLD}Services:${NC}"
echo -e "  ${GREEN}●${NC} MongoDB: ${CYAN}mongodb:27017${NC}"
echo -e "  ${GREEN}●${NC} MinIO: ${CYAN}minio:9000${NC}"
echo ""

echo -e "${BOLD}Connection Details:${NC}\n"

echo -e "${CYAN}MongoDB:${NC}"
echo -e "  ${DIM}URI:${NC} mongodb://admin:gngdevpass12@mongodb:27017/gngdb"
echo ""

echo -e "${CYAN}MinIO:${NC}"
echo -e "  ${DIM}Endpoint:${NC}    minio:9000"
echo -e "  ${DIM}Access Key:${NC}  minioadmin"
echo -e "  ${DIM}Secret Key:${NC}  minioadmin"
echo -e "  ${DIM}Bucket:${NC}      artifacts"
echo ""

# Get MinIO console route
MINIO_CONSOLE=$(oc get route minio-console -n "$NAMESPACE" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
if [ -n "$MINIO_CONSOLE" ]; then
    echo -e "  ${DIM}Console:${NC}     ${CYAN}https://$MINIO_CONSOLE${NC}"
    echo ""
fi

echo -e "${BOLD}📝 Next Steps:${NC}\n"

if [ "$WITH_CODE" = true ]; then
    # Get application routes
    FRONTEND_ROUTE=$(oc get route frontend -n "$NAMESPACE" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
    BACKEND_ROUTE=$(oc get route backend -n "$NAMESPACE" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")

    echo -e "${YELLOW}1.${NC} ${BOLD}Access your application:${NC}"
    if [ -n "$FRONTEND_ROUTE" ]; then
        echo -e "   ${CYAN}Frontend:${NC} https://$FRONTEND_ROUTE"
    fi
    if [ -n "$BACKEND_ROUTE" ]; then
        echo -e "   ${CYAN}Backend:${NC}  https://$BACKEND_ROUTE"
    fi
    echo -e "   ${DIM}Hot-reload is enabled for code changes${NC}\n"

    echo -e "${YELLOW}2.${NC} ${BOLD}Update code (for development):${NC}"
    echo -e "   ${DIM}# Sync local changes to running pods${NC}"
    echo -e "   ${DIM}oc rsync ./backend-code/ \$(oc get pod -l app=backend -o name | head -1):/code -n $NAMESPACE${NC}"
    echo -e "   ${DIM}oc rsync ./frontend-code/ \$(oc get pod -l app=frontend -o name | head -1):/code -n $NAMESPACE${NC}\n"

    echo -e "${YELLOW}3.${NC} ${BOLD}Access MinIO console:${NC}"
else
    echo -e "${YELLOW}1.${NC} ${BOLD}Use the backend services:${NC}"
    echo -e "   ${DIM}source .env.openshift${NC}"
    echo -e "   ${DIM}# All connection details are in this file${NC}\n"

    echo -e "${YELLOW}2.${NC} ${BOLD}Deploy your code:${NC}"
    echo -e "   ${DIM}$0 --username $USERNAME --with-code${NC}"
    echo -e "   ${DIM}# Deploys frontend and backend with hot-reload${NC}\n"

    echo -e "${YELLOW}3.${NC} ${BOLD}Access MinIO console:${NC}"
fi

if [ -n "$MINIO_CONSOLE" ]; then
    echo -e "   ${DIM}https://$MINIO_CONSOLE${NC}"
    echo -e "   ${DIM}Login: minioadmin / minioadmin${NC}\n"
else
    echo -e "   ${DIM}oc get route minio-console -n $NAMESPACE${NC}\n"
fi

if [ "$WITH_CODE" != true ]; then
    echo -e "${YELLOW}4.${NC} ${BOLD}Port-forward for local access:${NC}"
    echo -e "   ${DIM}oc port-forward service/mongodb 27017:27017 -n $NAMESPACE${NC}"
    echo -e "   ${DIM}oc port-forward service/minio 9000:9000 -n $NAMESPACE${NC}\n"
fi

echo -e "${BOLD}🛠  Useful Commands:${NC}\n"
echo -e "  ${CYAN}oc get all -n $NAMESPACE${NC}"
echo -e "    ${DIM}View all resources${NC}\n"
echo -e "  ${CYAN}oc logs -f deployment/postgres -n $NAMESPACE${NC}"
echo -e "    ${DIM}View PostgreSQL logs${NC}\n"
echo -e "  ${CYAN}./scripts/cleanup-jobs.sh${NC}"
echo -e "    ${DIM}Clean up old jobs${NC}\n"
echo -e "  ${CYAN}$0 --delete${NC}"
echo -e "    ${DIM}Delete your namespace${NC}\n"

echo -e "${GREEN}${BOLD}Happy Hacking! 🚀${NC}\n"
