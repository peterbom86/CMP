CREATE PROCEDURE [dbo].[rdh_ExcelSupplyCostDetailsSave]
  @ProductHierarchyID nvarchar(255),
  @CategoryGroup nvarchar(255),
  @ProductHierarchy nvarchar(255),
  @Value nvarchar(255),
  @SupplyCostHeaderID nvarchar(255)
  
AS

IF (SELECT COUNT(*) FROM dbo.ProductHierarchies WHERE PK_ProductHierarchyID = @ProductHierarchyID) = 0
BEGIN
	RAISERROR('No valid producthierarchy is specified',11,1)
	RETURN -1
END

IF (SELECT COUNT(*) FROM dbo.SupplyCostHeader WHERE PK_SupplyCostHeaderID = @SupplyCostHeaderID) = 0
BEGIN
	RAISERROR('No valid supplycost header is specified',11,1)
	RETURN -1
END

IF @Value = ''
BEGIN
	RAISERROR('No valid supplycost is specified',11,1)
	RETURN -1
END

IF ( SELECT COUNT(*) FROM dbo.SupplyCostDetails WHERE FK_SupplyCostHeaderID = @SupplyCostHeaderID AND FK_ProductHierarchyID = @ProductHierarchyID ) = 0
BEGIN
	INSERT INTO dbo.SupplyCostDetails
	        ( FK_SupplyCostHeaderID ,
	          FK_ProductHierarchyID ,
	          Value
	        )
	VALUES  ( @SupplyCostHeaderID,
			  @ProductHierarchyID,
			  @Value
	        )
END
ELSE
BEGIN
	UPDATE dbo.SupplyCostDetails
	SET Value = @Value
	WHERE FK_SupplyCostHeaderID = @SupplyCostHeaderID AND
		FK_ProductHierarchyID = @ProductHierarchyID
END

SELECT CAST(1 AS BIT) Success
