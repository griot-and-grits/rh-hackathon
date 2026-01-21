#!/bin/bash
# Griot & Grits - Run Backend with Hot Reload

set -e

BACKEND_DIR="${BACKEND_DIR:-$HOME/gng-backend}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[*]${NC} $1"; }
print_success() { echo -e "${GREEN}[+]${NC} $1"; }
print_error() { echo -e "${RED}[-]${NC} $1"; }

if [ ! -d "$BACKEND_DIR" ]; then
    print_error "Backend directory not found: $BACKEND_DIR"
    exit 1
fi

cd "$BACKEND_DIR"

# Check for .env
if [ ! -f .env ]; then
    print_error "No .env file found. Run setup.sh first."
    exit 1
fi

print_status "Starting backend server with hot reload..."
echo "  Directory: $BACKEND_DIR"
echo "  URL: http://localhost:8000"
echo "  Docs: http://localhost:8000/docs"
echo ""

# Activate virtual environment and run
if [ -d ".venv" ]; then
    source .venv/bin/activate
    uvicorn app.server:app --reload --host 0.0.0.0 --port 8000
elif command -v uv &> /dev/null; then
    uv run uvicorn app.server:app --reload --host 0.0.0.0 --port 8000
else
    print_error "No virtual environment found. Run setup.sh first."
    exit 1
fi
