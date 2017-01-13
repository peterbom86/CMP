CREATE    Function fn_Purpose (@CampaignID int)
Returns varchar(1000)

AS

BEGIN

DECLARE @temp varchar(4000)
DECLARE @purpose varchar(150)
SET @temp = ''

DECLARE Purpose CURSOR FOR 
  SELECT DISTINCT ActivityPurposes.Label FROM Activities INNER JOIN
  ActivityPurposes ON PK_ActivityPurposeID=FK_ActivityPurposeID
  WHERE FK_CampaignID=@CampaignID

OPEN Purpose

  FETCH NEXT FROM Purpose INTO @purpose
  
  WHILE (@@fetch_status <> -1)
  
  BEGIN
            IF (@@fetch_status <> -2)
            BEGIN
               SET @temp = @temp + @purpose +'|'
            END
            FETCH NEXT FROM Purpose INTO @purpose
  END

CLOSE Purpose
DEALLOCATE Purpose

if Len(@temp)>0 set @temp=LEFT(@temp,LEN(@temp)-1)

Return  @temp

END 






