CREATE PROCEDURE [dbo].[rdh_ExcelRabatimportSave] 
	@Participator NVARCHAR(255),
	@CustomerHierarchy NVARCHAR(255),
	@Product NVARCHAR(255),
	@ProductHierarchy NVARCHAR(255),
	@BaseDiscountType NVARCHAR(255), 
	@PeriodFrom NVARCHAR(255), 
	@PeriodTo NVARCHAR(255), 
	@BaseDiscount NVARCHAR(255)

AS

DECLARE @ParticipatorID int
DECLARE @CustomerHierarchyID int
DECLARE @ProductID int
DECLARE @ProductHierarchyID int
DECLARE @BaseDiscountTypeID INT
DECLARE @PeriodFromDate DATETIME
DECLARE @PeriodToDate DATETIME

EXEC @ParticipatorID = [rdh_ExcelMappingGetID] 6, @Participator
EXEC @CustomerHierarchyID = [rdh_ExcelMappingGetID] 5, @CustomerHierarchy
EXEC @ProductID = [rdh_ExcelMappingGetID] 8, @Product
EXEC @ProductHierarchyID = [rdh_ExcelMappingGetID] 7, @ProductHierarchy
EXEC @BaseDiscountTypeID = [rdh_ExcelMappingGetID] 9, @BaseDiscountType

DECLARE @PriceBaseID int
DECLARE @ValueTypeID int
DECLARE @VolumeBaseID int
DECLARE @OnInvoice bit

IF @ParticipatorID = -1
SET @ParticipatorID = Null

IF @CustomerHierarchyID = -1
SET @CustomerHierarchyID = Null

IF @ProductID = -1
SET @ProductID = Null

IF @ProductHierarchyID = -1
SET @ProductHierarchyID = Null

IF @ParticipatorID IS NULL AND @CustomerHierarchyID IS NULL
BEGIN
	RAISERROR('Either Participator or CustomerHierarchy must be specified',11,1)
	RETURN -1
END

IF @ProductID IS NULL AND @ProductHierarchyID IS NULL
BEGIN
	RAISERROR('Either Product or ProductHierarchy must be specified',11,1)
	RETURN -1
END

IF ISNULL(@BaseDiscountTypeID, -1) = -1
BEGIN 
	RAISERROR('No valid BaseDiscountType has been provided', 11, 1)
	RETURN -1
END

IF ISNULL(@BaseDiscount, '') = ''
BEGIN
	RAISERROR('No value for the BaseDiscount has been provided', 11, 1)
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

SELECT @PriceBaseID = FK_PriceBaseID, @ValueTypeID = FK_ValueTypeID, @VolumeBaseID = FK_VolumeBaseID, @OnInvoice = OnInvoice
FROM dbo.BaseDiscountTypes AS bdt
WHERE PK_BaseDiscountTypeID = @BaseDiscountTypeID

IF @PeriodToDate > '2099-12-31'
SET @PeriodToDate = '2099-12-31'

IF @PeriodFromDate > @PeriodToDate
SET @PeriodFromDate = @PeriodToDate

declare @NewPeriodFrom datetime
declare @NewPeriodTo datetime

Set @NewPeriodFrom=@PeriodToDate+1
Set @NewPeriodTo=@PeriodFromDate-1

-- Sletter priser der ligger INDEN for ny periode
DELETE
FROM BaseDiscountsEdit
WHERE 
  PeriodFrom >= @PeriodFromDate AND PeriodTo <= @PeriodToDate AND
  (ISNULL(FK_ParticipatorID, -1) = ISNULL(@ParticipatorID, -1) AND ISNULL(FK_CustomerHierarchyID, -1) = ISNULL(@CustomerHierarchyID, -1)) AND
  (ISNULL(FK_ProductID, -1) = ISNULL(@ProductID, -1) AND ISNULL(FK_ProductHierarchyID, -1) = ISNULL(@ProductHierarchyID, -1)) AND
  FK_BaseDiscountTypeID = @BaseDiscountTypeID

-- Hvis ny pris ligger indenfor en eksisterende prisperiode opdeles den eksisterende pris i 2 perioder (før/efter)

IF (SELECT count(*) FROM BaseDiscountsEdit
    WHERE PeriodFrom < @PeriodFromDate AND PeriodTo > @PeriodToDate AND
      (ISNULL(FK_ParticipatorID, -1) = ISNULL(@ParticipatorID, -1) AND ISNULL(FK_CustomerHierarchyID, -1) = ISNULL(@CustomerHierarchyID, -1)) AND
      (ISNULL(FK_ProductID, -1) = ISNULL(@ProductID, -1) AND ISNULL(FK_ProductHierarchyID, -1) = ISNULL(@ProductHierarchyID, -1)) AND
      FK_BaseDiscountTypeID = @BaseDiscountTypeID) > 0

BEGIN

  INSERT INTO BaseDiscountsEdit (FK_ParticipatorID, FK_CustomerHierarchyID, FK_ProductID, FK_ProductHierarchyID, FK_PriceBaseID, FK_BaseDiscountTypeID, 
    [Value], FK_ValueTypeID, FK_VolumeBaseID, OnInvoice, PeriodFrom, PeriodTo)
  SELECT FK_ParticipatorID, FK_CustomerHierarchyID, FK_ProductID, FK_ProductHierarchyID, FK_PriceBaseID, FK_BaseDiscountTypeID, 
    [Value], FK_ValueTypeID, FK_VolumeBaseID, OnInvoice, PeriodFrom, @NewPeriodTo
  FROM BaseDiscountsEdit
  WHERE PeriodFrom < @PeriodFromDate AND PeriodTo > @PeriodToDate AND
    (ISNULL(FK_ParticipatorID, -1) = ISNULL(@ParticipatorID, -1) AND ISNULL(FK_CustomerHierarchyID, -1) = ISNULL(@CustomerHierarchyID, -1)) AND
    (ISNULL(FK_ProductID, -1) = ISNULL(@ProductID, -1) AND ISNULL(FK_ProductHierarchyID, -1) = ISNULL(@ProductHierarchyID, -1)) AND
    FK_BaseDiscountTypeID = @BaseDiscountTypeID
  
  UPDATE BaseDiscountsEdit
  SET PeriodFrom = @NewPeriodFrom
  WHERE PeriodFrom < @PeriodFromDate AND PeriodTo > @PeriodToDate AND
    (ISNULL(FK_ParticipatorID, -1) = ISNULL(@ParticipatorID, -1) AND ISNULL(FK_CustomerHierarchyID, -1) = ISNULL(@CustomerHierarchyID, -1)) AND
    (ISNULL(FK_ProductID, -1) = ISNULL(@ProductID, -1) AND ISNULL(FK_ProductHierarchyID, -1) = ISNULL(@ProductHierarchyID, -1)) AND
    FK_BaseDiscountTypeID = @BaseDiscountTypeID

END


/* Any price which begins before the new validity period and ends in the period in ended the week before the new validity period */

UPDATE BaseDiscountsEdit
SET PeriodTo = @NewPeriodTo
WHERE PeriodFrom < @PeriodFromDate AND PeriodTo <= @PeriodToDate AND PeriodTo >= @PeriodFromDate AND
  (ISNULL(FK_ParticipatorID, -1) = ISNULL(@ParticipatorID, -1) AND ISNULL(FK_CustomerHierarchyID, -1) = ISNULL(@CustomerHierarchyID, -1)) AND
  (ISNULL(FK_ProductID, -1) = ISNULL(@ProductID, -1) AND ISNULL(FK_ProductHierarchyID, -1) = ISNULL(@ProductHierarchyID, -1)) AND
  FK_BaseDiscountTypeID = @BaseDiscountTypeID
 

/* Any price which begins in the new validity period and ends after the period in started in the week after the new validity period */

UPDATE BaseDiscountsEdit
SET PeriodFrom = @NewPeriodFrom
WHERE PeriodFrom >= @PeriodFromDate AND PeriodFrom <= @PeriodToDate AND PeriodTo > @PeriodToDate  AND
  (ISNULL(FK_ParticipatorID, -1) = ISNULL(@ParticipatorID, -1) AND ISNULL(FK_CustomerHierarchyID, -1) = ISNULL(@CustomerHierarchyID, -1)) AND
  (ISNULL(FK_ProductID, -1) = ISNULL(@ProductID, -1) AND ISNULL(FK_ProductHierarchyID, -1) = ISNULL(@ProductHierarchyID, -1)) AND
  FK_BaseDiscountTypeID = @BaseDiscountTypeID

 

/* The new price in inserted into the table */

INSERT INTO BaseDiscountsEdit (FK_ParticipatorID, FK_CustomerHierarchyID, FK_ProductID, FK_ProductHierarchyID, FK_PriceBaseID, FK_BaseDiscountTypeID, 
  [Value], FK_ValueTypeID, FK_VolumeBaseID, OnInvoice, PeriodFrom, PeriodTo)
VALUES (@ParticipatorID, @CustomerHierarchyID, @ProductID, @ProductHierarchyID, @PriceBaseID, @BaseDiscountTypeID, @BaseDiscount, @ValueTypeID, @VolumeBaseID, 
  @OnInvoice, @PeriodFromDate, @PeriodToDate)
  
SELECT CAST(1 AS BIT) Success
