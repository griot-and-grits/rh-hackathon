#!/bin/bash

# Colors for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

set -e

# Parse arguments
NAMESPACE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        *)
            echo -e "${YELLOW}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Auto-detect namespace if not provided
if [ -z "$NAMESPACE" ]; then
    CURRENT_PROJECT=$(oc project -q 2>/dev/null || echo "")
    if [ -n "$CURRENT_PROJECT" ]; then
        NAMESPACE="$CURRENT_PROJECT"
        echo -e "${CYAN}${BOLD}Using current namespace: ${NAMESPACE}${NC}"
    else
        echo -e "${YELLOW}No namespace specified and cannot detect current project${NC}"
        echo "Usage: $0 -n <namespace>"
        exit 1
    fi
else
    echo -e "${CYAN}${BOLD}Using namespace: ${NAMESPACE}${NC}"
    oc project "$NAMESPACE" > /dev/null
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")/infra"

echo ""
echo -e "${MAGENTA}${BOLD}=== Deploying Application Code with Hot-Reload ===${NC}"
echo ""

# Deploy Backend
echo -e "${CYAN}Deploying backend...${NC}"
oc apply -f "$INFRA_DIR/backend/openshift/backend-config.yaml" -n "$NAMESPACE" | grep -E "configured|created" | sed 's/^/  /'
oc apply -f "$INFRA_DIR/backend/openshift/backend.yaml" -n "$NAMESPACE" | grep -E "configured|created" | sed 's/^/  /'

# Wait for backend route to be created
sleep 3

# Get backend URL
BACKEND_URL=$(oc get route backend -n "$NAMESPACE" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
if [ -z "$BACKEND_URL" ]; then
    BACKEND_URL="backend-${NAMESPACE}.apps.cluster.local"
fi

# Get cluster domain from existing route or construct it
CLUSTER_DOMAIN=$(oc get route -n openshift-console console -o jsonpath='{.spec.host}' 2>/dev/null | sed 's/console-openshift-console\.//' || echo "apps.cluster.local")

# Construct frontend URL
FRONTEND_URL="frontend-${NAMESPACE}.${CLUSTER_DOMAIN}"

# Update frontend manifest with URLs
FRONTEND_MANIFEST="$INFRA_DIR/frontend/openshift/frontend.yaml"
TEMP_FRONTEND="/tmp/frontend-${NAMESPACE}.yaml"
sed -e "s|https://backend-NAMESPACE.CLUSTER_DOMAIN|https://${BACKEND_URL}|g" \
    -e "s|https://frontend-NAMESPACE.CLUSTER_DOMAIN|https://${FRONTEND_URL}|g" \
    "$FRONTEND_MANIFEST" > "$TEMP_FRONTEND"

# Deploy Frontend
echo -e "${CYAN}Deploying frontend...${NC}"
oc apply -f "$TEMP_FRONTEND" -n "$NAMESPACE" | grep -E "configured|created" | sed 's/^/  /'
rm -f "$TEMP_FRONTEND"

# Wait for pods to be ready
echo -e "${DIM}Waiting for pods to start...${NC}"
oc rollout status deployment/backend -n "$NAMESPACE" --timeout=5m &>/dev/null
oc rollout status deployment/frontend -n "$NAMESPACE" --timeout=5m &>/dev/null

echo ""
echo -e "${GREEN}${BOLD}✓ Applications Deployed${NC}\n"
echo -e "${CYAN}Frontend:${NC} https://${FRONTEND_URL}"
echo -e "${CYAN}Backend:${NC}  https://${BACKEND_URL}/docs"
echo ""
