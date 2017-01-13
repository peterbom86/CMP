CREATE  Procedure rdh_CleanUpDiscounts
@ActivityID int, @OnInvoice int

AS

DELETE FROM CampaignDiscounts WHERE FK_ActivityLineID IN
(SELECT PK_ActivityLineID FROM ActivityLines WHERE FK_ActivityID=@ActivityID)
AND OnInvoice=@OnInvoice


