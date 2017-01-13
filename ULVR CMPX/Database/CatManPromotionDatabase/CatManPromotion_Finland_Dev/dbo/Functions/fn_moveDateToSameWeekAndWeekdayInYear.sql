
CREATE FUNCTION [dbo].[fn_moveDateToSameWeekAndWeekdayInYear]
(
    @Year INT,
    @date DATETIME
)
RETURNS DATETIME
AS
BEGIN
	RETURN CASE
				WHEN DATEPART(ISO_WEEK, @date) = 53 THEN 
					dbo.fn_DateFromIsoYearWeekWeekday(@Year, DATEPART(ISO_WEEK, @date) - 1, DATEPART(WEEKDAY, @date))
				ELSE 
					dbo.fn_DateFromIsoYearWeekWeekday(@Year, DATEPART(ISO_WEEK, @date), DATEPART(WEEKDAY, @date)) 
            END
END