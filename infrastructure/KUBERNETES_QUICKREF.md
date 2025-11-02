# Kubernetes Deployment Quick Reference

## Quick Commands

### Deploy All Resources
```bash
kubectl apply -f infrastructure/kubernetes/
```

### Check Status
```bash
# All resources in namespace
kubectl get all -n medibot

# Pods
kubectl get pods -n medibot -o wide

# Services
kubectl get svc -n medibot

# Ingress
kubectl get ingress -n medibot
```

### View Logs
```bash
# Application logs
kubectl logs -n medibot -l app=medibot --tail=100 -f

# Ollama logs
kubectl logs -n medibot -l app=ollama --tail=100 -f

# Specific pod
kubectl logs -n medibot <pod-name> -f
```

### Execute Commands in Pod
```bash
# Get shell access
kubectl exec -it -n medibot <pod-name> -- /bin/bash

# Run single command
kubectl exec -n medibot <pod-name> -- ls -la /app/data
```

### Scale Application
```bash
# Manual scale
kubectl scale deployment/medibot-app --replicas=5 -n medibot

# Auto-scale
kubectl autoscale deployment medibot-app --min=2 --max=10 --cpu-percent=70 -n medibot
```

### Update Image
```bash
kubectl set image deployment/medibot-app \
  medibot-app=ghcr.io/yathanshnagar/medibot:v1.0.1 \
  -n medibot
```

### Rollback
```bash
# Rollback to previous version
kubectl rollout undo deployment/medibot-app -n medibot

# Check rollout status
kubectl rollout status deployment/medibot-app -n medibot

# View history
kubectl rollout history deployment/medibot-app -n medibot
```

### Port Forward (Local Testing)
```bash
# Forward application port
kubectl port-forward -n medibot svc/medibot-service 8000:8000

# Forward Ollama port
kubectl port-forward -n medibot svc/ollama-service 11434:11434
```

### Restart Deployment
```bash
kubectl rollout restart deployment/medibot-app -n medibot
```

### Debug
```bash
# Describe pod for events
kubectl describe pod -n medibot <pod-name>

# Get pod YAML
kubectl get pod -n medibot <pod-name> -o yaml

# Check endpoints
kubectl get endpoints -n medibot

# Check persistent volumes
kubectl get pv,pvc -n medibot
```

### Resource Usage
```bash
# Node resources
kubectl top nodes

# Pod resources
kubectl top pods -n medibot

# HPA status
kubectl get hpa -n medibot
```

### Clean Up
```bash
# Delete specific resource
kubectl delete deployment medibot-app -n medibot

# Delete all resources in namespace
kubectl delete namespace medibot
```

## Useful Aliases

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# Kubectl aliases
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias kga='kubectl get all'
alias kl='kubectl logs'
alias kd='kubectl describe'
alias kx='kubectl exec -it'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'

# MediBot specific
alias mb-pods='kubectl get pods -n medibot'
alias mb-logs='kubectl logs -n medibot -l app=medibot --tail=100 -f'
alias mb-shell='kubectl exec -it -n medibot $(kubectl get pod -n medibot -l app=medibot -o jsonpath="{.items[0].metadata.name}") -- /bin/bash'
```

## Troubleshooting Checklist

### Pod Not Starting
1. Check pod status: `kubectl get pods -n medibot`
2. Describe pod: `kubectl describe pod -n medibot <pod-name>`
3. Check logs: `kubectl logs -n medibot <pod-name>`
4. Check events: `kubectl get events -n medibot --sort-by='.lastTimestamp'`

### Application Not Accessible
1. Check service: `kubectl get svc -n medibot`
2. Check endpoints: `kubectl get endpoints -n medibot`
3. Check ingress: `kubectl get ingress -n medibot`
4. Test internally: `kubectl exec -it -n medibot <pod-name> -- curl http://localhost:8000/health`

### Ollama Connection Issues
1. Check Ollama pod: `kubectl get pods -n medibot -l app=ollama`
2. Check Ollama service: `kubectl get svc ollama-service -n medibot`
3. Test from app pod: `kubectl exec -it -n medibot <app-pod> -- curl http://ollama-service:11434`
4. Check Ollama logs: `kubectl logs -n medibot -l app=ollama`

### Storage Issues
1. Check PVCs: `kubectl get pvc -n medibot`
2. Describe PVC: `kubectl describe pvc -n medibot <pvc-name>`
3. Check PVs: `kubectl get pv`
4. Check storage class: `kubectl get storageclass`

## Environment-Specific Commands

### Staging
```bash
# Deploy to staging
kubectl apply -f infrastructure/kubernetes/ -n medibot-staging

# Check staging
kubectl get all -n medibot-staging
```

### Production
```bash
# Deploy to production
kubectl apply -f infrastructure/kubernetes/ -n medibot-production

# Check production
kubectl get all -n medibot-production
```

## Monitoring

### Watch Resources
```bash
# Watch pods
watch kubectl get pods -n medibot

# Watch HPA
watch kubectl get hpa -n medibot

# Watch all resources
watch kubectl get all -n medibot
```

### Resource Metrics
```bash
# Enable metrics server (if not already)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# View metrics
kubectl top nodes
kubectl top pods -n medibot
kubectl top pods -n medibot --containers
```

## Security

### Check RBAC
```bash
# Check what you can do
kubectl auth can-i --list -n medibot

# Check specific permission
kubectl auth can-i create pods -n medibot
```

### Secrets Management
```bash
# Create secret
kubectl create secret generic my-secret \
  --from-literal=key1=value1 \
  --from-literal=key2=value2 \
  -n medibot

# View secret (base64 encoded)
kubectl get secret my-secret -n medibot -o yaml

# Decode secret
kubectl get secret my-secret -n medibot -o jsonpath='{.data.key1}' | base64 -d
```

## Backup and Restore

### Backup
```bash
# Backup all resources
kubectl get all -n medibot -o yaml > medibot-backup.yaml

# Backup database
kubectl cp medibot/<pod-name>:/app/data/medical_llama.db ./backup.db
```

### Restore
```bash
# Restore resources
kubectl apply -f medibot-backup.yaml

# Restore database
kubectl cp ./backup.db medibot/<pod-name>:/app/data/medical_llama.db
```

## Performance Tuning

### Adjust Resources
```bash
# Edit deployment
kubectl edit deployment medibot-app -n medibot

# Or use kubectl set
kubectl set resources deployment medibot-app \
  --requests=cpu=500m,memory=1Gi \
  --limits=cpu=2,memory=4Gi \
  -n medibot
```

### Adjust HPA
```bash
# Edit HPA
kubectl edit hpa medibot-hpa -n medibot

# Or delete and recreate
kubectl delete hpa medibot-hpa -n medibot
kubectl apply -f infrastructure/kubernetes/hpa.yaml
```
