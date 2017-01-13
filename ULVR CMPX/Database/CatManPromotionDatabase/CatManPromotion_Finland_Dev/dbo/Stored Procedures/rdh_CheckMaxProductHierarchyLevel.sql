CREATE PROCEDURE rdh_CheckMaxProductHierarchyLevel
  @HierarchyID int

AS

SELECT
  CAST(CASE PK_ProductHierarchyLevelID
    WHEN MaxLevelID THEN 1
    ELSE 0
  END AS bit) IsMaxLevel
FROM ProductHierarchies
  INNER JOIN ProductHierarchyLevels PL1 ON FK_ProductHierarchyLevelID = PL1.PK_ProductHierarchyLevelID
  INNER JOIN (
    SELECT FK_ProductHierarchyNameID, MAX(PK_ProductHierarchyLevelID) MaxLevelID
    FROM ProductHierarchyLevels GROUP BY FK_ProductHierarchyNameID) MaxLevels ON PL1.FK_ProductHierarchyNameID = MaxLevels.FK_ProductHierarchyNameID
WHERE PK_ProductHierarchyID = @HierarchyID
