# GitHub Actions Runner Strategy

## Overview

All workflows in this project are configured to **prefer self-hosted runners** with GitHub-hosted runners (ubuntu-latest) as fallback. This approach provides:

- ✅ **Cost Optimization** - Reduced GitHub Actions minutes usage
- ✅ **Better Performance** - Direct access to internal resources
- ✅ **Kubernetes Access** - Direct kubectl access without additional configuration
- ✅ **Reliability** - Fallback to GitHub-hosted runners if self-hosted unavailable

## Runner Configuration

### Primary Strategy (All Workflows)

```yaml
runs-on: [self-hosted, ubuntu-latest]
```

**How it works:**
1. GitHub Actions tries to find a **self-hosted** runner first
2. If no self-hosted runner is available, it falls back to **ubuntu-latest**
3. This ensures workflows always run, even without self-hosted infrastructure

### Deploy Job (Kubernetes-specific)

```yaml
runs-on: self-hosted  # Required for kubectl access
```

The deploy job uses **only self-hosted** runners because:
- Direct Kubernetes cluster access required
- Pre-configured kubectl context
- Security: No kubeconfig secrets needed in GitHub

## Workflows Overview

| Workflow | Runner Strategy | Purpose |
|----------|----------------|---------|
| **ci-cd.yml** | Self-hosted + fallback | Main CI/CD pipeline |
| **self-hosted-build.yml** | Self-hosted only | Manual builds with cluster access |
| **manual-deploy.yml** | Self-hosted only | Manual deployments |

## Setting Up Self-Hosted Runner

### Quick Setup

1. **Navigate to Repository Settings**
   ```
   https://github.com/NoelKhan/MediBot_Final/settings/actions/runners/new
   ```

2. **Choose Platform**
   - Linux (recommended)
   - macOS
   - Windows

3. **Download and Configure**
   ```bash
   # Create a folder
   mkdir actions-runner && cd actions-runner
   
   # Download the latest runner package
   curl -o actions-runner-linux-x64-2.311.0.tar.gz -L \
     https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
   
   # Extract the installer
   tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz
   
   # Configure
   ./config.sh --url https://github.com/NoelKhan/MediBot_Final --token YOUR_TOKEN
   
   # Run as service
   sudo ./svc.sh install
   sudo ./svc.sh start
   ```

### Docker-based Self-Hosted Runner

```bash
# Using Docker to run the self-hosted runner
docker run -d --restart unless-stopped \
  --name github-runner \
  -e REPO_URL="https://github.com/NoelKhan/MediBot_Final" \
  -e RUNNER_TOKEN="YOUR_TOKEN" \
  -e RUNNER_NAME="docker-runner" \
  -e RUNNER_WORKDIR="/tmp/github-runner" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /tmp/github-runner:/tmp/github-runner \
  myoung34/github-runner:latest
```

### Kubernetes-based Runner (Recommended for Production)

```yaml
# Install actions-runner-controller
helm repo add actions-runner-controller \
  https://actions-runner-controller.github.io/actions-runner-controller

helm upgrade --install --namespace actions-runner-system \
  --create-namespace --wait actions-runner-controller \
  actions-runner-controller/actions-runner-controller

# Deploy runner
kubectl apply -f - <<EOF
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: medibot-runner
spec:
  replicas: 2
  template:
    spec:
      repository: NoelKhan/MediBot_Final
      labels:
        - self-hosted
      dockerdWithinRunnerContainer: true
EOF
```

## Benefits by Workflow Stage

### Test Stage
- **Self-hosted**: Faster with cached dependencies
- **Fallback**: Always runs even without self-hosted runner
- **Cost**: Free when using self-hosted

### Build Stage
- **Self-hosted**: Local Docker cache speeds up builds
- **Fallback**: Ensures builds complete
- **Performance**: 2-3x faster with cache

### Security Stage
- **Self-hosted**: Can use internal security tools
- **Fallback**: Uses GitHub's infrastructure
- **Coverage**: Always scans, regardless of runner

### Deploy Stage
- **Self-hosted only**: Direct cluster access
- **Security**: No kubeconfig in GitHub secrets
- **Speed**: Instant deployment

## Monitoring Runners

### Check Runner Status
```bash
# View runners in GitHub
https://github.com/NoelKhan/MediBot_Final/settings/actions/runners

# Check runner logs (on runner machine)
journalctl -u actions.runner.* -f
```

### Runner Health Checks
```bash
# On the runner machine
./run.sh --check

# View runner status
sudo ./svc.sh status
```

## Troubleshooting

### Runner Not Picking Up Jobs

**Problem**: Workflow runs on ubuntu-latest instead of self-hosted

**Solutions**:
1. Check runner is online: Settings → Actions → Runners
2. Verify runner labels match `self-hosted`
3. Check runner logs for errors
4. Restart runner service:
   ```bash
   sudo ./svc.sh stop
   sudo ./svc.sh start
   ```

### Deploy Job Fails

**Problem**: Deploy job needs self-hosted runner

**Solutions**:
1. Ensure at least one self-hosted runner is online
2. Runner must have kubectl configured
3. Runner needs cluster access:
   ```bash
   # Test kubectl access
   kubectl get nodes
   kubectl get namespaces
   ```

### Performance Issues

**Problem**: Builds slow on self-hosted runner

**Solutions**:
1. Enable Docker layer caching
2. Increase runner resources (CPU/RAM)
3. Use multiple runners for parallel jobs
4. Pre-pull common images:
   ```bash
   docker pull python:3.11-slim
   docker pull node:18-alpine
   ```

## Best Practices

### 1. Runner Maintenance
```bash
# Update runner
cd actions-runner
./config.sh remove --token YOUR_TOKEN
# Download new version
./config.sh --url https://github.com/NoelKhan/MediBot_Final --token YOUR_TOKEN
sudo ./svc.sh install
sudo ./svc.sh start
```

### 2. Security
- Run runners in isolated environments
- Use dedicated service accounts
- Restrict network access
- Regularly update runner version
- Monitor runner activity

### 3. Scaling
- Use multiple runners for parallel jobs
- Configure auto-scaling with Kubernetes
- Set appropriate timeout values
- Monitor resource usage

### 4. Cost Optimization
- Self-hosted runners = **$0** GitHub Actions minutes
- GitHub-hosted as fallback ensures reliability
- Deploy stage uses self-hosted only = maximum savings

## Migration from GitHub-Hosted Only

If you want to **temporarily disable self-hosted** and use only GitHub-hosted:

```yaml
# Change in all workflows
runs-on: ubuntu-latest  # Remove array notation
```

If you want to **require self-hosted only**:

```yaml
# Use for critical jobs
runs-on: self-hosted  # No fallback
```

## Current Configuration Summary

✅ **All workflows prefer self-hosted runners**
✅ **Automatic fallback to ubuntu-latest**
✅ **Deploy job requires self-hosted** (for kubectl access)
✅ **No workflow will fail due to runner unavailability**

## Next Steps

1. Set up at least one self-hosted runner
2. Configure kubectl on the runner for deployments
3. Monitor runner usage in Actions tab
4. Scale runners based on workload

For detailed setup instructions, see: [SELF_HOSTED_RUNNER.md](../infrastructure/SELF_HOSTED_RUNNER.md)
