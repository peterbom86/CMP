CREATE PROCEDURE [dbo].[rdh_GrantExecToAll]

AS

DECLARE @name nvarchar(255)
DECLARE @xtype nvarchar(10)
DECLARE @sql nvarchar(1000)

DECLARE nameCursor CURSOR FOR
SELECT name, xtype
FROM sysobjects
WHERE xtype IN ('FN', 'TF', 'V', 'P', 'U') AND name NOT LIKE 'dt%' AND name NOT LIKE 'sys%'
AND name <>'PrimeAssortments' AND name <>'PrimePromotions' AND name<>'ProductCodes'
ORDER BY xtype, name

OPEN nameCursor

FETCH NEXT FROM nameCursor INTO @name, @xtype

WHILE @@FETCH_STATUS = 0
BEGIN
  IF @xtype = 'P' OR @xtype = 'FN'
  SET @sql = 'GRANT EXEC ON ' + @name + ' TO Public'
  ELSE
  SET @sql = 'GRANT SELECT ON ' + @name + ' TO Public'
  EXEC ( @sql )
  FETCH NEXT FROM nameCursor INTO @name, @xtype
END

CLOSE nameCursor
DEALLOCATE nameCursor


