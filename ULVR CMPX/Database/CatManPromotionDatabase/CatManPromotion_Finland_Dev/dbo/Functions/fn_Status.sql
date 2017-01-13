CREATE   Function fn_Status (@CampaignID int)
Returns varchar(1000)

AS

BEGIN

DECLARE @temp varchar(4000)
DECLARE @status varchar(150)
SET @temp = ''

DECLARE Status CURSOR FOR 
  SELECT DISTINCT ActivityStatus.Label FROM Activities INNER JOIN
  ActivityStatus ON PK_ActivityStatusID=FK_ActivityStatusID
  WHERE FK_CampaignID=@CampaignID

OPEN Status

  FETCH NEXT FROM Status INTO @status
  
  WHILE (@@fetch_status <> -1)
  
  BEGIN
            IF (@@fetch_status <> -2)
            BEGIN
               SET @temp = @temp + @status +'|'
            END
            FETCH NEXT FROM Status INTO @status
  END

CLOSE Status
DEALLOCATE Status

if Len(@temp)>0 set @temp=LEFT(@temp,LEN(@temp)-1)

Return  @temp

END 




