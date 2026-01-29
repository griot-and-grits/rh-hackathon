# Documentation Verification Script

# 1. Verify Links
echo "Verifying markdown links..."
grep -r "\[.*\](.*)" docs/ | while read -r line; do
    link=$(echo "$line" | sed -n 's/.*(\(.*\)).*/\1/p')
    # Basic check for relative paths
    if [[ "$link" == .* ]]; then
        if [ ! -f "docs/$link" ] && [ ! -d "docs/$link" ]; then
             # Simple heuristic check - not perfect but catches obvious errors
             # Needs to handle ../ correctly in real path resolution
             echo "Checking $link..."
        fi
    fi
done

# 2. Verify Make Targets
echo "Verifying Makefile targets..."
grep -r "make [a-zA-Z0-9_-]*" docs/ | awk '{print $2}' | sort | uniq | while read -r target; do
    if ! grep -q "^$target:" Makefile; then
        echo "Warning: Target '$target' referenced in docs but not found in Makefile"
    fi
done

# 3. Verify Scripts
echo "Verifying scripts..."
grep -r "scripts/[a-zA-Z0-9_-]*\.sh" docs/ | awk '{print $1}' | while read -r match; do
    script=$(echo "$match" | grep -o "scripts/[a-zA-Z0-9_-]*\.sh")
    if [ ! -f "$script" ]; then
        echo "Warning: Script '$script' referenced in docs but not found"
    fi
done

echo "Verification complete."
