-- =============================================================================
-- FIUTAMI - Align Production species to match Staging (canonical data)
-- Handles unique index on Pet_Species.Code
-- Idempotent, safe to re-run
-- =============================================================================
SET NOCOUNT ON;
PRINT '=== Aligning Prod species to Staging ===';
PRINT '';

-- =============================================================================
-- STEP 1: Rename old species codes to avoid unique constraint conflicts
-- =============================================================================
PRINT '--- Step 1: Rename conflicting old codes ---';

UPDATE Pet_Species SET Code = Code + '_OLD' WHERE Id = '02DCA6B2-1A97-4DBB-B774-F553D5FBF6A2' AND Code = 'gatto';
UPDATE Pet_Species SET Code = Code + '_OLD' WHERE Id = 'E71EB918-3D1D-4787-8F04-E15AB32FE670' AND Code = 'coniglio';
UPDATE Pet_Species SET Code = Code + '_OLD' WHERE Id = '10695861-D6E2-4A58-974C-25DCA0BB42E3' AND Code = 'criceto';
UPDATE Pet_Species SET Code = Code + '_OLD' WHERE Id = '4F357AA9-E9CD-4311-BDD5-8FBC3B31525E' AND Code = 'canarino';
PRINT '  ~ Renamed gatto/coniglio/criceto/canarino -> _OLD';

-- =============================================================================
-- STEP 2: Insert canonical species (categories first, then children)
-- =============================================================================
PRINT '';
PRINT '--- Step 2: Insert canonical species ---';

-- Top-level species
IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000001')
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000001', 'cane', 'Cane', 'mammifero', 'Il migliore amico dell''uomo', '/assets/images/species/species-cane.png', 'molto', 'basso', 'giardino', 0, 'alto', 'alta', 1, 1, 'Optional', 1, 'species', SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000002')
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000002', 'gatto', 'Gatto', 'mammifero', 'Compagno indipendente e affettuoso', '/assets/images/species/species-gatto.png', 'medio', 'alto', 'interno', 0, 'medio', 'media', 1, 2, 'Optional', 1, 'species', SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000003')
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000003', 'coniglio', 'Coniglio', 'mammifero', 'Piccolo e dolce compagno', '/assets/images/species/species-coniglio.png', 'medio', 'medio', 'interno', 1, 'basso', 'media', 1, 3, 'Optional', 1, 'species', SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000004')
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000004', 'criceto', 'Criceto', 'mammifero', 'Piccolo roditore vivace', '/assets/images/species/species-criceto.png', 'poco', 'alto', 'interno', 1, 'medio', 'bassa', 1, 4, 'None', 0, 'species', SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000005')
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000005', 'cavia', 'Cavia', 'mammifero', 'Roditore socievole e docile', '/assets/images/species/species-cavia.png', 'poco', 'medio', 'interno', 1, 'basso', 'bassa', 1, 5, 'None', 0, 'species', SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000006')
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000006', 'furetto', 'Furetto', 'mammifero', 'Mustelide giocherellone', '/assets/images/species/species-furetto.png', 'medio', 'medio', 'interno', 0, 'alto', 'media', 1, 6, 'None', 0, 'species', SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000007')
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000007', 'gerbillo', 'Gerbillo', 'mammifero', 'Piccolo roditore del deserto', '/assets/images/species/species-gerbillo.png', 'poco', 'alto', 'interno', 1, 'medio', 'bassa', 1, 7, 'None', 0, 'species', SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000008')
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000008', 'ratto', 'Ratto', 'mammifero', 'Roditore intelligente e socievole', '/assets/images/species/species-ratto.png', 'poco', 'medio', 'interno', 0, 'medio', 'bassa', 1, 8, 'None', 0, 'species', SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000009')
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000009', 'cavallo', 'Cavallo', 'mammifero', 'Nobile compagno equino', '/assets/images/species/species-cavallo.png', 'molto', 'basso', 'giardino', 0, 'alto', 'alta', 1, 9, 'Optional', 1, 'species', SYSUTCDATETIME());

-- Categories
IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000012')
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000012', 'uccello', 'Uccello', 'uccello', 'Uccelli domestici', NULL, 'poco', 'alto', 'interno', 1, 'medio', 'bassa', 1, 10, 'None', 0, 'category', SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000053')
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000053', 'rettile', 'Rettile', 'rettile', 'Rettili domestici', NULL, 'poco', 'molto_alto', 'terrario', 1, 'basso', 'media', 1, 20, 'None', 0, 'category', SYSUTCDATETIME());

PRINT '  + Top-level species + categories';
GO

-- =============================================================================
-- STEP 3: Insert child species that need parents (separate batch for FK)
-- =============================================================================
PRINT '';
PRINT '--- Step 3: Insert child species ---';

-- Children of Uccello (..012)
IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000010')
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, ParentSpeciesId, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000010', 'pappagallo', 'Pappagallo', 'uccello', 'Uccello parlante e colorato', '/assets/images/species/species-pappagallo.png', 'medio', 'medio', 'interno', 1, 'alto', 'media', 1, 11, 'Optional', 0, 'species', '10000000-0000-0000-0000-000000000012', SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000011')
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, ParentSpeciesId, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000011', 'canarino', 'Canarino', 'uccello', 'Cantore melodioso', '/assets/images/species/species-canarino.png', 'poco', 'alto', 'interno', 1, 'basso', 'bassa', 1, 12, 'None', 0, 'species', '10000000-0000-0000-0000-000000000012', SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000051')
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, ParentSpeciesId, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000051', 'piccione', 'Piccione', 'uccello', 'Colombo domestico', NULL, 'medio', 'alto', 'balcone', 1, 'medio', 'media', 1, 18, 'None', 0, 'species', '10000000-0000-0000-0000-000000000012', SYSUTCDATETIME());

-- Children of Rettile (..053)
IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000013')
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, ParentSpeciesId, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000013', 'tartaruga-terra', 'Tartaruga di terra', 'rettile', 'Rettile longevo e pacifico', '/assets/images/species/species-tartaruga.png', 'poco', 'molto_alto', 'giardino', 1, 'basso', 'bassa', 1, 21, 'None', 0, 'species', '10000000-0000-0000-0000-000000000053', SYSUTCDATETIME());

IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000014')
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, ParentSpeciesId, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000014', 'serpente-non-velenoso', 'Serpente non velenoso', 'rettile', 'Rettile affascinante e silenzioso', '/assets/images/species/species-serpente.png', 'poco', 'molto_alto', 'terrario', 1, 'basso', 'media', 1, 22, 'None', 0, 'species', '10000000-0000-0000-0000-000000000053', SYSUTCDATETIME());

-- Child of Anfibio (..016)
IF NOT EXISTS (SELECT 1 FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000052')
    INSERT INTO Pet_Species (Id, Code, Name, Category, Description, ImageUrl, TimeRequirement, IndependenceLevel, SpaceRequirement, Hypoallergenic, ActivityLevel, CareLevel, IsActive, SortOrder, BreedPolicy, AllowsMixedLabel, TaxonRank, ParentSpeciesId, CreatedAt)
    VALUES ('10000000-0000-0000-0000-000000000052', 'rana', 'Rana', 'anfibio', 'Anfibio comune', '/assets/images/species/species-rana.png', 'poco', 'molto_alto', 'terrario', 1, 'basso', 'bassa', 1, 35, 'None', 0, 'species', '10000000-0000-0000-0000-000000000016', SYSUTCDATETIME());

PRINT '  + Child species inserted';

-- =============================================================================
-- STEP 4: Migrate pets from old GUIDs to canonical GUIDs
-- =============================================================================
PRINT '';
PRINT '--- Step 4: Migrate pets ---';

UPDATE Pet_Pets SET SpeciesId = '10000000-0000-0000-0000-000000000002' WHERE SpeciesId = '02DCA6B2-1A97-4DBB-B774-F553D5FBF6A2';
IF @@ROWCOUNT > 0 PRINT '  ~ gatto pets migrated';
UPDATE Pet_Pets SET SpeciesId = '10000000-0000-0000-0000-000000000011' WHERE SpeciesId = '4F357AA9-E9CD-4311-BDD5-8FBC3B31525E';
IF @@ROWCOUNT > 0 PRINT '  ~ canarino pets migrated';
UPDATE Pet_Pets SET SpeciesId = '10000000-0000-0000-0000-000000000003' WHERE SpeciesId = 'E71EB918-3D1D-4787-8F04-E15AB32FE670';
UPDATE Pet_Pets SET SpeciesId = '10000000-0000-0000-0000-000000000004' WHERE SpeciesId = '10695861-D6E2-4A58-974C-25DCA0BB42E3';

-- =============================================================================
-- STEP 5: Delete old prod-only species
-- =============================================================================
PRINT '';
PRINT '--- Step 5: Delete old species ---';

DELETE FROM Pet_Species WHERE Id = '02DCA6B2-1A97-4DBB-B774-F553D5FBF6A2';
IF @@ROWCOUNT > 0 PRINT '  - gatto_OLD';
DELETE FROM Pet_Species WHERE Id = 'E71EB918-3D1D-4787-8F04-E15AB32FE670';
IF @@ROWCOUNT > 0 PRINT '  - coniglio_OLD';
DELETE FROM Pet_Species WHERE Id = '10695861-D6E2-4A58-974C-25DCA0BB42E3';
IF @@ROWCOUNT > 0 PRINT '  - criceto_OLD';
DELETE FROM Pet_Species WHERE Id = '4F357AA9-E9CD-4311-BDD5-8FBC3B31525E';
IF @@ROWCOUNT > 0 PRINT '  - canarino_OLD';
DELETE FROM Pet_Species WHERE Id = '089945E3-3EBD-4096-A98B-FD79896E54E2';
IF @@ROWCOUNT > 0 PRINT '  - cane_grande';
DELETE FROM Pet_Species WHERE Id = 'C1D5F978-C6FE-4494-88D3-EB655FE25025';
IF @@ROWCOUNT > 0 PRINT '  - cane_medio';
DELETE FROM Pet_Species WHERE Id = '6FFE5E79-0DE8-4B23-8181-8123AA12BE0E';
IF @@ROWCOUNT > 0 PRINT '  - cane_piccolo';
DELETE FROM Pet_Species WHERE Id = '54EFA0AE-9599-4744-B592-3BF87F3443A6';
IF @@ROWCOUNT > 0 PRINT '  - geco';
DELETE FROM Pet_Species WHERE Id = '1E032589-66F8-48ED-AEF6-114BD178A5DC';
IF @@ROWCOUNT > 0 PRINT '  - pappagallino';
DELETE FROM Pet_Species WHERE Id = 'E5C773EC-8921-40F9-953E-020AC968B150';
IF @@ROWCOUNT > 0 PRINT '  - pesce_rosso';
DELETE FROM Pet_Species WHERE Id = 'B9BDBC6E-5066-457D-8CE0-6B2C68B43218';
IF @@ROWCOUNT > 0 PRINT '  - porcellino_india';
DELETE FROM Pet_Species WHERE Id = '6C433198-C5DE-4711-9FC1-5F3C04C3D834';
IF @@ROWCOUNT > 0 PRINT '  - tartaruga';
DELETE FROM Pet_Species WHERE Id = '27396228-26FA-41F9-9382-3E71E813949F';
IF @@ROWCOUNT > 0 PRINT '  - acquario_tropicale';

-- piccione-viaggiatore (..022) replaced by piccione (..051)
DELETE FROM Pet_Species WHERE Id = '10000000-0000-0000-0000-000000000022';
IF @@ROWCOUNT > 0 PRINT '  - piccione-viaggiatore';

-- Fix code: pesce-rosso-ornamentale -> pesce-rosso
UPDATE Pet_Species SET Code = 'pesce-rosso' WHERE Id = '10000000-0000-0000-0000-000000000030' AND Code <> 'pesce-rosso';
IF @@ROWCOUNT > 0 PRINT '  ~ pesce-rosso-ornamentale -> pesce-rosso';

-- =============================================================================
-- STEP 6: Set ParentSpeciesId for species missing hierarchy
-- =============================================================================
PRINT '';
PRINT '--- Step 6: Set ParentSpeciesId ---';

UPDATE Pet_Species SET ParentSpeciesId = '10000000-0000-0000-0000-000000000012'
WHERE Id IN ('10000000-0000-0000-0000-000000000010','10000000-0000-0000-0000-000000000011',
    '10000000-0000-0000-0000-000000000017','10000000-0000-0000-0000-000000000018',
    '10000000-0000-0000-0000-000000000019','10000000-0000-0000-0000-000000000020',
    '10000000-0000-0000-0000-000000000021','10000000-0000-0000-0000-000000000051')
AND ParentSpeciesId IS NULL;
IF @@ROWCOUNT > 0 PRINT '  ~ Uccelli -> parent Uccello';

UPDATE Pet_Species SET ParentSpeciesId = '10000000-0000-0000-0000-000000000053'
WHERE Id IN ('10000000-0000-0000-0000-000000000013','10000000-0000-0000-0000-000000000014',
    '10000000-0000-0000-0000-000000000023','10000000-0000-0000-0000-000000000024',
    '10000000-0000-0000-0000-000000000025')
AND ParentSpeciesId IS NULL;
IF @@ROWCOUNT > 0 PRINT '  ~ Rettili -> parent Rettile';

-- =============================================================================
-- STEP 7: Align SortOrder
-- =============================================================================
PRINT '';
PRINT '--- Step 7: Align SortOrder ---';

UPDATE Pet_Species SET SortOrder = 1  WHERE Id = '10000000-0000-0000-0000-000000000001';
UPDATE Pet_Species SET SortOrder = 2  WHERE Id = '10000000-0000-0000-0000-000000000002';
UPDATE Pet_Species SET SortOrder = 3  WHERE Id = '10000000-0000-0000-0000-000000000003';
UPDATE Pet_Species SET SortOrder = 4  WHERE Id = '10000000-0000-0000-0000-000000000004';
UPDATE Pet_Species SET SortOrder = 5  WHERE Id = '10000000-0000-0000-0000-000000000005';
UPDATE Pet_Species SET SortOrder = 6  WHERE Id = '10000000-0000-0000-0000-000000000006';
UPDATE Pet_Species SET SortOrder = 7  WHERE Id = '10000000-0000-0000-0000-000000000007';
UPDATE Pet_Species SET SortOrder = 8  WHERE Id = '10000000-0000-0000-0000-000000000008';
UPDATE Pet_Species SET SortOrder = 9  WHERE Id = '10000000-0000-0000-0000-000000000009';
UPDATE Pet_Species SET SortOrder = 10 WHERE Id = '10000000-0000-0000-0000-000000000012';
UPDATE Pet_Species SET SortOrder = 11 WHERE Id = '10000000-0000-0000-0000-000000000010';
UPDATE Pet_Species SET SortOrder = 12 WHERE Id = '10000000-0000-0000-0000-000000000011';
UPDATE Pet_Species SET SortOrder = 13 WHERE Id = '10000000-0000-0000-0000-000000000017';
UPDATE Pet_Species SET SortOrder = 14 WHERE Id = '10000000-0000-0000-0000-000000000018';
UPDATE Pet_Species SET SortOrder = 15 WHERE Id = '10000000-0000-0000-0000-000000000019';
UPDATE Pet_Species SET SortOrder = 16 WHERE Id = '10000000-0000-0000-0000-000000000020';
UPDATE Pet_Species SET SortOrder = 17 WHERE Id = '10000000-0000-0000-0000-000000000021';
UPDATE Pet_Species SET SortOrder = 18 WHERE Id = '10000000-0000-0000-0000-000000000051';
UPDATE Pet_Species SET SortOrder = 20 WHERE Id = '10000000-0000-0000-0000-000000000053';
UPDATE Pet_Species SET SortOrder = 21 WHERE Id = '10000000-0000-0000-0000-000000000013';
UPDATE Pet_Species SET SortOrder = 22 WHERE Id = '10000000-0000-0000-0000-000000000014';
UPDATE Pet_Species SET SortOrder = 23 WHERE Id = '10000000-0000-0000-0000-000000000023';
UPDATE Pet_Species SET SortOrder = 24 WHERE Id = '10000000-0000-0000-0000-000000000024';
UPDATE Pet_Species SET SortOrder = 25 WHERE Id = '10000000-0000-0000-0000-000000000025';
UPDATE Pet_Species SET SortOrder = 30 WHERE Id = '10000000-0000-0000-0000-000000000016';
UPDATE Pet_Species SET SortOrder = 31 WHERE Id = '10000000-0000-0000-0000-000000000026';
UPDATE Pet_Species SET SortOrder = 32 WHERE Id = '10000000-0000-0000-0000-000000000027';
UPDATE Pet_Species SET SortOrder = 33 WHERE Id = '10000000-0000-0000-0000-000000000028';
UPDATE Pet_Species SET SortOrder = 34 WHERE Id = '10000000-0000-0000-0000-000000000029';
UPDATE Pet_Species SET SortOrder = 35 WHERE Id = '10000000-0000-0000-0000-000000000052';
UPDATE Pet_Species SET SortOrder = 40 WHERE Id = '10000000-0000-0000-0000-000000000015';
UPDATE Pet_Species SET SortOrder = 41 WHERE Id = '10000000-0000-0000-0000-000000000030';
UPDATE Pet_Species SET SortOrder = 42 WHERE Id = '10000000-0000-0000-0000-000000000031';
UPDATE Pet_Species SET SortOrder = 43 WHERE Id = '10000000-0000-0000-0000-000000000032';
UPDATE Pet_Species SET SortOrder = 44 WHERE Id = '10000000-0000-0000-0000-000000000033';
UPDATE Pet_Species SET SortOrder = 45 WHERE Id = '10000000-0000-0000-0000-000000000034';
UPDATE Pet_Species SET SortOrder = 46 WHERE Id = '10000000-0000-0000-0000-000000000035';
UPDATE Pet_Species SET SortOrder = 47 WHERE Id = '10000000-0000-0000-0000-000000000036';
UPDATE Pet_Species SET SortOrder = 48 WHERE Id = '10000000-0000-0000-0000-000000000037';
UPDATE Pet_Species SET SortOrder = 49 WHERE Id = '10000000-0000-0000-0000-000000000038';
UPDATE Pet_Species SET SortOrder = 50 WHERE Id = '10000000-0000-0000-0000-000000000039';
UPDATE Pet_Species SET SortOrder = 60 WHERE Id = '10000000-0000-0000-0000-000000000040';
UPDATE Pet_Species SET SortOrder = 61 WHERE Id = '10000000-0000-0000-0000-000000000041';
UPDATE Pet_Species SET SortOrder = 62 WHERE Id = '10000000-0000-0000-0000-000000000042';
UPDATE Pet_Species SET SortOrder = 63 WHERE Id = '10000000-0000-0000-0000-000000000043';
UPDATE Pet_Species SET SortOrder = 64 WHERE Id = '10000000-0000-0000-0000-000000000044';
UPDATE Pet_Species SET SortOrder = 65 WHERE Id = '10000000-0000-0000-0000-000000000045';
UPDATE Pet_Species SET SortOrder = 66 WHERE Id = '10000000-0000-0000-0000-000000000046';
PRINT '  ~ SortOrder aligned';

-- =============================================================================
-- VERIFY
-- =============================================================================
PRINT '';
PRINT '=== Verification ===';
SELECT 'Total species' AS [Check], COUNT(*) AS [Value] FROM Pet_Species
UNION ALL
SELECT 'TaxonRank=species', COUNT(*) FROM Pet_Species WHERE TaxonRank = 'species'
UNION ALL
SELECT 'TaxonRank=category', COUNT(*) FROM Pet_Species WHERE TaxonRank = 'category'
UNION ALL
SELECT 'With ParentSpeciesId', COUNT(*) FROM Pet_Species WHERE ParentSpeciesId IS NOT NULL
UNION ALL
SELECT 'Pets total', COUNT(*) FROM Pet_Pets
UNION ALL
SELECT 'Orphan pets', COUNT(*) FROM Pet_Pets p WHERE NOT EXISTS (SELECT 1 FROM Pet_Species s WHERE s.Id = p.SpeciesId);

PRINT '';
PRINT '=== Alignment COMPLETE ===';
