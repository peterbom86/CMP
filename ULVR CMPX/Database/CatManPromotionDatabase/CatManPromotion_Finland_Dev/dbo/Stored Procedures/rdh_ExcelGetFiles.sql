CREATE PROCEDURE [dbo].[rdh_ExcelGetFiles]
  @Path NVARCHAR(255)

AS

DECLARE @Command NVARCHAR(255)
SET @Command = 'DIR ' + @Path
DECLARE @Return int
CREATE TABLE #DBAZ (Name varchar(400), Work int IDENTITY(1,1))
INSERT #DBAZ EXECUTE @Return = master.dbo.xp_cmdshell @Command

DELETE 
FROM #DBAZ 
WHERE LEN(RTRIM(LTRIM(SUBSTRING(Name,1,10)))) <> 10 OR
	SUBSTRING(Name,37,1) = '.' OR Name IS NULL OR
	SUBSTRING(Name,22,5) = '<DIR>'

SELECT @Path + SUBSTRING(Name,37,100) Path, 
	SUBSTRING(Name,37,100) AS MyFile, 
	CONVERT(Datetime, SUBSTRING(Name, 1, 10), 105) + CONVERT(Datetime, SUBSTRING(Name, 13, 5), 108) AS Date,
	CAST(REPLACE(REPLACE(SUBSTRING(NAME, 19, 17), ' ', ''), '.', '') AS Bigint) Size, 'GetFile' Action
FROM #DBAZ AS d

DROP TABLE #DBAZ

