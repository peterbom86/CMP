CREATE PROCEDURE [dbo].rdh_ExcelSupplyCostHeaderSave 
  @PeriodFrom datetime,
  @PeriodTo datetime

AS

DECLARE @SupplyCostHeaderID int
DECLARE @TempSupplyCostHeaderID int

-- Delete Supplycost within period
SELECT PK_SupplyCostHeaderID
INTO #tempDeletedSupplyCost
FROM SupplyCostHeader
WHERE PeriodFrom >= @PeriodFrom AND PeriodFrom <= @PeriodTo AND PeriodTo >= @PeriodFrom AND PeriodTo <= @PeriodTo

DELETE FROM SupplyCostDetails
WHERE FK_SupplyCostHeaderID IN (
  SELECT PK_SupplycostHeaderID FROM #tempDeletedSupplyCost )

DELETE FROM SupplyCostHeader
WHERE PK_SupplyCostHeaderID IN (
  SELECT PK_SupplyCostHeaderID FROM #tempDeletedSupplyCost )

DROP TABLE #tempDeletedSupplyCost

-- Insert Supplycost inside period
SELECT PK_SupplyCostHeaderID
INTO #tempNewSupplyCost
FROM SupplyCostHeader
WHERE PeriodFrom < @PeriodFrom AND PeriodFrom < @PeriodTo AND PeriodTo > @PeriodFrom AND PeriodTo > @PeriodTo

INSERT INTO SupplyCostHeader ( PeriodFrom, PeriodTo )
SELECT @PeriodTo + 1, PeriodTo
FROM #tempNewSupplyCost NSC
  INNER JOIN SupplyCostHeader SCH ON NSC.PK_SupplyCostHeaderID = SCH.PK_SupplyCostHeaderID

SET @TempSupplycostHeaderID = SCOPE_IDENTITY()

INSERT INTO SupplyCostDetails ( FK_SupplyCostHeaderID, FK_ProductHierarchyID, Value )
SELECT @TempSupplyCostHeaderID, FK_ProductHierarchyID, Value
FROM SupplyCostDetails
WHERE FK_SupplyCostHeaderID IN ( SELECT PK_SupplyCostHeaderID FROM #tempNewSupplyCost )

UPDATE SupplyCostHeader
SET PeriodTo = @PeriodFrom - 1
WHERE PK_SupplyCostHeaderID IN ( SELECT PK_SupplyCostHeaderID FROM #tempNewSupplyCost )

DROP TABLE #tempNewSupplyCost

-- Update when periodto is within new period
UPDATE SupplyCostHeader
SET PeriodTo = @PeriodFrom - 1
WHERE PeriodFrom < @PeriodFrom AND PeriodFrom < @PeriodTo AND PeriodTo >= @PeriodFrom AND PeriodTo <= @PeriodTo

-- Update when periodfrom is within new period
UPDATE SupplyCostHeader
SET PeriodFrom = @PeriodTo + 1
WHERE PeriodFrom >= @PeriodFrom AND PeriodFrom <= @PeriodTo AND PeriodTo > @PeriodFrom AND PeriodTo > @PeriodTo


-- Insert new or updates old SupplyCost
INSERT INTO SupplyCostHeader ( PeriodFrom, PeriodTo )
VALUES ( @PeriodFrom, @PeriodTo )

SET @SupplyCostHeaderID = SCOPE_IDENTITY()

-- Insert missing periods
INSERT INTO SupplyCostHeader ( PeriodFrom, PeriodTo )
SELECT PeriodTo + 1 PeriodFrom, ISNULL((SELECT TOP 1 PeriodFrom - 1 FROM SupplyCostHeader IH WHERE IH.PeriodFrom > H1.PeriodTo ORDER BY PeriodFrom ), '2099-12-31') PeriodTo
FROM SupplyCostHeader H1
WHERE PeriodTo + 1 NOT IN ( SELECT PeriodFrom FROM SupplyCostHeader ) AND PeriodTo < '2099-12-31'

INSERT INTO SupplyCostHeader ( PeriodFrom, PeriodTo )
SELECT '2001-01-01' PeriodFrom, MIN(PeriodFrom) -1 PeriodTo
FROM SupplyCostHeader H1
WHERE PeriodFrom - 1 NOT IN ( SELECT PeriodTo FROM SupplyCostHeader )
HAVING MIN(PeriodFrom) > '2001-01-01'

SELECT PK_SupplyCostHeaderID SupplyCostHeaderID, PeriodFrom, PeriodTo, CAST(1 AS BIT) Success
FROM SupplyCostHeader
WHERE PK_SupplyCostHeaderID = @SupplyCostHeaderID


