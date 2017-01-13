CREATE   PROCEDURE rdh_ImportBOM

AS

DECLARE @uploadid int
DECLARE @lastheader varchar(18)
DECLARE @currentheader varchar(18)
DECLARE @counter int

SET @lastheader = '-1'
SET @counter = 1

DECLARE bom_cursor CURSOR LOCAL FOR
SELECT UploadID, Header FROM tblUploadBOM
WHERE IsHandled = 0
ORDER BY UploadID
FOR UPDATE OF BOMID

OPEN bom_cursor

FETCH NEXT FROM bom_cursor INTO @uploadid, @currentheader

WHILE @@FETCH_STATUS = 0
BEGIN
  IF @lastheader <> @currentheader
  BEGIN
    SET @counter = @counter + 1
    SET @lastheader = @currentheader
  END
  UPDATE tblUploadBOM SET BOMID = @counter
  WHERE CURRENT OF bom_cursor
  FETCH NEXT FROM bom_cursor INTO @uploadid, @currentheader
END


UPDATE
  tblUploadBOM
SET
  ShouldBePicked = 0

UPDATE
  tblUploadBOM
SET
  ShouldBePicked = 1
WHERE 
  IsHandled = 0 AND
EXISTS (
  SELECT Header, Max(BOMID) AS MaxBOMID 
  FROM tblUploadBOM AS a 
  WHERE tblUploadBOM.Header = a.Header AND
    IsHandled = 0
  GROUP BY a.Header
  HAVING tblUploadBOM.BOMID = Max(a.BOMID))

BEGIN TRANSACTION
DELETE
FROM
  tblBaseBOM
WHERE
  Header IN (
    SELECT Header
    FROM tblUploadBOM
    WHERE ShouldBePicked = 1)

INSERT INTO
  tblBaseBOM (Header, BOMUsage, BaseQuantity, BUOM, Plant, ValidFrom, Component, ItemQuantity, ItemUOM)
SELECT
  Header, BOMUsage, BaseQuantity, BUOM, Plant, ValidFrom, Component, ItemQuantity, ItemUOM
FROM
  tblUploadBOM
WHERE
  ShouldBePicked = 1 AND
  NOT EXISTS (SELECT * FROM tblBaseBOM WHERE tblUploadBOM.Header = tblBaseBOM.Header AND tblUploadBOM.Component = tblBaseBOM.Component)

UPDATE tblUploadBOM
SET IsHandled = 1
COMMIT TRANSACTION




