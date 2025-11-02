# 🚀 Quick Start: Test Everything Locally

## Super Quick (30 seconds)

```bash
make help
```

## Start Here (2 minutes)

1. **Make sure Docker is running:**
   ```bash
   open -a Docker
   # Wait 30 seconds for Docker Desktop to start
   ```

2. **Run quick validation:**
   ```bash
   make validate
   ```

3. **Build and test:**
   ```bash
   make quick
   ```

## Available Make Commands

| Command | What It Does | Time |
|---------|-------------|------|
| `make validate` | Check configs without Docker | 30s |
| `make quick` | Build & run quick test | 2min |
| `make build` | Build Docker image only | 2min |
| `make run` | Start full stack (Docker Compose) | 1min |
| `make stop` | Stop all services | 10s |
| `make logs` | View service logs | - |
| `make clean` | Clean up Docker | 30s |
| `make pre-push` | Validate before git push | 3min |
| `make dev` | Full dev environment | 5min |
| `make ci-test` | Test GitHub Actions locally | 5min |

## Testing Workflows

### Option 1: Using Make (Recommended)
```bash
make help              # See all commands
make validate         # Quick validation
make quick            # Quick Docker test
make run              # Start services
make logs             # View logs
make stop             # Stop everything
```

### Option 2: Using Scripts
```bash
./validate-before-push.sh    # Validate everything
./quick-docker-test.sh       # Quick Docker test
./test-local.sh              # Interactive test menu
```

### Option 3: Manual Docker
```bash
# Build
docker build -t medibot:local .

# Run
docker compose up -d

# Stop
docker compose down
```

## Test GitHub Actions Locally

1. **Install act:**
   ```bash
   brew install act
   ```

2. **Run CI tests:**
   ```bash
   act push -j test
   # or use: make ci-test
   ```

## Before Pushing to GitHub

```bash
make pre-push
```

This will:
- ✅ Validate all configs
- ✅ Build Docker image
- ✅ Check for errors

Then:
```bash
git add .
git commit -m "Your changes"
git push
```

## Monitor GitHub Actions

After pushing, check: https://github.com/yathanshnagar/MediBot_Final/actions

## Troubleshooting

### Docker not running?
```bash
open -a Docker
# Wait 30 seconds
docker ps  # Should work now
```

### Port 8000 already in use?
```bash
make stop
# or
kill -9 $(lsof -ti:8000)
```

### Something broken?
```bash
make clean    # Clean everything
make dev      # Fresh start
```

## Quick Reference

**Just want to test if it builds?**
```bash
make build
```

**Want to run the full app?**
```bash
make run
curl http://localhost:8000/health
open http://localhost:8000/docs
```

**Ready to push to GitHub?**
```bash
make pre-push
git push
```

**Need to clean up?**
```bash
make stop && make clean
```

## Files Created for Testing

- `Makefile` - Quick make commands
- `validate-before-push.sh` - Pre-commit validation
- `quick-docker-test.sh` - Fast Docker test
- `test-local.sh` - Interactive test suite
- `TESTING-GUIDE.md` - Detailed testing guide
- `.github/workflows/test-ci-local.md` - GitHub Actions testing guide

## Next Steps

1. ✅ Test locally with `make quick`
2. ✅ If everything works, run `make pre-push`
3. ✅ Push to GitHub with `git push`
4. ✅ Monitor at https://github.com/yathanshnagar/MediBot_Final/actions
5. ✅ Docker images will be pushed to `ghcr.io/yathanshnagar/medibot_final`

## Tips

- Use `make` commands for speed
- Run `make validate` before every push
- Use `make dev` for development
- Run `make clean` to free up space
- Check `make help` for all commands

🎉 That's it! You're ready to test and deploy MediBot!
