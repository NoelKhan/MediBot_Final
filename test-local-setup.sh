#!/bin/bash

# MediBot Local Testing Script
# Run this to verify your local setup before deployment

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=================================="
echo "  MediBot Local Testing Suite"
echo "=================================="
echo ""

# Function to print status
print_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        exit 1
    fi
}

# 1. Check Python version
echo "1. Checking Python version..."
python3 --version | grep -q "Python 3" && print_status "Python 3 is installed"

# 2. Check if required files exist
echo ""
echo "2. Checking required files..."
required_files=(
    "main.py"
    "config.py"
    "database.py"
    "workflow.py"
    "llm_wrapper.py"
    "requirements.txt"
    "Dockerfile"
    "docker-compose.yml"
    "auth.html"
    "chat_ui.html"
    "dashboard.html"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} Found: $file"
    else
        echo -e "${RED}✗${NC} Missing: $file"
        exit 1
    fi
done

# 3. Check Python dependencies
echo ""
echo "3. Checking Python dependencies..."
if python3 -c "import fastapi, uvicorn, sqlalchemy, langchain" 2>/dev/null; then
    print_status "Core dependencies installed"
else
    echo -e "${YELLOW}⚠${NC} Some dependencies missing. Run: pip install -r requirements.txt"
fi

# 4. Check Docker
echo ""
echo "4. Checking Docker..."
if command -v docker &> /dev/null; then
    docker --version
    print_status "Docker is installed"
else
    echo -e "${YELLOW}⚠${NC} Docker not found. Install from: https://www.docker.com/products/docker-desktop"
fi

# 5. Check Docker Compose
echo ""
echo "5. Checking Docker Compose..."
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    print_status "Docker Compose is available"
else
    echo -e "${YELLOW}⚠${NC} Docker Compose not found"
fi

# 6. Validate docker-compose.yml
echo ""
echo "6. Validating docker-compose.yml..."
if docker compose config > /dev/null 2>&1 || docker-compose config > /dev/null 2>&1; then
    print_status "docker-compose.yml is valid"
else
    echo -e "${RED}✗${NC} docker-compose.yml has errors"
    exit 1
fi

# 7. Test Dockerfile
echo ""
echo "7. Testing Dockerfile syntax..."
if docker build --no-cache -f Dockerfile -t medibot-test:latest . > /dev/null 2>&1; then
    print_status "Dockerfile builds successfully"
else
    echo -e "${RED}✗${NC} Dockerfile has build errors"
    exit 1
fi

# 8. Check infrastructure files
echo ""
echo "8. Checking infrastructure files..."
if [ -d "infrastructure" ]; then
    k8s_files=(
        "infrastructure/kubernetes/namespace.yaml"
        "infrastructure/kubernetes/deployment.yaml"
        "infrastructure/kubernetes/service.yaml"
    )
    
    all_exist=true
    for file in "${k8s_files[@]}"; do
        if [ ! -f "$file" ]; then
            all_exist=false
            break
        fi
    done
    
    if [ "$all_exist" = true ]; then
        print_status "Kubernetes manifests found"
    else
        echo -e "${YELLOW}⚠${NC} Some Kubernetes files missing (optional)"
    fi
else
    echo -e "${YELLOW}⚠${NC} Infrastructure directory not found (optional)"
fi

# 9. Check for database
echo ""
echo "9. Checking database..."
if [ -f "medical_llama.db" ]; then
    echo -e "${GREEN}✓${NC} Database file exists"
else
    echo -e "${YELLOW}⚠${NC} Database not found. Run: python seed_data.py"
fi

# 10. Summary
echo ""
echo "=================================="
echo "  Test Summary"
echo "=================================="
echo ""
echo -e "${GREEN}✓ All critical checks passed!${NC}"
echo ""
echo "Next steps:"
echo "  1. Start Ollama: ollama serve"
echo "  2. Pull model: ollama pull mistral:7b-instruct"
echo "  3. Start app:"
echo "     • Local: python main.py"
echo "     • Docker: docker-compose up"
echo ""
echo "  4. Access: http://localhost:8000"
echo ""
