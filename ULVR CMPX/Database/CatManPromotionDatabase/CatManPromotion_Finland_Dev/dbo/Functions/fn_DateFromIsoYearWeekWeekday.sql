
CREATE FUNCTION [dbo].[fn_DateFromIsoYearWeekWeekday]
(
    @isoYear INT,
    @isoWeek INT,
    @isoWeekday INT
)
RETURNS DATETIME
AS
BEGIN
	-- ISO-WEEK 1 always contains 4th Jan, so let's use this as a base
	DECLARE @BaseDate datetime = cast(cast(@isoYear as varchar(4)) + '-01-04T12:00:00' as datetime)

	DECLARE @resultDate DATETIME;
	-- Base date weekday offset - Special handling for Sunday
	DECLARE @offset INT = CASE datepart(WEEKDAY, @BaseDate) 
								WHEN 1 THEN -- Sunday
									7 -- Offset Sunday to day 7 instead of day 1.
								ELSE 
									datepart(WEEKDAY, @BaseDate) - 1 
							END

	-- Destination week day offset - Special handling for Sunday
	SET @offset = CASE @isoWeekday 
						WHEN 1 THEN -- Sunday
							7 - @offset 
						ELSE 
							(@isoWeekday - 1) - @offset
					END

	--Adjust to correct week
	SET @resultDate = DATEADD(WEEK, @isoWeek - 1, @BaseDate);
	
	-- Adjust to correct week day
	SET @resultDate = DATEADD(DAY, @offset, @resultDate);

	RETURN @resultDate
END