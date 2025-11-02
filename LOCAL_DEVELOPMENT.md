# 🏠 Local Development Guide

## Quick Start

### Option 1: Docker Compose (Recommended)

```bash
# Start everything
docker-compose up

# Or build and start
docker-compose up --build

# Stop
docker-compose down
```

Access: http://localhost:8000

### Option 2: Local Python

```bash
# Install dependencies
pip install -r requirements.txt

# Start Ollama (in separate terminal)
ollama serve

# Pull model (first time only)
ollama pull mistral:7b-instruct

# Initialize database
python seed_data.py

# Start application
python main.py
# Or: uvicorn main:app --reload
```

Access: http://localhost:8000

## Project Structure

```
MediBot_Final/
├── 🐍 Python Application
│   ├── main.py                  # FastAPI application
│   ├── config.py                # Configuration
│   ├── database.py              # Database models
│   ├── workflow.py              # LangGraph workflow
│   ├── llm_wrapper.py           # LLM interface
│   ├── seed_data.py             # Database seeding
│   └── requirements.txt         # Dependencies
│
├── 🌐 Frontend (HTML)
│   ├── auth.html                # Login/Signup page
│   ├── dashboard.html           # User dashboard
│   ├── chat_ui.html             # Chat interface
│   └── medical_history.html     # History page
│
├── 🐳 Containerization
│   ├── Dockerfile               # Production image
│   ├── .dockerignore            # Build exclusions
│   └── docker-compose.yml       # Local dev environment
│
├── ☸️ Kubernetes & CI/CD
│   ├── .github/workflows/       # GitHub Actions
│   └── infrastructure/          # K8s manifests, Helm, docs
│
├── 🧪 Testing
│   ├── test_workflow.py         # Workflow tests
│   ├── test_api.py              # API tests
│   ├── quick_test.py            # Quick tests
│   └── test-local-setup.sh      # Setup verification
│
└── 📚 Documentation
    ├── README.md                # Main documentation
    ├── HOW_TO_USE.md            # User guide
    ├── QUICKSTART.md            # Quick start
    └── infrastructure/          # Deployment docs
```

## Development Workflow

### 1. Setup Environment

```bash
# Create virtual environment (optional but recommended)
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 2. Configure Ollama

```bash
# Check if Ollama is running
curl http://localhost:11434/api/version

# If not, start it
ollama serve

# Pull the model
ollama pull mistral:7b-instruct

# Verify
ollama list
```

### 3. Initialize Database

```bash
# Seed with sample data (hospitals, doctors)
python seed_data.py
```

### 4. Start Development Server

```bash
# With auto-reload
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Or simply
python main.py
```

### 5. Access Application

- **Application:** http://localhost:8000
- **API Docs:** http://localhost:8000/docs
- **Health Check:** http://localhost:8000/health

## Common Development Tasks

### Run Tests

```bash
# Quick API test
python quick_test.py

# Test API endpoints
python test_api.py

# Test workflow
python test_workflow.py
```

### Database Operations

```bash
# View database
sqlite3 medical_llama.db

# Common queries
sqlite3 medical_llama.db "SELECT * FROM users;"
sqlite3 medical_llama.db "SELECT * FROM consultations LIMIT 5;"

# Reset database (delete and recreate)
rm medical_llama.db
python seed_data.py
```

### Check Logs

```bash
# Application logs (if running locally)
# Check terminal output

# Docker logs
docker-compose logs -f medibot-app
docker-compose logs -f ollama
```

### Rebuild Docker Image

```bash
# Rebuild specific service
docker-compose build medibot-app

# Rebuild everything
docker-compose build --no-cache

# Remove old images
docker image prune -f
```

## Testing Before Deployment

### 1. Run Setup Test

```bash
./test-local-setup.sh
```

This checks:
- ✅ Python installation
- ✅ Required files
- ✅ Dependencies
- ✅ Docker setup
- ✅ Configuration validity

### 2. Test Docker Build

```bash
docker build -t medibot-test .
docker run -p 8000:8000 medibot-test
```

### 3. Test Docker Compose

```bash
docker-compose up
# Wait for services to start
curl http://localhost:8000/health
```

### 4. Test API Endpoints

```bash
# Health check
curl http://localhost:8000/health

# Service info
curl http://localhost:8000/info

# Create test user
curl -X POST http://localhost:8000/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "test123",
    "first_name": "Test",
    "last_name": "User",
    "age": 30,
    "gender": "male"
  }'
```

## Configuration

### Environment Variables

Create `.env` file (optional):

```env
# LLM Configuration
LLM_MODEL=mistral:7b-instruct
LLM_TEMPERATURE=0.3
LLM_MAX_TOKENS=1024
LLM_BASE_URL=http://localhost:11434

# Database
DATABASE_URL=sqlite:///./medical_llama.db

# Feature Flags
DEBUG=True
```

### Custom Configuration

Edit `config.py`:

```python
# Change model
LLM_MODEL = "llama2:7b"  # Or any Ollama model

# Adjust temperature
LLM_TEMPERATURE = 0.5  # Higher = more creative

# Change port in main.py
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
```

## Troubleshooting

### Issue: Port 8000 already in use

```bash
# Find process using port
lsof -i :8000

# Kill the process
kill -9 <PID>

# Or use different port
uvicorn main:app --port 8080
```

### Issue: Ollama not responding

```bash
# Check Ollama status
curl http://localhost:11434/api/version

# Restart Ollama
pkill ollama
ollama serve

# Verify model
ollama list
ollama pull mistral:7b-instruct
```

### Issue: Database locked

```bash
# Stop all processes using database
pkill -f main.py

# Or delete and recreate
rm medical_llama.db
python seed_data.py
```

### Issue: Import errors

```bash
# Reinstall dependencies
pip install --upgrade -r requirements.txt

# Or recreate virtual environment
rm -rf venv
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Issue: Docker build fails

```bash
# Clean Docker cache
docker system prune -af

# Rebuild without cache
docker build --no-cache -t medibot .

# Check Docker resources
docker system df
```

## Hot Reload Development

### Python Auto-Reload

```bash
# FastAPI auto-reloads on file changes
uvicorn main:app --reload
```

### Docker with Volume Mounting

Edit `docker-compose.yml`:

```yaml
services:
  medibot-app:
    volumes:
      - ./:/app  # Mount current directory
      - /app/__pycache__  # Exclude cache
    command: uvicorn main:app --reload --host 0.0.0.0
```

## Performance Tips

### 1. Use Docker Compose for Consistency

Docker Compose ensures Ollama and the app work together seamlessly.

### 2. Keep Ollama Running

Don't stop/start Ollama frequently - keep it running in background.

### 3. Pre-load Models

```bash
# Pull all needed models at once
ollama pull mistral:7b-instruct
ollama pull llama2:7b
```

### 4. Use SQLite WAL Mode

Already configured in `database.py` for better concurrent access.

### 5. Monitor Resources

```bash
# Docker stats
docker stats

# System resources
htop  # or top
```

## IDE Setup

### VS Code

Recommended extensions:
- Python
- Docker
- YAML
- Kubernetes

Settings (`.vscode/settings.json`):
```json
{
  "python.linting.enabled": true,
  "python.formatting.provider": "black",
  "editor.formatOnSave": true
}
```

### PyCharm

1. Configure Python interpreter
2. Enable FastAPI plugin
3. Set up Docker integration
4. Configure run configurations

## Git Workflow

### Before Committing

```bash
# Run tests
./test-local-setup.sh

# Test locally
docker-compose up

# Format code (optional)
black .
isort .
```

### Commit Message Format

```
type(scope): description

feat(api): add new endpoint for appointments
fix(docker): correct Ollama connection
docs(readme): update setup instructions
```

### Branch Strategy

- `main` - Production ready
- `develop` - Development branch
- `feature/*` - New features
- `fix/*` - Bug fixes

## Next Steps

After local testing:

1. **Test all features:**
   - User signup/login
   - Chat interface
   - Appointment booking
   - Medical history

2. **Deploy to staging:**
   - Use Kubernetes manifests
   - Test in staging environment

3. **Set up CI/CD:**
   - Configure GitHub Actions
   - Automated testing and deployment

4. **Production deployment:**
   - Follow deployment checklist
   - Monitor performance

## Useful Commands Cheat Sheet

```bash
# Application
python main.py                          # Start app
uvicorn main:app --reload               # With auto-reload
python seed_data.py                     # Seed database

# Docker
docker-compose up                       # Start services
docker-compose up --build               # Rebuild and start
docker-compose down                     # Stop services
docker-compose logs -f                  # View logs
docker-compose ps                       # List services

# Testing
./test-local-setup.sh                   # Verify setup
python quick_test.py                    # Quick tests
curl http://localhost:8000/health       # Health check

# Ollama
ollama serve                            # Start Ollama
ollama pull mistral:7b-instruct        # Pull model
ollama list                             # List models
curl http://localhost:11434/api/version # Check version

# Database
sqlite3 medical_llama.db                # Open database
python seed_data.py                     # Reseed database
rm medical_llama.db && python seed_data.py  # Reset

# Git
git status                              # Check status
git add .                               # Stage changes
git commit -m "message"                 # Commit
git push origin branch-name             # Push
```

## Support

For issues:
1. Check this guide
2. Run `./test-local-setup.sh`
3. Check logs
4. Review troubleshooting section
5. Check documentation in `infrastructure/`

---

**Happy coding! 🚀**
