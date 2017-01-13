CREATE  PROCEDURE rdh_ExpandedHierarchy( @RootNodeID INT ) AS
SELECT
  ProductHierarchies.PK_ProductHierarchyID, ProductHierarchies.Label AS Hierarchy, ProductHierarchyDetails.FK_ProductID, Products.Label
FROM    
  ProductHierarchyDetails INNER JOIN
        ProductHierarchies ON ProductHierarchyDetails.FK_ProductHierarchyParentID = ProductHierarchies.PK_ProductHierarchyID INNER JOIN
  Products ON Products.PK_ProductID = ProductHierarchyDetails.FK_ProductID  
WHERE     (ProductHierarchyDetails.FK_ProductHierarchyParentID = @RootNodeID)



