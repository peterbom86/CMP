CREATE procedure rdh_CreatePeriods


AS

Declare @intCounter int
Declare @date datetime

set @date='2000-01-01'
set @intCounter=0

WHILE @intCounter<4000


BEGIN

  INSERT INTO Periods(Label, PeriodWeek, PeriodYear,Period) VALUES
  (@date,dbo.fn_IsoWeekOnly(@date),dbo.fn_IsoYear(@date),dbo.fn_IsoWeek(@date))

  set @date=@date+1
  set @intCounter=@intCounter+1

END




