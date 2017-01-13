CREATE   PROCEDURE PoTestHierarchy
   @participatorid int

AS

DECLARE @level int
SET  @level = 1

CREATE TABLE #stack (child int, hierarchy int, item int, level int)

INSERT INTO #stack 
SELECT @participatorid, FK_CustomerHierarchyParentID, FK_CustomerHierarchyParentID, 1
FROM CustomerHierarchies
WHERE FK_ParticipatorID = @participatorid

WHILE (SELECT Count(*) FROM CustomerHierarchies INNER JOIN #stack ON PK_CustomerHierarchyID = item
WHERE level = @level) > 0
BEGIN
  SELECT @level = @level + 1

  INSERT INTO #stack
  SELECT PK_CustomerHierarchyID, hierarchy, FK_CustomerHierarchyParentID, level + 1
  FROM CustomerHierarchies INNER JOIN #stack ON PK_CustomerHierarchyID = item
  WHERE level = @level - 1
END

UPDATE #stack
  SET level = (SELECT Max(level) FROM #stack a WHERE #stack.hierarchy = a.hierarchy) - level

SELECT CN.Label, CL.Node LevelNode, CL.Label LevelLabel, CH.Node HierarchyNode, CH.Label HierarchyLabel, level, item, child 
FROM #stack
  INNER JOIN CustomerHierarchies CH ON item = PK_CustomerHierarchyID
  INNER JOIN CustomerHierarchyLevels CL ON PK_CustomerHierarchyLevelID = FK_CustomerHierarchyLevelID
  INNER JOIN CustomerHierarchyNames CN ON PK_CustomerHierarchyNameID = FK_CustomerHierarchyNameID
UNION ALL
SELECT CN.Label, '' LevelNode, CN.Label LevelLabel, '' HierarchyNode, '' HierarchyLavel, 0, -FK_CustomerHierarchyNameID, item
FROM #stack
  INNER JOIN CustomerHierarchies ON item = PK_CustomerHierarchyID
  INNER JOIN CustomerHierarchyLevels CL ON PK_CustomerHierarchyLevelID = FK_CustomerHierarchyLevelID
  INNER JOIN CustomerHierarchyNames CN ON PK_CustomerHierarchyNameID = FK_CustomerHierarchyNameID
WHERE level = 1
ORDER BY CN.Label, level

DROP TABLE #stack



