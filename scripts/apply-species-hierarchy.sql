-- =============================================================================
-- FIUTAMI - Comprehensive DB Migration (idempotent, safe to re-run)
--
-- Applies 4 EF Core migrations in one shot:
--   1. AddBreedPolicyAndVariantLabel  (columns on Pet_Species/Pets/Breeds + FK changes)
--   2. AddSpeciesHierarchy            (TaxonRank, ParentSpeciesId, ScientificName)
--   3. SeedExpandedSpecies            (48 total species with hierarchy)
--   4. AddStorageGdprEntities         (Storage_Files, PetDocuments, UserConsents, Exports)
--
-- Usage (via wrapper script):
--   ./apply-species-hierarchy.sh prod
--   ./apply-species-hierarchy.sh stage
-- =============================================================================

SET NOCOUNT ON;
PRINT '=== FIUTAMI Comprehensive Migration ===';
PRINT '';

-- =============================================================================
-- PART 1: Schema changes - columns, indexes, FKs, constraints
-- =============================================================================

PRINT '--- Pet_Species columns ---';

-- BreedPolicy (AddBreedPolicyAndVariantLabel)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Pet_Species' AND COLUMN_NAME = 'BreedPolicy')
BEGIN
    ALTER TABLE Pet_Species ADD BreedPolicy nvarchar(20) NOT NULL CONSTRAINT DF_Species_BreedPolicy DEFAULT 'Optional';
    PRINT '  + BreedPolicy';
END
ELSE PRINT '  ~ BreedPolicy exists';

-- AllowsMixedLabel (AddBreedPolicyAndVariantLabel)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Pet_Species' AND COLUMN_NAME = 'AllowsMixedLabel')
BEGIN
    ALTER TABLE Pet_Species ADD AllowsMixedLabel bit NOT NULL CONSTRAINT DF_Species_AllowsMixedLabel DEFAULT 0;
    PRINT '  + AllowsMixedLabel';
END
ELSE PRINT '  ~ AllowsMixedLabel exists';

-- SortOrder (AddBreedPolicyAndVariantLabel)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Pet_Species' AND COLUMN_NAME = 'SortOrder')
BEGIN
    ALTER TABLE Pet_Species ADD SortOrder int NOT NULL CONSTRAINT DF_Species_SortOrder DEFAULT 0;
    PRINT '  + SortOrder';
END
ELSE PRINT '  ~ SortOrder exists';

-- TaxonRank (AddSpeciesHierarchy)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Pet_Species' AND COLUMN_NAME = 'TaxonRank')
BEGIN
    ALTER TABLE Pet_Species ADD TaxonRank nvarchar(20) NOT NULL CONSTRAINT DF_Species_TaxonRank DEFAULT 'species';
    PRINT '  + TaxonRank';
END
ELSE PRINT '  ~ TaxonRank exists';

-- ScientificName (AddSpeciesHierarchy)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Pet_Species' AND COLUMN_NAME = 'ScientificName')
BEGIN
    ALTER TABLE Pet_Species ADD ScientificName nvarchar(150) NULL;
    PRINT '  + ScientificName';
END
ELSE PRINT '  ~ ScientificName exists';

-- ParentSpeciesId (AddSpeciesHierarchy)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Pet_Species' AND COLUMN_NAME = 'ParentSpeciesId')
BEGIN
    ALTER TABLE Pet_Species ADD ParentSpeciesId uniqueidentifier NULL;
    PRINT '  + ParentSpeciesId';
END
ELSE PRINT '  ~ ParentSpeciesId exists';

PRINT '';
PRINT '--- Pet_Pets columns ---';

-- BreedVariantLabel (AddBreedPolicyAndVariantLabel)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Pet_Pets' AND COLUMN_NAME = 'BreedVariantLabel')
BEGIN
    ALTER TABLE Pet_Pets ADD BreedVariantLabel nvarchar(60) NULL;
    PRINT '  + BreedVariantLabel';
END
ELSE PRINT '  ~ BreedVariantLabel exists';

PRINT '';
PRINT '--- Pet_Breeds columns ---';

-- AllowsUserVariantLabel
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Pet_Breeds' AND COLUMN_NAME = 'AllowsUserVariantLabel')
BEGIN
    ALTER TABLE Pet_Breeds ADD AllowsUserVariantLabel bit NOT NULL CONSTRAINT DF_Breeds_AllowsUserVariantLabel DEFAULT 0;
    PRINT '  + AllowsUserVariantLabel';
END
ELSE PRINT '  ~ AllowsUserVariantLabel exists';

-- BreedType
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Pet_Breeds' AND COLUMN_NAME = 'BreedType')
BEGIN
    ALTER TABLE Pet_Breeds ADD BreedType nvarchar(20) NOT NULL CONSTRAINT DF_Breeds_BreedType DEFAULT 'Pure';
    PRINT '  + BreedType';
END
ELSE PRINT '  ~ BreedType exists';

-- Code
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Pet_Breeds' AND COLUMN_NAME = 'Code')
BEGIN
    ALTER TABLE Pet_Breeds ADD Code nvarchar(50) NOT NULL CONSTRAINT DF_Breeds_Code DEFAULT '';
    PRINT '  + Code';
END
ELSE PRINT '  ~ Code exists';

-- SortOrder
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Pet_Breeds' AND COLUMN_NAME = 'SortOrder')
BEGIN
    ALTER TABLE Pet_Breeds ADD SortOrder int NOT NULL CONSTRAINT DF_Breeds_SortOrder DEFAULT 0;
    PRINT '  + SortOrder';
END
ELSE PRINT '  ~ SortOrder exists';

PRINT '';
PRINT '=== PART 1a complete: columns added ===';
PRINT '';
GO

-- =============================================================================
-- PART 1b: Indexes, FKs, constraints (separate batch - columns must exist first)
-- =============================================================================

PRINT '--- Indexes ---';

-- IX_Pet_Species_ParentSpeciesId
IF NOT EXISTS (SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Pet_Species_ParentSpeciesId' AND object_id = OBJECT_ID('Pet_Species'))
BEGIN
    CREATE INDEX IX_Pet_Species_ParentSpeciesId ON Pet_Species (ParentSpeciesId);
    PRINT '  + IX_Pet_Species_ParentSpeciesId';
END

-- IX_Pet_Species_TaxonRank
IF NOT EXISTS (SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Pet_Species_TaxonRank' AND object_id = OBJECT_ID('Pet_Species'))
BEGIN
    CREATE INDEX IX_Pet_Species_TaxonRank ON Pet_Species (TaxonRank);
    PRINT '  + IX_Pet_Species_TaxonRank';
END

-- IX_Pet_Breeds_SpeciesId_Code (unique - may fail if existing breeds have empty Code)
IF NOT EXISTS (SELECT 1 FROM sys.indexes
    WHERE name = 'IX_Pet_Breeds_SpeciesId_Code' AND object_id = OBJECT_ID('Pet_Breeds'))
BEGIN
    BEGIN TRY
        CREATE UNIQUE INDEX IX_Pet_Breeds_SpeciesId_Code ON Pet_Breeds (SpeciesId, Code);
        PRINT '  + IX_Pet_Breeds_SpeciesId_Code';
    END TRY
    BEGIN CATCH
        PRINT '  ! IX_Pet_Breeds_SpeciesId_Code skipped (duplicate Code values - update breeds first)';
    END CATCH
END

PRINT '';
PRINT '--- Foreign Keys ---';

-- FK: Pet_Species self-referencing ParentSpeciesId
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys
    WHERE name = 'FK_Pet_Species_Pet_Species_ParentSpeciesId')
BEGIN
    ALTER TABLE Pet_Species ADD CONSTRAINT FK_Pet_Species_Pet_Species_ParentSpeciesId
        FOREIGN KEY (ParentSpeciesId) REFERENCES Pet_Species(Id);
    PRINT '  + FK_Pet_Species_Pet_Species_ParentSpeciesId';
END

-- FK: Pet_Suggestions PetId (Cascade -> Restrict)
IF EXISTS (SELECT 1 FROM sys.foreign_keys
    WHERE name = 'FK_Pet_Suggestions_Pet_Pets_PetId' AND delete_referential_action_desc = 'CASCADE')
BEGIN
    ALTER TABLE Pet_Suggestions DROP CONSTRAINT FK_Pet_Suggestions_Pet_Pets_PetId;
    ALTER TABLE Pet_Suggestions ADD CONSTRAINT FK_Pet_Suggestions_Pet_Pets_PetId
        FOREIGN KEY (PetId) REFERENCES Pet_Pets(Id) ON DELETE NO ACTION;
    PRINT '  ~ FK_Pet_Suggestions_PetId (Cascade->Restrict)';
END

-- FK: Pet_Suggestions QuestionnaireId (SetNull -> Restrict)
IF EXISTS (SELECT 1 FROM sys.foreign_keys
    WHERE name = 'FK_Pet_Suggestions_Pet_SpeciesQuestionnaires_QuestionnaireId' AND delete_referential_action_desc = 'SET_NULL')
BEGIN
    ALTER TABLE Pet_Suggestions DROP CONSTRAINT FK_Pet_Suggestions_Pet_SpeciesQuestionnaires_QuestionnaireId;
    ALTER TABLE Pet_Suggestions ADD CONSTRAINT FK_Pet_Suggestions_Pet_SpeciesQuestionnaires_QuestionnaireId
        FOREIGN KEY (QuestionnaireId) REFERENCES Pet_SpeciesQuestionnaires(Id) ON DELETE NO ACTION;
    PRINT '  ~ FK_Pet_Suggestions_QuestionnaireId (SetNull->Restrict)';
END

PRINT '';
PRINT '--- Check Constraints ---';

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Pet_Species_TaxonRank')
BEGIN
    ALTER TABLE Pet_Species ADD CONSTRAINT CK_Pet_Species_TaxonRank
        CHECK ([TaxonRank] IN ('species','category'));
    PRINT '  + CK_Pet_Species_TaxonRank';
END

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Pet_Species_Parent_NotSelf')
BEGIN
    ALTER TABLE Pet_Species ADD CONSTRAINT CK_Pet_Species_Parent_NotSelf
        CHECK ([ParentSpeciesId] IS NULL OR [ParentSpeciesId] <> [Id]);
    PRINT '  + CK_Pet_Species_Parent_NotSelf';
END

PRINT '';
PRINT '=== PART 1 complete ===';
PRINT '';
GO

-- =============================================================================
-- PART 2: Storage & GDPR tables (AddStorageGdprEntities)
-- =============================================================================

-- Storage_Files
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Storage_Files')
BEGIN
    CREATE TABLE Storage_Files (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        OwnerUserId uniqueidentifier NOT NULL,
        StorageKey nvarchar(1000) NOT NULL,
        Bucket nvarchar(100) NOT NULL,
        OriginalFileName nvarchar(500) NOT NULL,
        ContentType nvarchar(100) NOT NULL,
        FileSizeBytes bigint NOT NULL,
        Checksum nvarchar(128) NULL,
        FileCategory nvarchar(50) NOT NULL,
        RelatedEntityId uniqueidentifier NULL,
        RelatedEntityType nvarchar(50) NULL,
        ParentFileId uniqueidentifier NULL,
        Variant nvarchar(20) NOT NULL DEFAULT 'original',
        Visibility nvarchar(20) NOT NULL DEFAULT 'private',
        Status nvarchar(20) NOT NULL DEFAULT 'pending',
        VirusScanStatus nvarchar(20) NOT NULL DEFAULT 'pending',
        StorageVersion int NOT NULL DEFAULT 1,
        LastAccessedAt datetime2 NULL,
        IsPersonalData bit NOT NULL DEFAULT 1,
        ProcessingBasis nvarchar(50) NULL,
        ConsentGivenAt datetime2 NULL,
        RetentionExpiresAt datetime2 NULL,
        MarkedForDeletion bit NOT NULL DEFAULT 0,
        DeletionScheduledAt datetime2 NULL,
        LegalHold bit NOT NULL DEFAULT 0,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        DeletedAt datetime2 NULL,
        CONSTRAINT PK_Storage_Files PRIMARY KEY (Id),
        CONSTRAINT FK_Storage_Files_Auth_Users_OwnerUserId
            FOREIGN KEY (OwnerUserId) REFERENCES Auth_Users(Id) ON DELETE NO ACTION,
        CONSTRAINT FK_Storage_Files_Storage_Files_ParentFileId
            FOREIGN KEY (ParentFileId) REFERENCES Storage_Files(Id) ON DELETE NO ACTION
    );
    CREATE INDEX IX_Storage_Files_OwnerUserId ON Storage_Files (OwnerUserId);
    CREATE INDEX IX_Storage_Files_RelatedEntity ON Storage_Files (RelatedEntityId, RelatedEntityType);
    CREATE INDEX IX_Storage_Files_Status ON Storage_Files (Status);
    CREATE INDEX IX_Storage_Files_MarkedForDeletion ON Storage_Files (MarkedForDeletion) WHERE MarkedForDeletion = 1;
    CREATE INDEX IX_Storage_Files_RetentionExpires ON Storage_Files (RetentionExpiresAt) WHERE RetentionExpiresAt IS NOT NULL;
    CREATE UNIQUE INDEX IX_Storage_Files_StorageKey ON Storage_Files (StorageKey);
    CREATE INDEX IX_Storage_Files_ParentFileId ON Storage_Files (ParentFileId);
    PRINT '  + Storage_Files (7 indexes)';
END
ELSE PRINT '  ~ Storage_Files exists';

-- Pet_PetDocuments
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Pet_PetDocuments')
BEGIN
    CREATE TABLE Pet_PetDocuments (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        PetId uniqueidentifier NOT NULL,
        UploadedByUserId uniqueidentifier NOT NULL,
        Title nvarchar(200) NOT NULL,
        DocumentType nvarchar(50) NOT NULL DEFAULT 'other',
        StoredFileId uniqueidentifier NOT NULL,
        DocumentDate datetime2 NULL,
        ExpiryDate datetime2 NULL,
        Notes nvarchar(1000) NULL,
        VetName nvarchar(200) NULL,
        IsVerified bit NOT NULL DEFAULT 0,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt datetime2 NULL,
        CONSTRAINT PK_Pet_PetDocuments PRIMARY KEY (Id),
        CONSTRAINT FK_Pet_PetDocuments_Pet_Pets_PetId
            FOREIGN KEY (PetId) REFERENCES Pet_Pets(Id) ON DELETE CASCADE,
        CONSTRAINT FK_Pet_PetDocuments_Auth_Users_UploadedByUserId
            FOREIGN KEY (UploadedByUserId) REFERENCES Auth_Users(Id) ON DELETE NO ACTION,
        CONSTRAINT FK_Pet_PetDocuments_Storage_Files_StoredFileId
            FOREIGN KEY (StoredFileId) REFERENCES Storage_Files(Id) ON DELETE NO ACTION
    );
    CREATE INDEX IX_Pet_PetDocuments_PetId_Type ON Pet_PetDocuments (PetId, DocumentType);
    CREATE INDEX IX_Pet_PetDocuments_ExpiryDate ON Pet_PetDocuments (ExpiryDate) WHERE ExpiryDate IS NOT NULL;
    CREATE INDEX IX_Pet_PetDocuments_UploadedByUserId ON Pet_PetDocuments (UploadedByUserId);
    CREATE INDEX IX_Pet_PetDocuments_StoredFileId ON Pet_PetDocuments (StoredFileId);
    PRINT '  + Pet_PetDocuments (4 indexes)';
END
ELSE PRINT '  ~ Pet_PetDocuments exists';

-- Auth_UserConsents
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Auth_UserConsents')
BEGIN
    CREATE TABLE Auth_UserConsents (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        UserId uniqueidentifier NOT NULL,
        ConsentType nvarchar(50) NOT NULL,
        ConsentVersion nvarchar(20) NOT NULL,
        IsGranted bit NOT NULL DEFAULT 0,
        GrantedAt datetime2 NULL,
        RevokedAt datetime2 NULL,
        IpAddress nvarchar(50) NULL,
        UserAgent nvarchar(500) NULL,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Auth_UserConsents PRIMARY KEY (Id),
        CONSTRAINT FK_Auth_UserConsents_Auth_Users_UserId
            FOREIGN KEY (UserId) REFERENCES Auth_Users(Id) ON DELETE CASCADE
    );
    CREATE INDEX IX_Auth_UserConsents_UserId_Type ON Auth_UserConsents (UserId, ConsentType);
    CREATE INDEX IX_Auth_UserConsents_Type ON Auth_UserConsents (ConsentType);
    PRINT '  + Auth_UserConsents (2 indexes)';
END
ELSE PRINT '  ~ Auth_UserConsents exists';

-- Account_Exports
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Account_Exports')
BEGIN
    CREATE TABLE Account_Exports (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        UserId uniqueidentifier NOT NULL,
        Status nvarchar(20) NOT NULL DEFAULT 'requested',
        RequestedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CompletedAt datetime2 NULL,
        ExpiresAt datetime2 NULL,
        FileStorageKey nvarchar(1000) NULL,
        FileSizeBytes bigint NULL,
        ErrorMessage nvarchar(2000) NULL,
        DownloadCount int NOT NULL DEFAULT 0,
        LastDownloadAt datetime2 NULL,
        CONSTRAINT PK_Account_Exports PRIMARY KEY (Id),
        CONSTRAINT FK_Account_Exports_Auth_Users_UserId
            FOREIGN KEY (UserId) REFERENCES Auth_Users(Id) ON DELETE CASCADE
    );
    CREATE INDEX IX_Account_Exports_UserId_Status ON Account_Exports (UserId, Status);
    CREATE INDEX IX_Account_Exports_ExpiresAt ON Account_Exports (ExpiresAt) WHERE ExpiresAt IS NOT NULL;
    PRINT '  + Account_Exports (2 indexes)';
END
ELSE PRINT '  ~ Account_Exports exists';

PRINT '';
PRINT '=== PART 2 complete ===';
PRINT '';
GO

-- =============================================================================
-- PART 3: Seed expanded species (SeedExpandedSpecies)
-- New batch required: SQL Server validates column names at parse time
-- =============================================================================

PRINT '--- Updating existing species ---';

-- Set SortOrder + BreedPolicy for original 17 species (only if still at defaults)
UPDATE Pet_Species SET SortOrder = 1,  BreedPolicy = 'Optional', AllowsMixedLabel = 1 WHERE Code = 'cane'     AND SortOrder = 0;
UPDATE Pet_Species SET SortOrder = 2,  BreedPolicy = 'Optional', AllowsMixedLabel = 1 WHERE Code = 'gatto'    AND SortOrder = 0;
UPDATE Pet_Species SET SortOrder = 3,  BreedPolicy = 'Optional', AllowsMixedLabel = 1 WHERE Code = 'coniglio' AND SortOrder = 0;
UPDATE Pet_Species SET SortOrder = 4,  BreedPolicy = 'None'     WHERE Code = 'criceto'  AND SortOrder = 0;
UPDATE Pet_Species SET SortOrder = 5,  BreedPolicy = 'None'     WHERE Code = 'cavia'    AND SortOrder = 0;
UPDATE Pet_Species SET SortOrder = 6,  BreedPolicy = 'None'     WHERE Code = 'furetto'  AND SortOrder = 0;
UPDATE Pet_Species SET SortOrder = 7,  BreedPolicy = 'None'     WHERE Code = 'gerbillo' AND SortOrder = 0;
UPDATE Pet_Species SET SortOrder = 8,  BreedPolicy = 'None'     WHERE Code = 'ratto'    AND SortOrder = 0;
UPDATE Pet_Species SET SortOrder = 9,  BreedPolicy = 'Optional', AllowsMixedLabel = 1 WHERE Code = 'cavallo'  AND SortOrder = 0;
UPDATE Pet_Species SET SortOrder = 10, BreedPolicy = 'Optional' WHERE Code = 'pappagallo' AND SortOrder = 0;
UPDATE Pet_Species SET SortOrder = 11, BreedPolicy = 'None'     WHERE Code = 'canarino' AND SortOrder = 0;
UPDATE Pet_Species SET SortOrder = 12, BreedPolicy = 'None'     WHERE Code = 'uccello'  AND SortOrder = 0;
PRINT '  ~ SortOrder + BreedPolicy set for original species';

-- Pesce -> category
UPDATE Pet_Species SET TaxonRank = 'category'
WHERE Id = '10000000-0000-0000-0000-000000000015' AND TaxonRank <> 'category';
IF @@ROWCOUNT > 0 PRINT '  ~ Pesce -> category';

-- Anfibio -> category
UPDATE Pet_Species SET TaxonRank = 'category'
WHERE Id = '10000000-0000-0000-0000-000000000016' AND TaxonRank <> 'category';
IF @@ROWCOUNT > 0 PRINT '  ~ Anfibio -> category';

-- Tartaruga -> Tartaruga di terra
UPDATE Pet_Species SET Name = 'Tartaruga di terra', Code = 'tartaruga-terra'
WHERE Id = '10000000-0000-0000-0000-000000000013' AND Code = 'tartaruga';
IF @@ROWCOUNT > 0 PRINT '  ~ Tartaruga -> Tartaruga di terra';

-- Serpente -> Serpente non velenoso
UPDATE Pet_Species SET Name = 'Serpente non velenoso', Code = 'serpente-non-velenoso'
WHERE Id = '10000000-0000-0000-0000-000000000014' AND Code = 'serpente';
IF @@ROWCOUNT > 0 PRINT '  ~ Serpente -> Serpente non velenoso';

PRINT '';
PRINT '--- Inserting parent categories ---';

-- Pesce category (may not exist in prod - prod has different seed data)
IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000015')
BEGIN
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000015', 'pesce', 'Pesce', 'pesce', 'Pesci domestici', NULL, 'poco', 'molto_alto', 'acquario', 1, 'basso', 'bassa', 1, 50, 'None', 0, 'category', SYSUTCDATETIME());
    PRINT '  + Pesce (category)';
END

-- Anfibio category (may not exist in prod)
IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000016')
BEGIN
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000016', 'anfibio', 'Anfibio', 'anfibio', 'Anfibi domestici', NULL, 'poco', 'molto_alto', 'terrario', 1, 'basso', 'media', 1, 55, 'None', 0, 'category', SYSUTCDATETIME());
    PRINT '  + Anfibio (category)';
END

PRINT '';
PRINT '--- Inserting new species ---';

-- Invertebrato category
IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000040')
BEGIN
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000040', 'invertebrato', 'Invertebrato', 'invertebrato', 'Invertebrati domestici', NULL, 'poco', 'molto_alto', 'terrario', 1, 'basso', 'bassa', 1, 60, 'None', 0, 'category', SYSUTCDATETIME());
    PRINT '  + Invertebrato (category)';
END

-- UCCELLI (6)
IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000017')
BEGIN
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, CreatedAt)
    VALUES
    ('10000000-0000-0000-0000-000000000017', 'cocorita', 'Cocorita', 'uccello', 'Pappagallino ondulato colorato', NULL, 'poco', 'alto', 'interno', 1, 'medio', 'bassa', 1, 13, 'None', 0, 'species', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000018', 'calopsita', 'Calopsita', 'uccello', 'Pappagallo con cresta gialla', NULL, 'medio', 'medio', 'interno', 1, 'medio', 'media', 1, 14, 'None', 0, 'species', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000019', 'inseparabile', 'Inseparabile', 'uccello', 'Piccolo pappagallo molto affettuoso', NULL, 'medio', 'basso', 'interno', 1, 'alto', 'media', 1, 15, 'None', 0, 'species', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000020', 'parrocchetto', 'Parrocchetto', 'uccello', 'Pappagallo di media taglia', NULL, 'medio', 'medio', 'interno', 1, 'alto', 'media', 1, 16, 'None', 0, 'species', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000021', 'diamantino', 'Diamantino', 'uccello', 'Piccolo uccello esotico colorato', NULL, 'poco', 'alto', 'interno', 1, 'basso', 'bassa', 1, 17, 'None', 0, 'species', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000022', 'piccione-viaggiatore', 'Piccione viaggiatore', 'uccello', 'Colombo con senso dell''orientamento', NULL, 'medio', 'alto', 'balcone', 1, 'medio', 'media', 1, 18, 'None', 0, 'species', SYSUTCDATETIME());
    PRINT '  + 6 uccelli';
END

-- RETTILI (3)
IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000023')
BEGIN
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, CreatedAt)
    VALUES
    ('10000000-0000-0000-0000-000000000023', 'tartaruga-acqua', 'Tartaruga d''acqua', 'rettile', 'Tartaruga acquatica domestica', NULL, 'poco', 'molto_alto', 'acquario', 1, 'basso', 'media', 1, 19, 'None', 0, 'species', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000024', 'pogona', 'Pogona', 'rettile', 'Drago barbuto australiano', NULL, 'poco', 'alto', 'terrario', 1, 'basso', 'media', 1, 20, 'None', 0, 'species', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000025', 'geco-leopardino', 'Geco leopardino', 'rettile', 'Piccolo rettile notturno maculato', NULL, 'poco', 'molto_alto', 'terrario', 1, 'basso', 'bassa', 1, 21, 'None', 0, 'species', SYSUTCDATETIME());
    PRINT '  + 3 rettili';
END

-- ANFIBI (4, ParentSpeciesId -> Anfibio)
IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000026')
BEGIN
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, ParentSpeciesId, CreatedAt)
    VALUES
    ('10000000-0000-0000-0000-000000000026', 'axolotl', 'Axolotl', 'anfibio', 'Salamandra messicana neotenica', NULL, 'poco', 'molto_alto', 'acquario', 1, 'basso', 'media', 1, 22, 'None', 0, 'species', '10000000-0000-0000-0000-000000000016', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000027', 'rana-pacman', 'Rana pacman', 'anfibio', 'Rana dalla bocca grande', NULL, 'poco', 'molto_alto', 'terrario', 1, 'basso', 'bassa', 1, 23, 'None', 0, 'species', '10000000-0000-0000-0000-000000000016', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000028', 'tritone', 'Tritone', 'anfibio', 'Anfibio acquatico caudato', NULL, 'poco', 'molto_alto', 'acquario', 1, 'basso', 'media', 1, 24, 'None', 0, 'species', '10000000-0000-0000-0000-000000000016', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000029', 'salamandra', 'Salamandra', 'anfibio', 'Anfibio terrestre', NULL, 'poco', 'molto_alto', 'terrario', 1, 'basso', 'media', 1, 25, 'None', 0, 'species', '10000000-0000-0000-0000-000000000016', SYSUTCDATETIME());
    PRINT '  + 4 anfibi';
END

-- PESCI (10, ParentSpeciesId -> Pesce)
IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000030')
BEGIN
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, ParentSpeciesId, CreatedAt)
    VALUES
    ('10000000-0000-0000-0000-000000000030', 'pesce-rosso', 'Pesce rosso', 'pesce', 'Classico pesce ornamentale', NULL, 'poco', 'molto_alto', 'acquario', 1, 'basso', 'bassa', 1, 26, 'None', 0, 'species', '10000000-0000-0000-0000-000000000015', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000031', 'betta-splendens', 'Betta splendens', 'pesce', 'Pesce combattente colorato', NULL, 'poco', 'molto_alto', 'acquario', 1, 'basso', 'bassa', 1, 27, 'None', 0, 'species', '10000000-0000-0000-0000-000000000015', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000032', 'guppy', 'Guppy', 'pesce', 'Piccolo pesce vivace e colorato', NULL, 'poco', 'molto_alto', 'acquario', 1, 'medio', 'bassa', 1, 28, 'None', 0, 'species', '10000000-0000-0000-0000-000000000015', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000033', 'molly', 'Molly', 'pesce', 'Pesce tropicale pacifico', NULL, 'poco', 'molto_alto', 'acquario', 1, 'medio', 'bassa', 1, 29, 'None', 0, 'species', '10000000-0000-0000-0000-000000000015', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000034', 'platy', 'Platy', 'pesce', 'Pesce tropicale resistente', NULL, 'poco', 'molto_alto', 'acquario', 1, 'medio', 'bassa', 1, 30, 'None', 0, 'species', '10000000-0000-0000-0000-000000000015', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000035', 'discus', 'Discus', 'pesce', 'Re dell''acquario tropicale', NULL, 'medio', 'molto_alto', 'acquario', 1, 'basso', 'alta', 1, 31, 'None', 0, 'species', '10000000-0000-0000-0000-000000000015', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000036', 'neon', 'Neon', 'pesce', 'Piccolo pesce luminoso da branco', NULL, 'poco', 'molto_alto', 'acquario', 1, 'medio', 'bassa', 1, 32, 'None', 0, 'species', '10000000-0000-0000-0000-000000000015', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000037', 'corydoras', 'Corydoras', 'pesce', 'Pesce gatto pulitore', NULL, 'poco', 'molto_alto', 'acquario', 1, 'medio', 'bassa', 1, 33, 'None', 0, 'species', '10000000-0000-0000-0000-000000000015', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000038', 'ciclidi-africani', 'Ciclidi africani', 'pesce', 'Pesci colorati dei laghi africani', NULL, 'poco', 'molto_alto', 'acquario', 1, 'medio', 'media', 1, 34, 'None', 0, 'species', '10000000-0000-0000-0000-000000000015', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000039', 'pesci-tropicali', 'Pesci tropicali', 'pesce', 'Acquario tropicale misto', NULL, 'poco', 'molto_alto', 'acquario', 1, 'medio', 'media', 1, 35, 'None', 0, 'species', '10000000-0000-0000-0000-000000000015', SYSUTCDATETIME());
    PRINT '  + 10 pesci';
END

-- INVERTEBRATI (6, ParentSpeciesId -> Invertebrato)
IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000041')
BEGIN
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, ParentSpeciesId, CreatedAt)
    VALUES
    ('10000000-0000-0000-0000-000000000041', 'ape', 'Ape', 'invertebrato', 'Insetto impollinatore domestico', NULL, 'medio', 'molto_alto', 'giardino', 1, 'alto', 'media', 1, 61, 'None', 0, 'species', '10000000-0000-0000-0000-000000000040', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000042', 'gamberetto', 'Gamberetto', 'invertebrato', 'Crostaceo d''acqua dolce', NULL, 'poco', 'molto_alto', 'acquario', 1, 'basso', 'bassa', 1, 62, 'None', 0, 'species', '10000000-0000-0000-0000-000000000040', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000043', 'granchio-acqua-dolce', 'Granchio d''acqua dolce', 'invertebrato', 'Crostaceo acquatico domestico', NULL, 'poco', 'molto_alto', 'acquario', 1, 'basso', 'bassa', 1, 63, 'None', 0, 'species', '10000000-0000-0000-0000-000000000040', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000044', 'insetto-stecco', 'Insetto stecco', 'invertebrato', 'Insetto mimetico a forma di ramoscello', NULL, 'poco', 'molto_alto', 'terrario', 1, 'basso', 'bassa', 1, 64, 'None', 0, 'species', '10000000-0000-0000-0000-000000000040', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000045', 'insetto-foglia', 'Insetto foglia', 'invertebrato', 'Insetto mimetico a forma di foglia', NULL, 'poco', 'molto_alto', 'terrario', 1, 'basso', 'bassa', 1, 65, 'None', 0, 'species', '10000000-0000-0000-0000-000000000040', SYSUTCDATETIME()),
    ('10000000-0000-0000-0000-000000000046', 'tarantola', 'Tarantola', 'invertebrato', 'Ragno di grandi dimensioni', NULL, 'poco', 'molto_alto', 'terrario', 1, 'basso', 'bassa', 1, 66, 'None', 0, 'species', '10000000-0000-0000-0000-000000000040', SYSUTCDATETIME());
    PRINT '  + 6 invertebrati';
END

PRINT '';
PRINT '=== PART 3 complete ===';
PRINT '';

-- =============================================================================
-- PART 4: Register migrations in EF Core history
-- =============================================================================

IF NOT EXISTS (SELECT 1 FROM __EFMigrationsHistory WHERE MigrationId = '20260214231345_AddBreedPolicyAndVariantLabel')
BEGIN
    INSERT INTO __EFMigrationsHistory (MigrationId, ProductVersion)
    VALUES ('20260214231345_AddBreedPolicyAndVariantLabel', '8.0.0');
    PRINT '  + Registered AddBreedPolicyAndVariantLabel';
END

IF NOT EXISTS (SELECT 1 FROM __EFMigrationsHistory WHERE MigrationId = '20260215120000_AddStorageGdprEntities')
BEGIN
    INSERT INTO __EFMigrationsHistory (MigrationId, ProductVersion)
    VALUES ('20260215120000_AddStorageGdprEntities', '8.0.0');
    PRINT '  + Registered AddStorageGdprEntities';
END

IF NOT EXISTS (SELECT 1 FROM __EFMigrationsHistory WHERE MigrationId = '20260215150000_AddSpeciesHierarchy')
BEGIN
    INSERT INTO __EFMigrationsHistory (MigrationId, ProductVersion)
    VALUES ('20260215150000_AddSpeciesHierarchy', '8.0.0');
    PRINT '  + Registered AddSpeciesHierarchy';
END

IF NOT EXISTS (SELECT 1 FROM __EFMigrationsHistory WHERE MigrationId = '20260215180000_SeedExpandedSpecies')
BEGIN
    INSERT INTO __EFMigrationsHistory (MigrationId, ProductVersion)
    VALUES ('20260215180000_SeedExpandedSpecies', '8.0.0');
    PRINT '  + Registered SeedExpandedSpecies';
END

PRINT '';
PRINT '=== PART 4 complete ===';
PRINT '';

-- =============================================================================
-- VERIFY
-- =============================================================================
PRINT '=== Verification ===';
SELECT 'Total species' AS [Check], COUNT(*) AS [Value] FROM Pet_Species
UNION ALL
SELECT 'TaxonRank=species', COUNT(*) FROM Pet_Species WHERE TaxonRank = 'species'
UNION ALL
SELECT 'TaxonRank=category', COUNT(*) FROM Pet_Species WHERE TaxonRank = 'category'
UNION ALL
SELECT 'With ParentSpeciesId', COUNT(*) FROM Pet_Species WHERE ParentSpeciesId IS NOT NULL
UNION ALL
SELECT 'EF Migrations', COUNT(*) FROM __EFMigrationsHistory;

PRINT '';
PRINT '=== ALL MIGRATIONS COMPLETE ===';
