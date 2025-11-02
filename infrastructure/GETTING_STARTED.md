# 🚀 Getting Started with MediBot Infrastructure

Welcome! This guide will help you get started with deploying MediBot using the infrastructure we've set up.

## 📋 Table of Contents

1. [Overview](#overview)
2. [Choose Your Path](#choose-your-path)
3. [Quick Start Guides](#quick-start-guides)
4. [What's Next](#whats-next)
5. [Getting Help](#getting-help)

## Overview

MediBot infrastructure includes everything needed to deploy your medical AI chatbot:

- 🐳 **Docker** - Containerized application
- ☸️ **Kubernetes** - Production orchestration
- 🎡 **Helm** - Package management
- 🔄 **CI/CD** - Automated deployment pipelines
- 📚 **Documentation** - Comprehensive guides

## Choose Your Path

### Path 1: Local Development 🏠

**Best for:** Testing, development, learning

**Time to deploy:** 5 minutes

**What you need:**
- Docker Desktop installed
- 8GB RAM minimum
- 10GB free disk space

**Follow:** [Local Development Guide](#local-development)

---

### Path 2: Cloud Kubernetes ☁️

**Best for:** Production deployment, team collaboration

**Time to deploy:** 20-30 minutes

**What you need:**
- Kubernetes cluster (GKE, EKS, AKS, or self-hosted)
- kubectl installed and configured
- Basic Kubernetes knowledge

**Follow:** [Kubernetes Deployment Guide](#kubernetes-deployment)

---

### Path 3: CI/CD Automation 🤖

**Best for:** Continuous deployment, automated workflows

**Time to setup:** 30-45 minutes

**What you need:**
- GitHub repository access
- Container registry access
- Kubernetes cluster (for deployment)

**Follow:** [CI/CD Setup Guide](#cicd-setup)

---

## Quick Start Guides

### Local Development

#### 1. Install Docker Desktop

**macOS:**
```bash
# Download from: https://www.docker.com/products/docker-desktop
# Or use Homebrew:
brew install --cask docker
```

**Windows:**
- Download from: https://www.docker.com/products/docker-desktop
- Run installer
- Restart computer

**Linux:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

#### 2. Start MediBot

```bash
# Clone repository (if not already)
git clone https://github.com/yathanshnagar/MediBot_Final.git
cd MediBot_Final

# Start all services
docker-compose up --build

# Wait for services to start (2-3 minutes)
# Look for: "Application startup complete"
```

#### 3. Access Application

Open browser: http://localhost:8000

**First-time setup:**
1. Click "Sign Up"
2. Create an account
3. Start chatting!

#### 4. Stop Services

```bash
# Press Ctrl+C in terminal
# Or in new terminal:
docker-compose down
```

**✅ Success!** You now have MediBot running locally!

**Next steps:**
- Explore the chat interface
- Book a test appointment
- View medical history
- Check API docs at http://localhost:8000/docs

---

### Kubernetes Deployment

#### Prerequisites Check

```bash
# Check kubectl
kubectl version --client

# Check cluster connection
kubectl cluster-info

# Check available resources
kubectl get nodes
```

#### Quick Deploy

```bash
# Navigate to project
cd MediBot_Final

# Run deployment script
./infrastructure/deploy.sh deploy

# This will:
# ✓ Create namespace
# ✓ Apply configurations
# ✓ Deploy application
# ✓ Deploy Ollama
# ✓ Setup services
# ✓ Configure ingress (optional)
# ✓ Enable auto-scaling (optional)
```

#### Verify Deployment

```bash
# Check all resources
kubectl get all -n medibot

# Watch pods start
kubectl get pods -n medibot -w

# Check logs
kubectl logs -n medibot -l app=medibot -f
```

#### Access Application

**Option 1: Port Forward**
```bash
kubectl port-forward -n medibot svc/medibot-service 8000:8000

# Open: http://localhost:8000
```

**Option 2: Ingress** (if configured)
```bash
# Get ingress URL
kubectl get ingress -n medibot

# Open the displayed URL
```

**✅ Success!** MediBot is running on Kubernetes!

**Next steps:**
- Configure domain name
- Enable TLS/SSL
- Set up monitoring
- Configure backups

---

### CI/CD Setup

#### 1. Prepare Repository

```bash
# Ensure you have latest code
git pull origin main

# Verify workflows exist
ls -la .github/workflows/

# Should show:
# ci-cd.yml
# self-hosted-build.yml
# manual-deploy.yml
```

#### 2. Configure GitHub Secrets

Go to: `Repository → Settings → Secrets and variables → Actions`

**Add these secrets:**

| Secret | How to Get | Required |
|--------|-----------|----------|
| `KUBE_CONFIG` | `cat ~/.kube/config \| base64` | Yes |
| `REGISTRY_USERNAME` | Your registry username | Optional* |
| `REGISTRY_PASSWORD` | Your registry password | Optional* |

*Optional if using GitHub Container Registry (GHCR)

**Detailed guide:** [`GITHUB_ACTIONS_SETUP.md`](./GITHUB_ACTIONS_SETUP.md)

#### 3. Enable Workflow Permissions

1. Go to: `Repository → Settings → Actions → General`
2. Under "Workflow permissions":
   - Select "Read and write permissions"
   - Check "Allow GitHub Actions to create and approve pull requests"
3. Click "Save"

#### 4. Test Workflow

```bash
# Make a small change
echo "# CI/CD Test" >> README.md

# Commit and push
git add .
git commit -m "Test CI/CD pipeline"
git push origin main
```

Go to: `Repository → Actions` and watch the workflow run!

**✅ Success!** Your CI/CD pipeline is active!

**Next steps:**
- Set up staging environment
- Configure deployment approvals
- Add notification webhooks
- Set up self-hosted runner

---

## What's Next?

After successful deployment, consider these next steps:

### Security 🔒

1. **Update Secrets**
   ```bash
   # Update production secrets
   kubectl create secret generic medibot-secrets \
     --from-literal=DATABASE_PASSWORD=CHANGE_ME \
     --from-literal=API_SECRET_KEY=CHANGE_ME \
     -n medibot --dry-run=client -o yaml | kubectl apply -f -
   ```

2. **Enable TLS**
   - Install cert-manager
   - Configure Let's Encrypt
   - Update ingress for HTTPS

3. **Set up Network Policies**
   ```bash
   kubectl apply -f infrastructure/kubernetes/network-policy.yaml
   ```

### Monitoring 📊

1. **Install Metrics Server**
   ```bash
   kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
   ```

2. **Check HPA Status**
   ```bash
   kubectl get hpa -n medibot
   kubectl describe hpa medibot-hpa -n medibot
   ```

3. **View Metrics**
   ```bash
   kubectl top pods -n medibot
   kubectl top nodes
   ```

### Backups 💾

1. **Backup Database**
   ```bash
   # Create backup script
   kubectl cp medibot/<pod-name>:/app/data/medical_llama.db \
     ./backups/medibot-$(date +%Y%m%d).db
   ```

2. **Schedule Backups**
   - Use Kubernetes CronJob
   - Or cloud provider backup service

### Scaling 📈

1. **Manual Scale**
   ```bash
   kubectl scale deployment/medibot-app --replicas=5 -n medibot
   ```

2. **Adjust HPA**
   ```bash
   kubectl edit hpa medibot-hpa -n medibot
   ```

3. **Add Node Resources**
   - Scale cluster nodes
   - Adjust resource requests/limits

### Multi-Environment 🌍

1. **Create Staging**
   ```bash
   # Copy and adjust configs
   cp -r infrastructure/kubernetes/ infrastructure/kubernetes-staging/
   
   # Update namespace
   # Deploy to staging
   kubectl apply -f infrastructure/kubernetes-staging/
   ```

2. **Environment Variables**
   - Use separate ConfigMaps per environment
   - Configure in Helm values files

## Documentation Reference

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **INFRASTRUCTURE_SUMMARY.md** | Complete overview | Start here! |
| **README.md** | Deployment guide | Detailed deployment |
| **KUBERNETES_QUICKREF.md** | Command reference | Daily operations |
| **DEPLOYMENT_CHECKLIST.md** | Step-by-step checklist | Before deployment |
| **GITHUB_ACTIONS_SETUP.md** | CI/CD configuration | Setting up pipelines |
| **SELF_HOSTED_RUNNER.md** | Runner setup | Advanced CI/CD |
| **DIRECTORY_TREE.txt** | File structure | Understanding layout |

## Common Tasks

### View Logs
```bash
kubectl logs -n medibot -l app=medibot -f
```

### Restart Application
```bash
kubectl rollout restart deployment/medibot-app -n medibot
```

### Update Configuration
```bash
kubectl edit configmap medibot-config -n medibot
kubectl rollout restart deployment/medibot-app -n medibot
```

### Check Status
```bash
./infrastructure/deploy.sh status
```

### Scale Application
```bash
kubectl scale deployment/medibot-app --replicas=3 -n medibot
```

## Getting Help

### Documentation
1. Check the relevant guide in `infrastructure/`
2. Review Kubernetes quickref for commands
3. Read the troubleshooting sections

### Debugging
```bash
# Describe pod for events
kubectl describe pod -n medibot <pod-name>

# Check logs
kubectl logs -n medibot <pod-name> --previous

# Execute into pod
kubectl exec -it -n medibot <pod-name> -- /bin/bash

# Check network
kubectl exec -it -n medibot <pod-name> -- curl http://ollama-service:11434
```

### Support Channels
- 📚 Documentation: `infrastructure/` directory
- 🐛 GitHub Issues: Report bugs and request features
- 💬 Discussions: Ask questions and share experiences
- 📧 Team: Contact DevOps team for urgent issues

## Troubleshooting Quick Links

### Issue: Pods not starting
**Solution:** [`README.md#troubleshooting`](./README.md#troubleshooting)

### Issue: Can't access application
**Solution:** Check ingress and services
```bash
kubectl get svc,ingress -n medibot
kubectl describe ingress -n medibot
```

### Issue: Ollama not responding
**Solution:** Check Ollama logs and restart if needed
```bash
kubectl logs -n medibot -l app=ollama
kubectl rollout restart deployment/ollama -n medibot
```

### Issue: Database not persisting
**Solution:** Check PVC status
```bash
kubectl get pvc -n medibot
kubectl describe pvc medibot-data-pvc -n medibot
```

### Issue: CI/CD pipeline failing
**Solution:** [`GITHUB_ACTIONS_SETUP.md#troubleshooting`](./GITHUB_ACTIONS_SETUP.md#troubleshooting)

## Success Checklist

You've successfully deployed MediBot when:

- [ ] Pods show `Running` status
- [ ] Health endpoint returns 200 OK
- [ ] Can access via browser
- [ ] Can create account and login
- [ ] Chat interface works
- [ ] Ollama responds to queries
- [ ] Database persists data
- [ ] Auto-scaling is active (if enabled)
- [ ] Logs are accessible
- [ ] CI/CD pipeline runs (if configured)

## Quick Reference Card

```bash
# Deploy
./infrastructure/deploy.sh deploy

# Status
kubectl get all -n medibot

# Logs
kubectl logs -n medibot -l app=medibot -f

# Port Forward
kubectl port-forward -n medibot svc/medibot-service 8000:8000

# Scale
kubectl scale deployment/medibot-app --replicas=3 -n medibot

# Restart
kubectl rollout restart deployment/medibot-app -n medibot

# Clean Up
./infrastructure/deploy.sh cleanup

# Health Check
curl http://localhost:8000/health
```

## Resources

- **Docker:** https://docs.docker.com/
- **Kubernetes:** https://kubernetes.io/docs/
- **Helm:** https://helm.sh/docs/
- **GitHub Actions:** https://docs.github.com/en/actions
- **FastAPI:** https://fastapi.tiangolo.com/

---

## 🎉 You're Ready!

Choose your path above and start deploying MediBot. Each path includes everything you need to succeed.

**Remember:**
- Start with local development if new to containers
- Use Kubernetes for production deployments
- Enable CI/CD for automated workflows
- Read the documentation when stuck
- Ask for help when needed

**Happy Deploying! 🚀**

---

*Last Updated: November 2025*
*Version: 1.0.0*
