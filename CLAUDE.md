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

### Staging
| Key | Value |
|-----|-------|
| Server | LEXe |
| IP | `91.99.229.111` |
| SSH | `ssh -i ~/.ssh/id_stage_new root@91.99.229.111` |
| Path | `/opt/fiutami` |
| Compose Project | `fiutami-stage` |
| Env File | `/opt/fiutami/.env` |
| Domains | `stage.fiutami.pet`, `api.stage.fiutami.pet`, `bo.stage.fiutami.pet` |
| Network | `fiutami-public` (dedicata, isolata da LEO/LEXE) |
| Traefik Config | `/opt/leo-platform/leo-infra/docker/traefik/dynamic/fiutami-stage.yml` |

### Production
| Key | Value |
|-----|-------|
| Server | Hetzner |
| IP | `49.12.85.92` |
| SSH | `ssh -i ~/.ssh/id_hetzner root@49.12.85.92` |
| Path | `/opt/fra/fiutami` |
| Compose Project | `fiutami-prod` |
| Env File | `/opt/fra/fiutami/.env` |
| Domains | `fiutami.pet`, `api.fiutami.pet`, `bo.fiutami.pet` |
| Ports | FE: 8080, BE: 5000, BO: 8055 |
| Network | `fiutami-public` (dedicata, non shared_public) |
| Traefik Config | `/opt/leo-platform/leo-infra/docker/traefik/dynamic/fiutami.yml` |

### Database (Production)
| Key | Value |
|-----|-------|
| Container | `fiutami-db-prod` |
| Type | SQL Server 2022 Express |
| Database | `fiutami_prod` |
| User | `sa` |
| Password | Vedi `/opt/fra/fiutami/.env` → `DB_PASSWORD` |
| Connect | `docker exec -it fiutami-db-prod /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -d fiutami_prod` |

### Database (Staging)
| Key | Value |
|-----|-------|
| Container | `fiutami-db-stage` |
| Type | SQL Server 2022 Express |
| Database | `fiutami_stage` |
| User | `sa` |
| Password | Vedi `/opt/fiutami/.env` → `DB_PASSWORD` |
| Connect | `docker exec -it fiutami-db-stage /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -d fiutami_stage` |

### Registry
`ghcr.io/fiutami/*` con tag `sha-*`, `stage`, `prod`

## Database Migrations

### Schema EF Core
- **31 tabelle** totali (Auth_*, Pet_*, Notify_*, Chat_*, Cal_*, Sub_*, Social_*, POI_*)
- **16 migrazioni** registrate in `__EFMigrationsHistory`
- Schema allineato in PROD e STAGE

### Comandi Migrazioni
```bash
# Creare nuova migrazione (locale)
cd backend
dotnet ef migrations add NomeMigrazione --project src/Fiutami.Infrastructure --startup-project src/Fiutami.API

# Applicare migrazioni (locale)
dotnet ef database update --project src/Fiutami.Infrastructure --startup-project src/Fiutami.API

# Lista migrazioni
dotnet ef migrations list --project src/Fiutami.Infrastructure --startup-project src/Fiutami.API
```

### Applicare Migrazioni in Ambiente
1. **Via GitHub Actions** (raccomandato):
   - Vai su Actions → "Database Migrations"
   - Seleziona environment (stage/prod)
   - Prima esegui con `dry_run: true` per vedere le pending
   - Poi esegui con `dry_run: false` per applicare

2. **Manualmente** (emergenza):
```bash
# STAGING
ssh -i ~/.ssh/id_stage_new root@91.99.229.111
source /opt/fiutami/.env
docker exec -it fiutami-db-stage /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -d fiutami_stage

# PRODUCTION
ssh -i ~/.ssh/id_hetzner root@49.12.85.92
source /opt/fra/fiutami/.env
docker exec -it fiutami-db-prod /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -d fiutami_prod
```

### Sync Prod → Stage
Il database di staging viene sincronizzato automaticamente con quello di produzione.

#### Sync Automatico (ogni 15 minuti)
- **Cron Job**: `*/15 * * * *` sul server prod
- **Script**: `/opt/fra/fiutami/scripts/sync-to-stage.sh`
- **Log**: `/var/log/fiutami-sync.log`
- **Lock file**: `/tmp/fiutami-sync.lock` (previene esecuzioni concorrenti)

#### Sync Manuale

1. **Via script locale**:
```bash
./infra/scripts/sync-prod-to-stage.sh
# Con dry-run: ./infra/scripts/sync-prod-to-stage.sh --dry-run
```

2. **Via GitHub Actions**:
   - Vai su Actions → "Sync Prod DB to Stage"
   - Digita "SYNC" per confermare
   - ATTENZIONE: sovrascrive completamente il DB di staging!

3. **Direttamente sul server prod**:
```bash
ssh -i ~/.ssh/id_hetzner root@49.12.85.92
/opt/fra/fiutami/scripts/sync-to-stage.sh
tail -f /var/log/fiutami-sync.log  # Monitor log
```

#### Come Funziona il Sync
1. Backup del DB prod in `/var/opt/mssql/data/` (non /backup/ per permessi)
2. Copia backup su host prod via `docker cp`
3. Trasferimento backup su staging via `scp`
4. Copia backup nel container staging
5. `chown mssql:root` per fixare permessi (eseguito con `-u root`)
6. RESTORE con MOVE dei logical files (`FIUTAMI` → `fiutami_stage.mdf`)
7. Cleanup dei file temporanei

**Nota**: I logical file names nel backup sono `FIUTAMI` e `FIUTAMI_log`, non `fiutami_prod`.

### Scripts Disponibili
| Script | Descrizione |
|--------|-------------|
| `scripts/baseline-migrations.sql` | Crea tutte le tabelle EF Core da zero |
| `scripts/sync-prod-to-stage.sh` | Sincronizza DB prod → stage (locale) |
| `scripts/sync-to-stage-auto.sh` | Sync automatico (deploy su prod server) |

### SSH Keys (local)
| Key | Server |
|-----|--------|
| `~/.ssh/id_hetzner` | Production (49.12.85.92) |
| `~/.ssh/id_stage_new` | Staging (91.99.229.111) |
| `~/.ssh/id_ssdnas` | Old server (play.francescotrani.com) |

## Environments
| Branch | Deploy Target |
|--------|---------------|
| any | localhost |
| develop/stage | Staging (91.99.229.111) |
| main | Production (49.12.85.92) |

## Org FIUTAMI
| Repo | Cosa fa |
|------|---------|
| frontend | Angular PWA |
| backend | .NET 8 API |
| backoffice | Directus CMS |
| **infra** | Docker, CI/CD ← SEI QUI |
| testing | Playwright E2E |
| docs | Documentazione |

## Troubleshooting

### Healthcheck Fallisce
**Sintomo**: Container mostra `(unhealthy)` ma il servizio risponde.

**Causa**: `localhost` non risolve correttamente nei container Alpine/Debian.

**Fix**: Usare `127.0.0.1` invece di `localhost` negli healthcheck:
```yaml
# ❌ Non funziona
test: ["CMD", "wget", "-q", "--spider", "http://localhost/"]

# ✅ Funziona
test: ["CMD", "wget", "-q", "--spider", "http://127.0.0.1/"]
```

**Backend .NET**: Non ha curl/wget, usare bash:
```yaml
test: ["CMD-SHELL", "bash -c 'echo > /dev/tcp/127.0.0.1/5000'"]
```

### Backend Auth Non Funziona (JWT Error)
**Sintomo**: `IDX10703: Cannot create SymmetricSecurityKey, key length is zero`

**Causa**: `JWT_SECRET` non passato al container (CI deploy senza .env).

**Diagnosi**:
```bash
docker inspect fiutami-backend-prod --format '{{range .Config.Env}}{{println .}}{{end}}' | grep Jwt__SecretKey
# Se vuoto → problema confermato
```

**Fix**: Ricreare container con docker compose (legge .env):
```bash
cd /opt/fra/fiutami  # o /opt/fiutami per stage
source .env
docker stop fiutami-backend-prod && docker rm fiutami-backend-prod
docker compose -p fiutami-prod -f docker-compose.prod.yml up -d --no-deps backend
```

### DB Staging Bloccato (SINGLE_USER)
**Sintomo**: Auth fallisce su staging, errori `database can only have one user`

**Causa**: Sync interrotto ha lasciato DB in SINGLE_USER mode.

**Diagnosi**:
```bash
source /opt/fiutami/.env
docker exec fiutami-db-stage /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C \
  -Q "SELECT user_access_desc FROM sys.databases WHERE name = 'fiutami_stage'"
# Se mostra SINGLE_USER → problema confermato
```

**Fix**:
```bash
docker exec fiutami-db-stage /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -d master -Q "
DECLARE @kill varchar(8000) = '';
SELECT @kill = @kill + 'KILL ' + CONVERT(varchar(5), session_id) + ';'
FROM sys.dm_exec_sessions WHERE database_id = DB_ID('fiutami_stage');
EXEC(@kill);
ALTER DATABASE [fiutami_stage] SET MULTI_USER;
"
```

### Container Nome Sbagliato (Traefik 502)
**Sintomo**: Traefik ritorna 502, container ha prefisso hash (es. `0618d860a285_fiutami-frontend-stage`)

**Causa**: Docker compose ha creato container con nome conflittuale.

**Fix**:
```bash
docker stop <container_con_hash>
docker rm <container_con_hash>
cd /opt/fiutami
docker compose -p fiutami-stage -f docker-compose.stage.yml up -d --no-deps <service>
docker network connect fiutami-public fiutami-<service>-stage
```

### Verificare Stato Completo
```bash
# Containers
docker ps --format 'table {{.Names}}\t{{.Status}}' | grep fiutami

# Endpoints
for url in fiutami.pet api.fiutami.pet bo.fiutami.pet stage.fiutami.pet api.stage.fiutami.pet bo.stage.fiutami.pet; do
  echo "$url → $(curl -sL -o /dev/null -w '%{http_code}' https://$url)"
done

# Sync log
tail -20 /var/log/fiutami-sync.log

# DB POI count
docker exec fiutami-db-prod /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$DB_PASSWORD" -C -d fiutami_prod -Q "SELECT COUNT(*) FROM POI_Points" -h -1
```
