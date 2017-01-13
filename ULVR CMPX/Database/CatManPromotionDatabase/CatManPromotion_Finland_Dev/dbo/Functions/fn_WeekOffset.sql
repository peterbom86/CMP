CREATE FUNCTION fn_WeekOffset
  (@FirstDay datetime,
  @SecondDay datetime)
  RETURNS int

AS

BEGIN
DECLARE @FirstDayConv int
DECLARE @SecondDayConv int

SET @FirstDayConv = DATEPART(dw, @FirstDay) - 2
SET @SecondDayConv = DATEPART(dw, @SecondDay) - 2

IF @FirstDayConv = -1 SET @FirstDayConv = 6
IF @SecondDayConv = -1 SET @SecondDayConv = 6

SET @FirstDay = DATEADD( d, -@FirstDayConv, @FirstDay )
SET @SecondDay = DATEADD( d, -@SecondDayConv, @SecondDay )

RETURN DATEDIFF( d, @FirstDay, @SecondDay ) / 7
END


