#!/bin/bash
# Griot & Grits - Clean Up Everything
# Removes containers and optionally data volumes

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
echo "  Griot & Grits - Cleanup"
echo "=========================================="
echo ""

# Check for --all flag
REMOVE_VOLUMES=false
if [ "$1" == "--all" ] || [ "$1" == "-a" ]; then
    REMOVE_VOLUMES=true
    print_warning "Will remove data volumes (--all specified)"
    echo ""
fi

# Stop and remove MongoDB
print_status "Removing MongoDB container..."
$RUNTIME stop "$MONGO_CONTAINER" 2>/dev/null || true
$RUNTIME rm "$MONGO_CONTAINER" 2>/dev/null || true
print_success "MongoDB container removed"

# Stop and remove MinIO
print_status "Removing MinIO container..."
$RUNTIME stop "$MINIO_CONTAINER" 2>/dev/null || true
$RUNTIME rm "$MINIO_CONTAINER" 2>/dev/null || true
print_success "MinIO container removed"

# Remove volumes if requested
if [ "$REMOVE_VOLUMES" == true ]; then
    print_status "Removing data volumes..."
    $RUNTIME volume rm gng-mongodb-data 2>/dev/null || true
    $RUNTIME volume rm gng-minio-data 2>/dev/null || true
    print_success "Data volumes removed"
fi

echo ""
print_success "Cleanup complete"
echo ""

if [ "$REMOVE_VOLUMES" == false ]; then
    echo "Data volumes preserved. Use --all to remove them."
fi
echo ""
