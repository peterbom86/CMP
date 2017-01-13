CREATE PROCEDURE rdh_CreateUploadHierarchy

AS

DECLARE @Level1Node varchar(10)
DECLARE @Level2Node varchar(10)
DECLARE @Level3Node varchar(10)
DECLARE @Level4Node varchar(10)
DECLARE @Level5Node varchar(10)
DECLARE @Level6Node varchar(10)
DECLARE @Level1Label varchar(40)
DECLARE @Level2Label varchar(40)
DECLARE @Level3Label varchar(40)
DECLARE @Level4Label varchar(40)
DECLARE @Level5Label varchar(40)
DECLARE @Level6Label varchar(40)

DECLARE @LastLevel1Node varchar(10)
DECLARE @LastLevel2Node varchar(10)
DECLARE @LastLevel3Node varchar(10)
DECLARE @LastLevel4Node varchar(10)
DECLARE @LastLevel5Node varchar(10)
DECLARE @LastLevel6Node varchar(10)
DECLARE @LastLevel1Label varchar(40)
DECLARE @LastLevel2Label varchar(40)
DECLARE @LastLevel3Label varchar(40)
DECLARE @LastLevel4Label varchar(40)
DECLARE @LastLevel5Label varchar(40)
DECLARE @LastLevel6Label varchar(40)

DELETE FROM tblUploadHierarchy
WHERE Level1Node IS Null AND Level2Node IS Null AND Level3Node IS Null AND
  Level4Node IS Null AND Level5Node IS Null AND Level6Node IS Null AND
  Level1Label IS Null AND Level2Label IS Null AND Level3Label IS Null AND
  Level4Label IS Null AND Level5Label IS Null AND Level6Label IS Null

DECLARE test CURSOR FOR 
SELECT Level1Node, Level2Node, Level3Node, Level4Node, Level5Node, Level6Node,
  Level1Label, Level2Label, Level3Label, Level4Label, Level5Label, Level6Label
FROM tblUploadHierarchy
FOR UPDATE

OPEN test

FETCH NEXT FROM test
INTO @Level1Node, @Level2Node, @Level3Node, @Level4Node, @Level5Node, @Level6Node, 
  @Level1Label, @Level2Label, @Level3Label, @Level4Label, @Level5Label, @Level6Label

WHILE @@FETCH_STATUS = 0
BEGIN
  IF @Level1Node IS NOT Null
    SET @LastLevel1Node = @Level1Node
 
  IF @Level2Node IS NOT Null AND @Level2Node <> '--'
    SET @LastLevel2Node = @Level2Node

  IF @Level3Node IS NOT Null AND @Level3Node <> '--'
    SET @LastLevel3Node = @Level3Node

  IF @Level4Node IS NOT Null AND @Level4Node <> '--'
    SET @LastLevel4Node = @Level4Node

  IF @Level5Node IS NOT Null AND @Level5Node <> '--'
    SET @LastLevel5Node = @Level5Node

  IF @Level6Node IS NOT Null AND @Level6Node <> '--'
    SET @LastLevel6Node = @Level6Node

  IF @Level1Label IS NOT Null AND @Level1Label <> '40'
    SET @LastLevel1Label = @Level1Label

  IF @Level1Label IS NOT Null AND @Level1Label <> '40'
    SET @LastLevel1Label = @Level1Label

  IF @Level2Label IS NOT Null AND @Level2Label <> '40'
    SET @LastLevel2Label = @Level2Label

  IF @Level3Label IS NOT Null AND @Level3Label <> '40'
    SET @LastLevel3Label = @Level3Label

  IF @Level4Label IS NOT Null AND @Level4Label <> '40'
    SET @LastLevel4Label = @Level4Label

  IF @Level5Label IS NOT Null AND @Level5Label <> '40'
    SET @LastLevel5Label = @Level5Label

  IF @Level6Label IS NOT Null AND @Level6Label <> '40'
    SET @LastLevel6Label = @Level6Label

  UPDATE tblUploadHierarchy
  SET Level1Node = @LastLevel1Node,
    Level2Node = @LastLevel2Node,
    Level3Node = @LastLevel3Node,
    Level4Node = @LastLevel4Node,
    Level5Node = @LastLevel5Node,
    Level6Node = @LastLevel6Node,
    Level1Label = @LastLevel1Label,
    Level2Label = @LastLevel2Label,
    Level3Label = @LastLevel3Label,
    Level4Label = @LastLevel4Label,
    Level5Label = @LastLevel5Label,
    Level6Label = @LastLevel6Label
  WHERE CURRENT OF test

  FETCH NEXT FROM test
  INTO @Level1Node, @Level2Node, @Level3Node, @Level4Node, @Level5Node, @Level6Node, 
    @Level1Label, @Level2Label, @Level3Label, @Level4Label, @Level5Label, @Level6Label
END

CLOSE test
DEALLOCATE test

DELETE FROM tblUploadHierarchy
WHERE Level6Node IS Null OR NOT EXISTS (
SELECT Min(UploadID) MinUploadID FROM tblUploadHierarchy UH
GROUP BY Level6Node
HAVING tblUploadHierarchy.UploadID = Min(UploadID))
