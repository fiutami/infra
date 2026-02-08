# Fiutami Organization - Technical Documentation

> Comprehensive documentation for the Fiutami pet care platform - repositories, architecture, deployment, and infrastructure.

**Version:** 1.0.0
**Last Updated:** December 2025
**Organization:** [github.com/fiutami](https://github.com/fiutami)

---

## Table of Contents

1. [Organization Overview](#organization-overview)
2. [Repository Structure](#repository-structure)
3. [Architecture](#architecture)
4. [Infrastructure](#infrastructure)
5. [Deployment](#deployment)
6. [CI/CD Pipelines](#cicd-pipelines)
7. [Environment URLs](#environment-urls)
8. [Development Workflow](#development-workflow)
9. [Troubleshooting](#troubleshooting)

---

## Organization Overview

**Fiutami** is a comprehensive pet care management platform built with modern web technologies. The platform consists of a user-facing Angular PWA, a .NET 8 API backend, and a Directus-based backoffice CMS for content management.

### Tech Stack Summary

| Component | Technology | Version |
|-----------|-----------|---------|
| Frontend | Angular | 18.0.0 |
| Backend API | .NET | 8.0 |
| Backoffice CMS | Directus | 10.10 |
| Database | SQL Server | 2022 Express |
| Web Server | Nginx | (via Nginx Proxy Manager) |
| Containerization | Docker | Docker Compose |
| CI/CD | GitHub Actions | - |
| Hosting | Hetzner Cloud | 116.203.127.208 |

### Key Features

- User authentication (JWT + OAuth2: Google, Facebook)
- Pet profile management
- Notification system
- Multi-language support (i18n)
- PWA capabilities (offline-first)
- Responsive design (mobile-first)
- Comprehensive backoffice with custom extensions
- Automated deployment pipelines

---

## Repository Structure

The Fiutami organization consists of 4 core repositories:

### 1. [fiutami/frontend](https://github.com/fiutami/frontend)

**Description:** Angular 18 Progressive Web Application (PWA) for end users.

**Tech Stack:**
- Angular 18 with standalone components
- Angular Signals for state management
- SCSS custom design system
- @ngx-translate for internationalization
- Playwright for E2E testing
- Service Worker for PWA capabilities

**Key Directories:**
```
frontend/
├── src/
│   ├── app/
│   │   ├── core/              # Guards, interceptors, services
│   │   ├── shared/            # Reusable components
│   │   ├── features/
│   │   │   ├── auth/          # Login, register, OAuth
│   │   │   ├── user/          # Dashboard, profile, settings
│   │   │   └── pet/           # Pet management
│   │   └── app.routes.ts      # Application routing
│   ├── styles/                # Global SCSS, design tokens
│   ├── assets/                # Images, icons, i18n files
│   └── environments/          # Environment configs
├── e2e/                       # Playwright E2E tests
├── .claude/                   # Claude AI integration
└── nginx.conf                 # Production web server config
```

**Scripts:**
```bash
npm start                      # Dev server (port 4200)
npm run build:prod             # Production build
npm run test                   # Unit tests (Jasmine)
npm run e2e                    # E2E tests (Playwright)
npm run lint                   # ESLint
```

**Docker:**
- Base image: `nginx:alpine`
- Production port: `80` (exposed as `8080` on host for prod, `8082` for stage)
- Health check: `wget http://localhost/health`

---

### 2. [fiutami/backend](https://github.com/fiutami/backend)

**Description:** .NET 8 RESTful API providing authentication, pet management, and business logic.

**Tech Stack:**
- .NET 8 (C#)
- Entity Framework Core
- SQL Server 2022
- JWT + BCrypt authentication
- Swagger/OpenAPI documentation

**Key Projects:**
```
backend/
├── src/
│   ├── Fiutami.API/           # Web API layer
│   │   ├── Controllers/       # REST endpoints
│   │   ├── Services/          # Business logic services
│   │   ├── Middleware/        # Custom middleware (auth, errors)
│   │   └── Program.cs         # App configuration
│   ├── Fiutami.Core/          # Domain layer
│   │   ├── Entities/          # Domain models (User, Pet, etc.)
│   │   └── Interfaces/        # Repository contracts
│   └── Fiutami.Infrastructure/ # Data layer
│       ├── Data/              # DbContext, migrations
│       └── Repositories/      # Data access implementations
├── tests/                     # Unit + Integration tests
└── Fiutami.sln                # Solution file
```

**API Endpoints:**
- `/api/auth` - Authentication (login, register, refresh token)
- `/api/users` - User profile management
- `/api/pets` - Pet CRUD operations
- `/api/notifications` - User notifications
- `/health` - Health check endpoint

**Scripts:**
```bash
dotnet restore                 # Restore dependencies
dotnet ef database update      # Run migrations
dotnet run --project src/Fiutami.API  # Start API (port 5000)
dotnet test                    # Run tests
```

**Docker:**
- Base image: `mcr.microsoft.com/dotnet/aspnet:8.0`
- Production port: `5000` (exposed as `5000` for prod, `5001` for stage)
- Environment: `ASPNETCORE_ENVIRONMENT=Production`
- Health check: `curl http://localhost:5000/health`

---

### 3. [fiutami/backoffice](https://github.com/fiutami/backoffice)

**Description:** Directus 10.10 headless CMS with 8 custom extensions for content management and admin operations.

**Tech Stack:**
- Directus 10.10 (Node.js CMS)
- Custom TypeScript extensions
- SQL Server backend
- Custom theme

**Extensions (8 total):**
1. **analytics** - Dashboard analytics and metrics
2. **user-actions** - User management operations
3. **pets** - Pet management interface
4. **species** - Pet species catalog management
5. **notifications** - Notification system admin
6. **cms** - Content management utilities
7. **support-tickets** - Customer support ticketing
8. **fiutami-theme** - Custom Directus UI theme

**Key Directories:**
```
backoffice/
├── extensions/
│   ├── analytics/             # Endpoint + panel
│   ├── user-actions/          # Endpoint + interface
│   ├── pets/                  # Endpoint + interface
│   ├── species/               # Endpoint + interface
│   ├── notifications/         # Endpoint + hooks
│   ├── cms/                   # Endpoint
│   ├── support-tickets/       # Endpoint + interface
│   └── fiutami-theme/         # Theme extension
├── snapshots/                 # Schema snapshots
├── assets/                    # Custom assets (logo, etc.)
├── scripts/                   # Build scripts
└── Dockerfile                 # Production container
```

**Scripts:**
```bash
npm run build                  # Build all extensions
npm run build:analytics        # Build single extension
npm run install:all            # Install deps for all extensions
npm run docker:build           # Build Docker image
```

**Docker:**
- Base image: `directus/directus:10.10`
- Production port: `8055`
- Volume: `/directus/database` for SQLite (or SQL Server connection)
- Health check: `wget http://localhost:8055/server/health`

**Access:**
- Production: `https://bo.fiutami.pet`
- Stage: `https://play.francescotrani.com/backoffice` (TBD)

---

### 4. [fiutami/infra](https://github.com/fiutami/infra)

**Description:** Infrastructure as Code (IaC), Docker Compose configurations, and reusable GitHub Actions workflows.

**Key Directories:**
```
infra/
├── docker/
│   ├── docker-compose.yml           # Base configuration
│   ├── docker-compose.local.yml     # Local development
│   ├── docker-compose.dev.yml       # Development environment
│   ├── docker-compose.stage.yml     # Staging (play.francescotrani.com)
│   └── docker-compose.prod.yml      # Production (fiutami.pet)
├── .github/workflows/
│   ├── reusable-docker-build.yml    # Build & push Docker images
│   ├── reusable-ssh-deploy.yml      # SSH deployment workflow
│   └── reusable-notify-e2e.yml      # E2E test notifications
├── scripts/
│   └── optimize-images.js           # Image optimization utility
└── .specs/                          # Technical specifications
```

**Reusable Workflows:**

Other repositories reference these workflows:

```yaml
# Example: frontend/.github/workflows/deploy-prod.yml
jobs:
  build:
    uses: fiutami/infra/.github/workflows/reusable-docker-build.yml@main
    with:
      image_name: fiutami/frontend
      image_tag: latest
    secrets:
      REGISTRY_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  deploy:
    uses: fiutami/infra/.github/workflows/reusable-ssh-deploy.yml@main
    with:
      environment: prod
      compose_file: docker-compose.prod.yml
    secrets:
      SSH_PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
      SSH_HOST: ${{ secrets.SSH_HOST }}
      SSH_USER: ${{ secrets.SSH_USER }}
```

---

## Architecture

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                       Internet (Users)                          │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         │ HTTPS
                         ↓
┌─────────────────────────────────────────────────────────────────┐
│              Nginx Proxy Manager (Host: 116.203.127.208)       │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ SSL Termination + Reverse Proxy                         │   │
│  │  • fiutami.pet → frontend:8080                          │   │
│  │  • api.fiutami.pet → backend:5000                       │   │
│  │  • bo.fiutami.pet → backoffice:8055                     │   │
│  │  • play.francescotrani.com → frontend-stage:8082        │   │
│  └─────────────────────────────────────────────────────────┘   │
└────────────────────────┬────────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        │                │                │
        ↓                ↓                ↓
┌───────────────┐ ┌──────────────┐ ┌─────────────────┐
│   Frontend    │ │   Backend    │ │   Backoffice    │
│  (Angular 18) │ │  (.NET 8)    │ │  (Directus 10)  │
│               │ │              │ │                 │
│  Port: 8080   │ │  Port: 5000  │ │  Port: 8055     │
│  (prod)       │ │  (prod)      │ │                 │
│               │ │              │ │  + 7 Custom     │
│  Port: 8082   │ │  Port: 5001  │ │    Extensions   │
│  (stage)      │ │  (stage)     │ │                 │
└───────────────┘ └──────┬───────┘ └────────┬────────┘
                         │                  │
                         │                  │
                         ↓                  ↓
                  ┌──────────────────────────────┐
                  │    SQL Server 2022 Express   │
                  │                              │
                  │  • fiutami (prod DB)         │
                  │    Port: 1433                │
                  │                              │
                  │  • fiutami_stage (stage DB)  │
                  │    Port: 1435                │
                  │                              │
                  │  Volume: /var/opt/mssql      │
                  └──────────────────────────────┘
```

### Service Communication

**Frontend → Backend:**
- HTTP REST API calls
- JWT token authentication (Bearer)
- CORS configured for `fiutami.pet` domain

**Backend → Database:**
- Entity Framework Core
- Connection pooling
- TrustServerCertificate=True (internal network)

**Backoffice → Database:**
- Direct SQL Server connection
- Shared database with Backend
- Admin-only access

---

## Infrastructure

### Server Details

**Provider:** Hetzner Cloud
**IP Address:** `116.203.127.208`
**OS:** Ubuntu 22.04 LTS
**Architecture:** x86_64

**Installed Software:**
- Docker Engine 24+
- Docker Compose v2
- Nginx Proxy Manager (Docker container)
- Portainer (Docker management UI)

### Network Configuration

**Firewall Rules:**
```
Port 80    → Open (HTTP → HTTPS redirect)
Port 443   → Open (HTTPS)
Port 8080  → Closed (internal - frontend prod)
Port 8082  → Closed (internal - frontend stage)
Port 5000  → Closed (internal - backend prod)
Port 5001  → Closed (internal - backend stage)
Port 1433  → Closed (internal - database prod)
Port 1435  → Closed (internal - database stage)
Port 8055  → Closed (internal - backoffice)
Port 22    → Open (SSH - key-only auth)
```

### Docker Networks

**Production:**
- `fiutami-network` (bridge) - Backend + DB + Frontend
- `proxy-net` (external) - Nginx Proxy Manager integration

**Staging:**
- `fiutami-stage` (bridge) - Isolated stage environment
- `proxy-net` (external) - Shared proxy network

### Volumes

**Production:**
- `mssql-prod-data` → `/var/opt/mssql` (SQL Server data)
- `directus-uploads` → `/directus/uploads` (CMS uploads)
- `directus-database` → `/directus/database` (Directus metadata)

**Staging:**
- `mssql-stage-data` → `/var/opt/mssql` (SQL Server staging data)

### Secrets Management

**Environment Variables (configured in Portainer Stacks):**

Required for Production:
```bash
DB_PASSWORD=<SQL_Server_SA_Password>           # Min 8 chars, complexity required
JWT_SECRET=<32+_character_secret>              # Min 32 chars for HS256
GOOGLE_CLIENT_ID=<OAuth_Google_ClientID>       # Optional (OAuth)
FACEBOOK_APP_ID=<OAuth_Facebook_AppID>         # Optional (OAuth)
FACEBOOK_APP_SECRET=<OAuth_Facebook_Secret>    # Optional (OAuth)
```

Required for Staging:
```bash
DB_PASSWORD=<Different_Password>               # Separate from prod
JWT_SECRET=<Different_Secret>                  # Separate from prod
```

**GitHub Secrets (for CI/CD):**
```
SSH_PRIVATE_KEY     # Private key for deployment user
SSH_HOST            # 116.203.127.208
SSH_USER            # deployment user (e.g., 'deploy')
GHCR_TOKEN          # GitHub Container Registry token
```

---

## Environment URLs

### Production Environment

**Branch:** `main`
**Domain:** `fiutami.pet`

| Service | URL | Port | SSL |
|---------|-----|------|-----|
| Frontend (Web App) | https://fiutami.pet | 443 | ✅ |
| Frontend (www) | https://www.fiutami.pet | 443 | ✅ |
| Backend API | https://api.fiutami.pet | 443 | ✅ |
| Backoffice CMS | https://bo.fiutami.pet | 443 | ✅ |
| API Health Check | https://api.fiutami.pet/health | 443 | ✅ |
| API Docs (Swagger) | https://api.fiutami.pet/swagger | 443 | ✅ |

**Internal Ports (not exposed):**
- Frontend: `8080`
- Backend: `5000`
- Database: `1433`
- Backoffice: `8055`

---

### Staging Environment

**Branch:** `stage`
**Domain:** `play.francescotrani.com` (alias)

| Service | URL | Port | SSL |
|---------|-----|------|-----|
| Frontend (Web App) | https://play.francescotrani.com | 443 | ✅ |
| Backend API | https://play.francescotrani.com:5001 | 5001 | ⚠️ |
| Backoffice CMS | TBD | - | - |

**Internal Ports:**
- Frontend: `8082`
- Backend: `5001`
- Database: `1435`

**Note:** Staging uses the same physical server as production but with isolated Docker containers and separate databases.

---

### Local Development

**Domains:** `localhost` / `127.0.0.1`

| Service | URL | Port |
|---------|-----|------|
| Frontend | http://localhost:4200 | 4200 |
| Backend | http://localhost:5000 | 5000 |
| Backend Swagger | http://localhost:5000/swagger | 5000 |
| Backoffice | http://localhost:8055 | 8055 |
| Database | localhost:1433 | 1433 |

---

## Deployment

### Prerequisites

1. **Server Access:**
   - SSH key configured for deployment user
   - User has Docker permissions: `usermod -aG docker $USER`

2. **GitHub Secrets Configured:**
   - `SSH_PRIVATE_KEY`
   - `SSH_HOST`
   - `SSH_USER`
   - `GHCR_TOKEN`

3. **Portainer Stacks:**
   - Production stack created with environment variables
   - Staging stack created with environment variables

### Deployment Methods

#### Method 1: Automated (via GitHub Actions)

**Production Deployment:**

1. Push to `main` branch:
   ```bash
   git checkout main
   git pull origin main
   git merge feature/your-feature
   git push origin main
   ```

2. GitHub Actions workflow triggers:
   - Builds Docker images
   - Pushes to GitHub Container Registry (ghcr.io)
   - SSHs into server
   - Pulls new images
   - Restarts containers (frontend, backend)
   - Runs health checks
   - Rolls back on failure

3. Monitor workflow:
   - https://github.com/fiutami/frontend/actions
   - https://github.com/fiutami/backend/actions

**Staging Deployment:**

1. Push to `stage` branch:
   ```bash
   git checkout stage
   git merge develop
   git push origin stage
   ```

2. Same workflow as production, but targets:
   - Image tag: `:stage`
   - Compose file: `docker-compose.stage.yml`
   - Ports: 8082 (frontend), 5001 (backend)

---

#### Method 2: Manual (SSH)

**Prerequisites:**
```bash
# SSH into server
ssh deploy@116.203.127.208

# Navigate to deploy directory
cd /opt/fiutami
```

**Production Deployment:**

```bash
# Pull latest images
docker compose -f docker-compose.prod.yml pull

# Stop frontend and backend (keep DB running)
docker compose -f docker-compose.prod.yml stop frontend backend

# Remove old containers
docker compose -f docker-compose.prod.yml rm -f frontend backend

# Start new containers
docker compose -f docker-compose.prod.yml up -d

# Check logs
docker compose -f docker-compose.prod.yml logs -f frontend backend

# Verify health
curl http://localhost:5000/health
curl http://localhost:8080
```

**Staging Deployment:**

```bash
# Same as production, but use stage compose file
docker compose -f docker-compose.stage.yml pull
docker compose -f docker-compose.stage.yml stop frontend backend
docker compose -f docker-compose.stage.yml rm -f frontend backend
docker compose -f docker-compose.stage.yml up -d
docker compose -f docker-compose.stage.yml logs -f
```

---

#### Method 3: Portainer UI

1. Login to Portainer: `https://portainer.fiutami.pet` (if configured)
2. Navigate to **Stacks** → `fiutami-prod` or `fiutami-stage`
3. Click **Editor** → Review compose file
4. Click **Pull and redeploy** button
5. Monitor container logs in real-time

---

### Deployment Checklist

**Pre-Deployment:**
- [ ] All tests passing (`npm test`, `dotnet test`, E2E tests)
- [ ] Code reviewed and merged
- [ ] Migrations tested locally
- [ ] Environment variables verified in Portainer
- [ ] Backup current database (if schema changes)

**Post-Deployment:**
- [ ] Health check endpoints return 200 OK
- [ ] Frontend loads correctly
- [ ] Login/OAuth flows working
- [ ] API endpoints responding
- [ ] Database migrations applied
- [ ] Monitor logs for errors (first 15 minutes)
- [ ] Verify SSL certificates valid
- [ ] Test critical user flows

**Rollback Procedure (if needed):**

```bash
# SSH into server
ssh deploy@116.203.127.208
cd /opt/fiutami

# Stop failed containers
docker compose -f docker-compose.prod.yml stop frontend backend

# List previous images
docker images | grep fiutami

# Tag previous working image as 'latest'
docker tag ghcr.io/fiutami/frontend:<previous-tag> ghcr.io/fiutami/frontend:latest
docker tag ghcr.io/fiutami/backend:<previous-tag> ghcr.io/fiutami/backend:latest

# Restart containers
docker compose -f docker-compose.prod.yml up -d

# Verify rollback
curl http://localhost:5000/health
```

---

## CI/CD Pipelines

### Frontend Pipeline

**Trigger:** Push to `main` or `stage` branch

**Workflow File:** `.github/workflows/deploy.yml`

**Steps:**
1. **Checkout Code:** Clone repository
2. **Setup Node.js:** Install Node 18
3. **Install Dependencies:** `npm ci`
4. **Lint:** `npm run lint`
5. **Unit Tests:** `npm test -- --watch=false`
6. **Build:** `npm run build:prod` (output: `dist/`)
7. **Build Docker Image:**
   - Uses `Dockerfile` (nginx:alpine + dist/)
   - Tags: `ghcr.io/fiutami/frontend:latest` (prod) or `:stage`
8. **Push to GHCR:** GitHub Container Registry
9. **Deploy via SSH:**
   - Uses `fiutami/infra/.github/workflows/reusable-ssh-deploy.yml`
   - Pulls new image on server
   - Restarts frontend container
10. **Health Checks:** Verify frontend responding
11. **Notify:** Slack/Discord notification (optional)

**E2E Tests (Post-Deploy):**
- Separate workflow: `.github/workflows/e2e-prod.yml`
- Triggered after successful deployment
- Runs Playwright tests against production URL
- Reports failures to team

---

### Backend Pipeline

**Trigger:** Push to `main` or `stage` branch

**Workflow File:** `.github/workflows/deploy.yml`

**Steps:**
1. **Checkout Code**
2. **Setup .NET 8 SDK**
3. **Restore Dependencies:** `dotnet restore`
4. **Build:** `dotnet build --configuration Release`
5. **Unit Tests:** `dotnet test`
6. **Publish:** `dotnet publish -c Release -o out/`
7. **Build Docker Image:**
   - Uses `Dockerfile` (mcr.microsoft.com/dotnet/aspnet:8.0)
   - Tags: `ghcr.io/fiutami/backend:latest` (prod) or `:stage`
8. **Push to GHCR**
9. **Deploy via SSH:**
   - Pulls new image
   - Restarts backend container
10. **Health Checks:** `curl http://localhost:5000/health`
11. **Database Migrations:** Auto-applied on startup (EF Core)
12. **Notify**

---

### Backoffice Pipeline

**Trigger:** Push to `main` branch

**Workflow File:** `.github/workflows/build.yml`

**Steps:**
1. **Checkout Code**
2. **Setup Node.js 18**
3. **Install Extension Dependencies:** `npm run install:all`
4. **Build Extensions:** `npm run build`
5. **Build Docker Image:**
   - Base: `directus/directus:10.10`
   - Copies built extensions to `/directus/extensions/`
   - Tags: `ghcr.io/fiutami/backoffice:latest`
6. **Push to GHCR**
7. **Manual Deploy:** Currently manual via Portainer

**Note:** Backoffice deployment is semi-automated. Docker image is built automatically, but deployment requires manual intervention due to potential schema changes.

---

### Infrastructure Pipeline

**Trigger:** Manual workflow dispatch or push to `main`

**Workflow File:** `.github/workflows/update-compose.yml`

**Steps:**
1. **Checkout Code**
2. **SSH into Server**
3. **Update Compose Files:** Copy latest `docker-compose.*.yml`
4. **Validate:** `docker compose config`
5. **No Restart:** Changes applied on next deployment

---

## Development Workflow

### Branching Strategy

**Main Branches:**
- `main` - Production-ready code
- `stage` - Staging/pre-production
- `develop` - Active development

**Feature Branches:**
- `feature/user-authentication`
- `feature/pet-profile-page`
- `bugfix/login-error`
- `hotfix/security-patch`

**Workflow:**
1. Create feature branch from `develop`
2. Develop and test locally
3. Create PR to `develop`
4. Code review + CI checks
5. Merge to `develop`
6. Deploy to `stage` for QA
7. Merge `stage` → `main` for production

---

### Local Development Setup

**1. Clone Repositories:**
```bash
cd ~/projects
git clone https://github.com/fiutami/frontend.git fiutami-frontend
git clone https://github.com/fiutami/backend.git fiutami-backend
git clone https://github.com/fiutami/backoffice.git fiutami-backoffice
git clone https://github.com/fiutami/infra.git fiutami-infra
```

**2. Start Backend + Database:**
```bash
cd fiutami-backend

# Start SQL Server via Docker
docker compose -f docker-compose.local.yml up -d db

# Run migrations
dotnet ef database update --project src/Fiutami.Infrastructure

# Start API
dotnet run --project src/Fiutami.API
# API: http://localhost:5000
# Swagger: http://localhost:5000/swagger
```

**3. Start Frontend:**
```bash
cd fiutami-frontend

# Install dependencies
npm install

# Start dev server
npm start
# App: http://localhost:4200
```

**4. Start Backoffice (Optional):**
```bash
cd fiutami-backoffice

# Build extensions
npm run build

# Start Directus via Docker
npm run docker:run
# Backoffice: http://localhost:8055
```

---

### Testing

**Frontend Tests:**
```bash
# Unit tests (Jasmine + Karma)
npm test

# E2E tests (Playwright)
npm run e2e

# E2E with UI
npm run e2e:ui

# Specific test suites
npm run e2e:auth       # Authentication tests
npm run e2e:user       # User flow tests
npm run e2e:visual     # Visual regression tests
npm run e2e:a11y       # Accessibility tests
npm run e2e:perf       # Performance tests
```

**Backend Tests:**
```bash
# All tests
dotnet test

# Specific project
dotnet test tests/Fiutami.API.Tests

# With coverage
dotnet test /p:CollectCoverage=true
```

---

## Troubleshooting

### Common Issues

#### 1. Frontend Not Loading

**Symptoms:** Blank page, 404 errors

**Diagnosis:**
```bash
# SSH into server
ssh deploy@116.203.127.208

# Check container status
docker ps | grep frontend

# Check logs
docker logs fiutami-frontend

# Check nginx config
docker exec fiutami-frontend cat /etc/nginx/nginx.conf
```

**Solutions:**
- Ensure container is running: `docker start fiutami-frontend`
- Verify Nginx Proxy Manager routing
- Check SSL certificates not expired
- Clear browser cache

---

#### 2. Backend API Errors

**Symptoms:** 500 errors, API not responding

**Diagnosis:**
```bash
# Check backend logs
docker logs fiutami-backend -f

# Check health endpoint
curl http://localhost:5000/health

# Check database connection
docker exec fiutami-db /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -Q "SELECT 1"
```

**Solutions:**
- Check `DB_PASSWORD` environment variable set correctly
- Ensure database container running: `docker ps | grep db`
- Verify database migrations applied
- Check JWT_SECRET configured

---

#### 3. Database Connection Issues

**Symptoms:** Backend can't connect to SQL Server

**Diagnosis:**
```bash
# Check database container
docker ps | grep db

# Check database logs
docker logs fiutami-db

# Test connection
docker exec -it fiutami-backend bash
curl http://fiutami-db:1433  # Should timeout but proves connectivity
```

**Solutions:**
- Verify connection string in `docker-compose.*.yml`
- Check `TrustServerCertificate=True` set
- Ensure database initialized: `docker restart fiutami-db`
- Check SA password complexity (8+ chars, uppercase, lowercase, number, symbol)

---

#### 4. OAuth Login Not Working

**Symptoms:** Google/Facebook login fails

**Diagnosis:**
- Check backend logs for OAuth errors
- Verify `GOOGLE_CLIENT_ID` environment variable set
- Check OAuth redirect URIs in Google Console

**Solutions:**
- Update Google Console: Authorized redirect URIs → `https://fiutami.pet/auth/google/callback`
- Verify client ID matches between Portainer and Google Console
- Ensure HTTPS (OAuth requires secure callback)

---

#### 5. Deployment Fails Health Check

**Symptoms:** GitHub Actions deployment fails at health check step

**Diagnosis:**
```bash
# Check backend health manually
ssh deploy@116.203.127.208
curl http://localhost:5000/health

# Check container started successfully
docker ps -a | grep backend

# Check startup logs
docker logs fiutami-backend --tail 100
```

**Solutions:**
- Increase health check timeout in workflow
- Fix application startup errors (check logs)
- Verify database reachable before backend starts
- Check migrations didn't fail

---

#### 6. SSL Certificate Issues

**Symptoms:** Browser shows "Not Secure" warning

**Diagnosis:**
- Check Nginx Proxy Manager UI
- Verify Let's Encrypt certificate renewal
- Check domain DNS records pointing to correct IP

**Solutions:**
- Renew certificates in NPM: SSL Certificates → Renew
- Verify DNS: `nslookup fiutami.pet` → `116.203.127.208`
- Check port 80 and 443 open on firewall

---

### Performance Issues

**Slow Frontend Load Times:**
- Enable production mode: `ng build --configuration=production`
- Check service worker caching
- Optimize images: `npm run images:optimize`
- Enable Gzip compression in Nginx

**Slow API Response:**
- Check database query performance
- Add indexes on frequently queried columns
- Enable API response caching
- Review N+1 query issues in EF Core

---

### Monitoring and Logs

**View Logs:**
```bash
# Real-time logs
docker logs fiutami-frontend -f
docker logs fiutami-backend -f
docker logs fiutami-db -f

# Last 100 lines
docker logs fiutami-backend --tail 100

# Logs with timestamps
docker logs fiutami-backend --timestamps
```

**Container Stats:**
```bash
# CPU, Memory, Network usage
docker stats

# Specific container
docker stats fiutami-backend
```

**Database Size:**
```bash
docker exec fiutami-db /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -Q "
  SELECT
    name,
    size * 8 / 1024 AS SizeMB
  FROM sys.master_files
  WHERE database_id = DB_ID('fiutami')
"
```

---

## Additional Resources

### Documentation

- **Frontend README:** [github.com/fiutami/frontend/README.md](https://github.com/fiutami/frontend)
- **Backend README:** [github.com/fiutami/backend/README.md](https://github.com/fiutami/backend)
- **Backoffice Docs:** [github.com/fiutami/backoffice/README.md](https://github.com/fiutami/backoffice)
- **Infrastructure Docs:** [github.com/fiutami/infra/README.md](https://github.com/fiutami/infra)

### External Documentation

- **Angular 18:** [angular.io/docs](https://angular.io/docs)
- **.NET 8:** [learn.microsoft.com/en-us/dotnet](https://learn.microsoft.com/en-us/dotnet/core/whats-new/dotnet-8)
- **Directus 10:** [docs.directus.io](https://docs.directus.io)
- **Docker Compose:** [docs.docker.com/compose](https://docs.docker.com/compose/)
- **SQL Server 2022:** [learn.microsoft.com/en-us/sql](https://learn.microsoft.com/en-us/sql/sql-server/)

### Support

- **GitHub Issues:** [github.com/fiutami](https://github.com/fiutami)
- **Team Contact:** dev@fiutami.pet (TBD)

---

## Changelog

### 2025-12-10 - v1.0.0
- Initial organization documentation
- Documented all 4 repositories
- Complete architecture overview
- Deployment procedures
- CI/CD pipeline documentation
- Troubleshooting guide

---

**Maintained by:** Fiutami Team
**Last Review:** December 10, 2025
**Next Review:** Quarterly (March 2026)

---

## Quick Reference

### SSH Access
```bash
ssh deploy@116.203.127.208
cd /opt/fiutami
```

### Production URLs
- Web: https://fiutami.pet
- API: https://api.fiutami.pet
- Backoffice: https://bo.fiutami.pet

### Container Management
```bash
docker ps                                      # List running containers
docker logs <container> -f                     # View logs
docker restart <container>                     # Restart container
docker compose -f docker-compose.prod.yml up -d  # Start stack
```

### Database Access
```bash
docker exec -it fiutami-db /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C
```

### Health Checks
```bash
curl http://localhost:5000/health              # Backend
curl http://localhost:8080                     # Frontend
curl http://localhost:8055/server/health       # Backoffice
```

---

**End of Document**
