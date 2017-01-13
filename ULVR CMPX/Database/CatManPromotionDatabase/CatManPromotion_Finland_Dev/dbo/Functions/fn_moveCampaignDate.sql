
CREATE FUNCTION [dbo].[fn_moveCampaignDate]
(
    @DestinationYear INT,
    @CampaignYear INT,
    @date DATETIME
)
RETURNS DATETIME
AS
BEGIN
	Declare @Year INT;   

	SET @Year = CASE 
					WHEN DATEPART(YEAR, @date) = @CampaignYear THEN 
						@DestinationYear 
					ELSE 
						@DestinationYear + (DATEPART(YEAR, @date) - @CampaignYear) 
				END

	RETURN CASE
				WHEN DATEPART(ISO_WEEK, @date) = 53 THEN 
					dbo.fn_DateFromIsoYearWeekWeekday(@Year, DATEPART(ISO_WEEK, @date) - 1, DATEPART(WEEKDAY, @date))
				ELSE 
					dbo.fn_DateFromIsoYearWeekWeekday(@Year, DATEPART(ISO_WEEK, @date), DATEPART(WEEKDAY, @date)) 
			END
END