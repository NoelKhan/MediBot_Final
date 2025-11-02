#!/bin/bash
# Pre-commit validation script
# Run this before pushing to GitHub to ensure CI/CD will pass

set -e

echo "🔍 MediBot Pre-Commit Validation"
echo "================================="
echo ""

ERRORS=0

# Check 1: Dockerfile syntax
echo "1️⃣  Checking Dockerfile..."
if docker build -t medibot:validation-test . --quiet > /dev/null 2>&1; then
    echo "   ✅ Dockerfile builds successfully"
else
    echo "   ❌ Dockerfile has errors"
    ERRORS=$((ERRORS + 1))
fi

# Check 2: Docker Compose syntax
echo "2️⃣  Checking docker-compose.yml..."
if docker-compose config > /dev/null 2>&1 || docker compose config > /dev/null 2>&1; then
    echo "   ✅ docker-compose.yml is valid"
else
    echo "   ❌ docker-compose.yml has errors"
    ERRORS=$((ERRORS + 1))
fi

# Check 3: Python syntax
echo "3️⃣  Checking Python files..."
if python3 -m py_compile *.py 2>/dev/null; then
    echo "   ✅ Python files have valid syntax"
else
    echo "   ⚠️  Some Python files may have issues"
fi

# Check 4: Requirements file
echo "4️⃣  Checking requirements.txt..."
if [ -f requirements.txt ]; then
    echo "   ✅ requirements.txt exists"
else
    echo "   ❌ requirements.txt missing"
    ERRORS=$((ERRORS + 1))
fi

# Check 5: GitHub Actions workflows
echo "5️⃣  Checking GitHub Actions workflows..."
WORKFLOW_ERRORS=0
for workflow in .github/workflows/*.yml; do
    if [ -f "$workflow" ]; then
        # Basic YAML syntax check
        if python3 -c "import yaml; yaml.safe_load(open('$workflow'))" 2>/dev/null; then
            echo "   ✅ $(basename $workflow) is valid YAML"
        else
            echo "   ❌ $(basename $workflow) has YAML errors"
            WORKFLOW_ERRORS=$((WORKFLOW_ERRORS + 1))
        fi
    fi
done

if [ $WORKFLOW_ERRORS -eq 0 ]; then
    echo "   ✅ All GitHub Actions workflows are valid"
else
    ERRORS=$((ERRORS + WORKFLOW_ERRORS))
fi

# Check 6: Kubernetes manifests
if command -v kubectl &> /dev/null; then
    echo "6️⃣  Checking Kubernetes manifests..."
    K8S_ERRORS=0
    for manifest in infrastructure/kubernetes/*.yaml; do
        if kubectl apply --dry-run=client -f "$manifest" > /dev/null 2>&1; then
            echo "   ✅ $(basename $manifest) is valid"
        else
            echo "   ❌ $(basename $manifest) has errors"
            K8S_ERRORS=$((K8S_ERRORS + 1))
        fi
    done
    
    if [ $K8S_ERRORS -gt 0 ]; then
        ERRORS=$((ERRORS + K8S_ERRORS))
    fi
else
    echo "6️⃣  Skipping Kubernetes validation (kubectl not installed)"
fi

# Check 7: Helm chart
if command -v helm &> /dev/null; then
    echo "7️⃣  Checking Helm chart..."
    if helm lint infrastructure/helm/ > /dev/null 2>&1; then
        echo "   ✅ Helm chart is valid"
    else
        echo "   ❌ Helm chart has errors"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "7️⃣  Skipping Helm validation (helm not installed)"
fi

# Summary
echo ""
echo "================================="
if [ $ERRORS -eq 0 ]; then
    echo "✅ All checks passed! Safe to push to GitHub."
    echo ""
    echo "Next steps:"
    echo "  git add ."
    echo "  git commit -m 'Your commit message'"
    echo "  git push"
    exit 0
else
    echo "❌ Found $ERRORS error(s). Please fix before pushing."
    exit 1
fi
