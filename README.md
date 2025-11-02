# 🏥 Medical Llama - AI Health Assistant

A comprehensive AI-powered medical chatbot system that provides conversational health triage, symptom assessment, doctor appointment booking, and medical history tracking.

![Medical Llama](https://img.shields.io/badge/AI-Medical%20Assistant-blue)
![Python](https://img.shields.io/badge/Python-3.8%2B-green)
![FastAPI](https://img.shields.io/badge/FastAPI-0.104-teal)
![LangChain](https://img.shields.io/badge/LangChain-0.0.350-orange)

## ✨ Features

### 🤖 AI-Powered Conversational Triage
- Multi-turn intelligent conversations about symptoms
- Emergency detection with instant 000 call simulation  
- Severity assessment (Emergency, Urgent, Routine)
- Personalized medical guidance and recommendations

### 📅 Doctor Appointment Booking
- Browse nearby hospitals and clinics (5 seeded hospitals in Sydney)
- View available doctors with specializations (12 doctors across specialties)
- Select date and time slots based on doctor availability
- Automatic appointment confirmations
- Real-time notifications

### 🔔 Smart Notifications
- Appointment booking confirmations (immediate)
- 1-day reminder before appointment
- 1-hour reminder before appointment
- Real-time notification updates on dashboard

### 📋 Medical History Management
- Complete consultation history
- Symptom tracking over time
- Diagnosis records with confidence levels
- Medication history
- Download records as TXT or PDF

### 📱 Modern User Interface
- ChatGPT-style conversational interface
- Responsive design for all devices
- Sidebar chat history
- Intuitive 4-step appointment booking flow
- Beautiful gradient themes

### 🎙️ Media Upload Support
- Image uploads (X-rays, photos)
- Document uploads (medical reports)
- Voice recording for symptom description

### 🔐 User Authentication
- Secure signup and login system
- Password hashing with SHA-256
- Session management with tokens
- Per-user data isolation

## � Container & Kubernetes Ready

MediBot is fully containerized and production-ready with:
- **Docker**: Multi-stage Dockerfile for optimized images
- **Docker Compose**: Local development environment with all services
- **Kubernetes**: Complete K8s manifests for production deployment
- **Helm Charts**: Package manager for easy deployment and upgrades
- **CI/CD**: GitHub Actions workflows for automated builds and deployments
- **Auto-scaling**: Horizontal Pod Autoscaler for handling variable load
- **Self-hosted Runners**: Support for building on your infrastructure

See the [`infrastructure/`](./infrastructure/) directory for complete deployment documentation.

## �🛠️ Technology Stack

- **Backend**: FastAPI, Python 3.8+
- **AI/LLM**: Mistral 7B Instruct via Ollama
- **Orchestration**: LangChain, LangGraph state machines
- **Database**: SQLite with SQLAlchemy ORM
- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Authentication**: Email/password with token-based sessions

---

## Comprehensiveness of functions, features, and testing

Feature coverage (implemented endpoints and flows):

- Authentication: signup/login endpoints (`/auth/signup`, `/auth/login`) in `main.py`.
- Patient management: register, get, and update patient profiles (`/patients/*`).
- Conversational triage: `/chat/triage` accepts messages + media and returns a structured triage outcome.
- Medical history: `/users/{user_id}/medical-history` and `/consultations/save` for storing consultations.
- Appointments: hospitals list, doctors list, book/cancel appointments, reminders background task.
- Notifications: user notifications endpoints.

Testing and verification:
- Unit / integration helpers: `test_workflow.py` exercises the workflow start-to-finish (note: it expects an Ollama model running for live LLM calls).
- API checks & quick script: `quick_test.py` and `test_api.py` show simple health checks and sample triage calls.

Edge cases handled in code:
- Missing or invalid patient — `404` responses and appropriate checks.
- LLM JSON parsing errors — fallbacks that ask clarifying questions instead of returning dangerous assertions.
- Emergency detection via keyword matching (immediate escalation) — reduces risk of incorrect triage for clear emergencies.
- Media processing: `chat/triage` accepts media attachments and includes metadata in stored interactions.

Limitations & verification notes:
- Real clinical validation is required before any production deployment. This project is a prototype for decision support and triage only.
- The LLM is not an approved medical device; the system includes multiple disclaimers and escalation paths to clinicians.

---

## Incorporation of advanced technologies

This project intentionally integrates multiple modern technologies to maximize performance, scalability, maintainability, and safety. The following are the primary technologies used and how they contribute to the system:

- FastAPI — production-grade ASGI web framework used for the REST API (`main.py`). FastAPI provides automatic OpenAPI docs, async-friendly performance, and strong typing via Pydantic.
- SQLAlchemy (ORM) + SQLite — robust persistence layer (`database.py`) for patient profiles, consultations, interactions, and events. SQLAlchemy provides maintainable models and migrations-ready patterns.
- Ollama via LangChain (`langchain_ollama`) — local LLM serving that keeps inference on-prem or on local hardware, improving privacy and reducing inference network latency compared to remote APIs. Implemented in `llm_wrapper.py`.
- Langraph workflow engine — explicit state-graph orchestration for multi-step medical reasoning (triage → pathway → action → finalize) in `workflow.py`. This enables easy testing and deterministic routing.
- LangChain (and prompt engineering) — structured system prompts (see `config.py`) and a few-shot approach to improve the reliability of LLM outputs and make them parseable (JSON responses expected by the service).
- Frontend single-file UIs (HTML/CSS/Vanilla JS) — lightweight, dependency-free client pages: `chat_ui.html`, `medical_history.html`, `auth.html`. They provide UX features such as media upload, appointment booking UI, and an emergency modal.
- Safety & validation utilities — explicit emergency keyword detection, confidence thresholds (see `config.py`), and fallback JSON parsing with safeties in `llm_wrapper.py` to reduce hallucination risk.

Measured / observed effects (from project test comments and in-code notes):
- First LLM inference: ~5–10s (model load to VRAM) — noted in `test_workflow.py` and `test_workflow` prints. Subsequent inferences are faster once the model is warmed.
- Emergency detection short-circuits expensive prompts and immediately returns high-confidence escalations (instant on-match), reducing average triage latency for clear emergencies.

Notes about data provenance and assumptions:
- Performance numbers and the "5–10s" inference note come from the project's test files (comments in `test_workflow.py` and `quick_test.py`). If you want precise latency numbers for your hardware, run `quick_test.py` and collect timing metrics.

---

## LLM-based Agent: Perception, Decision-making, and Interaction

This project uses an LLM-centered agent broken into three functional responsibilities. The implementation is in `llm_wrapper.py` and orchestrated by `workflow.py` and `main.py`.

Perception (input stage):
- Inputs accepted: free-text patient message, optional media (images, audio, files), and recent conversation history (last 5 interactions). The chat UI attaches media and the API stores a short media summary.
- Emergency keyword detection: `EMERGENCY_KEYWORDS` in `config.py` are checked in `MedicalLLMWrapper._check_emergency_keywords()` for immediate escalation (low-latency decision path).

Decision-making (reasoning / policy stage):
- Conversational triage: `perform_triage()` constructs a JSON-instruction prompt for the LLM to either ask targeted follow-up questions or provide a full assessment with severity, reasoning, suggested actions, and confidence.
- Care pathway selection: `recommend_care_pathway()` uses a separate system prompt to map triage to structured care pathways (`CARE_PATHWAY_SYSTEM_PROMPT` in `config.py`).
- Execution plan: `execute_action()` generates concrete action steps (book appointment, call emergency services, OTC suggestions) based on the care pathway.
- Confidence and escalation policy: `CONFIDENCE_THRESHOLD` in `config.py` determines whether low-confidence cases are escalated to a clinician. Langraph routes low-confidence or emergency cases to the `escalate` node.

Interaction (output / dialog stage):
- JSON-first responses: the LLM is asked to return structured JSON so downstream code can parse and present consistent information to the user. Parsing fallback is implemented to handle malformed outputs.
- Safety & disclaimers: each finalized action plan includes a medical disclaimer (see `workflow._node_finalize`) and `llm_wrapper.validate_response()` contains heuristics for detecting risky diagnosis language.

Benefits observed in the codebase:
- Deterministic routing: by separating triage, pathway, and action into nodes, the system improves traceability and makes it easier to test each step independently.
- Fall-back and safety: emergency keywords short-circuit prompts for instant escalation; parsing fallbacks ensure the system asks clarifying questions instead of returning potentially unsafe or misleading diagnostics.

---

## Agile development experience 

The project followed an Agile Scrum methodology to enable iterative development, rapid prototyping, and continuous improvement. The work was divided into three sprints under Stage 2, each lasting one week, focusing on progressively building and refining system functionality.

**Sprint 1 (Week 10: Oct 13 – Oct 19)**

Goal: Establish project foundations and implement proof-of-concept functionalities.
Key Deliverables:

Frontend project setup (web/mobile) and repository workflow

Initial LLM triage pipeline and care flow integration

Session and case management (frontend)

Multimodal input handling (text/audio/image)

Emergency escalation design

Coding framework, tooling, and CI/CD workflow setup

✅ Outcome: All foundational components were successfully completed, ensuring project readiness for full-stack integration.

**Sprint 2 (Week 11: Oct 20 – Oct 26)**

Goal: Implement and test the full end-to-end care flow pipeline.
Key Deliverables:

Reminder & follow-up engine

Emergency escalation workflow (EMS API)

Summary generation and export (PDF)

Safety guardrails for reasoning

Core AI agent logic implementation

🧩 Outcome: Completed all backend workflows and integrated safety and persistence features, preparing for deployment.

**Sprint 3 (Week 12: Oct 27 – Nov 2)**

Goal: System hardening and deployment for final demo.
Key Deliverables:

Backend integration with AI agent and LLM alignment

Containerisation using Docker & CI/CD (GitHub Actions)

Logging, observability, and performance optimisation

Final UI/UX polish and LLM refinement

Application deployment and hosting for prototype demonstration

🚀 Outcome: Finalised and deployed a fully functional prototype with improved reliability, usability, and maintainability.


Overall Agile Outcome:
The iterative sprint-based approach enabled continuous integration, regular testing, and frequent team reviews. This structure allowed the team to adapt quickly to new requirements, ensure feature completeness, and deliver a stable, production-ready healthcare assistant prototype.

---

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

1. **Python 3.8 or higher**
   - Download from: https://www.python.org/downloads/
   - Verify: `python --version`

2. **Ollama** (for running local LLM)
   - Download from: https://ollama.ai/download
   - Verify: `ollama --version`

## 🚀 Installation & Setup (Step-by-Step)

### Step 1: Navigate to Project Folder

### Step 2: Install Python Dependencies

```powershell
# Install all required packages
pip install -r requirements.txt
```

**What gets installed:**
- `fastapi` - Web framework
- `uvicorn` - ASGI server
- `sqlalchemy` - Database ORM
- `pydantic` - Data validation
- `email-validator` - Email validation
- `langchain` - LLM orchestration
- `langchain-community` - LangChain integrations
- `langgraph` - Workflow state machines
- `python-multipart` - File upload support
- `python-dotenv` - Environment variables
- `aiofiles` - Async file operations
- `requests` - HTTP library

### Step 3: Install and Setup Ollama

#### 3.1 Download Ollama

Visit **https://ollama.ai/download** and download the installer for Windows.

Run the installer - it will:
- Install Ollama
- Start Ollama service automatically
- Add Ollama to your system PATH

#### 3.2 Pull the Mistral Model

Open a new terminal/PowerShell window and run:

```powershell
ollama pull mistral:7b-instruct
```

This downloads the Mistral 7B Instruct model (~4.1GB). Wait for completion:
```
pulling manifest
pulling 61e88e884507... 100% ▕████████████████▏ 4.1 GB
pulling 43070e2d4e53... 100% ▕████████████████▏  11 KB
pulling e6836092461f... 100% ▕████████████████▏   42 B
pulling ed11eda7790d... 100% ▕████████████████▏   30 B
pulling f9b1e3196ecf... 100% ▕████████████████▏  483 B
verifying sha256 digest
writing manifest
removing any unused layers
success
```

#### 3.3 Verify Ollama is Running

```powershell
ollama list
```

Expected output:
```
NAME            ID              SIZE      MODIFIED
mistral:latest  61e88e884507    4.1 GB    2 minutes ago
```

### Step 4: Initialize the Database

Run the seed script to populate with sample hospitals and doctors:

```powershell
python seed_data.py
```

Expected output:
```
Seeding database with sample hospitals and doctors...
✅ Successfully seeded 5 hospitals and 12 doctors!
```

**What gets seeded:**

**5 Hospitals in Sydney:**
1. Sydney General Hospital (2.5km away)
2. Royal North Shore Hospital (5.2km)
3. Westmead Hospital (8.1km)
4. Prince of Wales Hospital (6.8km)
5. Liverpool Hospital (12.3km)

**12 Doctors across specialties:**
- General Medicine (5 doctors)
- Cardiology (2 doctors)
- Pediatrics (1 doctor)
- Neurology (1 doctor)
- Orthopedics (1 doctor)
- Oncology (1 doctor)
- Dermatology (1 doctor)

### Step 5: Start the Application Server

```powershell
python main.py
```

Expected output:
```
============================================================
🏥 Medical Llama - AI Health Assistant
============================================================

🚀 Server starting...

📍 Access the application at:
   http://localhost:8000

📄 Available pages:
   • Login/Signup:     http://localhost:8000/
   • Dashboard:        http://localhost:8000/dashboard
   • Chat:             http://localhost:8000/chat
   • Medical History:  http://localhost:8000/history

🔧 API Documentation:
   http://localhost:8000/docs

============================================================
```

### Step 6: Access the Application

1. Open your web browser
2. Navigate to: **http://localhost:8000**
3. Create a new account (Sign Up)
4. Start using Medical Llama!

## 📖 Complete User Guide

### Creating an Account

1. Click "Sign Up" tab
2. Fill in the form:
   - Email
   - Password  
   - First Name
   - Last Name
   - Age
   - Gender
3. Click "Create Account"
4. Automatically redirected to dashboard

### Using the Chat Interface

1. Click "Start Consultation" on dashboard
2. Type your symptoms
3. Answer AI's follow-up questions
4. Receive severity assessment and recommendations

### Booking Appointments

When severity is "Urgent":
1. Click "📅 Book Doctor Appointment" button
2. **Step 1**: Select a hospital
3. **Step 2**: Choose a doctor
4. **Step 3**: Pick date and time
5. **Step 4**: Confirm booking

### Viewing Appointments & Notifications

On dashboard you'll see:
- **Upcoming Appointments** - All scheduled visits
- **Notifications** - Booking confirmations and reminders

### Downloading Records

**In Chat:**
- Click "📄 Download TXT" for plain text
- Click "📑 Download PDF" for formatted document

**In Medical History:**
- Click "Download All as TXT"
- Click "Download All as PDF"

## 🐛 Troubleshooting

### "Cannot connect to Ollama"

```powershell
# Check if Ollama is running
ollama list

# Start Ollama if needed
ollama serve

# Pull model again
ollama pull mistral
```

### "Failed to load hospitals"

```powershell
# Reseed the database
python seed_data.py

# Restart server
python main.py
```

### "ModuleNotFoundError"

```powershell
# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Reinstall dependencies
pip install -r requirements.txt
```

### "Port 8000 already in use"

```powershell
# Find and kill process using port 8000
netstat -ano | findstr :8000
taskkill /PID <PID> /F
```

## ⚠️ Medical Disclaimer

**IMPORTANT**: This application is for **EDUCATIONAL AND DEMONSTRATION PURPOSES ONLY**.

- ❌ NOT a substitute for professional medical advice
- ❌ NOT intended to diagnose, treat, cure, or prevent disease
- ❌ NOT a replacement for qualified healthcare providers
- ✅ Always seek advice from qualified healthcare professionals
- ✅ In a real emergency, call 000 (Australia) or your local emergency number

## 🔒 Security Notes

This is a **demonstration/educational project**:
- NOT intended for real medical use
- Passwords hashed with SHA-256 (use bcrypt for production)
- No HTTPS encryption in development mode
- Simple session tokens (use JWT for production)

## 📁 Project Structure

```
try again/
├── main.py                 # FastAPI application
├── database.py            # Database models
├── workflow.py            # LangGraph workflow
├── config.py              # Configuration
├── seed_data.py           # Database seeding
├── requirements.txt       # Dependencies
├── medical_llama.db       # SQLite database (auto-created)
├── auth.html              # Login/Signup page
├── dashboard.html         # Dashboard
├── chat_ui.html           # Chat interface
└── medical_history.html   # Medical records
```

## 🎓 API Documentation

Once the server is running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## 🎉 Quick Start Checklist

- [ ] Python 3.8+ installed
- [ ] Ollama installed and running
- [ ] Mistral model pulled (`ollama pull mistral`)
- [ ] Dependencies installed (`pip install -r requirements.txt`)
- [ ] Database seeded (`python seed_data.py`)
- [ ] Server started (`python main.py`)
- [ ] Browser opened to http://localhost:8000
- [ ] Account created
- [ ] First consultation completed
- [ ] Appointment booked
- [ ] Notifications received

## 🚀 Deployment & Production

### Docker Deployment

#### Local Development with Docker Compose
```bash
# Clone the repository
git clone https://github.com/yathanshnagar/MediBot_Final.git
cd MediBot_Final

# Start all services
docker-compose up --build

# Access the application
# App: http://localhost:8000
# Ollama: http://localhost:11434
```

#### Build Docker Image
```bash
# Build the image
docker build -t medibot:latest .

# Run the container
docker run -p 8000:8000 medibot:latest
```

### Kubernetes Deployment

#### Prerequisites
- Kubernetes cluster (v1.24+)
- kubectl configured
- Ingress controller installed

#### Quick Deploy
```bash
# Deploy all resources
./infrastructure/deploy.sh deploy

# Check status
./infrastructure/deploy.sh status

# View logs
./infrastructure/deploy.sh logs
```

#### Manual Deploy
```bash
# Apply all manifests
kubectl apply -f infrastructure/kubernetes/

# Verify deployment
kubectl get all -n medibot

# Port forward for local access
kubectl port-forward -n medibot svc/medibot-service 8000:8000
```

#### Using Helm
```bash
# Install with Helm
helm install medibot ./infrastructure/helm \
  --namespace medibot \
  --create-namespace

# Upgrade
helm upgrade medibot ./infrastructure/helm

# Uninstall
helm uninstall medibot --namespace medibot
```

### CI/CD with GitHub Actions

The project includes three GitHub Actions workflows:

1. **CI/CD Pipeline** (`ci-cd.yml`)
   - Automated testing and linting
   - Docker image build and push
   - Security scanning with Trivy
   - Kubernetes deployment
   - Triggered on push to main/develop

2. **Self-Hosted Runner Build** (`self-hosted-build.yml`)
   - Build on your infrastructure
   - Direct kubectl access
   - Manual trigger for staging/production

3. **Manual Deploy** (`manual-deploy.yml`)
   - Deploy specific image tags
   - Environment selection (staging/production)

#### Setup GitHub Actions

1. **Add repository secrets:**
   ```
   Settings → Secrets and variables → Actions
   ```
   - `KUBE_CONFIG`: Base64 encoded kubeconfig
   - `REGISTRY_USERNAME`: Container registry username
   - `REGISTRY_PASSWORD`: Container registry password

2. **Enable workflows:**
   - Push code to trigger automatic deployment
   - Use workflow dispatch for manual deployments

3. **Self-hosted runner (optional):**
   See [`infrastructure/SELF_HOSTED_RUNNER.md`](./infrastructure/SELF_HOSTED_RUNNER.md) for setup instructions.

### Production Checklist

Before deploying to production:

- [ ] Update secrets in `infrastructure/kubernetes/secret.yaml`
- [ ] Configure domain in `infrastructure/kubernetes/ingress.yaml`
- [ ] Set resource limits appropriately
- [ ] Enable TLS/SSL certificates
- [ ] Configure backup strategy
- [ ] Set up monitoring and alerting
- [ ] Test disaster recovery procedures
- [ ] Review security settings
- [ ] Configure auto-scaling limits
- [ ] Set up log aggregation

### Infrastructure Documentation

Comprehensive documentation is available in the `infrastructure/` directory:

- **[README.md](./infrastructure/README.md)** - Complete deployment guide
- **[SELF_HOSTED_RUNNER.md](./infrastructure/SELF_HOSTED_RUNNER.md)** - GitHub Actions runner setup
- **[KUBERNETES_QUICKREF.md](./infrastructure/KUBERNETES_QUICKREF.md)** - Quick command reference
- **[DEPLOYMENT_CHECKLIST.md](./infrastructure/DEPLOYMENT_CHECKLIST.md)** - Step-by-step checklist

### Monitoring & Maintenance

#### Health Checks
```bash
# Check application health
curl http://localhost:8000/health

# In Kubernetes
kubectl get pods -n medibot
kubectl logs -n medibot -l app=medibot
```

#### Scaling
```bash
# Manual scaling
kubectl scale deployment/medibot-app --replicas=5 -n medibot

# Auto-scaling is configured via HPA
kubectl get hpa -n medibot
```

#### Updates
```bash
# Rolling update
kubectl set image deployment/medibot-app \
  medibot-app=ghcr.io/yathanshnagar/medibot:v1.1.0 \
  -n medibot

# Rollback if needed
kubectl rollout undo deployment/medibot-app -n medibot
```

### Troubleshooting Deployment

#### Docker Issues
```bash
# Check container logs
docker logs <container-id>

# Rebuild without cache
docker-compose build --no-cache
```

#### Kubernetes Issues
```bash
# Check pod status
kubectl describe pod -n medibot <pod-name>

# Check events
kubectl get events -n medibot --sort-by='.lastTimestamp'

# Test connectivity
kubectl exec -it -n medibot <pod-name> -- curl http://ollama-service:11434
```

## 🚀 Future Enhancements

- [ ] Real SMS/Email notifications (Twilio/SendGrid)
- [ ] Video consultation scheduling
- [ ] Prescription management
- [ ] Lab results integration
- [ ] Mobile app (React Native)
- [ ] Multi-language support
- [ ] Wearable device integration

## 📄 License

This project is provided as-is for educational purposes.

## 🤝 Support

For issues:
1. Check Troubleshooting section
2. Review API docs at http://localhost:8000/docs
3. Check browser console for errors (F12)
4. Review server logs in terminal

---

*Remember: This is a demonstration project. Always consult real healthcare professionals for medical advice!*

**Version:** 1.0.0  
**Last Updated:** November 2, 2025
# Medical Llama — AI Health Assistant




