CREATE                 procedure rdh_CampaignAgreementHeader
@CampaignID int

AS

SELECT     
  dbo.Campaigns.PK_CampaignID, 
  
  dbo.Campaigns.Label, dbo.Participators.Label AS Chain, 
  CASE WHEN FK_ActivityPurposeID=7 THEN
    CASE
      WHEN MIN(Fk_ActivityStatusID) = 2 THEN 'Prisaftale udkast nr. ' + CAST(PK_CampaignID as nvarchar)
      WHEN MIN(Fk_ActivityStatusID) = 3 THEN 'Prisaftale forslag nr. ' + CAST(PK_CampaignID as nvarchar)  
      WHEN MIN(Fk_ActivityStatusID) >= 4 THEN 'Prisaftale nr. '+ CAST(PK_CampaignID as nvarchar)
    END  
  ELSE
    CASE
      WHEN MIN(Fk_ActivityStatusID) = 2 THEN 'Kampagneudkast nr. ' + CAST(PK_CampaignID as nvarchar)
      WHEN MIN(Fk_ActivityStatusID) = 3 THEN 'Kampagneforslag nr. ' + CAST(PK_CampaignID as nvarchar)
      WHEN MIN(Fk_ActivityStatusID) >= 4 THEN 'Kampagneaftale nr. '+ CAST(PK_CampaignID as nvarchar)
    END
  END AS Header,

  dbo.Activities.ActivityFrom, 
  dbo.fn_ActivityType(dbo.Activities.ActivityTypes) AS ActivityType, dbo.Participators.Address, 
  dbo.Participators.PostalCode + ' ' + dbo.Participators.District AS City,

  (SELECT TOP 1 dbo.ContactPersons.Label FROM         
  dbo.ParticipatorContactPerson INNER JOIN
  dbo.ContactPersons ON dbo.ParticipatorContactPerson.FK_ContactPersonID = dbo.ContactPersons.PK_ContactPersonID
  WHERE FK_ParticipatorID=dbo.Participators.PK_ParticipatorID) AS Contact,
   
  MinDelivery AS FirstDelivery, 
  dbo.Activities.ActivityTo - 2 AS LastDelivery,

  CASE WHEN dbo.fn_IsoWeekOnly(MinDelivery) <> dbo.fn_IsoWeekOnly(MaxDelivery) THEN
    Cast(dbo.fn_IsoWeekOnly(MinDelivery) as nvarchar) + ' - ' + Cast(dbo.fn_IsoWeekOnly(MaxDelivery) as nvarchar)
  ELSE
    Cast(dbo.fn_IsoWeekOnly(MinDelivery) as nvarchar)
  END AS DeliveryWeek,

  CASE WHEN dbo.fn_IsoWeekOnly(dbo.Activities.ActivityFrom) <> dbo.fn_IsoWeekOnly(dbo.Activities.ActivityTo) THEN
    CAST(dbo.fn_IsoWeekOnly(dbo.Activities.ActivityFrom) AS nvarchar)  + ' - ' + CAST(dbo.fn_IsoWeekOnly(dbo.Activities.ActivityTo) AS nvarchar)
  ELSE
    CAST(dbo.fn_IsoWeekOnly(dbo.Activities.ActivityFrom) AS nvarchar) 
  END AS CampaignWeek,

  ISNULL(SUM(dbo.ActivitySubsider.[Value]),0) +  ISNULL((SELECT SUM([Value]) FROM dbo.CampaignSubsider WHERE FK_CampaignID=PK_CampaignID),0) AS Subsider,
  dbo.Campaigns.[Description] as Remarks,
  dbo.rdh_fn_Rebate(PK_CampaignID) AS RebateSettlement, UserName




FROM
  dbo.Campaigns INNER JOIN
  dbo.Activities ON dbo.Campaigns.PK_CampaignID = dbo.Activities.FK_CampaignID INNER JOIN
  dbo.Participators ON dbo.Campaigns.FK_ChainID = dbo.Participators.PK_ParticipatorID LEFT JOIN
  (SELECT FK_ActivityID,MIN(dbo.ActivityDeliveries.DeliveryDate) AS MinDelivery FROM dbo.ActivityDeliveries WHERE [value]> 0 
  GROUP BY FK_ActivityID) AS MinDelivery ON Activities.PK_ActivityID=MinDelivery.Fk_ActivityID LEFT JOIN
  (SELECT FK_ActivityID,MAX(dbo.ActivityDeliveries.DeliveryDate) AS MaxDelivery FROM dbo.ActivityDeliveries WHERE [value]> 0
  GROUP BY FK_ActivityID) AS MaxDelivery ON Activities.PK_ActivityID=MaxDelivery.Fk_ActivityID LEFT JOIN
        dbo.ActivitySubsider ON dbo.Activities.PK_ActivityID = dbo.ActivitySubsider.FK_ActivityID  LEFT OUTER JOIN
        dbo.Users ON dbo.Campaigns.FK_OwnerUserID = dbo.Users.PK_UserID


WHERE 
  dbo.Campaigns.PK_CampaignID=@CampaignID

GROUP BY 
  dbo.Campaigns.PK_CampaignID, dbo.Campaigns.Label, dbo.Participators.PK_ParticipatorID, dbo.Participators.Label, dbo.Activities.ActivityFrom, dbo.Activities.ActivityTypes, 
  dbo.Participators.Address, dbo.Participators.PostalCode, dbo.Participators.District, dbo.Campaigns.[Description], 
  MinDelivery, MaxDelivery,dbo.Activities.ActivityTo - 2, dbo.Activities.ActivityTo, UserName, FK_ActivityPurposeID


