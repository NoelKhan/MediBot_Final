#!/bin/bash

# MediBot Kubernetes Deployment Script
# This script helps deploy MediBot to Kubernetes cluster

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="medibot"
KUBECTL="kubectl"

# Functions
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl not found. Please install kubectl."
        exit 1
    fi
    print_success "kubectl is installed"
    
    # Check cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please configure kubectl."
        exit 1
    fi
    print_success "Connected to Kubernetes cluster"
    
    # Check if namespace exists
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        print_info "Namespace '$NAMESPACE' already exists"
    fi
}

create_namespace() {
    print_info "Creating namespace..."
    kubectl apply -f infrastructure/kubernetes/namespace.yaml
    print_success "Namespace created"
}

apply_configmap() {
    print_info "Applying ConfigMap..."
    kubectl apply -f infrastructure/kubernetes/configmap.yaml
    print_success "ConfigMap applied"
}

apply_secrets() {
    print_info "Applying Secrets..."
    echo -e "${YELLOW}⚠️  WARNING: Make sure to update secrets in production!${NC}"
    kubectl apply -f infrastructure/kubernetes/secret.yaml
    print_success "Secrets applied"
}

create_storage() {
    print_info "Creating Persistent Volume Claims..."
    kubectl apply -f infrastructure/kubernetes/pvc.yaml
    print_success "PVCs created"
    
    # Wait for PVCs to be bound
    print_info "Waiting for PVCs to be bound..."
    kubectl wait --for=condition=Bound pvc/medibot-data-pvc -n $NAMESPACE --timeout=60s
    kubectl wait --for=condition=Bound pvc/ollama-data-pvc -n $NAMESPACE --timeout=60s
    print_success "PVCs are bound"
}

deploy_ollama() {
    print_info "Deploying Ollama..."
    kubectl apply -f infrastructure/kubernetes/ollama-deployment.yaml
    print_success "Ollama deployment created"
    
    print_info "Waiting for Ollama pod to be ready (this may take a few minutes)..."
    kubectl wait --for=condition=Ready pod -l app=ollama -n $NAMESPACE --timeout=600s
    print_success "Ollama is ready"
}

deploy_application() {
    print_info "Deploying MediBot application..."
    kubectl apply -f infrastructure/kubernetes/deployment.yaml
    print_success "Application deployment created"
    
    print_info "Waiting for application pods to be ready..."
    kubectl wait --for=condition=Ready pod -l app=medibot -n $NAMESPACE --timeout=300s
    print_success "Application is ready"
}

create_services() {
    print_info "Creating services..."
    kubectl apply -f infrastructure/kubernetes/service.yaml
    print_success "Services created"
}

setup_ingress() {
    print_info "Setting up Ingress..."
    echo -e "${YELLOW}⚠️  Make sure to update the domain name in ingress.yaml${NC}"
    read -p "Do you want to apply Ingress? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl apply -f infrastructure/kubernetes/ingress.yaml
        print_success "Ingress created"
    else
        print_info "Skipping Ingress setup"
    fi
}

setup_autoscaling() {
    print_info "Setting up Horizontal Pod Autoscaler..."
    read -p "Do you want to enable auto-scaling? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl apply -f infrastructure/kubernetes/hpa.yaml
        print_success "HPA created"
    else
        print_info "Skipping HPA setup"
    fi
}

verify_deployment() {
    print_info "Verifying deployment..."
    
    echo ""
    echo "=== Pods ==="
    kubectl get pods -n $NAMESPACE
    
    echo ""
    echo "=== Services ==="
    kubectl get svc -n $NAMESPACE
    
    echo ""
    echo "=== Ingress ==="
    kubectl get ingress -n $NAMESPACE 2>/dev/null || echo "No ingress configured"
    
    echo ""
    print_info "Testing health endpoint..."
    POD_NAME=$(kubectl get pod -n $NAMESPACE -l app=medibot -o jsonpath="{.items[0].metadata.name}")
    if kubectl exec -n $NAMESPACE $POD_NAME -- curl -s http://localhost:8000/health > /dev/null; then
        print_success "Health check passed"
    else
        print_error "Health check failed"
    fi
}

show_access_info() {
    echo ""
    echo "======================================"
    echo "  MediBot Deployment Complete! 🎉"
    echo "======================================"
    echo ""
    
    # Port forward command
    echo "To access the application locally, run:"
    echo "  kubectl port-forward -n $NAMESPACE svc/medibot-service 8000:8000"
    echo "  Then open: http://localhost:8000"
    echo ""
    
    # Ingress info
    if kubectl get ingress -n $NAMESPACE &> /dev/null; then
        INGRESS_HOST=$(kubectl get ingress -n $NAMESPACE -o jsonpath='{.items[0].spec.rules[0].host}')
        echo "Ingress configured at: http://$INGRESS_HOST"
        echo ""
    fi
    
    echo "Useful commands:"
    echo "  View logs:    kubectl logs -n $NAMESPACE -l app=medibot -f"
    echo "  Get pods:     kubectl get pods -n $NAMESPACE"
    echo "  Describe pod: kubectl describe pod -n $NAMESPACE <pod-name>"
    echo ""
}

cleanup() {
    print_info "Cleaning up..."
    read -p "Are you sure you want to delete all MediBot resources? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete namespace $NAMESPACE
        print_success "All resources deleted"
    else
        print_info "Cleanup cancelled"
    fi
}

show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  deploy     - Deploy all resources"
    echo "  cleanup    - Delete all resources"
    echo "  status     - Show deployment status"
    echo "  logs       - Show application logs"
    echo "  help       - Show this help message"
    echo ""
}

show_status() {
    print_info "Deployment Status:"
    echo ""
    kubectl get all -n $NAMESPACE
}

show_logs() {
    print_info "Application Logs (press Ctrl+C to exit):"
    kubectl logs -n $NAMESPACE -l app=medibot --tail=50 -f
}

# Main script
case "${1:-}" in
    deploy)
        check_prerequisites
        create_namespace
        apply_configmap
        apply_secrets
        create_storage
        deploy_ollama
        deploy_application
        create_services
        setup_ingress
        setup_autoscaling
        verify_deployment
        show_access_info
        ;;
    cleanup)
        cleanup
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
