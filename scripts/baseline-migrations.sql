-- =============================================================================
-- FIUTAMI - Baseline Migrations Script
-- Porta il database prod allo stato completo allineato con EF Core
-- Eseguire su: fiutami_prod (PROD) poi fiutami_stage (STAGE)
-- =============================================================================

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
PRINT '====================================================';
PRINT 'FIUTAMI Baseline Migrations - Starting...';
PRINT '====================================================';

-- =============================================================================
-- STEP 1: Aggiungere colonne mancanti a Auth_Users (se non esistono)
-- =============================================================================
PRINT '';
PRINT '1. Verificando colonne Auth_Users...';

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Auth_Users' AND COLUMN_NAME = 'DeletedAt')
BEGIN
    ALTER TABLE Auth_Users ADD DeletedAt datetime2 NULL;
    PRINT '   - Aggiunta colonna DeletedAt';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Auth_Users' AND COLUMN_NAME = 'IsDeleted')
BEGIN
    ALTER TABLE Auth_Users ADD IsDeleted bit NOT NULL DEFAULT 0;
    PRINT '   - Aggiunta colonna IsDeleted';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Auth_Users' AND COLUMN_NAME = 'IsEmailVerified')
BEGIN
    ALTER TABLE Auth_Users ADD IsEmailVerified bit NOT NULL DEFAULT 0;
    PRINT '   - Aggiunta colonna IsEmailVerified';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Auth_Users' AND COLUMN_NAME = 'EmailVerifiedAt')
BEGIN
    ALTER TABLE Auth_Users ADD EmailVerifiedAt datetime2 NULL;
    PRINT '   - Aggiunta colonna EmailVerifiedAt';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Auth_Users' AND COLUMN_NAME = 'FailedLoginAttempts')
BEGIN
    ALTER TABLE Auth_Users ADD FailedLoginAttempts int NOT NULL DEFAULT 0;
    PRINT '   - Aggiunta colonna FailedLoginAttempts';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Auth_Users' AND COLUMN_NAME = 'LockoutEndAt')
BEGIN
    ALTER TABLE Auth_Users ADD LockoutEndAt datetime2 NULL;
    PRINT '   - Aggiunta colonna LockoutEndAt';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Auth_Users' AND COLUMN_NAME = 'LastPasswordChangeAt')
BEGIN
    ALTER TABLE Auth_Users ADD LastPasswordChangeAt datetime2 NULL;
    PRINT '   - Aggiunta colonna LastPasswordChangeAt';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Auth_Users' AND COLUMN_NAME = 'PendingEmail')
BEGIN
    ALTER TABLE Auth_Users ADD PendingEmail nvarchar(255) NULL;
    PRINT '   - Aggiunta colonna PendingEmail';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Auth_Users' AND COLUMN_NAME = 'PendingEmailToken')
BEGIN
    ALTER TABLE Auth_Users ADD PendingEmailToken nvarchar(500) NULL;
    PRINT '   - Aggiunta colonna PendingEmailToken';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Auth_Users' AND COLUMN_NAME = 'PendingEmailTokenExpiresAt')
BEGIN
    ALTER TABLE Auth_Users ADD PendingEmailTokenExpiresAt datetime2 NULL;
    PRINT '   - Aggiunta colonna PendingEmailTokenExpiresAt';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Auth_RefreshTokens' AND COLUMN_NAME = 'UserAgent')
BEGIN
    ALTER TABLE Auth_RefreshTokens ADD UserAgent nvarchar(500) NULL;
    PRINT '   - Aggiunta colonna UserAgent a Auth_RefreshTokens';
END

-- =============================================================================
-- STEP 2: Creare tabelle Auth_* mancanti
-- =============================================================================
PRINT '';
PRINT '2. Creando tabelle Auth_*...';

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Auth_AccountDeletionRequests')
BEGIN
    CREATE TABLE Auth_AccountDeletionRequests (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        UserId uniqueidentifier NOT NULL,
        DeletionType nvarchar(10) NOT NULL DEFAULT 'soft',
        Reason nvarchar(500) NULL,
        RequestedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        ScheduledDeletionAt datetime2 NOT NULL,
        CancelledAt datetime2 NULL,
        ExecutedAt datetime2 NULL,
        Status nvarchar(20) NOT NULL DEFAULT 'pending',
        CONSTRAINT PK_Auth_AccountDeletionRequests PRIMARY KEY (Id),
        CONSTRAINT FK_Auth_AccountDeletionRequests_Auth_Users_UserId FOREIGN KEY (UserId) REFERENCES Auth_Users(Id) ON DELETE CASCADE
    );
    CREATE INDEX IX_Auth_AccountDeletionRequests_ScheduledDeletionAt ON Auth_AccountDeletionRequests(ScheduledDeletionAt);
    CREATE INDEX IX_Auth_AccountDeletionRequests_Status ON Auth_AccountDeletionRequests(Status);
    CREATE UNIQUE INDEX IX_Auth_AccountDeletionRequests_UserId ON Auth_AccountDeletionRequests(UserId);
    PRINT '   - Creata Auth_AccountDeletionRequests';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Auth_AuditLogs')
BEGIN
    CREATE TABLE Auth_AuditLogs (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        UserId uniqueidentifier NULL,
        Action nvarchar(50) NOT NULL,
        EntityType nvarchar(50) NOT NULL,
        EntityId uniqueidentifier NULL,
        OldValues nvarchar(max) NULL,
        NewValues nvarchar(max) NULL,
        IpAddress nvarchar(50) NULL,
        UserAgent nvarchar(500) NULL,
        Success bit NOT NULL DEFAULT 1,
        FailureReason nvarchar(500) NULL,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Auth_AuditLogs PRIMARY KEY (Id),
        CONSTRAINT FK_Auth_AuditLogs_Auth_Users_UserId FOREIGN KEY (UserId) REFERENCES Auth_Users(Id) ON DELETE SET NULL
    );
    CREATE INDEX IX_Auth_AuditLogs_Action ON Auth_AuditLogs(Action);
    CREATE INDEX IX_Auth_AuditLogs_CreatedAt ON Auth_AuditLogs(CreatedAt);
    CREATE INDEX IX_Auth_AuditLogs_UserId ON Auth_AuditLogs(UserId);
    PRINT '   - Creata Auth_AuditLogs';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Auth_UserSessions')
BEGIN
    CREATE TABLE Auth_UserSessions (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        UserId uniqueidentifier NOT NULL,
        RefreshTokenId uniqueidentifier NOT NULL,
        DeviceType nvarchar(20) NOT NULL,
        Browser nvarchar(50) NOT NULL,
        OperatingSystem nvarchar(50) NOT NULL,
        DeviceName nvarchar(100) NOT NULL,
        IpAddress nvarchar(50) NULL,
        City nvarchar(100) NULL,
        Country nvarchar(100) NULL,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        LastActivityAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        RevokedAt datetime2 NULL,
        IsCurrent bit NOT NULL DEFAULT 0,
        CONSTRAINT PK_Auth_UserSessions PRIMARY KEY (Id),
        CONSTRAINT FK_Auth_UserSessions_Auth_RefreshTokens_RefreshTokenId FOREIGN KEY (RefreshTokenId) REFERENCES Auth_RefreshTokens(Id),
        CONSTRAINT FK_Auth_UserSessions_Auth_Users_UserId FOREIGN KEY (UserId) REFERENCES Auth_Users(Id) ON DELETE CASCADE
    );
    CREATE UNIQUE INDEX IX_Auth_UserSessions_RefreshTokenId ON Auth_UserSessions(RefreshTokenId);
    CREATE INDEX IX_Auth_UserSessions_UserId ON Auth_UserSessions(UserId);
    PRINT '   - Creata Auth_UserSessions';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Auth_UserSettings')
BEGIN
    CREATE TABLE Auth_UserSettings (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        UserId uniqueidentifier NOT NULL,
        EmailNotifications bit NOT NULL DEFAULT 1,
        PushNotifications bit NOT NULL DEFAULT 1,
        MarketingEmails bit NOT NULL DEFAULT 0,
        WeeklyDigest bit NOT NULL DEFAULT 0,
        ProfilePublic bit NOT NULL DEFAULT 1,
        ShowEmail bit NOT NULL DEFAULT 0,
        ShowPhone bit NOT NULL DEFAULT 0,
        AllowSearchByEmail bit NOT NULL DEFAULT 1,
        Language nvarchar(10) NOT NULL DEFAULT 'it',
        Timezone nvarchar(50) NOT NULL DEFAULT 'Europe/Rome',
        Theme nvarchar(20) NOT NULL DEFAULT 'system',
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Auth_UserSettings PRIMARY KEY (Id),
        CONSTRAINT FK_Auth_UserSettings_Auth_Users_UserId FOREIGN KEY (UserId) REFERENCES Auth_Users(Id) ON DELETE CASCADE
    );
    CREATE UNIQUE INDEX IX_Auth_UserSettings_UserId ON Auth_UserSettings(UserId);
    PRINT '   - Creata Auth_UserSettings';
END

-- =============================================================================
-- STEP 3: Creare tabelle Pet_* (Species deve essere prima di Pets)
-- =============================================================================
PRINT '';
PRINT '3. Creando tabelle Pet_*...';

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Pet_Species')
BEGIN
    CREATE TABLE Pet_Species (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        Code nvarchar(50) NOT NULL,
        Name nvarchar(100) NOT NULL,
        Category nvarchar(50) NOT NULL,
        Description nvarchar(500) NULL,
        ImageUrl nvarchar(500) NULL,
        TimeRequirement nvarchar(20) NOT NULL,
        IndependenceLevel nvarchar(20) NOT NULL,
        SpaceRequirement nvarchar(20) NOT NULL,
        Hypoallergenic bit NOT NULL DEFAULT 0,
        ActivityLevel nvarchar(20) NOT NULL,
        CareLevel nvarchar(20) NOT NULL,
        IsActive bit NOT NULL DEFAULT 1,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Pet_Species PRIMARY KEY (Id)
    );
    CREATE UNIQUE INDEX IX_Pet_Species_Code ON Pet_Species(Code);
    CREATE INDEX IX_Pet_Species_IsActive ON Pet_Species(IsActive);
    PRINT '   - Creata Pet_Species';

    -- Seed species data
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive)
    VALUES
        (NEWID(), 'gatto', 'Gatto', 'mammifero', 'Un compagno indipendente ma affettuoso', 'medio', 'alto', 'interno', 0, 'medio', 'media', 1),
        (NEWID(), 'cane_piccolo', 'Cane piccola taglia', 'mammifero', 'Affettuoso e giocherellone', 'molto', 'basso', 'balcone', 0, 'alto', 'alta', 1),
        (NEWID(), 'cane_medio', 'Cane media taglia', 'mammifero', 'Equilibrato e versatile', 'molto', 'basso', 'giardino', 0, 'alto', 'alta', 1),
        (NEWID(), 'cane_grande', 'Cane grande taglia', 'mammifero', 'Fedele e protettivo', 'molto', 'basso', 'giardino', 0, 'alto', 'alta', 1),
        (NEWID(), 'criceto', 'Criceto', 'mammifero', 'Piccolo e divertente', 'poco', 'alto', 'interno', 1, 'basso', 'bassa', 1),
        (NEWID(), 'coniglio', 'Coniglio', 'mammifero', 'Dolce e socievole', 'medio', 'medio', 'balcone', 0, 'medio', 'media', 1),
        (NEWID(), 'porcellino_india', 'Porcellino d''India', 'mammifero', 'Socievole e tranquillo', 'poco', 'medio', 'interno', 1, 'basso', 'bassa', 1),
        (NEWID(), 'canarino', 'Canarino', 'uccello', 'Melodioso e colorato', 'poco', 'alto', 'interno', 1, 'basso', 'bassa', 1),
        (NEWID(), 'pappagallino', 'Pappagallino', 'uccello', 'Intelligente e interattivo', 'medio', 'medio', 'interno', 1, 'medio', 'media', 1),
        (NEWID(), 'tartaruga', 'Tartaruga', 'rettile', 'Longeva e tranquilla', 'poco', 'alto', 'balcone', 1, 'basso', 'bassa', 1),
        (NEWID(), 'geco', 'Geco', 'rettile', 'Esotico e affascinante', 'poco', 'alto', 'interno', 1, 'basso', 'media', 1),
        (NEWID(), 'pesce_rosso', 'Pesce rosso', 'pesce', 'Classico e rilassante', 'poco', 'alto', 'interno', 1, 'basso', 'bassa', 1),
        (NEWID(), 'acquario_tropicale', 'Acquario tropicale', 'pesce', 'Colorato e affascinante', 'medio', 'alto', 'interno', 1, 'basso', 'media', 1);
    PRINT '   - Seed species data inserito';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Pet_SpeciesQuestionnaires')
BEGIN
    CREATE TABLE Pet_SpeciesQuestionnaires (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        UserId uniqueidentifier NOT NULL,
        Q1_Time nvarchar(20) NULL,
        Q2_Presence nvarchar(20) NULL,
        Q3_Space nvarchar(20) NULL,
        Q4_Allergies nvarchar(10) NULL,
        Q5_Desire nvarchar(20) NULL,
        Q6_Care nvarchar(20) NULL,
        RecommendedSpecies nvarchar(50) NULL,
        MatchScore int NULL,
        Status nvarchar(20) NOT NULL DEFAULT 'in_progress',
        CurrentStep int NOT NULL DEFAULT 1,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CompletedAt datetime2 NULL,
        CONSTRAINT PK_Pet_SpeciesQuestionnaires PRIMARY KEY (Id),
        CONSTRAINT FK_Pet_SpeciesQuestionnaires_Auth_Users_UserId FOREIGN KEY (UserId) REFERENCES Auth_Users(Id) ON DELETE CASCADE
    );
    CREATE INDEX IX_Pet_SpeciesQuestionnaires_CreatedAt ON Pet_SpeciesQuestionnaires(CreatedAt);
    CREATE INDEX IX_Pet_SpeciesQuestionnaires_Status ON Pet_SpeciesQuestionnaires(Status);
    CREATE INDEX IX_Pet_SpeciesQuestionnaires_UserId ON Pet_SpeciesQuestionnaires(UserId);
    PRINT '   - Creata Pet_SpeciesQuestionnaires';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Pet_Pets')
BEGIN
    CREATE TABLE Pet_Pets (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        UserId uniqueidentifier NOT NULL,
        SpeciesId uniqueidentifier NOT NULL,
        BreedId uniqueidentifier NULL,
        Name nvarchar(100) NOT NULL,
        Nickname nvarchar(100) NULL,
        DateOfBirth date NULL,
        DateAcquired date NULL,
        Gender nvarchar(10) NULL,
        Color nvarchar(50) NULL,
        Size nvarchar(20) NULL,
        Weight decimal(5,2) NULL,
        IsNeutered bit NOT NULL DEFAULT 0,
        Microchip nvarchar(50) NULL,
        Notes nvarchar(2000) NULL,
        PrimaryPhotoUrl nvarchar(500) NULL,
        CoverPhotoUrl nvarchar(500) NULL,
        IsActive bit NOT NULL DEFAULT 1,
        IsDeleted bit NOT NULL DEFAULT 0,
        DeletedAt datetime2 NULL,
        DeletionReason nvarchar(50) NULL,
        RowVersion rowversion NOT NULL,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Pet_Pets PRIMARY KEY (Id),
        CONSTRAINT FK_Pet_Pets_Auth_Users_UserId FOREIGN KEY (UserId) REFERENCES Auth_Users(Id),
        CONSTRAINT FK_Pet_Pets_Pet_Species_SpeciesId FOREIGN KEY (SpeciesId) REFERENCES Pet_Species(Id)
    );
    CREATE INDEX IX_Pet_Pets_CreatedAt ON Pet_Pets(CreatedAt);
    CREATE UNIQUE INDEX IX_Pet_Pets_Microchip ON Pet_Pets(Microchip) WHERE Microchip IS NOT NULL;
    CREATE INDEX IX_Pet_Pets_SpeciesId_Active ON Pet_Pets(SpeciesId, IsActive);
    CREATE INDEX IX_Pet_Pets_UserId_Active ON Pet_Pets(UserId, IsActive, IsDeleted);
    PRINT '   - Creata Pet_Pets';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Pet_Breeds')
BEGIN
    CREATE TABLE Pet_Breeds (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        SpeciesId uniqueidentifier NOT NULL,
        Name nvarchar(100) NOT NULL,
        NameOriginal nvarchar(100) NULL,
        Origin nvarchar(100) NULL,
        Recognition nvarchar(50) NULL,
        ImageUrl nvarchar(500) NULL,
        Description nvarchar(1000) NULL,
        GeneticsInfo nvarchar(200) NULL,
        GroupFCI nvarchar(100) NULL,
        AncestralBreeds nvarchar(500) NULL,
        HeightMinCm int NULL,
        HeightMaxCm int NULL,
        WeightMinKg decimal(5,2) NULL,
        WeightMaxKg decimal(5,2) NULL,
        CoatType nvarchar(100) NULL,
        Colors nvarchar(500) NULL,
        LifespanMinYears int NULL,
        LifespanMaxYears int NULL,
        EnergyLevel nvarchar(20) NULL,
        SocialityLevel nvarchar(20) NULL,
        TrainabilityLevel nvarchar(20) NULL,
        TemperamentTraits nvarchar(500) NULL,
        SuitableFor nvarchar(500) NULL,
        CareRituals nvarchar(2000) NULL,
        HealthRisks nvarchar(2000) NULL,
        History nvarchar(4000) NULL,
        Popularity int NOT NULL DEFAULT 50,
        IsActive bit NOT NULL DEFAULT 1,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Pet_Breeds PRIMARY KEY (Id),
        CONSTRAINT FK_Pet_Breeds_Pet_Species_SpeciesId FOREIGN KEY (SpeciesId) REFERENCES Pet_Species(Id)
    );
    CREATE INDEX IX_Pet_Breeds_Name ON Pet_Breeds(Name);
    CREATE INDEX IX_Pet_Breeds_Popularity ON Pet_Breeds(Popularity);
    CREATE INDEX IX_Pet_Breeds_SpeciesId ON Pet_Breeds(SpeciesId, IsActive);
    PRINT '   - Creata Pet_Breeds';
END

-- Add FK for BreedId if Pet_Pets exists and FK doesn't exist
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Pet_Pets')
   AND NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS WHERE CONSTRAINT_NAME = 'FK_Pet_Pets_Pet_Breeds_BreedId')
   AND EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Pet_Pets' AND COLUMN_NAME = 'BreedId')
BEGIN
    ALTER TABLE Pet_Pets ADD CONSTRAINT FK_Pet_Pets_Pet_Breeds_BreedId
        FOREIGN KEY (BreedId) REFERENCES Pet_Breeds(Id);
    PRINT '   - Aggiunta FK Pet_Pets -> Pet_Breeds';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Pet_PetPhotos')
BEGIN
    CREATE TABLE Pet_PetPhotos (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        PetId uniqueidentifier NOT NULL,
        Url nvarchar(500) NOT NULL,
        ThumbnailUrl nvarchar(500) NULL,
        Caption nvarchar(500) NULL,
        IsPrimary bit NOT NULL DEFAULT 0,
        SortOrder int NOT NULL DEFAULT 0,
        ContentType nvarchar(50) NULL,
        FileSizeBytes int NULL,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Pet_PetPhotos PRIMARY KEY (Id),
        CONSTRAINT FK_Pet_PetPhotos_Pet_Pets_PetId FOREIGN KEY (PetId) REFERENCES Pet_Pets(Id) ON DELETE CASCADE
    );
    CREATE INDEX IX_Pet_PetPhotos_PetId_Primary ON Pet_PetPhotos(PetId, IsPrimary) WHERE IsPrimary = 1;
    CREATE INDEX IX_Pet_PetPhotos_PetId_SortOrder ON Pet_PetPhotos(PetId, SortOrder);
    PRINT '   - Creata Pet_PetPhotos';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Pet_PetMemories')
BEGIN
    CREATE TABLE Pet_PetMemories (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        PetId uniqueidentifier NOT NULL,
        Title nvarchar(200) NOT NULL,
        Description nvarchar(1000) NULL,
        Date datetime2 NOT NULL,
        Type nvarchar(50) NOT NULL DEFAULT 'other',
        PhotoUrl nvarchar(500) NULL,
        ThumbnailUrl nvarchar(500) NULL,
        Location nvarchar(200) NULL,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Pet_PetMemories PRIMARY KEY (Id),
        CONSTRAINT FK_Pet_PetMemories_Pet_Pets_PetId FOREIGN KEY (PetId) REFERENCES Pet_Pets(Id) ON DELETE CASCADE
    );
    CREATE INDEX IX_Pet_PetMemories_PetId_Date ON Pet_PetMemories(PetId, Date);
    CREATE INDEX IX_Pet_PetMemories_Type ON Pet_PetMemories(Type);
    PRINT '   - Creata Pet_PetMemories';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Pet_SavedItems')
BEGIN
    CREATE TABLE Pet_SavedItems (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        UserId uniqueidentifier NOT NULL,
        PetId uniqueidentifier NOT NULL,
        SavedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Pet_SavedItems PRIMARY KEY (Id),
        CONSTRAINT FK_Pet_SavedItems_Auth_Users_UserId FOREIGN KEY (UserId) REFERENCES Auth_Users(Id) ON DELETE CASCADE,
        CONSTRAINT FK_Pet_SavedItems_Pet_Pets_PetId FOREIGN KEY (PetId) REFERENCES Pet_Pets(Id) ON DELETE CASCADE
    );
    CREATE INDEX IX_Pet_SavedItems_PetId ON Pet_SavedItems(PetId);
    CREATE UNIQUE INDEX IX_Pet_SavedItems_UserId_PetId ON Pet_SavedItems(UserId, PetId);
    CREATE INDEX IX_Pet_SavedItems_UserId_SavedAt ON Pet_SavedItems(UserId, SavedAt);
    PRINT '   - Creata Pet_SavedItems';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Pet_Suggestions')
BEGIN
    CREATE TABLE Pet_Suggestions (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        UserId uniqueidentifier NOT NULL,
        PetId uniqueidentifier NOT NULL,
        QuestionnaireId uniqueidentifier NULL,
        Score int NOT NULL,
        Reason nvarchar(1000) NOT NULL,
        IsViewed bit NOT NULL DEFAULT 0,
        ViewedAt datetime2 NULL,
        UserAction nvarchar(20) NULL,
        ActionAt datetime2 NULL,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Pet_Suggestions PRIMARY KEY (Id),
        CONSTRAINT FK_Pet_Suggestions_Auth_Users_UserId FOREIGN KEY (UserId) REFERENCES Auth_Users(Id) ON DELETE CASCADE,
        CONSTRAINT FK_Pet_Suggestions_Pet_Pets_PetId FOREIGN KEY (PetId) REFERENCES Pet_Pets(Id),
        CONSTRAINT FK_Pet_Suggestions_Pet_SpeciesQuestionnaires_QuestionnaireId FOREIGN KEY (QuestionnaireId) REFERENCES Pet_SpeciesQuestionnaires(Id)
    );
    CREATE INDEX IX_Pet_Suggestions_PetId ON Pet_Suggestions(PetId);
    CREATE INDEX IX_Pet_Suggestions_QuestionnaireId ON Pet_Suggestions(QuestionnaireId);
    CREATE INDEX IX_Pet_Suggestions_Score ON Pet_Suggestions(Score);
    CREATE UNIQUE INDEX IX_Pet_Suggestions_UserId_PetId ON Pet_Suggestions(UserId, PetId);
    CREATE INDEX IX_Pet_Suggestions_UserId_Status ON Pet_Suggestions(UserId, IsViewed, UserAction);
    PRINT '   - Creata Pet_Suggestions';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Pet_Adoptions')
BEGIN
    CREATE TABLE Pet_Adoptions (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        PetId uniqueidentifier NOT NULL,
        OwnerUserId uniqueidentifier NOT NULL,
        Description nvarchar(2000) NOT NULL,
        AdoptionFee decimal(10,2) NULL,
        Location nvarchar(500) NOT NULL,
        City nvarchar(100) NULL,
        Latitude decimal(9,6) NULL,
        Longitude decimal(9,6) NULL,
        Status nvarchar(20) NOT NULL DEFAULT 'available',
        Requirements nvarchar(2000) NULL,
        AllowMessages bit NOT NULL DEFAULT 1,
        ViewCount int NOT NULL DEFAULT 0,
        IsDeleted bit NOT NULL DEFAULT 0,
        DeletedAt datetime2 NULL,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Pet_Adoptions PRIMARY KEY (Id),
        CONSTRAINT FK_Pet_Adoptions_Auth_Users_OwnerUserId FOREIGN KEY (OwnerUserId) REFERENCES Auth_Users(Id),
        CONSTRAINT FK_Pet_Adoptions_Pet_Pets_PetId FOREIGN KEY (PetId) REFERENCES Pet_Pets(Id)
    );
    CREATE INDEX IX_Pet_Adoptions_ActivePet ON Pet_Adoptions(PetId, Status) WHERE IsDeleted = 0 AND Status IN ('available', 'pending');
    CREATE INDEX IX_Pet_Adoptions_CreatedAt ON Pet_Adoptions(CreatedAt);
    CREATE INDEX IX_Pet_Adoptions_OwnerUserId ON Pet_Adoptions(OwnerUserId);
    CREATE INDEX IX_Pet_Adoptions_Status_City ON Pet_Adoptions(Status, City);
    PRINT '   - Creata Pet_Adoptions';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Pet_LostPets')
BEGIN
    CREATE TABLE Pet_LostPets (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        PetId uniqueidentifier NOT NULL,
        ReportedByUserId uniqueidentifier NOT NULL,
        LastSeenLocation nvarchar(500) NOT NULL,
        LastSeenLatitude decimal(9,6) NOT NULL,
        LastSeenLongitude decimal(9,6) NOT NULL,
        LastSeenDate datetime2 NOT NULL,
        Description nvarchar(2000) NULL,
        Status nvarchar(20) NOT NULL DEFAULT 'lost',
        ContactPhone nvarchar(50) NULL,
        OfferReward bit NOT NULL DEFAULT 0,
        RewardAmount decimal(10,2) NULL,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        FoundAt datetime2 NULL,
        ClosedAt datetime2 NULL,
        CONSTRAINT PK_Pet_LostPets PRIMARY KEY (Id),
        CONSTRAINT FK_Pet_LostPets_Auth_Users_ReportedByUserId FOREIGN KEY (ReportedByUserId) REFERENCES Auth_Users(Id),
        CONSTRAINT FK_Pet_LostPets_Pet_Pets_PetId FOREIGN KEY (PetId) REFERENCES Pet_Pets(Id)
    );
    CREATE INDEX IX_Pet_LostPets_CreatedAt ON Pet_LostPets(CreatedAt);
    CREATE INDEX IX_Pet_LostPets_PetId_Status ON Pet_LostPets(PetId, Status);
    CREATE INDEX IX_Pet_LostPets_ReportedByUserId ON Pet_LostPets(ReportedByUserId);
    CREATE INDEX IX_Pet_LostPets_Status_Location ON Pet_LostPets(Status, LastSeenLatitude, LastSeenLongitude);
    PRINT '   - Creata Pet_LostPets';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Pet_LostPetSightings')
BEGIN
    CREATE TABLE Pet_LostPetSightings (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        LostPetId uniqueidentifier NOT NULL,
        ReporterUserId uniqueidentifier NOT NULL,
        Location nvarchar(500) NOT NULL,
        Latitude decimal(9,6) NOT NULL,
        Longitude decimal(9,6) NOT NULL,
        SightingDate datetime2 NOT NULL,
        Description nvarchar(1000) NULL,
        PhotoUrl nvarchar(500) NULL,
        Confidence nvarchar(20) NOT NULL DEFAULT 'likely',
        IsVerified bit NOT NULL DEFAULT 0,
        VerifiedAt datetime2 NULL,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Pet_LostPetSightings PRIMARY KEY (Id),
        CONSTRAINT FK_Pet_LostPetSightings_Auth_Users_ReporterUserId FOREIGN KEY (ReporterUserId) REFERENCES Auth_Users(Id),
        CONSTRAINT FK_Pet_LostPetSightings_Pet_LostPets_LostPetId FOREIGN KEY (LostPetId) REFERENCES Pet_LostPets(Id) ON DELETE CASCADE
    );
    CREATE INDEX IX_Pet_LostPetSightings_LostPetId_Date ON Pet_LostPetSightings(LostPetId, SightingDate);
    CREATE INDEX IX_Pet_LostPetSightings_ReporterUserId ON Pet_LostPetSightings(ReporterUserId);
    PRINT '   - Creata Pet_LostPetSightings';
END

-- =============================================================================
-- STEP 4: Creare tabelle Notify_*, Cal_*, Chat_*, Sub_*
-- =============================================================================
PRINT '';
PRINT '4. Creando tabelle Notify_*, Cal_*, Chat_*, Sub_*...';

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Notify_Notifications')
BEGIN
    CREATE TABLE Notify_Notifications (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        UserId uniqueidentifier NOT NULL,
        Type nvarchar(50) NOT NULL,
        Title nvarchar(200) NOT NULL,
        Message nvarchar(1000) NULL,
        ActionUrl nvarchar(500) NULL,
        ImageUrl nvarchar(500) NULL,
        IsRead bit NOT NULL DEFAULT 0,
        ReadAt datetime2 NULL,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Notify_Notifications PRIMARY KEY (Id),
        CONSTRAINT FK_Notify_Notifications_Auth_Users_UserId FOREIGN KEY (UserId) REFERENCES Auth_Users(Id) ON DELETE CASCADE
    );
    CREATE INDEX IX_Notify_Notifications_CreatedAt_IsRead ON Notify_Notifications(CreatedAt, IsRead);
    CREATE INDEX IX_Notify_Notifications_UserId_IsRead ON Notify_Notifications(UserId, IsRead, CreatedAt);
    CREATE INDEX IX_Notify_Notifications_UserId_Type ON Notify_Notifications(UserId, Type, CreatedAt);
    PRINT '   - Creata Notify_Notifications';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Notify_Activities')
BEGIN
    CREATE TABLE Notify_Activities (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        UserId uniqueidentifier NOT NULL,
        Type nvarchar(50) NOT NULL,
        Title nvarchar(200) NOT NULL,
        Description nvarchar(1000) NULL,
        RelatedEntityId uniqueidentifier NULL,
        RelatedEntityType nvarchar(50) NULL,
        IsRead bit NOT NULL DEFAULT 0,
        ReadAt datetime2 NULL,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Notify_Activities PRIMARY KEY (Id),
        CONSTRAINT FK_Notify_Activities_Auth_Users_UserId FOREIGN KEY (UserId) REFERENCES Auth_Users(Id) ON DELETE CASCADE
    );
    CREATE INDEX IX_Notify_Activities_UserId_IsRead ON Notify_Activities(UserId, IsRead, CreatedAt);
    CREATE INDEX IX_Notify_Activities_UserId_Type ON Notify_Activities(UserId, Type, CreatedAt);
    PRINT '   - Creata Notify_Activities';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Cal_Events')
BEGIN
    CREATE TABLE Cal_Events (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        UserId uniqueidentifier NOT NULL,
        PetId uniqueidentifier NULL,
        Type nvarchar(50) NOT NULL,
        Title nvarchar(200) NOT NULL,
        Description nvarchar(1000) NULL,
        StartDate datetime2 NOT NULL,
        EndDate datetime2 NULL,
        IsAllDay bit NOT NULL DEFAULT 0,
        Location nvarchar(255) NULL,
        ReminderMinutes int NULL,
        RecurrenceRule nvarchar(255) NULL,
        Color nvarchar(7) NULL,
        IsCompleted bit NOT NULL DEFAULT 0,
        CompletedAt datetime2 NULL,
        IsDeleted bit NOT NULL DEFAULT 0,
        DeletedAt datetime2 NULL,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Cal_Events PRIMARY KEY (Id),
        CONSTRAINT FK_Cal_Events_Auth_Users_UserId FOREIGN KEY (UserId) REFERENCES Auth_Users(Id) ON DELETE CASCADE,
        CONSTRAINT FK_Cal_Events_Pet_Pets_PetId FOREIGN KEY (PetId) REFERENCES Pet_Pets(Id) ON DELETE SET NULL
    );
    CREATE INDEX IX_Cal_Events_PetId_StartDate ON Cal_Events(PetId, StartDate);
    CREATE INDEX IX_Cal_Events_Type ON Cal_Events(Type);
    CREATE INDEX IX_Cal_Events_UserId_StartDate ON Cal_Events(UserId, StartDate, IsDeleted);
    PRINT '   - Creata Cal_Events';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Chat_Conversations')
BEGIN
    CREATE TABLE Chat_Conversations (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        User1Id uniqueidentifier NOT NULL,
        User2Id uniqueidentifier NOT NULL,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        UpdatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Chat_Conversations PRIMARY KEY (Id),
        CONSTRAINT FK_Chat_Conversations_Auth_Users_User1Id FOREIGN KEY (User1Id) REFERENCES Auth_Users(Id),
        CONSTRAINT FK_Chat_Conversations_Auth_Users_User2Id FOREIGN KEY (User2Id) REFERENCES Auth_Users(Id)
    );
    CREATE INDEX IX_Chat_Conversations_UpdatedAt ON Chat_Conversations(UpdatedAt);
    CREATE UNIQUE INDEX IX_Chat_Conversations_User1Id_User2Id ON Chat_Conversations(User1Id, User2Id);
    CREATE INDEX IX_Chat_Conversations_User2Id ON Chat_Conversations(User2Id);
    PRINT '   - Creata Chat_Conversations';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Chat_Messages')
BEGIN
    CREATE TABLE Chat_Messages (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        ConversationId uniqueidentifier NOT NULL,
        SenderId uniqueidentifier NOT NULL,
        Text nvarchar(4000) NOT NULL,
        IsRead bit NOT NULL DEFAULT 0,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Chat_Messages PRIMARY KEY (Id),
        CONSTRAINT FK_Chat_Messages_Auth_Users_SenderId FOREIGN KEY (SenderId) REFERENCES Auth_Users(Id),
        CONSTRAINT FK_Chat_Messages_Chat_Conversations_ConversationId FOREIGN KEY (ConversationId) REFERENCES Chat_Conversations(Id) ON DELETE CASCADE
    );
    CREATE INDEX IX_Chat_Messages_ConversationId_CreatedAt ON Chat_Messages(ConversationId, CreatedAt);
    CREATE INDEX IX_Chat_Messages_SenderId ON Chat_Messages(SenderId);
    CREATE INDEX IX_Chat_Messages_Unread ON Chat_Messages(ConversationId, SenderId, IsRead);
    PRINT '   - Creata Chat_Messages';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Sub_Subscriptions')
BEGIN
    CREATE TABLE Sub_Subscriptions (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        UserId uniqueidentifier NOT NULL,
        PlanId nvarchar(50) NOT NULL DEFAULT 'free',
        Status nvarchar(20) NOT NULL DEFAULT 'active',
        StartedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        ExpiresAt datetime2 NULL,
        CancelledAt datetime2 NULL,
        CONSTRAINT PK_Sub_Subscriptions PRIMARY KEY (Id),
        CONSTRAINT FK_Sub_Subscriptions_Auth_Users_UserId FOREIGN KEY (UserId) REFERENCES Auth_Users(Id) ON DELETE CASCADE
    );
    CREATE INDEX IX_Sub_Subscriptions_UserId ON Sub_Subscriptions(UserId);
    CREATE INDEX IX_Sub_Subscriptions_UserId_Status ON Sub_Subscriptions(UserId, Status);
    PRINT '   - Creata Sub_Subscriptions';
END

-- =============================================================================
-- STEP 5: Creare tabelle Social_*
-- =============================================================================
PRINT '';
PRINT '5. Creando tabelle Social_*...';

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Social_Invites')
BEGIN
    CREATE TABLE Social_Invites (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        SenderUserId uniqueidentifier NOT NULL,
        Email nvarchar(255) NULL,
        InviteCode nvarchar(50) NOT NULL,
        Type nvarchar(20) NOT NULL DEFAULT 'app_invite',
        Status nvarchar(20) NOT NULL DEFAULT 'pending',
        AcceptedByUserId uniqueidentifier NULL,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        ExpiresAt datetime2 NOT NULL,
        AcceptedAt datetime2 NULL,
        CONSTRAINT PK_Social_Invites PRIMARY KEY (Id),
        CONSTRAINT FK_Social_Invites_Auth_Users_AcceptedByUserId FOREIGN KEY (AcceptedByUserId) REFERENCES Auth_Users(Id),
        CONSTRAINT FK_Social_Invites_Auth_Users_SenderUserId FOREIGN KEY (SenderUserId) REFERENCES Auth_Users(Id)
    );
    CREATE INDEX IX_Social_Invites_AcceptedByUserId ON Social_Invites(AcceptedByUserId);
    CREATE UNIQUE INDEX IX_Social_Invites_Code ON Social_Invites(InviteCode);
    CREATE INDEX IX_Social_Invites_Sender ON Social_Invites(SenderUserId, Status);
    CREATE INDEX IX_Social_Invites_Status ON Social_Invites(Status);
    PRINT '   - Creata Social_Invites';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Social_PetAntagonists')
BEGIN
    CREATE TABLE Social_PetAntagonists (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        PetId uniqueidentifier NOT NULL,
        AntagonistPetId uniqueidentifier NOT NULL,
        ReportedByUserId uniqueidentifier NOT NULL,
        Reason nvarchar(500) NULL,
        Severity nvarchar(20) NOT NULL DEFAULT 'moderate',
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Social_PetAntagonists PRIMARY KEY (Id),
        CONSTRAINT FK_Social_PetAntagonists_Auth_Users_ReportedByUserId FOREIGN KEY (ReportedByUserId) REFERENCES Auth_Users(Id),
        CONSTRAINT FK_Social_PetAntagonists_Pet_Pets_AntagonistPetId FOREIGN KEY (AntagonistPetId) REFERENCES Pet_Pets(Id),
        CONSTRAINT FK_Social_PetAntagonists_Pet_Pets_PetId FOREIGN KEY (PetId) REFERENCES Pet_Pets(Id)
    );
    CREATE INDEX IX_Social_PetAntagonists_AntagonistPetId ON Social_PetAntagonists(AntagonistPetId);
    CREATE INDEX IX_Social_PetAntagonists_PetId ON Social_PetAntagonists(PetId);
    CREATE INDEX IX_Social_PetAntagonists_ReportedByUserId ON Social_PetAntagonists(ReportedByUserId);
    CREATE UNIQUE INDEX IX_Social_PetAntagonists_Unique ON Social_PetAntagonists(PetId, AntagonistPetId);
    PRINT '   - Creata Social_PetAntagonists';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Social_PetFriendships')
BEGIN
    CREATE TABLE Social_PetFriendships (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        Pet1Id uniqueidentifier NOT NULL,
        Pet2Id uniqueidentifier NOT NULL,
        InitiatedByUserId uniqueidentifier NOT NULL,
        Status nvarchar(20) NOT NULL DEFAULT 'pending',
        ConfirmedAt datetime2 NULL,
        Notes nvarchar(500) NULL,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Social_PetFriendships PRIMARY KEY (Id),
        CONSTRAINT FK_Social_PetFriendships_Auth_Users_InitiatedByUserId FOREIGN KEY (InitiatedByUserId) REFERENCES Auth_Users(Id),
        CONSTRAINT FK_Social_PetFriendships_Pet_Pets_Pet1Id FOREIGN KEY (Pet1Id) REFERENCES Pet_Pets(Id),
        CONSTRAINT FK_Social_PetFriendships_Pet_Pets_Pet2Id FOREIGN KEY (Pet2Id) REFERENCES Pet_Pets(Id)
    );
    CREATE INDEX IX_Social_PetFriendships_InitiatedByUserId ON Social_PetFriendships(InitiatedByUserId);
    CREATE INDEX IX_Social_PetFriendships_Pet2Id ON Social_PetFriendships(Pet2Id);
    CREATE INDEX IX_Social_PetFriendships_Status ON Social_PetFriendships(Status);
    CREATE UNIQUE INDEX IX_Social_PetFriendships_Unique ON Social_PetFriendships(Pet1Id, Pet2Id);
    PRINT '   - Creata Social_PetFriendships';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Social_UserBlocks')
BEGIN
    CREATE TABLE Social_UserBlocks (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        BlockerUserId uniqueidentifier NOT NULL,
        BlockedUserId uniqueidentifier NOT NULL,
        Reason nvarchar(500) NULL,
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT PK_Social_UserBlocks PRIMARY KEY (Id),
        CONSTRAINT FK_Social_UserBlocks_Auth_Users_BlockedUserId FOREIGN KEY (BlockedUserId) REFERENCES Auth_Users(Id),
        CONSTRAINT FK_Social_UserBlocks_Auth_Users_BlockerUserId FOREIGN KEY (BlockerUserId) REFERENCES Auth_Users(Id)
    );
    CREATE INDEX IX_Social_UserBlocks_BlockedUserId ON Social_UserBlocks(BlockedUserId);
    CREATE INDEX IX_Social_UserBlocks_BlockerUserId ON Social_UserBlocks(BlockerUserId);
    CREATE UNIQUE INDEX IX_Social_UserBlocks_Unique ON Social_UserBlocks(BlockerUserId, BlockedUserId);
    PRINT '   - Creata Social_UserBlocks';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'Social_UserFriendships')
BEGIN
    CREATE TABLE Social_UserFriendships (
        Id uniqueidentifier NOT NULL DEFAULT NEWSEQUENTIALID(),
        RequesterId uniqueidentifier NOT NULL,
        AddresseeId uniqueidentifier NOT NULL,
        Status nvarchar(20) NOT NULL DEFAULT 'pending',
        CreatedAt datetime2 NOT NULL DEFAULT SYSUTCDATETIME(),
        RespondedAt datetime2 NULL,
        CONSTRAINT PK_Social_UserFriendships PRIMARY KEY (Id),
        CONSTRAINT FK_Social_UserFriendships_Auth_Users_AddresseeId FOREIGN KEY (AddresseeId) REFERENCES Auth_Users(Id),
        CONSTRAINT FK_Social_UserFriendships_Auth_Users_RequesterId FOREIGN KEY (RequesterId) REFERENCES Auth_Users(Id)
    );
    CREATE INDEX IX_Social_UserFriendships_Addressee ON Social_UserFriendships(AddresseeId, Status);
    CREATE INDEX IX_Social_UserFriendships_Status ON Social_UserFriendships(Status);
    CREATE UNIQUE INDEX IX_Social_UserFriendships_Unique ON Social_UserFriendships(RequesterId, AddresseeId);
    PRINT '   - Creata Social_UserFriendships';
END

-- =============================================================================
-- STEP 6: Verificare POI_Points e POI_Favorites (dovrebbero esistere)
-- =============================================================================
PRINT '';
PRINT '6. Verificando tabelle POI_*...';

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'POI_Points')
BEGIN
    PRINT '   - ATTENZIONE: POI_Points non esiste! Creala manualmente o esegui seed-poi-prod.sql';
END
ELSE
BEGIN
    PRINT '   - POI_Points esiste OK';
END

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'POI_Favorites')
BEGIN
    PRINT '   - ATTENZIONE: POI_Favorites non esiste!';
END
ELSE
BEGIN
    PRINT '   - POI_Favorites esiste OK';
END

-- =============================================================================
-- STEP 7: Aggiornare __EFMigrationsHistory
-- =============================================================================
PRINT '';
PRINT '7. Aggiornando __EFMigrationsHistory...';

-- Clear and re-insert all migrations as applied
DELETE FROM __EFMigrationsHistory;

INSERT INTO __EFMigrationsHistory (MigrationId, ProductVersion) VALUES
    ('20251127201857_InitialAuth', '8.0.0'),
    ('20251130100006_AddUserAreaEntities', '8.0.0'),
    ('20251204001031_AddSpeciesQuestionnaireEntities', '8.0.0'),
    ('20251204052125_AddPetAndNotificationEntities', '8.0.0'),
    ('20251206065404_AddUserOnboardingStatus', '8.0.0'),
    ('20251219182504_AddChat', '8.0.0'),
    ('20251219182830_AddSubscription', '8.0.0'),
    ('20251220085631_AddSavedItem', '8.0.0'),
    ('20251220085816_AddActivity', '8.0.0'),
    ('20251220090052_AddPoi', '8.0.0'),
    ('20251220090758_AddSocialSystem', '8.0.0'),
    ('20251220091020_AddSuggestion', '8.0.0'),
    ('20251220091327_AddAdoption', '8.0.0'),
    ('20251220091721_AddLostPets', '8.0.0'),
    ('20260122000001_AddPetProfileFeatures', '8.0.0'),
    ('20260207180000_SeedCanonicalSpecies', '8.0.0');

PRINT '   - Inserite 16 migrazioni in __EFMigrationsHistory';

-- =============================================================================
-- DONE
-- =============================================================================
PRINT '';
PRINT '====================================================';
PRINT 'FIUTAMI Baseline Migrations - COMPLETATO!';
PRINT '====================================================';
PRINT '';
PRINT 'Prossimi passi:';
PRINT '1. Verificare che tutte le tabelle siano state create';
PRINT '2. Eseguire: SELECT COUNT(*) FROM __EFMigrationsHistory;  -- dovrebbe essere 16';
PRINT '3. Testare il backend con dotnet run';
PRINT '';

-- Final verification
SELECT 'Tabelle EF Core:' AS Info, COUNT(*) AS Totale
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME NOT LIKE 'directus_%'
  AND TABLE_NAME NOT LIKE 'sys%'
  AND TABLE_NAME != '__EFMigrationsHistory';

SELECT MigrationId FROM __EFMigrationsHistory ORDER BY MigrationId;
