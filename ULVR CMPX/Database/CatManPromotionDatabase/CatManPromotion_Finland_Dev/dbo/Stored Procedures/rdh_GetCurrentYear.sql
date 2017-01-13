CREATE PROCEDURE [dbo].[rdh_GetCurrentYear]

AS

SELECT PeriodYear
FROM Periods
WHERE Label = CAST(FLOOR(CAST(GETDATE() AS float)) AS datetime)
