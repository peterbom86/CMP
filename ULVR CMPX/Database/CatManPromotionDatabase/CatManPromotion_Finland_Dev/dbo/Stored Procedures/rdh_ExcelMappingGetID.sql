CREATE PROCEDURE [dbo].[rdh_ExcelMappingGetID]
  @ExcelMappingTableColumnID int,
  @ValueName nvarchar(255)

AS 

DECLARE @ValueID INT
DECLARE @ValueStatement NVARCHAR(MAX)

SELECT @ValueStatement = ValueStatement
FROM dbo.ExcelMappingTableColumn AS emtc
WHERE PK_ExcelMappingTableColumnID = @ExcelMappingTableColumnID

IF ( ISNULL(@ValueStatement, '') = '' ) 
BEGIN
	SET @ValueID = -1
END
ELSE
BEGIN
	CREATE TABLE #temp (ValueID INT)
	
	DECLARE @orderByPosition INT
	SET @orderByPosition = PATINDEX('%ORDER BY%', @ValueStatement)
	IF @orderByPosition > 0
		SET @ValueStatement = LEFT(@ValueStatement, PATINDEX('%ORDER BY%', @ValueStatement) - 1)
	SET @ValueStatement = 'INSERT INTO #temp SELECT ValueID FROM (' + @ValueStatement + ') SubQ WHERE ValueName = ''' + @ValueName + ''''
	EXEC(@ValueStatement)
	IF ( SELECT COUNT(*) FROM #temp AS t ) > 0
		SELECT @ValueID = ValueID FROM #temp AS t
	ELSE
		SET @ValueID = -1
	DROP TABLE #temp
END

RETURN @ValueID

