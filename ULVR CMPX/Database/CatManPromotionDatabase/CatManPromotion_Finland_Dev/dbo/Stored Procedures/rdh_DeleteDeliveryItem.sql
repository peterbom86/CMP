CREATE   PROCEDURE rdh_DeleteDeliveryItem
@DeliveryItemID int,
@ProfileID int

AS

DELETE FROM 
  DeliveryItems
WHERE 
  PK_DeliveryItemID = @DeliveryItemID

IF (SELECT Count(*) FROM DeliveryItems WHERE FK_DeliveryProfileID = @ProfileID) = 0
BEGIN
  DELETE FROM DeliveryProfiles WHERE PK_DeliveryProfileID = @ProfileID
END




