CREATE PROCEDURE [dbo].[rdh_ExcelSupplyCostDetails]
 @SupplyCostHeaderID int

AS

SELECT CategoryGroup, PK_ProductHierarchyID ProductHierarchyID, ProductHierarchy, ISNULL(Value, 0) VALUE, @SupplyCostHeaderID SupplyCostHeaderID
FROM (
  SELECT CG.Label CategoryGroup, PK_ProductHierarchyID, PH.Label ProductHierarchy
  FROM ProductHierarchies PH
    INNER JOIN ProductHierarchyLevels PHL ON PK_ProductHierarchyLevelID = FK_ProductHierarchyLevelID
    INNER JOIN ProductHierarchyNames PHN ON PK_ProductHierarchyNameID = FK_ProductHierarchyNameID
    LEFT JOIN CategoryGroups CG ON PK_CategoryGroupID = FK_CategoryGroupID
  WHERE IsForecastingUnit = 1 AND PH.Node <> 'Forecasting1') ForecastingUnits
    LEFT JOIN SupplyCostDetails ON PK_ProductHierarchyID = FK_ProductHierarchyID AND FK_SupplyCostHeaderID = @SupplyCostHeaderID
ORDER BY CategoryGroup, ProductHierarchy
