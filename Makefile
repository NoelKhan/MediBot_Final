.PHONY: help test build run stop clean validate quick full-test ci-test

# Default target
help:
	@echo "🏥 MediBot Testing Commands"
	@echo "============================"
	@echo ""
	@echo "Quick Tests:"
	@echo "  make validate     - Validate all configs (fastest)"
	@echo "  make quick        - Quick Docker test (~2 min)"
	@echo "  make build        - Build Docker image only"
	@echo "  make run          - Run with Docker Compose"
	@echo ""
	@echo "Advanced Tests:"
	@echo "  make full-test    - Complete test suite"
	@echo "  make ci-test      - Simulate GitHub Actions locally"
	@echo ""
	@echo "Maintenance:"
	@echo "  make stop         - Stop all services"
	@echo "  make clean        - Clean up Docker resources"
	@echo "  make logs         - View service logs"
	@echo ""
	@echo "Kubernetes:"
	@echo "  make k8s-validate - Validate Kubernetes manifests"
	@echo "  make helm-test    - Test Helm chart"
	@echo ""

# Quick validation (no Docker needed)
validate:
	@echo "🔍 Validating configuration..."
	@./validate-before-push.sh

# Quick Docker test
quick:
	@echo "⚡ Running quick Docker test..."
	@./quick-docker-test.sh

# Build Docker image
build:
	@echo "📦 Building Docker image..."
	@docker build -t medibot:local .
	@echo "✅ Build complete!"

# Run with Docker Compose
run:
	@echo "🚀 Starting services with Docker Compose..."
	@mkdir -p data logs
	@docker compose up -d
	@echo "✅ Services started!"
	@echo ""
	@echo "Access points:"
	@echo "  - API: http://localhost:8000"
	@echo "  - Docs: http://localhost:8000/docs"
	@echo "  - Health: http://localhost:8000/health"

# Stop services
stop:
	@echo "🛑 Stopping services..."
	@docker compose down || true
	@docker stop medibot-quick-test 2>/dev/null || true
	@docker rm medibot-quick-test 2>/dev/null || true
	@echo "✅ Services stopped"

# View logs
logs:
	@docker compose logs -f

# Clean up Docker resources
clean:
	@echo "🧹 Cleaning up Docker resources..."
	@docker compose down -v || true
	@docker stop medibot-quick-test 2>/dev/null || true
	@docker rm medibot-quick-test 2>/dev/null || true
	@docker system prune -f
	@echo "✅ Cleanup complete"

# Full test suite
full-test:
	@echo "🎯 Running full test suite..."
	@./test-local.sh

# Test GitHub Actions locally (requires 'act')
ci-test:
	@echo "🔄 Running GitHub Actions locally..."
	@if command -v act >/dev/null 2>&1; then \
		act push -j test; \
	else \
		echo "❌ 'act' is not installed. Install with: brew install act"; \
		exit 1; \
	fi

# Validate Kubernetes manifests
k8s-validate:
	@echo "☸️  Validating Kubernetes manifests..."
	@if command -v kubectl >/dev/null 2>&1; then \
		for file in infrastructure/kubernetes/*.yaml; do \
			echo "Checking $$file..."; \
			kubectl apply --dry-run=client -f "$$file"; \
		done; \
		echo "✅ Kubernetes validation complete"; \
	else \
		echo "❌ kubectl is not installed"; \
		exit 1; \
	fi

# Test Helm chart
helm-test:
	@echo "⛵ Testing Helm chart..."
	@if command -v helm >/dev/null 2>&1; then \
		helm lint infrastructure/helm/ && \
		helm template medibot infrastructure/helm/ > /dev/null && \
		echo "✅ Helm chart is valid"; \
	else \
		echo "❌ helm is not installed. Install with: brew install helm"; \
		exit 1; \
	fi

# Quick pre-push check
pre-push: validate build
	@echo ""
	@echo "✅ Ready to push to GitHub!"
	@echo ""
	@echo "Next steps:"
	@echo "  git add ."
	@echo "  git commit -m 'Your message'"
	@echo "  git push"

# Development workflow
dev: clean build run
	@echo ""
	@echo "✅ Development environment ready!"
	@echo ""
	@echo "Test the API:"
	@echo "  curl http://localhost:8000/health"
	@echo "  open http://localhost:8000/docs"
	@echo ""
	@echo "View logs:"
	@echo "  make logs"
	@echo ""
	@echo "Stop services:"
	@echo "  make stop"
