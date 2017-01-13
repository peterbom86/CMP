CREATE PROCEDURE CreateSP 
  @SPName varchar(255)

AS

DECLARE @sp varchar(4000)
DECLARE @sql1 varchar(4000)
DECLARE @sql2 varchar(4000)
DECLARE @sql3 varchar(4000)
DECLARE @sql4 varchar(4000)
DECLARE @sql5 varchar(4000)
DECLARE @sql6 varchar(4000)
DECLARE @sql7 varchar(4000)
DECLARE @sql8 varchar(4000)

SET @sql1 = ''
SET @sql2 = ''
SET @sql3 = ''
SET @sql4 = ''
SET @sql5 = ''
SET @sql6 = ''
SET @sql7 = ''
SET @sql8 = ''

DECLARE StoredProcedure_Cursor CURSOR FOR 
SELECT StoredProcedureLine
FROM DatabaseSammenligning.dbo.tblStoredProcedureLines
  INNER JOIN DatabaseSammenligning.dbo.tblStoredProcedures ON PK_StoredProcedureID = FK_StoredProcedureID
WHERE StoredProcedure = @SPName AND FK_DatabaseID = 2
ORDER BY FK_StoredProcedureID, ColOrder

OPEN StoredProcedure_Cursor

FETCH NEXT FROM StoredProcedure_Cursor INTO @sp

WHILE @@FETCH_STATUS = 0
BEGIN
  IF LEN(@sql1) + LEN(@sp) > 3990 OR LEN(@sql2) > 0
    IF LEN(@sql2) + LEN(@sp) > 3990 OR LEN(@sql3) > 0
      IF LEN(@sql3) + LEN(@sp) > 3990 OR LEN(@sql4) > 0
        IF LEN(@sql4) + LEN(@sp) > 3990 OR LEN(@sql5) > 0
          IF LEN(@sql5) + LEN(@sp) > 3990 OR LEN(@sql6) > 0
            IF LEN(@sql6) + LEN(@sp) > 3990 OR LEN(@sql7) > 0
              IF LEN(@sql7) + LEN(@sp) > 3990 OR LEN(@sql8) > 0
                SET @sql8 = @sql8 + CHAR(13) + CHAR(10) + @sp
              ELSE
                SET @sql7 = @sql7 + CHAR(13) + CHAR(10) + @sp
            ELSE
              SET @sql6 = @sql6 + CHAR(13) + CHAR(10) + @sp
          ELSE
            SET @sql5 = @sql5 + CHAR(13) + CHAR(10) + @sp
        ELSE
          SET @sql4 = @sql4 + CHAR(13) + CHAR(10) + @sp
      ELSE
        SET @sql3 = @sql3 + CHAR(13) + CHAR(10) + @sp
    ELSE
      SET @sql2 = @sql2 + CHAR(13) + CHAR(10) + @sp
  ELSE
    BEGIN
      IF LEN(@sql1) > 0 
        SET @sql1 = @sql1 + CHAR(13) + CHAR(10) 
      SET @sql1 = @sql1 + @sp
    END

  FETCH NEXT FROM StoredProcedure_Cursor INTO @sp
END

CLOSE StoredProcedure_Cursor
DEALLOCATE StoredProcedure_Cursor

EXEC ( @sql1 + @sql2 + @sql3 + @sql4 + @sql5 + @sql6 + @sql7 + @sql8 )

