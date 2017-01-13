CREATE PROCEDURE rdg_SelectPreviousForecast
  @ForecastingUnit int,
  @ParticipatorID int

AS


SELECT PH2.PK_ProductHierarchyID, FK_ChainID, * 
FROM Campaigns C
  INNER JOIN Activities A ON PK_CampaignID = FK_CampaignID
  INNER JOIN ActivityLines AL ON PK_ActivityID = FK_ActivityID
  INNER JOIN Products P ON AL.FK_SalesUnitID = P.PK_ProductID
  INNER JOIN ProductHierarchies PH1 ON P.PK_ProductID = PH1.FK_ProductID
  INNER JOIN ProductHierarchies PH2 ON PH1.FK_ProductHierarchyParentID = PH2.PK_ProductHierarchyID 
    AND PH2.FK_ProductHierarchyLevelID = 4
WHERE
  PH2.PK_ProductHierarchyID = @ForecastingUnit AND
  C.FK_ChainID = @ParticipatorID



