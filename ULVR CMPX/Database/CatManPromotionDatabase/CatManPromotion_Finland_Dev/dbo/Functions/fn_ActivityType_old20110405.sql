CREATE Function [dbo].[fn_ActivityType_old20110405] (@TypeID int)
Returns varchar(100)

AS

BEGIN

DECLARE @temp varchar(4000)
DECLARE @activitytype varchar(40)
SET @temp = ''

DECLARE Types CURSOR FOR 
  SELECT Label FROM ActivityTypes
  WHERE ( Value & @TypeID ) <> 0

OPEN Types

  FETCH NEXT FROM Types INTO @activitytype
  
  WHILE (@@fetch_status <> -1)
  
  BEGIN
            IF (@@fetch_status <> -2)
            BEGIN
               SET @temp = @temp + @activitytype +'|'
            END
            FETCH NEXT FROM Types INTO @activitytype
  END

CLOSE Types
DEALLOCATE Types

if Len(@temp)>0 set @temp=LEFT(@temp,LEN(@temp)-1)

Return  @temp

END 
