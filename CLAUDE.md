# CLAUDE.md - Infrastructure

## Contesto
Configurazione Docker e CI/CD per FIUTAMI. Deploy su VPS con Nginx Proxy Manager.

## Stack
- Docker / Docker Compose
- GitHub Actions
- Nginx Proxy Manager
- PostgreSQL
- Redis

## Struttura
```
fiutami-infra/
├── docker/              # Dockerfiles
├── scripts/             # Deploy scripts
├── .github/workflows/   # CI/CD
│   ├── reusable-docker-build.yml
│   ├── reusable-notify-e2e.yml
│   └── reusable-ssh-deploy.yml
└── .specs/              # ADRs
```

## Comandi
```bash
docker compose up -d           # Start all services
docker compose build --no-cache # Rebuild
docker compose logs -f [service] # View logs
docker compose down            # Stop all
```

## Services
| Service | Port | Descrizione |
|---------|------|-------------|
| postgres | 5432 | Database |
| redis | 6379 | Cache |
| directus | 8055 | CMS |
| backend | 5000 | API .NET |
| frontend | 4200 | Angular PWA |

## Deploy
- VPS: 91.99.229.111
- Path: /opt/fiutami/
- Proxy: Nginx Proxy Manager
- Domains: fiutami.pet, play.francescotrani.com

## Environments
| Env | Branch | Deploy |
|-----|--------|--------|
| Dev | any | localhost |
| Stage | stage | CI only |
| Prod | main | CD to VPS |

## Secrets (GitHub)
- SSH_HOST, SSH_USER, SSH_KEY
- DOCKER_REGISTRY_*
- DB_PASSWORD
- JWT_SECRET

## Link
- [Docs](https://github.com/fiutami/docs)
- [ADR: Docker over K8s](./.specs/adr/001-docker-compose-over-k8s.md)
