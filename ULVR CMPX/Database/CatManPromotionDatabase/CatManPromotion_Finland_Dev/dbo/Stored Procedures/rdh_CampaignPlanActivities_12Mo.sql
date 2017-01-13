
CREATE PROC [dbo].[rdh_CampaignPlanActivities_12Mo]
@year INT,
@userid int

AS


----[dbo].[rdh_CampaignPlanActivities_12Mo] 2016,1
Declare @Procname nvarchar(100)
Declare @Activities int
Declare @PeriodName int
Set @PeriodName = @year

set @Procname = 'rdh_CampaignPlan_12Mo'
set @Activities = (SELECT SUM(CAST(Criteria as int)) FROM ReportCriterias WHERE ReportObjectName=@ProcName AND UserID=@UserID AND DBField='Value') - (SELECT SUM(Value) FROM ActivityTypes)

SELECT  DISTINCT   
  'Activities' AS GroupBy, A.Label AS Col1,
  CASE WHEN ISNULL(AT.Label,'') ='' THEN CH.Label ELSE CH.Label + ' (' + AT.Label + ')' END AS Chain, C.Label AS Campaign, AT.label AS PromotionType,
  Month(a.ActivityFrom) As Period, dbo.fn_ActivityType(a.ActivityTypes) As Types, Pr.PeriodYear,
  AST.Label As Status, 0 AS Volume,
    (SELECT MAX(

  CASE WHEN ActivityLines.EstimatedSalesPricePieces=0 THEN
    CASE WHEN ISNULL(ActivityLines.EstimatedSalesPrice,0)=0 THEN 'No Price point' 
    ELSE 
    '1 for ' + REPLACE(CAST(ActivityLines.EstimatedSalesPrice as nvarchar),'.',',')
    END
  ELSE
    CAST(ActivityLines.EstimatedSalesPricePieces as nvarchar) + ' for ' + REPLACE(CAST(ActivityLines.EstimatedSalesPrice as nvarchar),'.',',') 
  END) 
  FROM ActivityLines  
  
  WHERE FK_ActivityID=A.PK_ActivityID
  GROUP BY FK_ActivityID)

  AS PricePoint, Month(a.ActivityFrom)
FROM
  dbo.CategoryGroups CG
  INNER JOIN dbo.ProductHierarchies PH ON CG.PK_CategoryGroupID = PH.FK_CategoryGroupID
  INNER JOIN dbo.ProductHierarchies PH2 ON PH.PK_ProductHierarchyID = PH2.FK_ProductHierarchyParentID 
  INNER JOIN dbo.Products P ON PH2.FK_ProductID = P.PK_ProductID 
  INNER JOIN dbo.ActivityLines AL ON P.PK_ProductID = AL.FK_SalesUnitID
  INNER JOIN dbo.Activities A ON AL.FK_ActivityID = A.PK_ActivityID
  INNER JOIN dbo.ActivityPurposes AP ON A.FK_ActivityPurposeID = AP.PK_ActivityPurposeID
  INNER JOIN dbo.ActivityStatus AST ON A.FK_ActivityStatusID = AST.PK_ActivityStatusID
  LEFT JOIN dbo.ActivityTypes AT ON (AT.Value & A.ActivityTypes)!=0
  INNER JOIN dbo.Participators WS
  INNER JOIN dbo.Campaigns C ON WS.PK_ParticipatorID = C.FK_WholesellerID
  INNER JOIN dbo.Participators CH ON C.FK_ChainID = CH.PK_ParticipatorID ON A.FK_CampaignID = C.PK_CampaignID
  INNER JOIN dbo.Periods PR ON PR.Label = A.ActivityFrom 
WHERE     
  (WS.PK_ParticipatorID IN
    (SELECT Criteria FROM ReportCriterias 
    WHERE ReportObjectName=@ProcName AND UserID=@UserID AND DBField='ParticipatorID')  OR

  C.FK_ChainID IN (SELECT Criteria FROM ReportCriterias 
    WHERE ReportObjectName=@ProcName AND UserID=@UserID AND DBField='ChainID'))

  AND A.Label IN 
    (SELECT Label FROM vwActivityID WHERE PK_ProductHierarchyID IN
    (SELECT Criteria FROM ReportCriterias 
    WHERE ReportObjectName=@ProcName AND UserID=@UserID AND DBField='ForecastUnitID')) 

  AND A.FK_ActivityStatusID IN 
    (SELECT Criteria FROM ReportCriterias 
    WHERE ReportObjectName=@ProcName AND UserID=@UserID AND DBField='FK_ActivityStatusID') 

  AND (Year(A.ActivityFrom) >= @year) AND 
  (Year(A.ActivityTo) <= @year)

  AND (PK_ActivityID IN (SELECT DISTINCT PK_ActivityID FROM Activities INNER JOIN ReportCriterias ON (ActivityTypes & Criteria) = Criteria 
  WHERE ReportObjectName=@ProcName AND UserID=@UserID AND DBField='Value') OR @Activities = 0)
  

ORDER BY A.Label, CASE WHEN ISNULL(AT.Label,'') ='' THEN CH.Label ELSE CH.Label + ' (' + AT.Label + ')' END, Month(A.ActivityFrom)

