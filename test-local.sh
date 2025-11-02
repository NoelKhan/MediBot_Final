#!/bin/bash
# Local Testing Script for MediBot CI/CD and Docker Setup
# This script helps test Docker builds, CI/CD workflows, and Kubernetes configs locally

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}MediBot Local Testing Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${YELLOW}>>> $1${NC}"
    echo ""
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check prerequisites
print_section "1. Checking Prerequisites"

check_command() {
    if command -v $1 &> /dev/null; then
        print_success "$1 is installed"
        return 0
    else
        print_error "$1 is NOT installed"
        return 1
    fi
}

check_command docker
check_command docker-compose || check_command "docker compose"
check_command kubectl || echo -e "${YELLOW}⚠ kubectl not installed (optional for K8s testing)${NC}"
check_command helm || echo -e "${YELLOW}⚠ helm not installed (optional for Helm testing)${NC}"

echo ""
echo "Select what you want to test:"
echo "1) Docker build only"
echo "2) Docker Compose (full stack)"
echo "3) Simulate GitHub Actions CI locally"
echo "4) Validate Kubernetes manifests"
echo "5) Test Helm chart"
echo "6) All of the above"
echo ""
read -p "Enter your choice (1-6): " choice

case $choice in
    1|6)
        print_section "2. Testing Docker Build"
        echo "Building Docker image..."
        docker build -t medibot:local-test .
        print_success "Docker build completed successfully"
        
        echo ""
        echo "Image details:"
        docker images medibot:local-test
        ;;
esac

case $choice in
    2|6)
        print_section "3. Testing Docker Compose"
        echo "Starting services with Docker Compose..."
        echo -e "${YELLOW}Note: This will pull Ollama model (~4GB). Press Ctrl+C to cancel, or wait...${NC}"
        sleep 3
        
        # Create necessary directories
        mkdir -p data logs
        
        # Start services in detached mode
        if command -v docker-compose &> /dev/null; then
            docker-compose up -d
        else
            docker compose up -d
        fi
        
        print_success "Docker Compose services started"
        
        echo ""
        echo "Waiting for services to be healthy (60 seconds)..."
        sleep 60
        
        echo ""
        echo "Service status:"
        if command -v docker-compose &> /dev/null; then
            docker-compose ps
        else
            docker compose ps
        fi
        
        echo ""
        echo -e "${GREEN}Services are running!${NC}"
        echo "- MediBot API: http://localhost:8000"
        echo "- Health check: http://localhost:8000/health"
        echo "- API docs: http://localhost:8000/docs"
        echo "- Ollama: http://localhost:11434"
        
        echo ""
        read -p "Press Enter to stop services or Ctrl+C to keep them running..."
        
        if command -v docker-compose &> /dev/null; then
            docker-compose down
        else
            docker compose down
        fi
        print_success "Services stopped"
        ;;
esac

case $choice in
    3|6)
        print_section "4. Simulating GitHub Actions CI Locally"
        
        if ! command -v act &> /dev/null; then
            print_error "act is not installed"
            echo "Install with: brew install act"
            echo "Then run: act -l to list workflows"
        else
            echo "Listing available workflows:"
            act -l
            
            echo ""
            echo "Running CI workflow (test job only)..."
            echo -e "${YELLOW}This simulates what GitHub Actions will do${NC}"
            
            # Run just the test job
            act push -j test --container-architecture linux/amd64
            
            print_success "CI simulation completed"
        fi
        ;;
esac

case $choice in
    4|6)
        print_section "5. Validating Kubernetes Manifests"
        
        if ! command -v kubectl &> /dev/null; then
            print_error "kubectl is not installed"
        else
            echo "Validating Kubernetes YAML files..."
            
            for file in infrastructure/kubernetes/*.yaml; do
                echo "Checking $file..."
                kubectl apply --dry-run=client -f "$file" && print_success "$(basename $file) is valid" || print_error "$(basename $file) has issues"
            done
            
            print_success "Kubernetes manifest validation completed"
        fi
        ;;
esac

case $choice in
    5|6)
        print_section "6. Testing Helm Chart"
        
        if ! command -v helm &> /dev/null; then
            print_error "helm is not installed"
        else
            echo "Linting Helm chart..."
            helm lint infrastructure/helm/ && print_success "Helm chart is valid" || print_error "Helm chart has issues"
            
            echo ""
            echo "Rendering Helm templates (dry-run)..."
            helm template medibot infrastructure/helm/ --debug > /tmp/medibot-helm-output.yaml
            print_success "Helm templates rendered to /tmp/medibot-helm-output.yaml"
            
            echo ""
            echo "Preview of rendered resources:"
            grep "^kind:" /tmp/medibot-helm-output.yaml | sort | uniq -c
        fi
        ;;
esac

print_section "Testing Complete!"
echo ""
echo -e "${GREEN}All selected tests have completed!${NC}"
echo ""
echo "Next steps:"
echo "1. Push to GitHub to trigger actual CI/CD pipeline"
echo "2. Check GitHub Actions tab for build status"
echo "3. Docker images will be pushed to ghcr.io"
echo ""
echo "Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Rebuild: docker-compose up --build"
echo "  - Clean up: docker system prune -a"
echo ""
