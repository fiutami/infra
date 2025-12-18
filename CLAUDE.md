# CLAUDE.md - Infrastructure

## Questo Repo
**Path:** `/home/frisco/projects/fiutami-infra`
**Stack:** Docker, GitHub Actions, Nginx Proxy Manager

## Org FIUTAMI
| Repo | Path | Cosa fa |
|------|------|---------|
| frontend | `fiutami-frontend` | Angular PWA |
| backend | `fiutami-backend` | .NET 8 API |
| backoffice | `fiutami-backoffice` | Directus CMS |
| **infra** | `fiutami-infra` ← SEI QUI | Docker, CI/CD |
| testing | `fiutami-testing` | Playwright E2E |
| docs | `fiutami-docs` | Documentazione |

## Dove Lavoro
| Task | Path |
|------|------|
| Dockerfiles | `docker/` |
| Deploy scripts | `scripts/` |
| CI/CD workflows | `.github/workflows/` |
| ADRs | `.specs/` |

## Comandi
```bash
docker compose up -d            # Start all
docker compose logs -f [svc]    # Logs
docker compose down             # Stop
```

## Deploy
VPS: `91.99.229.111` | Path: `/opt/fiutami/`
Domains: `fiutami.pet`, `play.francescotrani.com`

## Environments
| Branch | Deploy |
|--------|--------|
| any | localhost |
| stage | CI only |
| main | CD → VPS |
