#!/bin/bash

# Admin script to pre-create namespaces for hackathon participants
# This should be run ONCE by cluster admin before the hackathon

set -e

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# Usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -f, --file FILE        File with one username per line"
    echo "  -n, --numbered COUNT   Create numbered users (user1, user2, ..., userN)"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --file users.txt                # Create from username list"
    echo "  $0 --numbered 60                   # Create gng-user1 through gng-user60"
}

# Parse arguments
MODE=""
FILE=""
COUNT=0

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            MODE="file"
            FILE="$2"
            shift 2
            ;;
        -n|--numbered)
            MODE="numbered"
            COUNT="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

echo -e "${CYAN}${BOLD}=== Griot & Grits - Create User Namespaces ===${NC}"
echo ""

# Check if user is cluster admin
if ! oc auth can-i create namespaces &>/dev/null; then
    echo -e "${RED}Error: You need permissions to create namespaces${NC}"
    exit 1
fi

# Validate input
if [ -z "$MODE" ]; then
    echo -e "${RED}Error: Must specify --file or --numbered${NC}"
    show_usage
    exit 1
fi

if [ "$MODE" = "file" ] && [ ! -f "$FILE" ]; then
    echo -e "${RED}Error: File not found: $FILE${NC}"
    exit 1
fi

if [ "$MODE" = "numbered" ] && [ "$COUNT" -le 0 ]; then
    echo -e "${RED}Error: Count must be > 0${NC}"
    exit 1
fi

# Create namespaces function
create_namespace() {
    local username=$1
    local namespace="gng-${username}"

    echo -n "  Creating $namespace for $username... "

    # Create namespace (or verify it exists)
    local created=false
    if oc new-project "$namespace" --display-name="Griot & Grits - $username" &>/dev/null; then
        created=true
    elif oc get namespace "$namespace" &>/dev/null; then
        # Namespace already exists, that's OK
        created=true
    else
        echo -e "${YELLOW}⚠ Failed to create${NC}"
        return 1
    fi

    # Label for cleanup (skip if already labeled)
    oc label namespace "$namespace" app=griot-grits-hackathon --overwrite &>/dev/null

    # Grant user admin access (or update if already exists)
    if oc adm policy add-role-to-user admin "$username" -n "$namespace" &>/dev/null; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ Failed to grant access${NC}"
        return 1
    fi
}

# Create from file
if [ "$MODE" = "file" ]; then
    echo -e "${CYAN}Creating namespaces from file: $FILE${NC}"
    echo ""

    TOTAL=$(wc -l < "$FILE")
    CREATED=0
    FAILED=0

    while read username; do
        # Skip empty lines and comments
        [[ -z "$username" || "$username" =~ ^# ]] && continue

        if create_namespace "$username"; then
            ((CREATED++))
        else
            ((FAILED++))
        fi
    done < "$FILE"

    echo ""
    echo -e "${GREEN}${BOLD}✓ Complete${NC}"
    echo "  Created: $CREATED"
    echo "  Failed:  $FAILED"
fi

# Create numbered users
if [ "$MODE" = "numbered" ]; then
    echo -e "${CYAN}Creating $COUNT numbered namespaces${NC}"
    echo ""

    CREATED=0
    FAILED=0

    for i in $(seq 1 "$COUNT"); do
        username="user$i"

        if create_namespace "$username"; then
            ((CREATED++))
        else
            ((FAILED++))
        fi
    done

    echo ""
    echo -e "${GREEN}${BOLD}✓ Complete${NC}"
    echo "  Created: $CREATED"
    echo "  Failed:  $FAILED"
fi

echo ""
echo "To verify:"
echo -e "  ${CYAN}oc get namespaces -l app=griot-grits-hackathon${NC}"
echo -e "  ${CYAN}oc get rolebindings -A | grep admin | grep gng-${NC}"
echo ""
echo "To delete all:"
echo -e "  ${CYAN}oc delete namespace -l app=griot-grits-hackathon${NC}"
echo ""
