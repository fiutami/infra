# Fiutami Infrastructure

Infrastructure as Code, CI/CD templates, and Docker configurations for the Fiutami platform.

## Structure

```
infra/
├── docker/                    # Docker Compose configurations
│   ├── docker-compose.yml     # Base configuration
│   ├── docker-compose.dev.yml # Development overrides
│   ├── docker-compose.local.yml
│   ├── docker-compose.stage.yml
│   └── docker-compose.prod.yml
├── .github/workflows/         # Reusable GitHub Actions workflows
│   ├── reusable-docker-build.yml
│   ├── reusable-ssh-deploy.yml
│   └── reusable-notify-e2e.yml
├── scripts/                   # Utility scripts
└── .specs/                    # Infrastructure specifications
```

## Reusable Workflows

Other repositories in the `fiutami` organization can use these workflows:

```yaml
# Example: Using docker build workflow
jobs:
  build:
    uses: fiutami/infra/.github/workflows/reusable-docker-build.yml@main
    with:
      image_name: fiutami/frontend
      image_tag: latest
    secrets:
      REGISTRY_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Environments

| Environment | Server | IP | Branch | URL |
|-------------|--------|-----|--------|-----|
| Production | Hetzner | `49.12.85.92` | `main` | https://fiutami.pet |
| Staging | LEXe | `91.99.229.111` | `develop` | https://stage.fiutami.pet |
| Development | Local | - | any | localhost |

### Porte per Ambiente

| Service | Staging | Production |
|---------|---------|------------|
| Frontend | 8082 | 8080 |
| Backend | 5001 | 5000 |
| Backoffice | 8055 | 8055 |

## Quick Start

```bash
# Local development
docker compose -f docker/docker-compose.yml -f docker/docker-compose.local.yml up -d

# Staging deployment
docker compose -f docker/docker-compose.yml -f docker/docker-compose.stage.yml up -d
```

## Related Repositories

- [fiutami/frontend](https://github.com/fiutami/frontend) - Angular PWA
- [fiutami/backend](https://github.com/fiutami/backend) - .NET API
- [fiutami/backoffice](https://github.com/fiutami/backoffice) - Directus CMS
- [fiutami/testing](https://github.com/fiutami/testing) - E2E Tests
- [fiutami/docs](https://github.com/fiutami/docs) - Documentation
