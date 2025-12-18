# CLAUDE.md - Fiutami Infrastructure

## Context
Infrastructure as Code for Fiutami. Contains Docker configurations, CI/CD workflows, and deployment scripts.

## Stack
- Docker & Docker Compose
- GitHub Actions
- Nginx Proxy Manager
- Hetzner VPS

## Project Structure
```
fiutami-infra/
├── docker/
│   ├── local/           # Local dev compose
│   ├── staging/         # Stage environment
│   └── production/      # Prod environment
├── scripts/             # Deployment scripts
└── .github/workflows/   # Reusable GH Actions
```

## Environments
| Env | Branch | Deploy |
|-----|--------|--------|
| Dev | any | localhost |
| Stage | stage | CI only |
| Prod | main | CD to VPS |

## Commands
```bash
# Local
docker compose -f docker/local/docker-compose.yml up -d

# Deploy
./scripts/deploy.sh production
```

## VPS Info
- IP: 91.99.229.111
- Deploy dir: /opt/fiutami/
- Domains: fiutami.pet, play.francescotrani.com

## Links
- Docs: https://github.com/fiutami/docs
- Portainer: (internal)
