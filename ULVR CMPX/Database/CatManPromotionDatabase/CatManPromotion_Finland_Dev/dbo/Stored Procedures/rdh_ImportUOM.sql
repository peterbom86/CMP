CREATE   PROCEDURE rdh_ImportUOM

AS

DECLARE @uploadid int
DECLARE @lastcommon varchar(18)
DECLARE @currentcommon varchar(18)
DECLARE @counter int

SET @lastcommon = '-1'
SET @counter = 1

DECLARE uom_cursor CURSOR LOCAL FOR
SELECT UploadID, Common FROM tblUploadUOM 
WHERE IsHandled = 0
ORDER BY UploadID
FOR UPDATE OF UOMID

OPEN uom_cursor

FETCH NEXT FROM uom_cursor INTO @uploadid, @currentcommon

WHILE @@FETCH_STATUS = 0
BEGIN
  IF @lastcommon <> @currentcommon
  BEGIN
    SET @counter = @counter + 1
    SET @lastcommon = @currentcommon
  END
  UPDATE tblUploadUOM SET UOMID = @counter
  WHERE CURRENT OF uom_cursor
  FETCH NEXT FROM uom_cursor INTO @uploadid, @currentcommon
END


UPDATE
  tblUploadUOM
SET
  ShouldBePicked = 0

UPDATE
  tblUploadUOM
SET
  ShouldBePicked = 1
WHERE
  IsHandled = 0 AND
 EXISTS (
  SELECT Common, Max(UOMID) AS MaxUOMID 
  FROM tblUploadUOM AS a 
  WHERE tblUploadUOM.Common = a.Common AND
    IsHandled = 0
  GROUP BY a.Common 
  HAVING tblUploadUOM.UOMID = Max(a.UOMID))

BEGIN TRANSACTION
DELETE
FROM tblBaseUOM
WHERE
  Common IN (
    SELECT Common
    FROM tblUploadUOM
    WHERE ShouldBePicked = 1)

INSERT INTO
  tblBaseUOM (Common, UOM, Num, Denom, BUOM)
SELECT
  Common, UOM, Num, Denom, BUOM
FROM
  tblUploadUOM
WHERE
  ShouldBePicked = 1 AND
  NOT EXISTS (SELECT * FROM tblBaseUOM WHERE tblUploadUOM.Common = tblBaseUOM.Common AND tblUploadUOM.UOM = tblBaseUOM.UOM)

UPDATE tblUploadUOM
SET IsHandled = 1

COMMIT TRANSACTION




