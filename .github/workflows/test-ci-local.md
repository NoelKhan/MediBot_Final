# Testing CI/CD Locally

This guide helps you test the GitHub Actions workflows locally before pushing to GitHub.

## Prerequisites

Install `act` to run GitHub Actions locally:

```bash
# macOS
brew install act

# Or download from: https://github.com/nektos/act
```

## Quick Start

### 1. List Available Workflows

```bash
act -l
```

### 2. Run the Test Job Only

```bash
act push -j test
```

### 3. Run the Full CI/CD Pipeline

```bash
act push
```

### 4. Test a Specific Workflow

```bash
# Test CI/CD workflow
act -W .github/workflows/ci-cd.yml

# Test manual deploy
act workflow_dispatch -W .github/workflows/manual-deploy.yml
```

## Common Issues & Solutions

### Issue: Docker in Docker

If you get Docker socket errors:

```bash
act push -j test --container-architecture linux/amd64
```

### Issue: Missing Secrets

Create a `.secrets` file:

```bash
GITHUB_TOKEN=your_token_here
```

Then run:

```bash
act push --secret-file .secrets
```

### Issue: Platform Architecture

```bash
act push --container-architecture linux/amd64
```

## What Gets Tested

- ✅ Python setup and dependency installation
- ✅ Code formatting (black, isort)
- ✅ Linting (flake8)
- ✅ Unit tests (pytest)
- ✅ Docker image build
- ✅ Container registry push (simulated)

## Tips

1. **Test specific job**: `act push -j build`
2. **Dry run**: `act push -n`
3. **Verbose output**: `act push -v`
4. **Use host Docker**: `act push --bind`

## Quick Validation Checklist

Before pushing to GitHub:

- [ ] Docker build succeeds locally
- [ ] Docker Compose stack runs
- [ ] Health endpoint responds
- [ ] Tests pass with act
- [ ] Kubernetes manifests validate
- [ ] Helm chart lints successfully

## Real GitHub Actions

Once you push, monitor at:
```
https://github.com/yathanshnagar/MediBot_Final/actions
```
