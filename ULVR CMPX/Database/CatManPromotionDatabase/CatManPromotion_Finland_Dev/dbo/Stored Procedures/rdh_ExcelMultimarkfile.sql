CREATE PROCEDURE [dbo].[rdh_ExcelMultimarkfile]

AS

DECLARE @Path NVARCHAR(255)
SET @Path = 'E:\Data\Multimark\Export\Archive\'
EXEC rdh_ExcelGetFiles @Path

