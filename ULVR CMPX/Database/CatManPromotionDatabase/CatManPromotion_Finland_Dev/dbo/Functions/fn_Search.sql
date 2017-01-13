CREATE FUNCTION fn_Search (@TextToSearchIn nvarchar(4000), @TextToSearchFor nvarchar(4000), @Start int)
RETURNS int

AS

BEGIN
  DECLARE @lenTextToSearchIn int
  DECLARE @lenTextToSearchFor int
  DECLARE @iCounter int
  DECLARE @iReturnValue int

  SET @lenTextToSearchIn = LEN(@TextToSearchIn)
  SET @lenTextToSearchFor = LEN(@TextToSearchFor)
  SET @iCounter = @Start
  SET @iReturnValue = -1

  WHILE @iCounter <= @lenTextToSearchIn - @lenTextToSearchFor + 1
  BEGIN
    IF SUBSTRING(@TextToSearchIn, @iCounter, @lenTextToSearchFor) = @TextToSearchFor
    BEGIN
      SET @iReturnValue = @iCounter
      SET @iCounter = @lenTextToSearchIn
    END
    SET @iCounter = @iCounter + 1
   END

   RETURN(@iReturnValue)

END



