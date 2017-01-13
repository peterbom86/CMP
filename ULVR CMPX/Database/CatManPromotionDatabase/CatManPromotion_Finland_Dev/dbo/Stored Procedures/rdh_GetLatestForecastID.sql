CREATE PROCEDURE rdh_GetLatestForecastID

AS

DECLARE @CurrentLogisticForecastID int
DECLARE @PreviousLogisticForecastID int

SELECT TOP 1 @CurrentLogisticForecastID = PK_LogisticForecastID FROM LogisticForecast ORDER BY PeriodFrom DESC
SELECT TOP 1 @PreviousLogisticForecastID = PK_LogisticForecastID FROM LogisticForecast WHERE PK_LogisticForecastID <> @CurrentLogisticForecastID ORDER BY PeriodFrom DESC

SELECT @CurrentLogisticForecastID CurrentLogisticForecastID, @PreviousLogisticForecastID PreviousLogisticForecastID
