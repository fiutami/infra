# CLAUDE.md - Infrastructure

## Contesto
Docker configurations e CI/CD workflows per FIUTAMI.

## Stack
- Docker / Docker Compose
- GitHub Actions (reusable workflows)
- Nginx Proxy Manager

## Struttura
```
fiutami-infra/
├── docker/
│   ├── docker-compose.yml        # Base config
│   ├── docker-compose.local.yml  # Local dev
│   ├── docker-compose.dev.yml    # Dev environment
│   ├── docker-compose.stage.yml  # Staging
│   └── docker-compose.prod.yml   # Production
├── .github/workflows/
│   ├── reusable-docker-build.yml # Build + push GHCR
│   ├── reusable-ssh-deploy.yml   # Deploy via SSH
│   └── reusable-notify-e2e.yml   # Trigger E2E tests
├── scripts/
│   └── optimize-images.js        # Image optimization
└── .specs/
    └── adr/                      # Architecture Decision Records
```

## Servizi Docker
| Service | Image | Porta |
|---------|-------|-------|
| frontend | fiutami-frontend | 8080 |
| backend | fiutami-backend | 5000 |
| db | mssql/server:2022 | 1433 |
| redis | redis:alpine | - |
| nginx | nginx:alpine | 8081/8443 |

## Workflows Riutilizzabili
Altri repo chiamano questi workflows:

```yaml
# Build Docker image
uses: fiutami/fiutami-infra/.github/workflows/reusable-docker-build.yml@main
with:
  image_name: fiutami/fiutami-frontend
  image_tag: latest

# Deploy via SSH
uses: fiutami/fiutami-infra/.github/workflows/reusable-ssh-deploy.yml@main
with:
  environment: prod
  compose_file: docker-compose.prod.yml
```

## Comandi
```bash
# Local development
docker compose -f docker/docker-compose.local.yml up -d
docker compose -f docker/docker-compose.local.yml logs -f
docker compose -f docker/docker-compose.local.yml down

# Production (on VPS)
docker compose -f docker-compose.prod.yml up -d
docker compose -f docker-compose.prod.yml logs -f [service]
```

## Deploy
| Key | Value |
|-----|-------|
| VPS | `91.99.229.111` |
| Path | `/opt/fiutami/` |
| Domains | `fiutami.pet`, `play.francescotrani.com` |
| Registry | `ghcr.io/fiutami/*` |

## Environments
| Branch | Deploy |
|--------|--------|
| any | localhost |
| stage | CI only |
| main | CD → VPS |

## Org FIUTAMI
| Repo | Cosa fa |
|------|---------|
| frontend | Angular PWA |
| backend | .NET 8 API |
| backoffice | Directus CMS |
| **infra** | Docker, CI/CD ← SEI QUI |
| testing | Playwright E2E |
| docs | Documentazione |
