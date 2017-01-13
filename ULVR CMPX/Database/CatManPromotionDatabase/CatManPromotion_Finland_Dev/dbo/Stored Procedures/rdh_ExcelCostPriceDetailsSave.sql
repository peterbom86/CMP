CREATE PROCEDURE [dbo].[rdh_ExcelCostPriceDetailsSave]
  @CostPriceHeaderID NVARCHAR(255),
  @CommonCodeID NVARCHAR(255),
  @Value NVARCHAR(255),
  @CategoryGroup NVARCHAR(255),
  @ProductHierarchy NVARCHAR(255),
  @ProductCode NVARCHAR(255),
  @ProductName NVARCHAR(255),
  @CommonCode NVARCHAR(255)

AS

IF (SELECT COUNT(*) FROM dbo.CommonCodes WHERE PK_CommonCodeID = @CommonCodeID) = 0
BEGIN
	RAISERROR('No valid commoncode is specified',11,1)
	RETURN -1
END

IF (SELECT COUNT(*) FROM dbo.CostPriceHeader WHERE PK_CostPriceHeaderID = @CostPriceHeaderID) = 0
BEGIN
	RAISERROR('No valid costprice header is specified',11,1)
	RETURN -1
END

IF @Value = ''
BEGIN
	RAISERROR('No valid costprice is specified',11,1)
	RETURN -1
END


DECLARE @CostPriceDetailID int

IF (SELECT COUNT(*) FROM CostPriceHeader WHERE PK_CostPriceHeaderID = @CostPriceHeaderID) > 0 AND
  (SELECT COUNT(*) FROM dbo.CommonCodes WHERE PK_CommonCodeID = @CommonCodeID) > 0
BEGIN
  IF ( SELECT COUNT(*) FROM CostPriceDetails WHERE FK_CostPriceHeaderID = @CostPriceHeaderID AND FK_CommonCodeID = @CommonCodeID ) > 0
  BEGIN
    UPDATE CostPriceDetails
    SET Value = @Value
    WHERE FK_CostPriceHeaderID = @CostPriceHeaderID AND
      FK_CommonCodeID = @CommonCodeID

    SELECT @CostPriceDetailID = PK_CostPriceDetailID
    FROM CostPriceDetails
    WHERE FK_CostPriceHeaderID = @CostPriceHeaderID AND
      FK_CommonCodeID = @CommonCodeID
  END
  ELSE
  BEGIN
    INSERT INTO CostPriceDetails ( FK_CostPriceHeaderID, FK_CommonCodeID, Value )
    SELECT @CostPriceHeaderID, @CommonCodeID, @Value

    SET @CostPriceDetailID = SCOPE_IDENTITY()
  END
END
ELSE
BEGIN
  SET @CostPriceDetailID = -1
END

SELECT @CostPriceDetailID CostPriceDetailID, CAST(1 AS BIT) Success
