#!/bin/bash
# =============================================================================
# FIUTAMI - Import Users & Pets from Production to Staging (NON-DESTRUCTIVE)
#
# MERGE (upsert) approach:
#   - INSERT records that exist in prod but not in staging
#   - UPDATE existing records with prod values
#   - NEVER delete staging-only records
#   - NEVER touch: Storage_Files, Pet_PetDocuments, Pet_PetPhotos,
#                  Auth_UserConsents, Account_Exports, Chat, Social, etc.
#   - PrimaryPhotoUrl/CoverPhotoUrl set to NULL for new pets
#     (staging photos are stored in MinIO, not synced from prod)
#
# Tables synced: Auth_Users, Pet_Species, Pet_Breeds, Pet_Pets
#
# Usage:
#   ./import-prod-data.sh              # Full import
#   ./import-prod-data.sh --dry-run    # Show counts only, no changes
#
# Run from: production server (49.12.85.92)
# Requires: SSH key to staging at /root/.ssh/id_stage
# =============================================================================

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# --- Config ---
PROD_CONTAINER="fiutami-db-prod"
PROD_DB="fiutami_prod"
STAGE_SERVER="91.99.229.111"
STAGE_SSH_KEY="/root/.ssh/id_stage"
STAGE_CONTAINER="fiutami-db-stage"
STAGE_DB="fiutami_stage"
EXPORT_DIR="/tmp/fiutami-export"
TABLES="Auth_Users Pet_Species Pet_Breeds Pet_Pets"

source /opt/fra/fiutami/.env
PROD_PASS="$DB_PASSWORD"

log() { echo "[$(date '+%H:%M:%S')] $1"; }

run_prod_sql() {
    docker exec "$PROD_CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "$PROD_PASS" -d "$PROD_DB" -C -W -Q "$1"
}

run_stage_sql() {
    ssh -i "$STAGE_SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=30 \
        "root@${STAGE_SERVER}" << REMOTE_SQL
source /opt/fiutami/.env
docker exec $STAGE_CONTAINER /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "\$DB_PASSWORD" -d $STAGE_DB -C -W -Q "$1"
REMOTE_SQL
}

# --- Show current counts ---
log "=== Production counts ==="
run_prod_sql "
SELECT 'Auth_Users' AS [Table], COUNT(*) AS [Count] FROM Auth_Users UNION ALL
SELECT 'Pet_Pets (active)', COUNT(*) FROM Pet_Pets WHERE IsDeleted = 0 UNION ALL
SELECT 'Pet_Species', COUNT(*) FROM Pet_Species UNION ALL
SELECT 'Pet_Breeds', COUNT(*) FROM Pet_Breeds
"

log "=== Staging counts (before) ==="
run_stage_sql "
SELECT 'Auth_Users' AS [Table], COUNT(*) AS [Count] FROM Auth_Users UNION ALL
SELECT 'Pet_Pets (active)', COUNT(*) FROM Pet_Pets WHERE IsDeleted = 0 UNION ALL
SELECT 'Pet_Species', COUNT(*) FROM Pet_Species UNION ALL
SELECT 'Pet_Breeds', COUNT(*) FROM Pet_Breeds
"

if [ "$DRY_RUN" = true ]; then
    log "=== DRY RUN complete - no changes made ==="
    exit 0
fi

# --- Export from prod using BCP (character mode for portability) ---
log "Exporting data from production..."
mkdir -p "$EXPORT_DIR"

for TABLE in $TABLES; do
    log "  Exporting $TABLE..."

    # Pet_Pets: skip RowVersion (timestamp) column - use a view
    if [ "$TABLE" = "Pet_Pets" ]; then
        run_prod_sql "
            IF OBJECT_ID('dbo._vw_export_pets','V') IS NOT NULL DROP VIEW dbo._vw_export_pets;
        " > /dev/null 2>&1
        docker exec "$PROD_CONTAINER" /opt/mssql-tools18/bin/sqlcmd \
            -S localhost -U sa -P "$PROD_PASS" -d "$PROD_DB" -C -Q "
            CREATE VIEW dbo._vw_export_pets AS
            SELECT Id, UserId, SpeciesId, BreedId, Name, Nickname, DateOfBirth, DateAcquired,
                   Gender, Color, Size, Weight, IsNeutered, Microchip, Notes,
                   PrimaryPhotoUrl, CoverPhotoUrl, IsActive, IsDeleted, DeletedAt,
                   DeletionReason, CreatedAt, UpdatedAt
            FROM Pet_Pets
        " > /dev/null 2>&1

        docker exec "$PROD_CONTAINER" /opt/mssql-tools18/bin/bcp \
            "${PROD_DB}.dbo._vw_export_pets" out "/tmp/${TABLE}.bcp" \
            -S localhost -U sa -P "$PROD_PASS" -u -c -t '\t' 2>/dev/null

        run_prod_sql "DROP VIEW IF EXISTS dbo._vw_export_pets" > /dev/null 2>&1
    else
        docker exec "$PROD_CONTAINER" /opt/mssql-tools18/bin/bcp \
            "${PROD_DB}.dbo.${TABLE}" out "/tmp/${TABLE}.bcp" \
            -S localhost -U sa -P "$PROD_PASS" -u -c -t '\t' 2>/dev/null
    fi

    docker cp "$PROD_CONTAINER:/tmp/${TABLE}.bcp" "$EXPORT_DIR/${TABLE}.bcp"
    docker exec "$PROD_CONTAINER" rm -f "/tmp/${TABLE}.bcp"

    SIZE=$(ls -lh "$EXPORT_DIR/${TABLE}.bcp" | awk '{print $5}')
    log "  $TABLE: $SIZE"
done

# --- Transfer to staging ---
log "Transferring to staging..."
scp -i "$STAGE_SSH_KEY" -o StrictHostKeyChecking=no \
    "$EXPORT_DIR"/*.bcp "root@${STAGE_SERVER}:/tmp/" 2>/dev/null
log "Transfer complete"

# --- Import on staging ---
log "Importing on staging (MERGE)..."

ssh -i "$STAGE_SSH_KEY" -o StrictHostKeyChecking=no \
    "root@${STAGE_SERVER}" bash << 'REMOTE_SCRIPT'
set -e
source /opt/fiutami/.env
C="fiutami-db-stage"
DB="fiutami_stage"
P="$DB_PASSWORD"

sql() {
    docker exec "$C" /opt/mssql-tools18/bin/sqlcmd \
        -S localhost -U sa -P "$P" -d "$DB" -C -W -Q "$1"
}

bcp_in() {
    docker cp "/tmp/${1}.bcp" "$C:/tmp/${1}.bcp"
    docker exec "$C" /opt/mssql-tools18/bin/bcp \
        "${DB}.dbo._Import_${1}" in "/tmp/${1}.bcp" \
        -S localhost -U sa -P "$P" -u -c -t '\t' 2>/dev/null
    docker exec "$C" rm -f "/tmp/${1}.bcp" || true
    rm -f "/tmp/${1}.bcp" || true
}

echo "Creating import tables..."
# Auth_Users: schema matches prod=stage, SELECT * is safe
# Pet_Species: staging has extra cols (AllowsMixedLabel, BreedPolicy, SortOrder) - use explicit cols
# Pet_Breeds: staging has extra cols (AllowsUserVariantLabel, BreedType, Code, SortOrder) - use explicit cols
# Pet_Pets: skip RowVersion (timestamp) - use explicit cols
sql "
DROP TABLE IF EXISTS _Import_Auth_Users;
DROP TABLE IF EXISTS _Import_Pet_Species;
DROP TABLE IF EXISTS _Import_Pet_Breeds;
DROP TABLE IF EXISTS _Import_Pet_Pets;

SELECT * INTO _Import_Auth_Users FROM Auth_Users WHERE 1=0;

SELECT Id, Code, Name, Category, Description, ImageUrl,
       TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic,
       ActivityLevel, CareLevel, IsActive, CreatedAt
INTO _Import_Pet_Species FROM Pet_Species WHERE 1=0;

SELECT Id, SpeciesId, Name, NameOriginal, Origin, Recognition, ImageUrl,
       Description, GeneticsInfo, GroupFCI, AncestralBreeds,
       HeightMinCm, HeightMaxCm, WeightMinKg, WeightMaxKg,
       CoatType, Colors, LifespanMinYears, LifespanMaxYears,
       EnergyLevel, SocialityLevel, TrainabilityLevel, TemperamentTraits,
       SuitableFor, CareRituals, HealthRisks, History,
       Popularity, IsActive, CreatedAt, UpdatedAt
INTO _Import_Pet_Breeds FROM Pet_Breeds WHERE 1=0;

SELECT Id, UserId, SpeciesId, BreedId, Name, Nickname, DateOfBirth, DateAcquired,
       Gender, Color, Size, Weight, IsNeutered, Microchip, Notes,
       PrimaryPhotoUrl, CoverPhotoUrl, IsActive, IsDeleted, DeletedAt,
       DeletionReason, CreatedAt, UpdatedAt
INTO _Import_Pet_Pets FROM Pet_Pets WHERE 1=0;
" > /dev/null

echo "BCP importing..."
bcp_in "Auth_Users"
bcp_in "Pet_Species"
bcp_in "Pet_Breeds"
bcp_in "Pet_Pets"

echo "Running MERGE statements..."

# MERGE Auth_Users
sql "
MERGE Auth_Users AS t
USING _Import_Auth_Users AS s ON t.Id = s.Id
WHEN MATCHED THEN UPDATE SET
    t.Email = s.Email, t.PasswordHash = s.PasswordHash,
    t.FirstName = s.FirstName, t.LastName = s.LastName,
    t.Provider = s.Provider, t.ProviderId = s.ProviderId,
    t.IsDeleted = s.IsDeleted, t.IsEmailVerified = s.IsEmailVerified,
    t.EmailVerifiedAt = s.EmailVerifiedAt,
    t.HasCompletedOnboarding = s.HasCompletedOnboarding,
    t.OnboardingCompletedAt = s.OnboardingCompletedAt,
    t.FailedLoginAttempts = s.FailedLoginAttempts,
    t.LastPasswordChangeAt = s.LastPasswordChangeAt
WHEN NOT MATCHED BY TARGET THEN INSERT
    (Id, Email, PasswordHash, FirstName, LastName, Provider, ProviderId,
     CreatedAt, IsDeleted, IsEmailVerified, EmailVerifiedAt,
     HasCompletedOnboarding, OnboardingCompletedAt, FailedLoginAttempts,
     LastPasswordChangeAt)
VALUES
    (s.Id, s.Email, s.PasswordHash, s.FirstName, s.LastName,
     s.Provider, s.ProviderId, s.CreatedAt, s.IsDeleted,
     s.IsEmailVerified, s.EmailVerifiedAt, s.HasCompletedOnboarding,
     s.OnboardingCompletedAt, s.FailedLoginAttempts, s.LastPasswordChangeAt);
PRINT 'Auth_Users: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows affected';
"

# MERGE Pet_Species
sql "
MERGE Pet_Species AS t
USING _Import_Pet_Species AS s ON t.Id = s.Id
WHEN MATCHED THEN UPDATE SET
    t.Name = s.Name, t.Category = s.Category, t.IsActive = s.IsActive
WHEN NOT MATCHED BY TARGET THEN INSERT
    (Id, Name, Category, IsActive, CreatedAt)
VALUES (s.Id, s.Name, s.Category, s.IsActive, s.CreatedAt);
PRINT 'Pet_Species: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows affected';
"

# MERGE Pet_Breeds
sql "
MERGE Pet_Breeds AS t
USING _Import_Pet_Breeds AS s ON t.Id = s.Id
WHEN MATCHED THEN UPDATE SET
    t.Name = s.Name, t.NameOriginal = s.NameOriginal,
    t.Origin = s.Origin, t.IsActive = s.IsActive,
    t.Popularity = s.Popularity, t.UpdatedAt = s.UpdatedAt
WHEN NOT MATCHED BY TARGET THEN INSERT
    (Id, SpeciesId, Name, NameOriginal, Origin, Recognition, ImageUrl,
     Description, GeneticsInfo, GroupFCI, AncestralBreeds,
     HeightMinCm, HeightMaxCm, WeightMinKg, WeightMaxKg,
     CoatType, Colors, LifespanMinYears, LifespanMaxYears,
     EnergyLevel, SocialityLevel, TrainabilityLevel, TemperamentTraits,
     SuitableFor, CareRituals, HealthRisks, History,
     Popularity, IsActive, CreatedAt, UpdatedAt)
VALUES
    (s.Id, s.SpeciesId, s.Name, s.NameOriginal, s.Origin, s.Recognition, s.ImageUrl,
     s.Description, s.GeneticsInfo, s.GroupFCI, s.AncestralBreeds,
     s.HeightMinCm, s.HeightMaxCm, s.WeightMinKg, s.WeightMaxKg,
     s.CoatType, s.Colors, s.LifespanMinYears, s.LifespanMaxYears,
     s.EnergyLevel, s.SocialityLevel, s.TrainabilityLevel, s.TemperamentTraits,
     s.SuitableFor, s.CareRituals, s.HealthRisks, s.History,
     s.Popularity, s.IsActive, s.CreatedAt, s.UpdatedAt);
PRINT 'Pet_Breeds: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows affected';
"

# MERGE Pet_Pets (PrimaryPhotoUrl/CoverPhotoUrl = NULL for new, preserve for existing)
sql "
MERGE Pet_Pets AS t
USING _Import_Pet_Pets AS s ON t.Id = s.Id
WHEN MATCHED THEN UPDATE SET
    t.Name = s.Name, t.Nickname = s.Nickname,
    t.DateOfBirth = s.DateOfBirth, t.DateAcquired = s.DateAcquired,
    t.Gender = s.Gender, t.Color = s.Color, t.Size = s.Size,
    t.Weight = s.Weight, t.IsNeutered = s.IsNeutered,
    t.Microchip = s.Microchip, t.Notes = s.Notes,
    t.IsActive = s.IsActive, t.IsDeleted = s.IsDeleted,
    t.DeletedAt = s.DeletedAt, t.DeletionReason = s.DeletionReason,
    t.UpdatedAt = s.UpdatedAt
WHEN NOT MATCHED BY TARGET THEN INSERT
    (Id, UserId, SpeciesId, BreedId, Name, Nickname, DateOfBirth, DateAcquired,
     Gender, Color, Size, Weight, IsNeutered, Microchip, Notes,
     PrimaryPhotoUrl, CoverPhotoUrl,
     IsActive, IsDeleted, DeletedAt, DeletionReason, CreatedAt, UpdatedAt)
VALUES
    (s.Id, s.UserId, s.SpeciesId, s.BreedId, s.Name, s.Nickname,
     s.DateOfBirth, s.DateAcquired, s.Gender, s.Color, s.Size,
     s.Weight, s.IsNeutered, s.Microchip, s.Notes,
     NULL, NULL,
     s.IsActive, s.IsDeleted, s.DeletedAt, s.DeletionReason,
     s.CreatedAt, s.UpdatedAt);
PRINT 'Pet_Pets: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' rows affected';
"

echo "Cleaning up import tables..."
sql "
DROP TABLE IF EXISTS _Import_Auth_Users;
DROP TABLE IF EXISTS _Import_Pet_Species;
DROP TABLE IF EXISTS _Import_Pet_Breeds;
DROP TABLE IF EXISTS _Import_Pet_Pets;
" > /dev/null

echo "=== MERGE complete ==="
REMOTE_SCRIPT

REMOTE_RESULT=$?

# Cleanup local
rm -rf "$EXPORT_DIR"

if [ $REMOTE_RESULT -ne 0 ]; then
    log "ERROR: Import failed"
    exit 1
fi

log "=== Staging counts (after) ==="
run_stage_sql "
SELECT 'Auth_Users' AS [Table], COUNT(*) AS [Count] FROM Auth_Users UNION ALL
SELECT 'Pet_Pets (active)', COUNT(*) FROM Pet_Pets WHERE IsDeleted = 0 UNION ALL
SELECT 'Pet_Species', COUNT(*) FROM Pet_Species UNION ALL
SELECT 'Pet_Breeds', COUNT(*) FROM Pet_Breeds
"

log "=== Import complete ==="
