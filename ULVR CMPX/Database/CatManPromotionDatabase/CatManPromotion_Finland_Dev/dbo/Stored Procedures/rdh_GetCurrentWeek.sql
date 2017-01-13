CREATE PROCEDURE rdh_GetCurrentWeek

AS

SELECT Period
FROM Periods
WHERE Label = CAST(FLOOR(CAST(GETDATE() AS float)) AS datetime)
