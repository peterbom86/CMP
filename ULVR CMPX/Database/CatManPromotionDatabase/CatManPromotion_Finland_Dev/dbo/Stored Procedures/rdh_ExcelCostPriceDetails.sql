CREATE PROCEDURE [dbo].[rdh_ExcelCostPriceDetails]
 @CostPriceHeaderID int

AS

SELECT @CostPriceHeaderID CostPriceHeaderID, CategoryGroup, ProductHierarchy, ProductCode, ProductName, PK_CommonCodeID CommonCodeID, CommonCode, ISNULL(Value, 0) Value
FROM (
	SELECT CG.Label CategoryGroup, PH2.Label ProductHierarchy, ProductCode, p.Label ProductName, 
	  PK_CommonCodeID, CommonCode
	FROM dbo.CommonCodes AS cc
	  INNER JOIN dbo.Products AS p ON cc.FK_ProductID = p.PK_ProductID
	  INNER JOIN dbo.ProductStatus AS ps ON p.FK_ProductStatusID = ps.PK_ProductStatusID
	  INNER JOIN dbo.ProductHierarchies AS ph ON p.PK_ProductID = ph.FK_ProductID
	  INNER JOIN dbo.ProductHierarchies AS ph2 ON ph.FK_ProductHierarchyParentID = ph2.PK_ProductHierarchyID
	  INNER JOIN dbo.ProductHierarchyLevels AS phl ON ph2.FK_ProductHierarchyLevelID = phl.PK_ProductHierarchyLevelID
	  INNER JOIN dbo.ProductHierarchyNames AS phn ON phl.FK_ProductHierarchyNameID = phn.PK_ProductHierarchyNameID
	  INNER JOIN CategoryGroups CG ON PK_CategoryGroupID = ph2.FK_CategoryGroupID
	WHERE IsHidden = 0 AND IsForecastingUnit = 1) Products
    LEFT JOIN CostPriceDetails ON PK_CommonCodeID = FK_CommonCodeID AND FK_CostPriceHeaderID = @CostPriceHeaderID
ORDER BY CategoryGroup, ProductHierarchy, ProductName


