CREATE PROCEDURE [dbo].rdh_ExcelPrisimportSave
  @ProductCode NVARCHAR(255),
  @CommonCode NVARCHAR(255),
  @ProductName NVARCHAR(255),
  @PriceType NVARCHAR(255),
  @PeriodFrom NVARCHAR(255), 
  @PeriodTo NVARCHAR(255), 
  @Value NVARCHAR(255)

AS

DECLARE @ProductID int
DECLARE @ProductCodeID INT
DECLARE @CommonCodeID INT
DECLARE @ProductNameID INT
DECLARE @PriceTypeID INT
DECLARE @PeriodFromDate DATETIME
DECLARE @PeriodToDate DATETIME

EXEC @ProductCodeID = [rdh_ExcelMappingGetID] 21, @ProductCode
EXEC @CommonCodeID = [rdh_ExcelMappingGetID] 22, @CommonCode
EXEC @ProductNameID = [rdh_ExcelMappingGetID] 23,  @ProductName
EXEC @PriceTypeID = [rdh_ExcelMappingGetID] 24,  @PriceType

IF @ProductCodeID = -1
SET @ProductCodeID = Null

IF @CommonCodeID = -1
SET @CommonCodeID = Null

IF @ProductNameID = -1
SET @ProductNameID = Null

SET @ProductID = COALESCE(@ProductCodeID, @CommonCodeID, @ProductNameID)

IF @ProductID IS NULL
BEGIN
	RAISERROR('Either ProductCode, CommonCode or ProductName must be specified',11,1)
	RETURN -1
END

IF ISNULL(@PriceTypeID, -1) = -1
BEGIN 
	RAISERROR('No valid PriceType has been provided', 11, 1)
	RETURN -1
END

IF ISDATE(ISNULL(@PeriodFrom, '')) = 0
BEGIN
	RAISERROR('No start date has been provided', 11, 1)
	RETURN -1
END
SET @PeriodFromDate = CAST(@PeriodFrom AS DATETIME)

IF ISDATE(ISNULL(@PeriodTo, '')) = 0
BEGIN
	RAISERROR('No end date has been provided', 11, 1)
	RETURN -1
END
SET @PeriodToDate = CAST(@PeriodTo AS DATETIME)



declare @NewPeriodFrom datetime
declare @NewPeriodTo datetime

Set @NewPeriodFrom=@PeriodToDate+1
Set @NewPeriodTo=@PeriodFromDate-1

IF @PeriodToDate > '2099-12-31'
SET @PeriodToDate = '2099-12-31'

IF @PeriodFromDate > @PeriodToDate
SET @PeriodFromDate = @PeriodToDate

-- Sletter priser der ligger INDEN for ny periode
DELETE FROM 
  Prices
WHERE 
  PeriodFrom >= @PeriodFromDate AND PeriodTo <= @PeriodToDate AND FK_ProductID= @ProductID 
  AND FK_PriceTypeID= @PriceTypeID

-- Hvis ny pris ligger indenfor en eksisterende prisperiode opdeles den eksisterende pris i 2 perioder (før/efter)

IF 
  (SELECT count(*) FROM Prices 
  WHERE PeriodFrom < @PeriodFromDate AND PeriodTo > @PeriodToDate AND 
  FK_ProductID = @ProductID AND FK_PriceTypeID = @PriceTypeID) > 0

BEGIN

  INSERT INTO Prices (FK_ProductID, FK_PriceTypeID, [value], PeriodFrom, PeriodTo)
  SELECT FK_ProductID, FK_PriceTypeID, [value], PeriodFrom, @NewPeriodTo
  FROM Prices
  WHERE PeriodFrom < @PeriodFromDate AND PeriodTo > @PeriodToDate AND 
  FK_ProductID = @ProductID AND FK_PriceTypeID = @PriceTypeID
  
  UPDATE Prices
  SET PeriodFrom = @NewPeriodFrom
  WHERE PeriodFrom < @PeriodFromDate AND PeriodTo > @PeriodToDate AND FK_ProductID = @ProductID 
  AND FK_PriceTypeID = @PriceTypeID

END


/* Any price which begins before the new validity period and ends in the period in ended the week before the new validity period */

UPDATE Prices
SET PeriodTo = @NewPeriodTo WHERE FK_ProductID = @ProductID AND 
FK_PriceTypeID = @PriceTypeID AND PeriodFrom < @PeriodFromDate AND PeriodTo <= @PeriodToDate AND PeriodTo >= @PeriodFromDate
 

/* Any price which begins in the new validity period and ends after the period in started in the week after the new validity period */

UPDATE Prices
SET PeriodFrom = @NewPeriodFrom WHERE FK_ProductID = @ProductID AND FK_PriceTypeID = @PriceTypeID AND PeriodFrom >= @PeriodFromDate AND PeriodFrom <= @PeriodToDate AND PeriodTo > @PeriodToDate

 

/* The new price in inserted into the table */

INSERT INTO Prices

  (FK_ProductID, FK_PriceTypeID, [value], PeriodFrom, PeriodTo)

  VALUES

   (@ProductID, @PriceTypeID, @Value, @PeriodFromDate, @PeriodToDate)

SELECT SCOPE_IDENTITY() PriceID, CAST(1 AS BIT) Success
