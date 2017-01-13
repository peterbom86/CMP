/* DDC: 13.09.2006 */
/* PO: 02.09.2008 - PerformMaterialChange is removed */

CREATE PROCEDURE [dbo].[rdh_InsertActivityLine]( 
  @ActivityID INT,
  @SalesUnitID INT,
  @ProductID INT, -- NY parameter
  --@PerformMaterialChange BIT,
  @SupplierVolume INT,
  @WholesellerVolume INT,
  @ParticipatorVolume INT,
  @ChainVolume INT,
  @SalesPieces INT,
  @PricePoint FLOAT, 
  @Fbox NVARCHAR(4)='None')
  
AS

DECLARE @PerformMaterialChange BIT
DECLARE @FBoxID INT

SELECT @FBoxID = CASE WHEN @Fbox = 'None' THEN 0 ELSE CAST(RIGHT(@Fbox,1) AS NVARCHAR) END
SET @PerformMaterialChange = 1

Declare @ActivityLineID int
Declare @returnID int

Set @ActivityLineID= ISNULL((SELECT PK_ActivityLineID FROM ActivityLines WHERE FK_ActivityID=@ActivityID AND FK_SalesUnitID=@SalesUnitID AND FK_ProductID=@ProductID),-1)

If @ActivityLineID=-1

BEGIN

INSERT INTO ActivityLines 
  ( 
  FK_ActivityID, 
  FK_SalesUnitID,
        FK_ProductID, 
  PerformMaterialChange, 
  EstimatedVolumeSupplier, 
  EstimatedVolumeWholeseller, 
  EstimatedVolumeChain,
  EstimatedVolumeParticipator,
  EstimatedSalesPricePieces,
  EstimatedSalesPrice,
  FK_FboxID
  )

SELECT 
        @ActivityID, 
		@SalesUnitID,
		@ProductID,
        @PerformMaterialChange, 
        @SupplierVolume, 
        @WholesellerVolume, 
        @ChainVolume,
		@ParticipatorVolume, 
        @SalesPieces, 
        @PricePoint,
        @FBoxID
END

  SELECT @returnID = SCOPE_IDENTITY()

If @ActivityLineID<>-1

BEGIN

UPDATE ActivityLines
SET 
  FK_ActivityID = @ActivityID, 
  FK_SalesUnitID = @SalesUnitID, 
  FK_ProductID = @ProductID, 
  PerformMaterialChange = @PerformMaterialChange, 
  EstimatedVolumeSupplier = @SupplierVolume, 
  EstimatedVolumeWholeseller =  @WholesellerVolume, 
  EstimatedVolumeChain =  @ChainVolume, 
  EstimatedVolumeParticipator = @ParticipatorVolume,
  EstimatedSalesPricePieces =  @SalesPieces, 
  EstimatedSalesPrice = @PricePoint,
  FK_FboxID = @FBoxID
WHERE 
  PK_ActivityLineID = @ActivityLineID

  Set @returnID = @ActivityLineID
  
END
  SELECT @returnID

