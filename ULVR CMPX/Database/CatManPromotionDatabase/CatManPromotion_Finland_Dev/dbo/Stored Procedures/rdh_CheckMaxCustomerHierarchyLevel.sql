CREATE PROCEDURE rdh_CheckMaxCustomerHierarchyLevel
  @HierarchyID int

AS

SELECT
  CAST(CASE PK_CustomerHierarchyLevelID
    WHEN MaxLevelID THEN 1
    ELSE 0
  END AS bit) IsMaxLevel
FROM CustomerHierarchies
  INNER JOIN CustomerHierarchyLevels CL1 ON FK_CustomerHierarchyLevelID = CL1.PK_CustomerHierarchyLevelID
  INNER JOIN (
    SELECT FK_CustomerHierarchyNameID, MAX(PK_CustomerHierarchyLevelID) MaxLevelID
    FROM CustomerHierarchyLevels GROUP BY FK_CustomerHierarchyNameID) MaxLevels ON CL1.FK_CustomerHierarchyNameID = MaxLevels.FK_CustomerHierarchyNameID
WHERE PK_CustomerHierarchyID = @HierarchyID
