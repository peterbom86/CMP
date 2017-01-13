CREATE   Function rdh_fn_Rebate (@CampaignID int)
Returns varchar(40)

AS

BEGIN

DECLARE @Settlement varchar(40)
DECLARE @OnInvoice int
DECLARE @OffInvoice int


Set @OnInvoice=    
  (SELECT COUNT(*) FROM dbo.Activities INNER JOIN
        dbo.ActivityLines ON dbo.Activities.PK_ActivityID = dbo.ActivityLines.FK_ActivityID INNER JOIN
        dbo.CampaignDiscounts ON dbo.ActivityLines.PK_ActivityLineID = dbo.CampaignDiscounts.FK_ActivityLineID
  WHERE OnInvoice=1 AND FK_CampaignID=@CampaignID AND [value]<>0)


Set @OffInvoice=    
  (SELECT COUNT(*) FROM dbo.Activities INNER JOIN
        dbo.ActivityLines ON dbo.Activities.PK_ActivityID = dbo.ActivityLines.FK_ActivityID INNER JOIN
        dbo.CampaignDiscounts ON dbo.ActivityLines.PK_ActivityLineID = dbo.CampaignDiscounts.FK_ActivityLineID
  WHERE OnInvoice=0 AND FK_CampaignID=@CampaignID AND [value]<>0)

set @Settlement='N/A'

if @OnInvoice>0 AND @OffInvoice>0 set @Settlement='På faktura/Bagud'
if @OnInvoice=0 AND @OffInvoice>0 set @Settlement='Bagud'
if @OnInvoice>0 AND @OffInvoice=0 set @Settlement='På faktura'

return @Settlement

END



