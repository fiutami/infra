# FIUTAMI - Setup Server PROD

> Istruzioni per completare il setup del server production (49.12.85.92)

## Stato Pipeline CD

| Componente | Stato |
|------------|-------|
| GitHub Environments (staging/production) | Configurati |
| Secrets per environment | Configurati |
| Workflows frontend/backend/backoffice | Aggiornati e pushati |
| docker-compose.prod.yml su GitHub | Aggiornato con IMAGE_TAG |
| docker-compose.stage.yml su GitHub | Aggiornato con IMAGE_TAG |
| Repo infra | Pubblico (per curl compose file) |
| Deploy step | **FUNZIONA** |
| Health check prod | Fallisce (richiede setup server) |

## Azione Richiesta - Setup Server PROD

### 1. Connessione SSH

```bash
ssh root@49.12.85.92
```

### 2. Creare Network Docker

```bash
docker network create shared_public
```

### 3. Creare Directory e .env

```bash
cd /opt/fra/fiutami

cat > .env << 'EOF'
# Database
DB_PASSWORD=<genera_password_sicura_con_openssl_rand_base64_24>

# JWT
JWT_SECRET=<genera_jwt_secret_con_openssl_rand_base64_48>

# OAuth
GOOGLE_CLIENT_ID=384947883378-eghthqhqvoau0m0ubqstvr9baq0pbtbb.apps.googleusercontent.com
FACEBOOK_APP_ID=
FACEBOOK_APP_SECRET=

# Directus
DIRECTUS_KEY=<genera_con_openssl_rand_base64_32>
DIRECTUS_SECRET=<genera_con_openssl_rand_base64_32>
DIRECTUS_ADMIN_EMAIL=admin@fiutami.pet
DIRECTUS_ADMIN_PASSWORD=<password_admin>
EOF

chmod 600 .env
```

### 4. Generare Secrets (Comandi)

```bash
# DB Password
openssl rand -base64 24

# JWT Secret
openssl rand -base64 48

# Directus Key
openssl rand -base64 32

# Directus Secret
openssl rand -base64 32
```

### 5. Test Manuale Deploy

```bash
cd /opt/fra/fiutami

# Scarica compose file
curl -sSL https://raw.githubusercontent.com/fiutami/infra/main/docker/docker-compose.prod.yml -o docker-compose.prod.yml

# Login GHCR
echo "<GHCR_PAT>" | docker login ghcr.io -u fiutami --password-stdin

# Deploy frontend
export IMAGE_TAG=prod
docker compose -p fiutami-prod -f docker-compose.prod.yml up -d frontend

# Verifica
docker ps | grep fiutami
curl http://localhost:8080/
```

### 6. Triggera Deploy da GitHub Actions

```bash
gh workflow run deploy.yml --repo fiutami/frontend --field environment=production
gh workflow run deploy.yml --repo fiutami/backend --field environment=production
gh workflow run deploy.yml --repo fiutami/backoffice --field environment=production
```

## Architettura

| Ambiente | Server | IP | Path | Compose Project |
|----------|--------|-----|------|-----------------|
| **STAGING** | LEXe | `91.99.229.111` | `/opt/fiutami` | `fiutami-stage` |
| **PRODUCTION** | Hetzner | `49.12.85.92` | `/opt/fra/fiutami` | `fiutami-prod` |

### Domini

| Dominio | IP | Porta |
|---------|-----|-------|
| stage.fiutami.pet | 91.99.229.111 | 8082 |
| api.stage.fiutami.pet | 91.99.229.111 | 5001 |
| bo.stage.fiutami.pet | 91.99.229.111 | 8055 |
| fiutami.pet | 49.12.85.92 | 8080 |
| api.fiutami.pet | 49.12.85.92 | 5000 |
| bo.fiutami.pet | 49.12.85.92 | 8055 |

## Branch -> Deploy

| Branch | Target | Auto |
|--------|--------|------|
| `develop` | Staging | Si |
| `stage` | Staging | Si |
| `main` | Production | Si |

---

*Creato: 2026-02-10*
