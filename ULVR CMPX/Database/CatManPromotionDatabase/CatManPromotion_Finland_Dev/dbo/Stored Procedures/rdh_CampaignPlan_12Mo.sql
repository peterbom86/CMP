CREATE PROC [dbo].[rdh_CampaignPlan_12Mo]
@year int,
@userid int

--[dbo].[rdh_CampaignPlan_12Mo] 2016,1

AS

Declare @Procname nvarchar(100)
Declare @Activities int

set @Procname=(SELECT Name FROM Sysobjects WHERE ID = @@PROCID)
set @Activities = (SELECT SUM(CAST(Criteria as int)) FROM ReportCriterias WHERE ReportObjectName=@ProcName AND UserID=@UserID AND DBField='Value') - (SELECT SUM(Value) FROM ActivityTypes)

SELECT DISTINCT 
  WS.Label AS GroupBy, 
  CASE WHEN ISNULL(AT.Label,'') ='' THEN CH.Label ELSE CH.Label + ' (' + AT.Label + ')' END AS Col1, C.Label AS Campaign, A.Label As Activity,
  Month(A.ActivityFrom) As Period, 
  dbo.fn_ActivityType(A.ActivityTypes) AS Types,
  AST.Label As Status, 
  0 AS Volume, 
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

  AS PricePoint, Month(A.ActivityFrom)

FROM
  dbo.CategoryGroups CG 
  INNER JOIN dbo.ProductHierarchies PH on PK_CategoryGroupID = FK_CategoryGroupID 
  INNER JOIN dbo.ProductHierarchies PH2 on ph.PK_ProductHierarchyID = PH2.FK_ProductHierarchyParentID 
  INNER JOIN dbo.Products P on PH2.FK_ProductID = P.PK_ProductID 
  INNER JOIN dbo.ActivityLines AL on P.PK_ProductID = AL.FK_SalesUnitID
  INNER JOIN dbo.Activities A on AL.FK_ActivityID = A.PK_ActivityID 
  INNER JOIN dbo.ActivityPurposes AP ON A.FK_ActivityPurposeID = AP.PK_ActivityPurposeID 
  INNER JOIN dbo.ActivityStatus AST ON A.FK_ActivityStatusID = AST.PK_ActivityStatusID 
  LEFT JOIN dbo.ActivityTypes AT ON (AT.Value & A.ActivityTypes)!=0
  INNER JOIN dbo.Participators WS 
  INNER JOIN dbo.Campaigns C ON WS.PK_ParticipatorID = C.FK_WholesellerID 
  INNER JOIN dbo.Participators CH ON C.FK_ChainID = CH.PK_ParticipatorID ON A.FK_CampaignID = C.PK_CampaignID

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

ORDER BY 
	WS.Label, CASE WHEN ISNULL(AT.Label,'') ='' THEN CH.Label ELSE CH.Label + ' (' + AT.Label + ')' END, Month(A.ActivityFrom)
