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
oc apply -f "$INFRA_DIR/backend/openshift/backend-config.yaml" -n "$NAMESPACE"
oc apply -f "$INFRA_DIR/backend/openshift/backend.yaml" -n "$NAMESPACE"

# Wait for backend route to be created
echo -e "${DIM}Waiting for backend route...${NC}"
sleep 3

# Get backend URL
BACKEND_URL=$(oc get route backend -n "$NAMESPACE" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
if [ -z "$BACKEND_URL" ]; then
    echo -e "${YELLOW}Warning: Could not get backend route, using placeholder${NC}"
    BACKEND_URL="backend-${NAMESPACE}.apps.cluster.local"
fi

echo -e "${GREEN}Backend URL: https://${BACKEND_URL}${NC}"

# Update frontend manifest with backend URL
FRONTEND_MANIFEST="$INFRA_DIR/frontend/openshift/frontend.yaml"
TEMP_FRONTEND="/tmp/frontend-${NAMESPACE}.yaml"

# Replace placeholder values in frontend manifest
sed "s|VITE_API_URL.*|VITE_API_URL: \"https://${BACKEND_URL}\"|g" "$FRONTEND_MANIFEST" > "$TEMP_FRONTEND"

# Deploy Frontend
echo ""
echo -e "${CYAN}Deploying frontend...${NC}"
oc apply -f "$TEMP_FRONTEND" -n "$NAMESPACE"
rm -f "$TEMP_FRONTEND"

# Wait for pods to be ready
echo ""
echo -e "${CYAN}Waiting for deployments to be ready...${NC}"
oc rollout status deployment/backend -n "$NAMESPACE" --timeout=5m
oc rollout status deployment/frontend -n "$NAMESPACE" --timeout=5m

# Get frontend URL
FRONTEND_URL=$(oc get route frontend -n "$NAMESPACE" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")

echo ""
echo -e "${GREEN}${BOLD}=== Deployment Complete ===${NC}"
echo ""
echo -e "${BOLD}Access your application:${NC}"
echo -e "  ${CYAN}Frontend:${NC} https://${FRONTEND_URL}"
echo -e "  ${CYAN}Backend:${NC}  https://${BACKEND_URL}"
echo ""
echo -e "${DIM}Hot-reload is enabled for both frontend and backend.${NC}"
echo -e "${DIM}Code changes will be automatically detected and reloaded.${NC}"
echo ""
echo -e "${YELLOW}${BOLD}To update code:${NC}"
echo -e "  ${DIM}# Get the pod name${NC}"
echo -e "  oc get pods -n $NAMESPACE"
echo ""
echo -e "  ${DIM}# Sync your local changes to the pod${NC}"
echo -e "  oc rsync ./local-backend-code/ backend-pod-name:/code -n $NAMESPACE"
echo -e "  oc rsync ./local-frontend-code/ frontend-pod-name:/code -n $NAMESPACE"
echo ""
