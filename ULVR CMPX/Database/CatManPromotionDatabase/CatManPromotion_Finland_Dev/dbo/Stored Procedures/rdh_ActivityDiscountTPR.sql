Create Procedure rdh_ActivityDiscountTPR
@ActivityID int

AS

SELECT SUM(
CASE WHEN FK_valueTypeID=1 THEN Value*NSV*Supplier ELSE Value*Supplier END)/
SUM(Supplier*NSV) 

FROM vwCampaignDiscounts WHERE FK_ActivityID=@ActivityID
AND OnInvoice=1




