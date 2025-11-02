# Setting Up GitHub Self-Hosted Runner

This guide explains how to set up a self-hosted GitHub Actions runner for building and deploying MediBot.

## Why Self-Hosted Runners?

Self-hosted runners offer several advantages:
- **Faster builds:** Direct access to your infrastructure
- **Custom environment:** Pre-installed tools and dependencies
- **Cost savings:** No GitHub Actions minutes consumed
- **Direct kubectl access:** Deploy to Kubernetes without complex authentication
- **Better caching:** Persistent Docker layer caching

## Prerequisites

- Linux/macOS/Windows machine with:
  - Docker installed
  - kubectl configured for your cluster
  - Sufficient resources (4GB RAM, 2 CPUs minimum)
  - Network access to GitHub and your Kubernetes cluster

## Installation Steps

### 1. Prepare the Machine

#### Ubuntu/Debian
```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Logout and login to apply group changes
```

#### macOS
```bash
# Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop

# Install kubectl
brew install kubectl
```

### 2. Create Runner Directory

```bash
# Create a directory for the runner
mkdir ~/actions-runner && cd ~/actions-runner
```

### 3. Download GitHub Actions Runner

Navigate to your repository on GitHub:
```
https://github.com/yathanshnagar/MediBot_Final/settings/actions/runners/new
```

Or use these commands:

#### For Linux x64
```bash
# Download
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz

# Extract
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz
```

#### For macOS
```bash
# Download
curl -o actions-runner-osx-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-osx-x64-2.311.0.tar.gz

# Extract
tar xzf ./actions-runner-osx-x64-2.311.0.tar.gz
```

### 4. Configure the Runner

```bash
# Get your token from GitHub:
# Settings → Actions → Runners → New self-hosted runner

# Configure
./config.sh \
  --url https://github.com/yathanshnagar/MediBot_Final \
  --token YOUR_RUNNER_TOKEN \
  --name medibot-runner \
  --labels medibot,docker,kubernetes \
  --work _work
```

Configuration prompts:
- **Runner group:** Default (press Enter)
- **Runner name:** medibot-runner (or custom name)
- **Runner labels:** medibot,docker,kubernetes
- **Work folder:** _work (press Enter)

### 5. Install as a Service (Recommended)

#### Linux (systemd)
```bash
# Install the service
sudo ./svc.sh install

# Start the service
sudo ./svc.sh start

# Check status
sudo ./svc.sh status

# Enable auto-start on boot
sudo systemctl enable actions.runner.yathanshnagar-MediBot_Final.medibot-runner.service
```

#### macOS (launchd)
```bash
# Install the service
./svc.sh install

# Start the service
./svc.sh start

# Check status
./svc.sh status
```

### 6. Configure kubectl Access

Ensure the runner can access your Kubernetes cluster:

```bash
# Copy your kubeconfig
mkdir -p ~/.kube
cp /path/to/your/kubeconfig ~/.kube/config

# Test access
kubectl get nodes
kubectl get namespaces
```

For cloud providers:

#### AWS EKS
```bash
aws eks update-kubeconfig --region us-east-1 --name your-cluster-name
```

#### Google GKE
```bash
gcloud container clusters get-credentials your-cluster-name --region us-central1
```

#### Azure AKS
```bash
az aks get-credentials --resource-group your-rg --name your-cluster-name
```

### 7. Configure Docker Access

```bash
# Ensure runner user can use Docker
sudo usermod -aG docker $USER

# Test Docker access
docker ps
docker version
```

### 8. Install Additional Tools (Optional)

```bash
# Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Trivy (security scanner)
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy
```

## Running the Runner

### Manual Start (for testing)
```bash
cd ~/actions-runner
./run.sh
```

### Service Management

#### Start
```bash
sudo ./svc.sh start
```

#### Stop
```bash
sudo ./svc.sh stop
```

#### Restart
```bash
sudo ./svc.sh restart
```

#### Check Status
```bash
sudo ./svc.sh status
```

#### View Logs
```bash
# Linux
sudo journalctl -u actions.runner.yathanshnagar-MediBot_Final.medibot-runner.service -f

# Or check runner logs
tail -f ~/actions-runner/_diag/Runner_*.log
```

## Verifying the Runner

1. **Check GitHub:**
   ```
   Repository → Settings → Actions → Runners
   ```
   Your runner should appear with a green dot (online).

2. **Test with a workflow:**
   - Push a commit to trigger the CI/CD pipeline
   - Workflow should show "Running on medibot-runner"

3. **Check logs:**
   ```bash
   cd ~/actions-runner
   tail -f _diag/Runner_*.log
   ```

## Security Best Practices

### 1. Use a Dedicated User
```bash
# Create a dedicated user for the runner
sudo useradd -m -s /bin/bash github-runner
sudo usermod -aG docker github-runner

# Switch to that user
sudo su - github-runner

# Then configure runner as this user
```

### 2. Restrict kubectl Permissions
```bash
# Create a service account with limited permissions
kubectl create serviceaccount github-runner -n medibot
kubectl create rolebinding github-runner-binding \
  --clusterrole=edit \
  --serviceaccount=medibot:github-runner \
  --namespace=medibot
```

### 3. Use Secrets for Sensitive Data
Never hardcode credentials in workflows. Use GitHub Secrets:
```yaml
- name: Login to registry
  env:
    REGISTRY_PASSWORD: ${{ secrets.REGISTRY_PASSWORD }}
```

### 4. Enable Runner Security
```bash
# Disable anonymous access
./config.sh --disableupdate

# Use HTTPS
./config.sh --url https://github.com/...
```

### 5. Network Security
- Run runner behind a firewall
- Use VPN for cluster access
- Restrict outbound connections

## Multiple Runners

To run multiple runners on the same machine:

```bash
# Create separate directories
mkdir ~/actions-runner-1
mkdir ~/actions-runner-2

# Configure each with different names
cd ~/actions-runner-1
./config.sh --name runner-1 --labels build

cd ~/actions-runner-2
./config.sh --name runner-2 --labels deploy
```

## Troubleshooting

### Runner Not Connecting
```bash
# Check network connectivity
curl -I https://github.com

# Check runner logs
tail -f ~/actions-runner/_diag/Runner_*.log

# Restart runner
sudo ./svc.sh restart
```

### Docker Permission Denied
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Logout and login
exit

# Or restart the service
sudo ./svc.sh restart
```

### kubectl Not Working
```bash
# Verify kubeconfig
kubectl config view

# Test connection
kubectl get nodes

# Check permissions
kubectl auth can-i list pods -n medibot
```

### Disk Space Issues
```bash
# Check disk usage
df -h

# Clean Docker images
docker system prune -af

# Clean runner workspace
rm -rf ~/actions-runner/_work/*
```

## Monitoring

### System Resources
```bash
# Monitor CPU/Memory
htop

# Monitor disk usage
watch df -h

# Monitor Docker
docker stats
```

### Runner Metrics
```bash
# Check runner uptime
sudo ./svc.sh status

# View runner diagnostics
cat ~/actions-runner/_diag/Runner_*.log | grep -i error
```

## Maintenance

### Update Runner
```bash
# Stop the runner
sudo ./svc.sh stop

# Download latest version
# Check: https://github.com/actions/runner/releases

# Extract and replace files
tar xzf actions-runner-linux-x64-X.XXX.X.tar.gz

# Start the runner
sudo ./svc.sh start
```

### Backup Configuration
```bash
# Backup runner configuration
cp ~/.runner ~/backup/.runner
cp ~/actions-runner/.credentials ~/backup/.credentials
```

### Remove Runner
```bash
# Stop the service
sudo ./svc.sh stop

# Uninstall the service
sudo ./svc.sh uninstall

# Remove from GitHub
./config.sh remove --token YOUR_TOKEN
```

## Auto-Scaling Runners (Advanced)

For auto-scaling self-hosted runners, consider:

1. **Actions Runner Controller (ARC):**
   - Kubernetes-native solution
   - Auto-scales based on workflow demand
   - [GitHub Actions Runner Controller](https://github.com/actions/actions-runner-controller)

2. **Terraform/Ansible:**
   - Automate runner provisioning
   - Use spot instances for cost savings

3. **Docker-based Runners:**
   - Run runners in Docker containers
   - Easy to scale and manage

## Docker-in-Docker Runner (Alternative)

Run the runner in a Docker container:

```bash
docker run -d \
  --name github-runner \
  --restart unless-stopped \
  -e REPO_URL="https://github.com/yathanshnagar/MediBot_Final" \
  -e RUNNER_TOKEN="YOUR_TOKEN" \
  -e RUNNER_NAME="docker-runner" \
  -e LABELS="docker,linux" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v runner-work:/home/runner/_work \
  myoung34/github-runner:latest
```

## Best Practices Summary

✅ **DO:**
- Use dedicated hardware/VM for runners
- Keep runners updated
- Monitor resource usage
- Use service accounts with limited permissions
- Enable automatic updates
- Implement proper logging
- Use labels to organize runners

❌ **DON'T:**
- Run runners as root
- Use the same runner for multiple repositories
- Store secrets in runner configuration
- Expose runner to public internet
- Ignore security updates
- Run untrusted workflows

## Support

For issues:
- Check runner logs: `~/actions-runner/_diag/`
- GitHub Actions documentation: https://docs.github.com/en/actions
- Community forums: https://github.community/

## Next Steps

After setting up the runner:
1. Test with the `self-hosted-build.yml` workflow
2. Configure environment-specific deployments
3. Set up monitoring and alerting
4. Document your runner configuration
5. Create runbooks for common operations
