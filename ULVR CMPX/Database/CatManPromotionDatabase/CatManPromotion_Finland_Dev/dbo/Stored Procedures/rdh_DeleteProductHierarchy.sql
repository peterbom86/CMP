CREATE PROCEDURE rdh_DeleteProductHierarchy
  @HierarchyID int

AS

DELETE
FROM ProductHierarchies
WHERE FK_ProductHierarchyParentID = @HierarchyID

DELETE
FROM BaseDiscountsEdit
WHERE FK_ProductHierarchyID = @HierarchyID

DELETE
FROM ProductHierarchies
WHERE PK_ProductHierarchyID = @HierarchyID
