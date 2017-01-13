CREATE FUNCTION  rdh_fn_GetCompleteHierarchy ()
RETURNS @HierarchyTable TABLE ( PK_TempHierarchyID int IDENTITY(1, 1) PRIMARY KEY,
  Level int,
  CustomerHierarchyID int,
  DynamicCustomerHierarchyID int, 
  ParticipatorID int )

AS

BEGIN

DECLARE @Level int
SET @Level = 1

/*
CREATE TABLE #tempHierarchy (
  PK_TempHierarchyID int IDENTITY(1, 1) PRIMARY KEY,
  Level int,
  CustomerHierarchyID int,
  DynamicCustomerHierarchyID int, 
  ParticipatorID int )
*/

INSERT INTO @HierarchyTable ( Level, CustomerHierarchyID, DynamicCustomerHierarchyID, ParticipatorID )
SELECT @Level Level, PK_CustomerHierarchyID, PK_CustomerHierarchyID, FK_ParticipatorID
FROM CustomerHierarchies
WHERE FK_ParticipatorID IS Null

WHILE (
  SELECT COUNT(*) FROM @HierarchyTable TH 
    INNER JOIN CustomerHierarchies CH ON TH.DynamicCustomerHierarchyID = CH.FK_CustomerHierarchyParentID
  WHERE ParticipatorID IS Null) > 0
BEGIN
  SET @Level = @Level + 1

  INSERT INTO @HierarchyTable ( Level, CustomerHierarchyID, DynamicCustomerHierarchyID, ParticipatorID )
  SELECT @Level Level, TH.CustomerHierarchyID, CH.PK_CustomerHierarchyID, CH.FK_ParticipatorID
  FROM @HierarchyTable TH
    INNER JOIN CustomerHierarchies CH ON TH.DynamicCustomerHierarchyID = CH.FK_CustomerHierarchyParentID
  WHERE TH.ParticipatorID IS Null

  DELETE FROM @HierarchyTable
  WHERE Level = @Level - 1 AND ParticipatorID IS Null

END

/*SELECT * 
FROM #tempHierarchy TH
ORDER BY ParticipatorID, Level DESC

DROP TABLE #tempHierarchy
*/

RETURN 

END

