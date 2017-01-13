CREATE PROC dbo.rdh_CampaignPlan
@week int,
@year int,
@userid int

AS

Declare @Procname nvarchar(100)
Declare @Activities int

set @Procname=(SELECT Name FROM Sysobjects WHERE ID = @@PROCID)
set @Activities = (SELECT SUM(CAST(Criteria as int)) FROM ReportCriterias WHERE ReportObjectName=@ProcName AND UserID=@UserID AND DBField='Value') - (SELECT SUM(Value) FROM ActivityTypes)

SELECT DISTINCT 
  Participators_1.Label AS GroupBy, dbo.Participators.Label AS Col1, Activities.Label As Activity,
  dbo.fn_IsoWeekOnly(dbo.Activities.ActivityFrom) As Period, dbo.fn_ActivityType(dbo.Activities.ActivityTypes) AS Types,
  dbo.ActivityStatus.Label As Status, (SELECT SUM(EstimatedVolumeSupplier) FROM ActivityLines WHERE FK_ActivityID=dbo.Activities.PK_ActivityID) AS Volume,

  (SELECT MAX(

  CASE WHEN ActivityLines.EstimatedSalesPricePieces=0 THEN
    CASE WHEN ISNULL(ActivityLines.EstimatedSalesPrice,0)=0 THEN 'Pris mangler' 
    ELSE 
    '1 for ' + REPLACE(CAST(ActivityLines.EstimatedSalesPrice as nvarchar),'.',',')
    END
  ELSE
    CAST(ActivityLines.EstimatedSalesPricePieces as nvarchar) + ' for ' + REPLACE(CAST(ActivityLines.EstimatedSalesPrice as nvarchar),'.',',') 
  END) 
  FROM ActivityLines  
  
  WHERE FK_ActivityID=dbo.Activities.PK_ActivityID
  GROUP BY FK_ActivityID)

  AS PricePoint, dbo.fn_IsoWeek(dbo.Activities.ActivityFrom)

FROM
  dbo.CategoryGroups as cg INNER JOIN
  dbo.ProductHierarchies as ph on PK_CategoryGroupID = FK_CategoryGroupID INNER JOIN
  dbo.ProductHierarchies as ph2 on ph.PK_ProductHierarchyID = ph2.FK_ProductHierarchyParentID INNER JOIN
  dbo.Products as p on ph2.FK_ProductID = p.PK_ProductID INNER JOIN
  dbo.ActivityLines as al on p.PK_ProductID = al.FK_SalesUnitID INNER JOIN
  dbo.Activities on al.FK_ActivityID = dbo.Activities.PK_ActivityID INNER JOIN
  dbo.ActivityPurposes ON dbo.Activities.FK_ActivityPurposeID = dbo.ActivityPurposes.PK_ActivityPurposeID INNER JOIN
  dbo.ActivityStatus ON dbo.Activities.FK_ActivityStatusID = dbo.ActivityStatus.PK_ActivityStatusID INNER JOIN
  dbo.Participators Participators_1 INNER JOIN
  dbo.Campaigns ON Participators_1.PK_ParticipatorID = dbo.Campaigns.FK_WholesellerID INNER JOIN
  dbo.Participators ON dbo.Campaigns.FK_ChainID = dbo.Participators.PK_ParticipatorID ON 
  dbo.Activities.FK_CampaignID = dbo.Campaigns.PK_CampaignID

WHERE    

  (Participators_1.PK_ParticipatorID IN
    (SELECT Criteria FROM ReportCriterias 
    WHERE ReportObjectName=@ProcName AND UserID=@UserID AND DBField='ParticipatorID')  OR

  dbo.Campaigns.FK_ChainID IN (SELECT Criteria FROM ReportCriterias 
    WHERE ReportObjectName=@ProcName AND UserID=@UserID AND DBField='ChainID'))

  AND dbo.Activities.Label IN 
    (SELECT Label FROM vwActivityID WHERE PK_ProductHierarchyID IN
    (SELECT Criteria FROM ReportCriterias 
    WHERE ReportObjectName=@ProcName AND UserID=@UserID AND DBField='ForecastUnitID')) 

  AND dbo.Activities.FK_ActivityStatusID IN 
    (SELECT Criteria FROM ReportCriterias 
    WHERE ReportObjectName=@ProcName AND UserID=@UserID AND DBField='FK_ActivityStatusID') 

  AND (dbo.fn_IsoWeek(dbo.Activities.ActivityFrom) >= dbo.rdh_fn_period(@year,@week,1)) AND 
  (dbo.fn_IsoWeek(dbo.Activities.ActivityTo) <= dbo.rdh_fn_period(@year,@week,13))

  AND (PK_ActivityID IN (SELECT DISTINCT PK_ActivityID FROM Activities INNER JOIN ReportCriterias ON (ActivityTypes & Criteria) = Criteria 
  WHERE ReportObjectName=@ProcName AND UserID=@UserID AND DBField='Value') OR @Activities = 0)

ORDER BY Participators_1.Label, dbo.Participators.Label, dbo.fn_IsoWeek(dbo.Activities.ActivityFrom)
