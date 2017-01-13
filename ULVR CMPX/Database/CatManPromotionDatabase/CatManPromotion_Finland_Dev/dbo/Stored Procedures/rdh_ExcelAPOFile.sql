CREATE PROCEDURE [dbo].[rdh_ExcelAPOFile]

AS

DECLARE @Path NVARCHAR(255)
SELECT @Path = DownloadPath FROM dbo.APOConfiguration
EXEC rdh_ExcelGetFiles @Path
