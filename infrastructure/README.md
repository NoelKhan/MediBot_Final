# MediBot Infrastructure Documentation

This directory contains all infrastructure-as-code (IaC) for containerizing, deploying, and managing the MediBot application.

## 📁 Directory Structure

```
infrastructure/
├── docker/                 # Docker-related files
├── kubernetes/            # Kubernetes manifests
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── pvc.yaml
│   ├── deployment.yaml
│   ├── ollama-deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── hpa.yaml
├── helm/                  # Helm charts
│   ├── Chart.yaml
│   └── values.yaml
└── README.md

.github/
└── workflows/             # CI/CD pipelines
    ├── ci-cd.yml
    ├── self-hosted-build.yml
    └── manual-deploy.yml
```

## 🚀 Quick Start

### Local Development with Docker Compose

1. **Build and run locally:**
   ```bash
   docker-compose up --build
   ```

2. **Access the application:**
   - Application: http://localhost:8000
   - Ollama: http://localhost:11434
   - Health check: http://localhost:8000/health

3. **Stop services:**
   ```bash
   docker-compose down
   ```

### Building Docker Image

```bash
# Build the image
docker build -t medibot:latest .

# Run the container
docker run -p 8000:8000 \
  -e DATABASE_URL=sqlite:////app/data/medical_llama.db \
  -e LLM_BASE_URL=http://ollama:11434 \
  medibot:latest
```

## ☸️ Kubernetes Deployment

### Prerequisites

- Kubernetes cluster (v1.24+)
- kubectl configured
- Ingress controller (nginx recommended)
- Persistent volume provisioner

### Deploy to Kubernetes

1. **Create namespace and apply manifests:**
   ```bash
   kubectl apply -f infrastructure/kubernetes/namespace.yaml
   kubectl apply -f infrastructure/kubernetes/configmap.yaml
   kubectl apply -f infrastructure/kubernetes/secret.yaml
   kubectl apply -f infrastructure/kubernetes/pvc.yaml
   kubectl apply -f infrastructure/kubernetes/deployment.yaml
   kubectl apply -f infrastructure/kubernetes/ollama-deployment.yaml
   kubectl apply -f infrastructure/kubernetes/service.yaml
   kubectl apply -f infrastructure/kubernetes/ingress.yaml
   kubectl apply -f infrastructure/kubernetes/hpa.yaml
   ```

2. **Or apply all at once:**
   ```bash
   kubectl apply -f infrastructure/kubernetes/
   ```

3. **Verify deployment:**
   ```bash
   kubectl get all -n medibot
   kubectl get pods -n medibot
   kubectl logs -n medibot -l app=medibot
   ```

### Deploy with Helm

1. **Install the chart:**
   ```bash
   helm install medibot ./infrastructure/helm \
     --namespace medibot \
     --create-namespace \
     --values ./infrastructure/helm/values.yaml
   ```

2. **Upgrade the release:**
   ```bash
   helm upgrade medibot ./infrastructure/helm \
     --namespace medibot \
     --values ./infrastructure/helm/values.yaml
   ```

3. **Uninstall:**
   ```bash
   helm uninstall medibot --namespace medibot
   ```

## 🔧 Configuration

### Environment Variables

Key environment variables that can be configured:

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | SQLite database path | `sqlite:////app/data/medical_llama.db` |
| `LLM_BASE_URL` | Ollama service URL | `http://ollama-service:11434` |
| `LLM_MODEL` | LLM model name | `mistral:7b-instruct` |
| `LLM_TEMPERATURE` | Model temperature | `0.3` |
| `LLM_MAX_TOKENS` | Max tokens per response | `1024` |
| `LOG_LEVEL` | Logging level | `INFO` |

### Kubernetes ConfigMap

Edit `infrastructure/kubernetes/configmap.yaml` to update configuration:

```yaml
data:
  LLM_MODEL: "mistral:7b-instruct"
  LLM_TEMPERATURE: "0.3"
  # ... other configs
```

### Secrets Management

**⚠️ IMPORTANT:** Never commit real secrets to Git!

1. **Update secrets before deploying:**
   ```bash
   kubectl create secret generic medibot-secrets \
     --from-literal=DATABASE_PASSWORD=your_secure_password \
     --from-literal=API_SECRET_KEY=your_api_key \
     -n medibot
   ```

2. **Or use a secrets manager:**
   - AWS Secrets Manager + External Secrets Operator
   - HashiCorp Vault
   - Sealed Secrets

## 🔄 CI/CD Pipeline

### GitHub Actions Workflows

Three workflows are provided:

#### 1. **CI/CD Pipeline** (`ci-cd.yml`)
Automatically triggered on push to main/develop branches:
- Runs tests and linting
- Builds Docker image
- Pushes to GitHub Container Registry
- Scans for security vulnerabilities
- Deploys to Kubernetes
- Sends notifications

#### 2. **Self-Hosted Runner Build** (`self-hosted-build.yml`)
Manual workflow for building on self-hosted runners:
- Uses local Docker daemon
- Faster builds with caching
- Direct kubectl access

#### 3. **Manual Deploy** (`manual-deploy.yml`)
Manual deployment workflow:
- Choose environment (staging/production)
- Specify image tag
- Deploy to Kubernetes

### Setup GitHub Actions

1. **Add required secrets:**
   ```
   Settings → Secrets and variables → Actions
   ```
   
   Required secrets:
   - `KUBE_CONFIG`: Base64 encoded kubeconfig file
   - `REGISTRY_USERNAME`: Container registry username
   - `REGISTRY_PASSWORD`: Container registry password

2. **Enable GitHub Container Registry:**
   ```
   Settings → Packages → Container registry
   ```

3. **Configure permissions:**
   ```
   Settings → Actions → General → Workflow permissions
   - Read and write permissions
   ```

### Setting Up Self-Hosted Runner

See [SELF_HOSTED_RUNNER.md](./SELF_HOSTED_RUNNER.md) for detailed instructions.

Quick setup:
```bash
# On your server/machine
mkdir actions-runner && cd actions-runner

# Download and configure
# Get the download URL from: Repository Settings → Actions → Runners → Add runner

./config.sh --url https://github.com/yathanshnagar/MediBot_Final --token YOUR_TOKEN
./run.sh
```

## 📊 Monitoring and Observability

### Health Checks

- **Liveness probe:** `/health` endpoint
- **Readiness probe:** `/health` endpoint

### Viewing Logs

```bash
# Application logs
kubectl logs -n medibot -l app=medibot --tail=100 -f

# Ollama logs
kubectl logs -n medibot -l app=ollama --tail=100 -f

# All pods
kubectl logs -n medibot --all-containers=true --tail=100 -f
```

### Metrics

The HPA automatically scales based on:
- CPU utilization (target: 70%)
- Memory utilization (target: 80%)

View HPA status:
```bash
kubectl get hpa -n medibot
kubectl describe hpa medibot-hpa -n medibot
```

## 🔒 Security Best Practices

1. **Use secrets management:**
   - Never hardcode credentials
   - Use external secrets operators
   - Rotate secrets regularly

2. **Network policies:**
   - Implement network policies to restrict pod communication
   - Use service mesh for mTLS

3. **Image scanning:**
   - CI/CD pipeline includes Trivy scanning
   - Review security reports regularly

4. **RBAC:**
   - Use least privilege principle
   - Create dedicated service accounts

5. **TLS/SSL:**
   - Enable TLS in ingress
   - Use cert-manager for automatic certificate management

## 🛠️ Troubleshooting

### Common Issues

#### Pods not starting
```bash
kubectl describe pod -n medibot <pod-name>
kubectl logs -n medibot <pod-name>
```

#### Storage issues
```bash
kubectl get pvc -n medibot
kubectl describe pvc -n medibot
```

#### Network connectivity
```bash
# Test connectivity between pods
kubectl exec -it -n medibot <app-pod> -- curl http://ollama-service:11434

# Check services
kubectl get svc -n medibot
kubectl get endpoints -n medibot
```

#### Ollama model not loading
```bash
# Check Ollama logs
kubectl logs -n medibot -l app=ollama

# Manually pull model
kubectl exec -it -n medibot <ollama-pod> -- ollama pull mistral:7b-instruct
```

### Debugging

Enable debug mode:
```bash
kubectl set env deployment/medibot-app LOG_LEVEL=DEBUG -n medibot
```

## 📈 Scaling

### Manual Scaling
```bash
# Scale application
kubectl scale deployment medibot-app --replicas=5 -n medibot

# Scale Ollama (typically keep at 1)
kubectl scale deployment ollama --replicas=1 -n medibot
```

### Auto-scaling
HPA is configured by default. Adjust in `infrastructure/kubernetes/hpa.yaml`:
```yaml
minReplicas: 2
maxReplicas: 10
```

## 🔄 Updates and Rollbacks

### Rolling Update
```bash
kubectl set image deployment/medibot-app \
  medibot-app=ghcr.io/yathanshnagar/medibot:v1.1.0 \
  -n medibot
```

### Check Rollout Status
```bash
kubectl rollout status deployment/medibot-app -n medibot
```

### Rollback
```bash
# Rollback to previous version
kubectl rollout undo deployment/medibot-app -n medibot

# Rollback to specific revision
kubectl rollout undo deployment/medibot-app --to-revision=2 -n medibot

# View rollout history
kubectl rollout history deployment/medibot-app -n medibot
```

## 🌍 Multi-Environment Setup

Create separate namespaces for different environments:

```bash
# Staging
kubectl create namespace medibot-staging
kubectl apply -f infrastructure/kubernetes/ -n medibot-staging

# Production
kubectl create namespace medibot-production
kubectl apply -f infrastructure/kubernetes/ -n medibot-production
```

## 📝 Maintenance

### Backup Database
```bash
# Backup SQLite database
kubectl cp medibot/<pod-name>:/app/data/medical_llama.db ./backup-$(date +%Y%m%d).db -n medibot
```

### Update Configuration
```bash
# Edit configmap
kubectl edit configmap medibot-config -n medibot

# Restart deployment to pick up changes
kubectl rollout restart deployment/medibot-app -n medibot
```

### Clean Up
```bash
# Delete all resources
kubectl delete namespace medibot

# Or use Helm
helm uninstall medibot --namespace medibot
```

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [FastAPI Deployment](https://fastapi.tiangolo.com/deployment/)

## 🤝 Contributing

When adding infrastructure changes:
1. Test locally with Docker Compose
2. Test in staging Kubernetes environment
3. Update documentation
4. Submit PR with changes

## 📞 Support

For issues or questions:
- Create an issue in the repository
- Contact the DevOps team
- Check the troubleshooting section above
