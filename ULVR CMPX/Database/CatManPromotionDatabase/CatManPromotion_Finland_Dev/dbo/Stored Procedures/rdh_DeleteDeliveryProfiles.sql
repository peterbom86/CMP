CREATE PROCEDURE rdh_DeleteDeliveryProfiles
  @DeliveryProfileID int

AS

DELETE FROM DeliveryProfiles
WHERE PK_DeliveryProfileID = @DeliveryProfileID




