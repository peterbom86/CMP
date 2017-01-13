CREATE PROCEDURE [dbo].rdh_ExcelBaselineFile

AS
DECLARE @Path NVARCHAR(255)
SET @Path = 'E:\Data\APO\Import\Archive\'

EXEC rdh_ExcelGetFiles @Path
