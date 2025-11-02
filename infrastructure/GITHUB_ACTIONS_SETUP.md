# GitHub Actions Setup Guide

This guide walks you through configuring GitHub Actions for automated CI/CD of your MediBot application.

## Prerequisites

- GitHub account with repository access
- Container registry access (GitHub Container Registry is used by default)
- Kubernetes cluster access (if using self-hosted runner)

## Step 1: Enable GitHub Container Registry (GHCR)

### 1.1 Create Personal Access Token (PAT)

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a name: `MediBot Container Registry`
4. Select scopes:
   - ✅ `write:packages`
   - ✅ `read:packages`
   - ✅ `delete:packages`
   - ✅ `repo` (full control)
5. Click "Generate token"
6. **Save the token securely** - you won't see it again!

### 1.2 Configure Package Settings

1. Go to your repository
2. Click on "Packages" (if not visible, push a package first)
3. After first push, go to package settings
4. Change visibility to "Public" or "Private" as needed
5. Link to repository

## Step 2: Add Repository Secrets

Navigate to: `Repository → Settings → Secrets and variables → Actions`

### Required Secrets

#### For GitHub-Hosted Runners

| Secret Name | Description | How to Get |
|------------|-------------|------------|
| `KUBE_CONFIG` | Base64 encoded kubeconfig | See below |
| `GITHUB_TOKEN` | Auto-provided | Already available |

#### For Private Registry (Optional)

| Secret Name | Description |
|------------|-------------|
| `REGISTRY_USERNAME` | Container registry username |
| `REGISTRY_PASSWORD` | Container registry password |

### Creating KUBE_CONFIG Secret

#### Method 1: From Local kubeconfig

```bash
# Encode your kubeconfig
cat ~/.kube/config | base64

# Or for macOS
cat ~/.kube/config | base64 | pbcopy

# Copy the output and paste as KUBE_CONFIG secret
```

#### Method 2: Create Service Account (Recommended)

```bash
# Create service account
kubectl create serviceaccount github-actions -n medibot

# Create role binding
kubectl create clusterrolebinding github-actions-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=medibot:github-actions

# Get service account token (Kubernetes 1.24+)
kubectl create token github-actions -n medibot --duration=87600h

# Create kubeconfig file
cat > github-kubeconfig.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
- name: default-cluster
  cluster:
    server: $(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
    certificate-authority-data: $(kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
contexts:
- name: default-context
  context:
    cluster: default-cluster
    user: github-actions
    namespace: medibot
current-context: default-context
users:
- name: github-actions
  user:
    token: $(kubectl create token github-actions -n medibot --duration=87600h)
EOF

# Encode and copy
cat github-kubeconfig.yaml | base64

# Securely delete the file
rm github-kubeconfig.yaml
```

#### Method 3: Cloud Provider Specific

**AWS EKS:**
```bash
# Create kubeconfig
aws eks update-kubeconfig --name your-cluster-name --region us-east-1

# Encode
cat ~/.kube/config | base64
```

**Google GKE:**
```bash
# Get credentials
gcloud container clusters get-credentials your-cluster-name --region us-central1

# Encode
cat ~/.kube/config | base64
```

**Azure AKS:**
```bash
# Get credentials
az aks get-credentials --resource-group your-rg --name your-cluster-name

# Encode
cat ~/.kube/config | base64
```

## Step 3: Configure Workflow Permissions

1. Go to: `Repository → Settings → Actions → General`
2. Scroll to "Workflow permissions"
3. Select: **"Read and write permissions"**
4. Check: **"Allow GitHub Actions to create and approve pull requests"**
5. Click "Save"

## Step 4: Enable GitHub Packages

1. Go to: `Repository → Settings → Packages`
2. Ensure "Container registry" is enabled
3. Configure package visibility as needed

## Step 5: Update Workflow Files

### Update Image Registry (if not using GHCR)

If using a different registry, update `.github/workflows/ci-cd.yml`:

```yaml
env:
  REGISTRY: ghcr.io  # Change to: docker.io, quay.io, etc.
  IMAGE_NAME: ${{ github.repository }}
```

### Update Kubernetes Cluster Configuration

In `.github/workflows/ci-cd.yml`, update the kubectl configuration section:

```yaml
- name: Configure kubectl context
  run: |
    # For AWS EKS
    aws eks update-kubeconfig --name your-cluster --region us-east-1
    
    # For GKE
    # gcloud container clusters get-credentials your-cluster --region us-central1
    
    # For AKS
    # az aks get-credentials --resource-group your-rg --name your-cluster
    
    # Or use KUBE_CONFIG secret
    # mkdir -p $HOME/.kube
    # echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > $HOME/.kube/config
```

## Step 6: Test the Workflows

### Test CI/CD Pipeline

1. Make a small change to your code
2. Commit and push to main branch:
   ```bash
   git add .
   git commit -m "Test CI/CD pipeline"
   git push origin main
   ```
3. Go to: `Repository → Actions`
4. Watch the workflow run
5. Verify each step completes successfully

### Test Manual Deploy

1. Go to: `Repository → Actions`
2. Select "Manual Deploy to Kubernetes"
3. Click "Run workflow"
4. Choose environment and image tag
5. Click "Run workflow"
6. Monitor the deployment

## Step 7: Setup Self-Hosted Runner (Optional)

For better performance and direct cluster access, set up a self-hosted runner.

See detailed instructions in [`SELF_HOSTED_RUNNER.md`](./SELF_HOSTED_RUNNER.md)

Quick setup:
```bash
# On your server
mkdir ~/actions-runner && cd ~/actions-runner

# Download runner (get URL from GitHub)
# Repository → Settings → Actions → Runners → New self-hosted runner

# Configure
./config.sh --url https://github.com/yathanshnagar/MediBot_Final \
  --token YOUR_TOKEN

# Install as service
sudo ./svc.sh install
sudo ./svc.sh start
```

## Step 8: Configure Notifications (Optional)

### Slack Notifications

Add to workflow file:

```yaml
- name: Notify Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'Deployment ${{ job.status }}'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

Add `SLACK_WEBHOOK` secret with your Slack webhook URL.

### Discord Notifications

```yaml
- name: Notify Discord
  if: always()
  uses: sarisia/actions-status-discord@v1
  with:
    webhook: ${{ secrets.DISCORD_WEBHOOK }}
    status: ${{ job.status }}
```

### Email Notifications

GitHub sends email notifications automatically to commit authors.

Configure in: `Settings → Notifications`

## Workflow Overview

### CI/CD Pipeline Flow

```
┌─────────────────────────────────────────────────────────┐
│              Push to main/develop                        │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                  Test Job                                │
│  • Checkout code                                         │
│  • Setup Python                                          │
│  • Install dependencies                                  │
│  • Run tests                                             │
│  • Run linters                                           │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                  Build Job                               │
│  • Checkout code                                         │
│  • Setup Docker Buildx                                   │
│  • Login to GHCR                                         │
│  • Build & push image                                    │
│  • Generate SBOM                                         │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                Security Job                              │
│  • Run Trivy scan                                        │
│  • Upload to GitHub Security                             │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                  Deploy Job                              │
│  • Checkout code                                         │
│  • Setup kubectl                                         │
│  • Update deployment                                     │
│  • Verify rollout                                        │
│  • Run smoke tests                                       │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────┐
│                Notify Job                                │
│  • Send success/failure notifications                    │
└─────────────────────────────────────────────────────────┘
```

## Troubleshooting

### Error: "No space left on device"

**Solution:** Clean up Docker images on runner

```bash
docker system prune -af --volumes
```

Or configure in workflow:
```yaml
- name: Clean up Docker
  run: docker system prune -af
```

### Error: "Unable to connect to cluster"

**Solution:** Verify KUBE_CONFIG secret

```bash
# Decode and test locally
echo "$KUBE_CONFIG" | base64 -d > test-kubeconfig
export KUBECONFIG=test-kubeconfig
kubectl get nodes
rm test-kubeconfig
```

### Error: "Permission denied on kubectl"

**Solution:** Check service account permissions

```bash
kubectl auth can-i --list --as=system:serviceaccount:medibot:github-actions
```

### Error: "Failed to push image"

**Solution:** Check registry authentication

```bash
# Test login locally
echo ${{ secrets.GITHUB_TOKEN }} | docker login ghcr.io -u ${{ github.actor }} --password-stdin

# Verify permissions
# Go to: Settings → Actions → General → Workflow permissions
```

### Error: "Workflow not triggering"

**Solutions:**
1. Check if Actions are enabled: `Settings → Actions → General`
2. Verify branch names in workflow trigger
3. Check `.github/workflows/` directory structure
4. Ensure workflow files have `.yml` or `.yaml` extension

### Error: "Image pull backoff in Kubernetes"

**Solutions:**
1. Check if image exists in registry
2. Verify image pull secrets configured
3. Check if image is public or private
4. Ensure correct image tag

```bash
# Check image
kubectl describe pod -n medibot <pod-name>

# Create image pull secret if needed
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=$GITHUB_USERNAME \
  --docker-password=$GITHUB_TOKEN \
  -n medibot
```

## Best Practices

### 1. Use Environments

Create GitHub Environments for better control:

```
Settings → Environments → New environment
```

Configure:
- Protection rules
- Required reviewers
- Wait timer
- Environment secrets

### 2. Use Branch Protection

```
Settings → Branches → Add rule
```

Enable:
- Require pull request reviews
- Require status checks to pass
- Require branches to be up to date

### 3. Cache Dependencies

Already configured in workflow:
```yaml
- uses: actions/setup-python@v5
  with:
    cache: 'pip'
```

### 4. Use Concurrency Control

Add to workflow:
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### 5. Secure Secrets

- Never log secrets
- Use minimal permissions
- Rotate regularly
- Use external secret managers for production

### 6. Monitor Workflow Runs

- Set up notifications
- Review failed runs
- Check security alerts
- Monitor build times

## Security Checklist

- [ ] All secrets are configured and not exposed in logs
- [ ] KUBE_CONFIG has minimal required permissions
- [ ] Image registry is private or uses authentication
- [ ] Security scanning is enabled (Trivy)
- [ ] Branch protection is configured
- [ ] Required reviewers are set for production
- [ ] Secrets rotation schedule is defined
- [ ] Audit logs are enabled
- [ ] Two-factor authentication is enabled for maintainers

## Workflow Status Badges

Add to your README.md:

```markdown
![CI/CD Pipeline](https://github.com/yathanshnagar/MediBot_Final/actions/workflows/ci-cd.yml/badge.svg)
```

## Next Steps

After GitHub Actions is set up:

1. ✅ Push code to trigger first workflow
2. ✅ Monitor workflow execution
3. ✅ Verify deployment to Kubernetes
4. ✅ Set up monitoring and alerts
5. ✅ Configure backup workflows
6. ✅ Document deployment procedures
7. ✅ Train team on workflow usage
8. ✅ Set up staging environment
9. ✅ Create runbooks for incidents
10. ✅ Schedule regular security audits

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Container Registry Guide](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [Kubernetes in GitHub Actions](https://github.com/marketplace/actions/kubernetes-action)
- [Docker Build Push Action](https://github.com/marketplace/actions/build-and-push-docker-images)
- [Trivy Security Scanner](https://github.com/marketplace/actions/aqua-security-trivy)

## Support

For issues with GitHub Actions:
- Check [Actions tab](../../actions) for logs
- Review [GitHub Status](https://www.githubstatus.com/)
- Check [GitHub Actions Community](https://github.community/c/actions/9)
- Open an issue in this repository

---

**Last Updated:** November 2025
**Maintained by:** MediBot Team
