CREATE  Function fn_Activities (@CampaignID int)
Returns varchar(1000)

AS

BEGIN

DECLARE @temp varchar(4000)
DECLARE @activity varchar(150)
SET @temp = ''

DECLARE Activities CURSOR FOR 
  SELECT Label FROM Activities
  WHERE FK_CampaignID=@CampaignID

OPEN Activities

  FETCH NEXT FROM Activities INTO @activity
  
  WHILE (@@fetch_status <> -1)
  
  BEGIN
            IF (@@fetch_status <> -2)
            BEGIN
               SET @temp = @temp + @activity +'|'
            END
            FETCH NEXT FROM Activities INTO @activity
  END

CLOSE Activities
DEALLOCATE Activities

if Len(@temp)>0 set @temp=LEFT(@temp,LEN(@temp)-1)

Return  @temp

END 



