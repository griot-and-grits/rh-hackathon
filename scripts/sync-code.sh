#!/bin/bash

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Parse arguments
NAMESPACE=""
BACKEND_DIR=""
FRONTEND_DIR=""
SYNC_BACKEND=false
SYNC_FRONTEND=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -n, --namespace NAME    Target namespace (default: auto-detect)"
    echo "  -b, --backend           Sync backend only"
    echo "  -f, --frontend          Sync frontend only"
    echo "  --backend-dir PATH      Backend directory (default: ../gng-backend)"
    echo "  --frontend-dir PATH     Frontend directory (default: ../gng-web)"
    echo "  -h, --help              Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                      # Sync both backend and frontend"
    echo "  $0 -b                   # Sync backend only"
    echo "  $0 -f -n gng-user1      # Sync frontend to specific namespace"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -b|--backend)
            SYNC_BACKEND=true
            shift
            ;;
        -f|--frontend)
            SYNC_FRONTEND=true
            shift
            ;;
        --backend-dir)
            BACKEND_DIR="$2"
            shift 2
            ;;
        --frontend-dir)
            FRONTEND_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

# Auto-detect namespace
if [ -z "$NAMESPACE" ]; then
    NAMESPACE=$(oc project -q 2>/dev/null || echo "")
    if [ -z "$NAMESPACE" ]; then
        echo -e "${RED}Error: No namespace specified and cannot detect current project${NC}"
        echo "Use: $0 -n <namespace>"
        exit 1
    fi
fi

# Default directories
if [ -z "$BACKEND_DIR" ]; then
    BACKEND_DIR="$ROOT_DIR/gng-backend"
fi

if [ -z "$FRONTEND_DIR" ]; then
    FRONTEND_DIR="$ROOT_DIR/gng-web"
fi

# If neither specified, sync both
if [ "$SYNC_BACKEND" = false ] && [ "$SYNC_FRONTEND" = false ]; then
    SYNC_BACKEND=true
    SYNC_FRONTEND=true
fi

echo -e "${CYAN}${BOLD}=== Syncing Code to OpenShift ===${NC}"
echo -e "${CYAN}Namespace:${NC} $NAMESPACE"
echo ""

# Sync backend
if [ "$SYNC_BACKEND" = true ]; then
    if [ ! -d "$BACKEND_DIR" ]; then
        echo -e "${YELLOW}⚠ Backend directory not found: $BACKEND_DIR${NC}"
    else
        BACKEND_POD=$(oc get pod -l app=backend -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

        if [ -z "$BACKEND_POD" ]; then
            echo -e "${RED}✗ Backend pod not found${NC}"
        else
            echo -e "${CYAN}Syncing backend...${NC}"
            if oc rsync "$BACKEND_DIR/" "$BACKEND_POD:/tmp/app" -n "$NAMESPACE" \
                --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' \
                --exclude='node_modules' --exclude='.venv' --no-perms 2>/dev/null; then
                echo -e "${GREEN}✓ Backend synced${NC}"
            else
                echo -e "${RED}✗ Backend sync failed${NC}"
            fi
        fi
    fi
fi

# Sync frontend
if [ "$SYNC_FRONTEND" = true ]; then
    if [ ! -d "$FRONTEND_DIR" ]; then
        echo -e "${YELLOW}⚠ Frontend directory not found: $FRONTEND_DIR${NC}"
    else
        FRONTEND_POD=$(oc get pod -l app=frontend -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

        if [ -z "$FRONTEND_POD" ]; then
            echo -e "${RED}✗ Frontend pod not found${NC}"
        else
            echo -e "${CYAN}Syncing frontend...${NC}"
            if oc rsync "$FRONTEND_DIR/" "$FRONTEND_POD:/tmp/app" -n "$NAMESPACE" \
                --exclude='.git' --exclude='node_modules' --exclude='dist' \
                --exclude='.next' --no-perms 2>/dev/null; then
                echo -e "${GREEN}✓ Frontend synced${NC}"
            else
                echo -e "${RED}✗ Frontend sync failed${NC}"
            fi
        fi
    fi
fi

echo ""
echo -e "${GREEN}${BOLD}Done!${NC}"
echo -e "${CYAN}Hot-reload will detect changes automatically.${NC}"
echo ""
