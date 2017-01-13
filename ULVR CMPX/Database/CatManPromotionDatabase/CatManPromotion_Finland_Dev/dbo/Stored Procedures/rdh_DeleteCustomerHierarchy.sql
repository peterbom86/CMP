CREATE PROCEDURE rdh_DeleteCustomerHierarchy
  @HierarchyID int

AS

DELETE
FROM CustomerHierarchies
WHERE FK_CustomerHierarchyParentID = @HierarchyID

DELETE
FROM BaseDiscountsEdit
WHERE FK_CustomerHierarchyID = @HierarchyID

DELETE
FROM CustomerHierarchies
WHERE PK_CustomerHierarchyID = @HierarchyID
