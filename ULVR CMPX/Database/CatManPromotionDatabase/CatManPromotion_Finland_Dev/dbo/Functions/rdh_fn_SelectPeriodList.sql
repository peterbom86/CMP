CREATE FUNCTION rdh_fn_SelectPeriodList( 
  @StartWeek int,
  @NumberOfWeeks int)
RETURNS @PeriodList Table (Period int)

AS

BEGIN
DECLARE @FirstMonday datetime

SELECT @FirstMonday = MIN(Label) 
FROM Periods
WHERE Period = @StartWeek

Insert into @PeriodList 
SELECT DISTINCT Period
FROM Periods
WHERE Label BETWEEN @FirstMonday AND @FirstMonday + (@NumberOfWeeks - 1) * 7
ORDER BY Period
RETURN
END

