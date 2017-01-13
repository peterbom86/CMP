CREATE  Procedure rdh_activity
@CampaignID int

AS

SELECT     
  vwActivities.Label AS Activity,
  vwActivities.SupplierVolume AS Forecast,
  dbo.rdh_fn_ActivityDiscountTPR(vwActivities.PK_ActivityID,1) AS OnInvoice,
  dbo.rdh_fn_ActivityDiscountTPR(vwActivities.PK_ActivityID,0) AS OffInvoice
FROM         
  vwActivities INNER JOIN
  dbo.ActivityStatus ON vwActivities.FK_ActivityStatusID = dbo.ActivityStatus.PK_ActivityStatusID
WHERE     
  FK_CampaignID= @CampaignID
ORDER BY 
  vwActivities.Label






