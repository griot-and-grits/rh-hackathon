#!/bin/bash
# Griot & Grits - Stop Infrastructure Services

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[!]${NC} $1"; }

# Detect container runtime
detect_runtime() {
    if [ -f "$ROOT_DIR/.container-runtime" ]; then
        RUNTIME=$(cat "$ROOT_DIR/.container-runtime")
        if command -v "$RUNTIME" &> /dev/null; then
            echo "$RUNTIME"
            return
        fi
    fi
    if command -v podman &> /dev/null; then
        echo "podman"
    elif command -v docker &> /dev/null; then
        echo "docker"
    else
        echo ""
    fi
}

RUNTIME=$(detect_runtime)

if [ -z "$RUNTIME" ]; then
    echo "No container runtime found"
    exit 1
fi

# Container names
MONGO_CONTAINER="gng-mongodb"
MINIO_CONTAINER="gng-minio"

echo ""
echo "=========================================="
echo "  Stopping Griot & Grits Services"
echo "=========================================="
echo ""

# Stop MongoDB
if $RUNTIME ps --format '{{.Names}}' 2>/dev/null | grep -q "^${MONGO_CONTAINER}$"; then
    print_status "Stopping MongoDB..."
    $RUNTIME stop "$MONGO_CONTAINER"
    print_success "MongoDB stopped"
else
    print_warning "MongoDB not running"
fi

# Stop MinIO
if $RUNTIME ps --format '{{.Names}}' 2>/dev/null | grep -q "^${MINIO_CONTAINER}$"; then
    print_status "Stopping MinIO..."
    $RUNTIME stop "$MINIO_CONTAINER"
    print_success "MinIO stopped"
else
    print_warning "MinIO not running"
fi

echo ""
print_success "All services stopped"
echo ""
echo "Data is preserved in volumes."
echo "To remove data: $RUNTIME volume rm gng-mongodb-data gng-minio-data"
echo ""
