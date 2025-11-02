#!/bin/bash
# Quick Docker test - builds and runs MediBot locally
# Perfect for rapid testing before pushing to GitHub

set -e

echo "🚀 Quick Docker Test for MediBot"
echo "================================"
echo ""

# Step 1: Build the image
echo "📦 Building Docker image..."
docker build -t medibot:test .
echo "✓ Build complete!"
echo ""

# Step 2: Run a quick test container
echo "🧪 Starting test container..."
docker run -d \
  --name medibot-quick-test \
  -p 8000:8000 \
  -e DATABASE_URL=sqlite:////app/data/medical_llama.db \
  -e LLM_BASE_URL=http://host.docker.internal:11434 \
  medibot:test

echo "✓ Container started!"
echo ""

# Wait for startup
echo "⏳ Waiting for app to start (10 seconds)..."
sleep 10

# Test the health endpoint
echo "🏥 Testing health endpoint..."
if curl -f http://localhost:8000/health 2>/dev/null; then
    echo ""
    echo "✅ SUCCESS! App is running!"
    echo ""
    echo "Access points:"
    echo "  - API: http://localhost:8000"
    echo "  - Docs: http://localhost:8000/docs"
    echo ""
else
    echo ""
    echo "⚠️  Health check failed - checking logs..."
    docker logs medibot-quick-test
fi

echo ""
echo "Container is running. To stop it, run:"
echo "  docker stop medibot-quick-test && docker rm medibot-quick-test"
echo ""
echo "To view logs:"
echo "  docker logs -f medibot-quick-test"
echo ""
