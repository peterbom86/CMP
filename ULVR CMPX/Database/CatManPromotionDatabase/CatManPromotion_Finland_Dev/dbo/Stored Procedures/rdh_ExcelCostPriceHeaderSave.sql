CREATE PROCEDURE [dbo].[rdh_ExcelCostPriceHeaderSave]
  @PeriodFrom datetime,
  @PeriodTo datetime

AS

DECLARE @CostPriceHeaderID int
DECLARE @TempCostPriceHeaderID int

-- Delete CostPrice within period
SELECT PK_CostPriceHeaderID
INTO #tempDeletedCostPrice
FROM CostPriceHeader
WHERE PeriodFrom >= @PeriodFrom AND PeriodFrom <= @PeriodTo AND PeriodTo >= @PeriodFrom AND PeriodTo <= @PeriodTo

DELETE FROM CostPriceDetails
WHERE FK_CostPriceHeaderID IN (
  SELECT PK_CostPriceHeaderID FROM #tempDeletedCostPrice )

DELETE FROM CostPriceHeader
WHERE PK_CostPriceHeaderID IN (
  SELECT PK_CostPriceHeaderID FROM #tempDeletedCostPrice )

DROP TABLE #tempDeletedCostPrice

-- Insert CostPrice inside period
SELECT PK_CostPriceHeaderID
INTO #tempNewCostPrice
FROM CostPriceHeader
WHERE PeriodFrom < @PeriodFrom AND PeriodFrom < @PeriodTo AND PeriodTo > @PeriodFrom AND PeriodTo > @PeriodTo

INSERT INTO CostPriceHeader ( PeriodFrom, PeriodTo )
SELECT @PeriodTo + 1, PeriodTo
FROM #tempNewCostPrice NSC
  INNER JOIN CostPriceHeader SCH ON NSC.PK_CostPriceHeaderID = SCH.PK_CostPriceHeaderID

SET @TempCostPriceHeaderID = SCOPE_IDENTITY()

INSERT INTO CostPriceDetails ( FK_CostPriceHeaderID, FK_CommonCodeID, Value )
SELECT @TempCostPriceHeaderID, FK_CommonCodeID, Value
FROM CostPriceDetails
WHERE FK_CostPriceHeaderID IN ( SELECT PK_CostPriceHeaderID FROM #tempNewCostPrice )

UPDATE CostPriceHeader
SET PeriodTo = @PeriodFrom - 1
WHERE PK_CostPriceHeaderID IN ( SELECT PK_CostPriceHeaderID FROM #tempNewCostPrice )

DROP TABLE #tempNewCostPrice

-- Update when periodto is within new period
UPDATE CostPriceHeader
SET PeriodTo = @PeriodFrom - 1
WHERE PeriodFrom < @PeriodFrom AND PeriodFrom < @PeriodTo AND PeriodTo >= @PeriodFrom AND PeriodTo <= @PeriodTo

-- Update when periodfrom is within new period
UPDATE CostPriceHeader
SET PeriodFrom = @PeriodTo + 1
WHERE PeriodFrom >= @PeriodFrom AND PeriodFrom <= @PeriodTo AND PeriodTo > @PeriodFrom AND PeriodTo > @PeriodTo


-- Insert new or updates old CostPrice
INSERT INTO CostPriceHeader ( PeriodFrom, PeriodTo )
VALUES ( @PeriodFrom, @PeriodTo )

SET @CostPriceHeaderID = SCOPE_IDENTITY()

-- Insert missing periods
INSERT INTO CostPriceHeader ( PeriodFrom, PeriodTo )
SELECT PeriodTo + 1 PeriodFrom, ISNULL((SELECT TOP 1 PeriodFrom - 1 FROM CostPriceHeader IH WHERE IH.PeriodFrom > H1.PeriodTo ORDER BY PeriodFrom ), '2099-12-31') PeriodTo
FROM CostPriceHeader H1
WHERE PeriodTo + 1 NOT IN ( SELECT PeriodFrom FROM CostPriceHeader ) AND PeriodTo < '2099-12-31'

INSERT INTO CostPriceHeader ( PeriodFrom, PeriodTo )
SELECT '2001-01-01' PeriodFrom, MIN(PeriodFrom) -1 PeriodTo
FROM CostPriceHeader H1
WHERE PeriodFrom - 1 NOT IN ( SELECT PeriodTo FROM CostPriceHeader )
HAVING MIN(PeriodFrom) > '2001-01-01'

SELECT PK_CostPriceHeaderID CostPriceHeaderID, PeriodFrom, PeriodTo, CAST(1 AS BIT) Success
FROM CostPriceHeader
WHERE PK_CostPriceHeaderID = @CostPriceHeaderID
