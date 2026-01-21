#!/bin/bash

# Colors for output
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

set -e

# Parse arguments
NAMESPACE=""
BACKEND_DIR=""
FRONTEND_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -b|--backend)
            BACKEND_DIR="$2"
            shift 2
            ;;
        -f|--frontend)
            FRONTEND_DIR="$2"
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
    NAMESPACE=$(oc project -q 2>/dev/null || echo "")
    if [ -z "$NAMESPACE" ]; then
        echo -e "${YELLOW}No namespace specified. Use -n <namespace>${NC}"
        exit 1
    fi
fi

echo -e "${CYAN}${BOLD}=== Code Auto-Sync Watcher ===${NC}"
echo -e "${DIM}Namespace: ${NAMESPACE}${NC}"
echo ""

# Get hackathon root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HACKATHON_DIR="$(dirname "$SCRIPT_DIR")"

# Clone repos if not present
if [ -z "$BACKEND_DIR" ]; then
    BACKEND_DIR="$HACKATHON_DIR/gng-backend"
    if [ ! -d "$BACKEND_DIR" ]; then
        echo -e "${CYAN}Cloning backend repository...${NC}"
        git clone https://github.com/griot-and-grits/gng-backend.git "$BACKEND_DIR"
    fi
fi

if [ -z "$FRONTEND_DIR" ]; then
    FRONTEND_DIR="$HACKATHON_DIR/gng-web"
    if [ ! -d "$FRONTEND_DIR" ]; then
        echo -e "${CYAN}Cloning frontend repository...${NC}"
        git clone https://github.com/griot-and-grits/gng-web.git "$FRONTEND_DIR"
    fi
fi

echo -e "${GREEN}Watching:${NC}"
echo -e "  ${DIM}Backend:  ${BACKEND_DIR}${NC}"
echo -e "  ${DIM}Frontend: ${FRONTEND_DIR}${NC}"
echo ""

# Function to sync backend
sync_backend() {
    BACKEND_POD=$(oc get pod -l app=backend -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$BACKEND_POD" ]; then
        echo -e "${MAGENTA}[$(date +%H:%M:%S)]${NC} Syncing backend..."
        oc rsync "$BACKEND_DIR/" "$BACKEND_POD:/tmp/app" -n "$NAMESPACE" \
            --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' \
            --exclude='node_modules' --exclude='.venv' --no-perms 2>/dev/null
        echo -e "${GREEN}✓${NC} Backend synced"
    else
        echo -e "${YELLOW}⚠${NC} Backend pod not found"
    fi
}

# Function to sync frontend
sync_frontend() {
    FRONTEND_POD=$(oc get pod -l app=frontend -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
    if [ -n "$FRONTEND_POD" ]; then
        echo -e "${MAGENTA}[$(date +%H:%M:%S)]${NC} Syncing frontend..."
        oc rsync "$FRONTEND_DIR/" "$FRONTEND_POD:/tmp/app" -n "$NAMESPACE" \
            --exclude='.git' --exclude='node_modules' --exclude='dist' \
            --exclude='.next' --no-perms 2>/dev/null
        echo -e "${GREEN}✓${NC} Frontend synced"
    else
        echo -e "${YELLOW}⚠${NC} Frontend pod not found"
    fi
}

# Initial sync
echo -e "${CYAN}Performing initial sync...${NC}"
sync_backend
sync_frontend
echo ""

echo -e "${GREEN}${BOLD}🔄 Watching for changes...${NC}"
echo -e "${DIM}Press Ctrl+C to stop${NC}"
echo ""

# Detect OS and use appropriate file watcher
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - use fswatch
    if ! command -v fswatch &> /dev/null; then
        echo -e "${YELLOW}fswatch not found. Installing via Homebrew...${NC}"
        brew install fswatch
    fi

    # Watch both directories
    fswatch -o -r \
        --exclude='\.git' --exclude='__pycache__' --exclude='node_modules' \
        --exclude='\.venv' --exclude='dist' --exclude='\.next' \
        "$BACKEND_DIR" "$FRONTEND_DIR" | while read change; do

        # Determine which directory changed
        if [[ "$change" == *"gng-backend"* ]]; then
            sync_backend
        else
            sync_frontend
        fi
    done
else
    # Linux - use inotifywait
    if ! command -v inotifywait &> /dev/null; then
        echo -e "${YELLOW}inotifywait not found. Install via: sudo apt install inotify-tools${NC}"
        exit 1
    fi

    # Watch both directories
    inotifywait -m -r -e modify,create,delete,move \
        --exclude '(\.git|__pycache__|node_modules|\.venv|dist|\.next)' \
        "$BACKEND_DIR" "$FRONTEND_DIR" | while read path action file; do

        # Determine which directory changed
        if [[ "$path" == *"gng-backend"* ]]; then
            sync_backend
        else
            sync_frontend
        fi

        # Rate limit to avoid hammering on rapid changes
        sleep 1
    done
fi
