# MediBot Deployment Checklist

Use this checklist when deploying MediBot to ensure all steps are completed.

## Pre-Deployment

### Infrastructure Preparation
- [ ] Kubernetes cluster is running and accessible
- [ ] kubectl is installed and configured
- [ ] Ingress controller is installed (nginx recommended)
- [ ] Storage provisioner is configured
- [ ] DNS is configured for your domain
- [ ] TLS certificates are ready (optional but recommended)

### Application Preparation
- [ ] Docker image is built and pushed to registry
- [ ] All required secrets are prepared
- [ ] Environment-specific configurations are ready
- [ ] Database backup exists (for updates)

### Documentation Review
- [ ] Read infrastructure/README.md
- [ ] Review Kubernetes manifests
- [ ] Understand rollback procedure

## Deployment Steps

### 1. Create Namespace
```bash
kubectl apply -f infrastructure/kubernetes/namespace.yaml
```
- [ ] Namespace created successfully
- [ ] Verify: `kubectl get namespace medibot`

### 2. Apply ConfigMap
```bash
kubectl apply -f infrastructure/kubernetes/configmap.yaml
```
- [ ] ConfigMap created
- [ ] Verify: `kubectl get configmap -n medibot`
- [ ] Review configuration values

### 3. Create Secrets
```bash
kubectl apply -f infrastructure/kubernetes/secret.yaml
```
**⚠️ Update secrets before applying in production!**
- [ ] Secrets created with production values
- [ ] Verify: `kubectl get secrets -n medibot`
- [ ] Secrets are not in Git

### 4. Create Persistent Volumes
```bash
kubectl apply -f infrastructure/kubernetes/pvc.yaml
```
- [ ] PVCs created
- [ ] Verify: `kubectl get pvc -n medibot`
- [ ] PVCs are bound

### 5. Deploy Ollama
```bash
kubectl apply -f infrastructure/kubernetes/ollama-deployment.yaml
```
- [ ] Ollama deployment created
- [ ] Verify: `kubectl get pods -n medibot -l app=ollama`
- [ ] Wait for pod to be running
- [ ] Check logs: `kubectl logs -n medibot -l app=ollama`
- [ ] Model is downloaded (may take 5-10 minutes)

### 6. Deploy Application
```bash
kubectl apply -f infrastructure/kubernetes/deployment.yaml
```
- [ ] Application deployment created
- [ ] Verify: `kubectl get pods -n medibot -l app=medibot`
- [ ] Wait for pods to be running
- [ ] Check logs: `kubectl logs -n medibot -l app=medibot`

### 7. Create Services
```bash
kubectl apply -f infrastructure/kubernetes/service.yaml
```
- [ ] Services created
- [ ] Verify: `kubectl get svc -n medibot`
- [ ] Check endpoints: `kubectl get endpoints -n medibot`

### 8. Configure Ingress
```bash
kubectl apply -f infrastructure/kubernetes/ingress.yaml
```
- [ ] Update domain name in ingress.yaml
- [ ] Ingress created
- [ ] Verify: `kubectl get ingress -n medibot`
- [ ] DNS points to ingress IP/hostname

### 9. Enable Auto-Scaling (Optional)
```bash
kubectl apply -f infrastructure/kubernetes/hpa.yaml
```
- [ ] HPA created
- [ ] Verify: `kubectl get hpa -n medibot`
- [ ] Metrics server is running

## Post-Deployment Verification

### Health Checks
- [ ] Application health endpoint responds
  ```bash
  kubectl exec -n medibot <pod-name> -- curl http://localhost:8000/health
  ```
- [ ] External access works (if ingress configured)
  ```bash
  curl https://medibot.yourdomain.com/health
  ```

### Functionality Tests
- [ ] Can access login page
- [ ] Can create user account
- [ ] Can start chat session
- [ ] Ollama responds to queries
- [ ] Database persists data
- [ ] File uploads work (if applicable)

### Monitoring Setup
- [ ] Pod logs are accessible
- [ ] Resource metrics are available
- [ ] Alerts are configured (if using monitoring)
- [ ] HPA is functioning correctly

### Security Verification
- [ ] Secrets are not exposed
- [ ] TLS is enabled (if configured)
- [ ] RBAC is properly configured
- [ ] Network policies work (if configured)

## Rollback Plan

### If Issues Occur
1. [ ] Document the issue
2. [ ] Check logs: `kubectl logs -n medibot -l app=medibot`
3. [ ] Check events: `kubectl get events -n medibot --sort-by='.lastTimestamp'`
4. [ ] Decide: Fix forward or rollback?

### Rollback Procedure
```bash
# Rollback deployment
kubectl rollout undo deployment/medibot-app -n medibot

# Verify rollback
kubectl rollout status deployment/medibot-app -n medibot

# Check previous versions
kubectl rollout history deployment/medibot-app -n medibot
```
- [ ] Rollback executed
- [ ] Application is working
- [ ] Document reason for rollback

## CI/CD Setup

### GitHub Actions Configuration
- [ ] Repository secrets are configured
  - `KUBE_CONFIG` (if using GitHub-hosted runners)
  - `REGISTRY_USERNAME` (if using private registry)
  - `REGISTRY_PASSWORD` (if using private registry)
- [ ] Workflows are enabled
- [ ] Self-hosted runner is configured (if using)
- [ ] Test workflow runs successfully

### Self-Hosted Runner (If Applicable)
- [ ] Runner machine is prepared
- [ ] Docker is installed
- [ ] kubectl is configured
- [ ] Runner is registered with GitHub
- [ ] Runner service is running
- [ ] Runner can access Kubernetes cluster

## Documentation

- [ ] Update README with deployment details
- [ ] Document environment-specific configurations
- [ ] Create runbook for common operations
- [ ] Document troubleshooting steps
- [ ] Share access credentials with team (securely)

## Team Communication

- [ ] Notify team of deployment
- [ ] Share deployment URL
- [ ] Provide access credentials
- [ ] Schedule knowledge transfer session
- [ ] Document any known issues

## Production-Specific Items

### Before Production Deploy
- [ ] Perform full testing in staging
- [ ] Run security scan
- [ ] Review resource limits
- [ ] Plan maintenance window
- [ ] Notify stakeholders
- [ ] Prepare rollback plan
- [ ] Backup existing data

### Production Deployment
- [ ] Deploy during maintenance window
- [ ] Monitor deployment closely
- [ ] Verify all functionality
- [ ] Check performance metrics
- [ ] Monitor for errors
- [ ] Keep team on standby

### After Production Deploy
- [ ] Monitor for 24 hours
- [ ] Verify backups are working
- [ ] Update documentation
- [ ] Conduct post-deployment review
- [ ] Document lessons learned

## Ongoing Maintenance

### Daily
- [ ] Check application logs
- [ ] Monitor error rates
- [ ] Verify backups

### Weekly
- [ ] Review resource usage
- [ ] Check for updates
- [ ] Review security alerts

### Monthly
- [ ] Update dependencies
- [ ] Review and rotate secrets
- [ ] Performance optimization review
- [ ] Disaster recovery test

## Sign-Off

### Deployed By
- Name: _______________
- Date: _______________
- Environment: _______________
- Version/Tag: _______________

### Verified By
- Name: _______________
- Date: _______________
- Signature: _______________

### Notes
```
[Add any deployment-specific notes here]
```

---

## Quick Commands Reference

```bash
# View all resources
kubectl get all -n medibot

# Check deployment status
kubectl rollout status deployment/medibot-app -n medibot

# View logs
kubectl logs -n medibot -l app=medibot --tail=100 -f

# Restart deployment
kubectl rollout restart deployment/medibot-app -n medibot

# Scale manually
kubectl scale deployment/medibot-app --replicas=3 -n medibot

# Delete everything
kubectl delete namespace medibot
```
