# 🚀 Quick Testing Guide for MediBot CI/CD

## Prerequisites Setup

### 1. Start Docker Desktop
```bash
# Make sure Docker Desktop is running
open -a Docker
# Wait ~30 seconds for Docker to start
```

### 2. Verify Docker is Running
```bash
docker ps
# Should show running containers (or empty list if none running)
```

## Quick Tests (Choose Your Speed)

### ⚡ Super Quick Test (2 minutes)
Just validate configuration files without building:

```bash
./validate-before-push.sh
```

### 🏃 Fast Test (5 minutes)
Build Docker image and test basic functionality:

```bash
./quick-docker-test.sh
```

After it runs, test the API:
```bash
curl http://localhost:8000/health
curl http://localhost:8000/docs
```

Stop the test container:
```bash
docker stop medibot-quick-test && docker rm medibot-quick-test
```

### 🔄 Full Stack Test (10-15 minutes)
Test everything with Docker Compose (includes Ollama ~4GB):

```bash
./test-local.sh
# Choose option 2 (Docker Compose)
```

### 🎯 Interactive Test Suite
Full testing menu with all options:

```bash
./test-local.sh
# Choose option 6 (All tests)
```

## Test GitHub Actions Locally

### Install `act` (GitHub Actions runner)
```bash
brew install act
```

### Run CI tests locally
```bash
# List available workflows
act -l

# Run just the test job
act push -j test

# Run full CI pipeline
act push
```

## Manual Docker Commands

### Build the image
```bash
docker build -t medibot:local .
```

### Run the container
```bash
docker run -d \
  --name medibot-test \
  -p 8000:8000 \
  -e DATABASE_URL=sqlite:////app/data/medical_llama.db \
  medibot:local
```

### View logs
```bash
docker logs -f medibot-test
```

### Stop and remove
```bash
docker stop medibot-test && docker rm medibot-test
```

## Docker Compose Commands

### Start all services
```bash
docker compose up -d
```

### View logs
```bash
docker compose logs -f
```

### Stop all services
```bash
docker compose down
```

### Rebuild and restart
```bash
docker compose up --build -d
```

## Validate Kubernetes Manifests

```bash
# Validate all K8s files
for file in infrastructure/kubernetes/*.yaml; do
  kubectl apply --dry-run=client -f $file
done
```

## Test Helm Chart

```bash
# Lint the chart
helm lint infrastructure/helm/

# Render templates
helm template medibot infrastructure/helm/

# Do a dry-run install
helm install medibot infrastructure/helm/ --dry-run --debug
```

## Troubleshooting

### Docker not running
```bash
# Start Docker Desktop
open -a Docker
# Or restart it
killall Docker && open -a Docker
```

### Port already in use
```bash
# Find what's using port 8000
lsof -ti:8000

# Kill the process
kill -9 $(lsof -ti:8000)
```

### Clean up Docker
```bash
# Remove all stopped containers
docker container prune -f

# Remove unused images
docker image prune -a -f

# Remove everything (careful!)
docker system prune -a --volumes -f
```

### Reset everything
```bash
# Stop all containers
docker compose down
docker stop $(docker ps -aq) 2>/dev/null

# Remove test containers
docker rm medibot-quick-test medibot-test 2>/dev/null

# Clean up
docker system prune -f
```

## What Gets Tested

### ✅ Docker Build
- Multi-stage build optimization
- Python dependencies
- Health check configuration
- Port exposure

### ✅ Docker Compose
- Service orchestration
- Networking between services
- Volume mounting
- Environment variables
- Ollama LLM integration

### ✅ CI/CD Pipeline (with act)
- Python setup
- Dependency installation
- Code formatting (black, isort)
- Linting (flake8)
- Tests (pytest)
- Docker image build
- Container registry push (simulated)

### ✅ Kubernetes
- Manifest syntax
- Resource definitions
- ConfigMaps and Secrets
- Services and Ingress
- HPA and PVC

### ✅ Helm
- Chart structure
- Template rendering
- Values validation

## Quick Reference

| What to Test | Command | Time |
|-------------|---------|------|
| Just validation | `./validate-before-push.sh` | 30s |
| Quick Docker test | `./quick-docker-test.sh` | 2min |
| Full stack | `./test-local.sh` → option 2 | 10min |
| GitHub Actions | `act push -j test` | 5min |
| Everything | `./test-local.sh` → option 6 | 15min |

## Before Pushing to GitHub

1. ✅ Start Docker Desktop
2. ✅ Run `./validate-before-push.sh`
3. ✅ Run `./quick-docker-test.sh`
4. ✅ Fix any errors
5. ✅ Commit and push

```bash
git add .
git commit -m "Your commit message"
git push
```

## Monitor GitHub Actions

After pushing, monitor your workflows:
```
https://github.com/yathanshnagar/MediBot_Final/actions
```

## Tips

- **Fast iteration**: Use `quick-docker-test.sh` for rapid testing
- **Full validation**: Use `test-local.sh` before important pushes
- **Debug builds**: Add `--progress=plain` to docker build commands
- **Watch logs**: Use `-f` flag with docker logs or docker compose logs
- **Clean often**: Run `docker system prune -f` to free up space
