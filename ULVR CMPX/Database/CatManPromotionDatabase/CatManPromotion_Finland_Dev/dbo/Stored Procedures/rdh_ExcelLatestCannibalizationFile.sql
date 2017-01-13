CREATE PROCEDURE [dbo].[rdh_ExcelLatestCannibalizationFile] --'E:\Data\APO\Export\', 'test'--, ''
 ( @Path NVARCHAR(255),
  @Filename nvarchar(255),
  @LatestFilename nvarchar(255) output)

AS

DECLARE @Command NVARCHAR(255)
SET @Command = 'DIR ' + @Path
DECLARE @Return int
CREATE TABLE #DBAZ (Name varchar(400), Work int IDENTITY(1,1))
INSERT #DBAZ EXECUTE @Return = master.dbo.xp_cmdshell @Command

DELETE 
FROM #DBAZ 
WHERE LEN(RTRIM(LTRIM(SUBSTRING(Name,1,10)))) <> 10 OR
	SUBSTRING(Name,37,1) = '.' OR Name IS NULL OR Name LIKE '%<DIR>%'

SELECT TOP 1 @Path + SUBSTRING(Name,37,100)
FROM #DBAZ
WHERE SUBSTRING(Name, 37, 100) LIKE '%' + @Filename + '%'
ORDER BY CONVERT(Datetime, SUBSTRING(Name, 1, 10), 105) + CONVERT(Datetime, SUBSTRING(Name, 13, 5), 108) DESC

SELECT TOP 1 @LatestFilename = CAST(@Path + SUBSTRING(Name,37,100) as nvarchar(255))
FROM #DBAZ
WHERE SUBSTRING(Name, 37, 100) LIKE '%' + @Filename + '%'
ORDER BY CONVERT(Datetime, SUBSTRING(Name, 1, 10), 105) + CONVERT(Datetime, SUBSTRING(Name, 13, 5), 108) DESC

DROP TABLE #DBAZ

SELECT @LatestFilename
RETURN
