CREATE    function fn_IsoWeekStr(@date datetime, @WeekName nvarchar(10) = 'Uge')
Returns nvarchar(11)

AS
begin

declare @isoWeek int
declare @isoYear int
declare @string nvarchar (12)
--declare @period int

set @isoWeek = 

CASE
 -- Exception where @date is part of week 52 (or 53) of the previous year
  WHEN @date < CASE (DATEPART(dw, CAST(YEAR(@date) AS CHAR(4)) + '-01-04') + @@DATEFIRST - 1) % 7
    WHEN 1 THEN CAST(YEAR(@date) AS CHAR(4)) + '-01-04'
    WHEN 2 THEN DATEADD(d, -1, CAST(YEAR(@date) AS CHAR(4)) + '-01-04')
    WHEN 3 THEN DATEADD(d, -2, CAST(YEAR(@date) AS CHAR(4)) + '-01-04')
    WHEN 4 THEN DATEADD(d, -3, CAST(YEAR(@date) AS CHAR(4)) + '-01-04')
    WHEN 5 THEN DATEADD(d, -4, CAST(YEAR(@date) AS CHAR(4)) + '-01-04')
    WHEN 6 THEN DATEADD(d, -5, CAST(YEAR(@date) AS CHAR(4)) + '-01-04')
    ELSE DATEADD(d, -6, CAST(YEAR(@date) AS CHAR(4)) + '-01-04')
    END
   THEN
    (DATEDIFF(d,CASE (DATEPART(dw, CAST(YEAR(@date) - 1 AS CHAR(4)) + '-01-04') + @@DATEFIRST - 1) % 7
    WHEN 1 THEN CAST(YEAR(@date) - 1 AS CHAR(4)) + '-01-04'
    WHEN 2 THEN DATEADD(d, -1, CAST(YEAR(@date) - 1 AS CHAR(4)) + '-01-04')
    WHEN 3 THEN DATEADD(d, -2, CAST(YEAR(@date) - 1 AS CHAR(4)) + '-01-04')
    WHEN 4 THEN DATEADD(d, -3, CAST(YEAR(@date) - 1 AS CHAR(4)) + '-01-04')
    WHEN 5 THEN DATEADD(d, -4, CAST(YEAR(@date) - 1 AS CHAR(4)) + '-01-04')
    WHEN 6 THEN DATEADD(d, -5, CAST(YEAR(@date) - 1 AS CHAR(4)) + '-01-04')
    ELSE DATEADD(d, -6, CAST(YEAR(@date) - 1 AS CHAR(4)) + '-01-04')
    END, @date) / 7) + 1

 -- Exception where @date is part of week 1 of the following year
  WHEN @date >= CASE (DATEPART(dw, CAST(YEAR(@date) + 1 AS CHAR(4)) + '-01-04') + @@DATEFIRST - 1) % 7
    WHEN 1 THEN CAST(YEAR(@date) + 1 AS CHAR(4)) + '-01-04'
    WHEN 2 THEN DATEADD(d, -1, CAST(YEAR(@date) + 1 AS CHAR(4)) + '-01-04')
    WHEN 3 THEN DATEADD(d, -2, CAST(YEAR(@date) + 1 AS CHAR(4)) + '-01-04')
    WHEN 4 THEN DATEADD(d, -3, CAST(YEAR(@date) + 1 AS CHAR(4)) + '-01-04')
    WHEN 5 THEN DATEADD(d, -4, CAST(YEAR(@date) + 1 AS CHAR(4)) + '-01-04')
    WHEN 6 THEN DATEADD(d, -5, CAST(YEAR(@date) + 1 AS CHAR(4)) + '-01-04')
    ELSE DATEADD(d, -6, CAST(YEAR(@date) + 1 AS CHAR(4)) + '-01-04')
    END
  THEN 1

 ELSE
  -- Calculate the ISO week number for all dates that are not part of the exceptions above
    (DATEDIFF(d,
    CASE (DATEPART(dw, CAST(YEAR(@date) AS CHAR(4)) + '-01-04') + @@DATEFIRST - 1) % 7
    WHEN 1 THEN CAST(YEAR(@date) AS CHAR(4)) + '-01-04'
    WHEN 2 THEN DATEADD(d, -1, CAST(YEAR(@date) AS CHAR(4)) + '-01-04')
    WHEN 3 THEN DATEADD(d, -2, CAST(YEAR(@date) AS CHAR(4)) + '-01-04')
    WHEN 4 THEN DATEADD(d, -3, CAST(YEAR(@date) AS CHAR(4)) + '-01-04')
    WHEN 5 THEN DATEADD(d, -4, CAST(YEAR(@date) AS CHAR(4)) + '-01-04')
    WHEN 6 THEN DATEADD(d, -5, CAST(YEAR(@date) AS CHAR(4)) + '-01-04')
    ELSE DATEADD(d, -6, CAST(YEAR(@date) AS CHAR(4)) + '-01-04')
    END,@date) / 7) + 1
END


set @IsoYear = 

CASE
 -- Exception where @date is part of week 52 (or 53) of the previous year
  WHEN @date < CASE (DATEPART(dw, CAST(YEAR(@date) AS CHAR(4)) + '-01-04') + @@DATEFIRST - 1) % 7
    WHEN 1 THEN CAST(YEAR(@date) AS CHAR(4)) + '-01-04'
    WHEN 2 THEN DATEADD(d, -1, CAST(YEAR(@date) AS CHAR(4)) + '-01-04')
    WHEN 3 THEN DATEADD(d, -2, CAST(YEAR(@date) AS CHAR(4)) + '-01-04')
    WHEN 4 THEN DATEADD(d, -3, CAST(YEAR(@date) AS CHAR(4)) + '-01-04')
    WHEN 5 THEN DATEADD(d, -4, CAST(YEAR(@date) AS CHAR(4)) + '-01-04')
    WHEN 6 THEN DATEADD(d, -5, CAST(YEAR(@date) AS CHAR(4)) + '-01-04')
    ELSE DATEADD(d, -6, CAST(YEAR(@date) AS CHAR(4)) + '-01-04')
    END
   THEN
    Year(@Date)-1

 -- Exception where @date is part of week 1 of the following year
  WHEN @date >= CASE (DATEPART(dw, CAST(YEAR(@date) + 1 AS CHAR(4)) + '-01-04') + @@DATEFIRST - 1) % 7
    WHEN 1 THEN CAST(YEAR(@date) + 1 AS CHAR(4)) + '-01-04'
    WHEN 2 THEN DATEADD(d, -1, CAST(YEAR(@date) + 1 AS CHAR(4)) + '-01-04')
    WHEN 3 THEN DATEADD(d, -2, CAST(YEAR(@date) + 1 AS CHAR(4)) + '-01-04')
    WHEN 4 THEN DATEADD(d, -3, CAST(YEAR(@date) + 1 AS CHAR(4)) + '-01-04')
    WHEN 5 THEN DATEADD(d, -4, CAST(YEAR(@date) + 1 AS CHAR(4)) + '-01-04')
    WHEN 6 THEN DATEADD(d, -5, CAST(YEAR(@date) + 1 AS CHAR(4)) + '-01-04')
    ELSE DATEADD(d, -6, CAST(YEAR(@date) + 1 AS CHAR(4)) + '-01-04')
    END
  THEN Year(@Date)+1

 ELSE
  -- Calculate the ISO week number for all dates that are not part of the exceptions above
  Year(@Date)
END


If @isoWeek<10 set @string=CAST(@IsoYear AS nvarchar) + ' ' + @WeekName + ' 0' + CAST(@isoweek as nvarchar)
If @isoWeek>=10 set @string=CAST(@IsoYear AS nvarchar) + ' '+ @WeekName + ' ' + CAST(@isoweek as nvarchar)

--set @period=CAST(@string AS int)

return(@string)

end









