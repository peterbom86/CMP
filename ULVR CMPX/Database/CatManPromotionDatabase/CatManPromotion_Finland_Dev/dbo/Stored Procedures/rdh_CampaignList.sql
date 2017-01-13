CREATE PROCEDURE [dbo].[rdh_CampaignList] 
@YearFrom int,
@UserID int,
@bitValue int

AS

Declare @UserName nvarchar(100)

set @UserName=(SELECT UserName FROM USERS WHERE PK_UserID=@UserID)


SELECT     
  dbo.Campaigns.PK_CampaignID AS CampaignID, dbo.Campaigns.Label AS Campaign,
  (select label from dbo.Participators where dbo.Participators.PK_ParticipatorID = dbo.campaigns.FK_WholesellerID) as Wholesaler,  
  Participators_1.Label AS Chain, vwActivities.Label AS Activity,   
  dbo.fn_ActivityType(vwActivities.ActivityTypes) AS CampaignType, 
  dbo.fn_IsoYear(vwActivities.ActivityFrom) AS Yr, 
  dbo.fn_IsoWeekOnly(vwActivities.ActivityFrom) AS StartWeek,
  vwActivities.SupplierVolume AS Forecast,
  dbo.Campaigns.Export,
  dbo.ActivitySubsider.[Value] AS Subsider, dbo.ActivityStatus.Label AS Status, 
  dbo.ActivityPurposes.Label As Purpose,
  dbo.Teams.Label AS Team, Users_1.UserName AS Owner, 
  dbo.Users.UserName AS CreatedBy,
  dbo.Campaigns.CreatedDate,
  dbo.Campaigns.RebateAgreementNoDiscount,
  dbo.Campaigns.RebateAgreementNoSubsider,
  dbo.Campaigns.SalesDealNo,
  dbo.Campaigns.ExcludeFromMassUpdates as AllowUpdate   
FROM         
  (SELECT FK_CampaignID, SUM(DISTINCT cg.BitValue) BitValue
FROM    dbo.CategoryGroups as cg
           INNER JOIN dbo.ProductHierarchies as ph on PK_CategoryGroupID = FK_CategoryGroupID
           INNER JOIN dbo.ProductHierarchies as ph2 on ph.PK_ProductHierarchyID = ph2.FK_ProductHierarchyParentID
           INNER JOIN dbo.Products as p on ph2.FK_ProductID = p.PK_ProductID
           INNER JOIN dbo.ActivityLines as al on p.PK_ProductID = al.FK_SalesUnitID
           INNER JOIN dbo.Activities as a on al.FK_ActivityID = a.PK_ActivityID
GROUP BY FK_CampaignID) SubCG 
           INNER JOIN dbo.Campaigns on SubCG.FK_CampaignID = dbo.Campaigns.PK_CampaignID INNER JOIN
  vwActivities ON dbo.Campaigns.PK_CampaignID = vwActivities.FK_CampaignID INNER JOIN
  --dbo.Campaigns ON vwActivities.FK_CampaignID = dbo.Campaigns.PK_CampaignID INNER JOIN
  dbo.Participators ON dbo.Campaigns.FK_WholesellerID = dbo.Participators.PK_ParticipatorID INNER JOIN
  dbo.Participators Participators_1 ON dbo.Campaigns.FK_ChainID = Participators_1.PK_ParticipatorID INNER JOIN
  dbo.ActivityStatus ON vwActivities.FK_ActivityStatusID = dbo.ActivityStatus.PK_ActivityStatusID INNER JOIN
  dbo.ActivityPurposes ON vwActivities.FK_ActivityPurposeID = dbo.ActivityPurposes.PK_ActivityPurposeID INNER JOIN
  dbo.Teams ON dbo.Participators.FK_TeamID = dbo.Teams.PK_TeamID INNER JOIN
    -- AND Participators_1.FK_TeamID = dbo.Teams.PK_TeamID INNER JOIN // Changed po 2011-08-16 - the wholeseller does not have to be same team as the chain
  dbo.Users ON vwActivities.FK_CreatedByUserID = dbo.Users.PK_UserID LEFT JOIN
  dbo.ActivitySubsider ON vwActivities.PK_ActivityID = dbo.ActivitySubsider.FK_ActivityID INNER JOIN
  dbo.Users Users_1 ON dbo.Campaigns.FK_OwnerUserID = Users_1.PK_UserID
WHERE     
  SubCG.BitValue & @bitValue > 0 AND
  (YEAR(vwActivities.ActivityFrom) = @YearFrom OR @YearFrom = -1) AND 
  dbo.Campaigns.FK_OwnerUserID= 
  CASE WHEN @UserID=0 THEN dbo.Campaigns.FK_OwnerUserID ELSE @UserID END

GROUP BY
dbo.Campaigns.PK_CampaignID,
dbo.Campaigns.Label,
Participators_1.Label,
vwActivities.Label,
dbo.fn_ActivityType(vwActivities.ActivityTypes), 
  dbo.fn_IsoYear(vwActivities.ActivityFrom), 
  dbo.fn_IsoWeekOnly(vwActivities.ActivityFrom),
vwActivities.SupplierVolume,
dbo.ActivitySubsider.[Value], 
dbo.ActivityStatus.Label, 
  dbo.ActivityPurposes.Label,
  dbo.Teams.Label, 
Users_1.UserName, 
  dbo.Users.UserName,
  dbo.Campaigns.CreatedDate,
  dbo.Campaigns.Export,
  dbo.Campaigns.RebateAgreementNoDiscount,
  dbo.Campaigns.RebateAgreementNoSubsider,
  dbo.Campaigns.SalesDealNo,
vwActivities.ActivityFrom,
dbo.Campaigns.ExcludeFromMassUpdates,
dbo.campaigns.FK_WholesellerID



ORDER BY 
  CASE WHEN Users_1.UserName=@UserName THEN 1 ELSE 2 END, vwActivities.ActivityFrom
