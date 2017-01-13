CREATE  FUNCTION rdh_ManualProductsWithPieces ( @products varchar(4000) )
RETURNS @productTable TABLE (ProductCode varchar(50), Pieces int)

AS

BEGIN

DECLARE @compString varchar(10)
DECLARE @pieces varchar(4000)
DECLARE @iCounter int
DECLARE @tempString varchar(4000)
DECLARE @iCounter2 int
DECLARE @lastPosition int

SET @compString = ','
SET @iCounter = 1
SET @lastPosition = 1
WHILE @iCounter <= LEN(@products) - LEN(@compString) + 1
BEGIN
  IF SUBSTRING(@products, @iCounter, LEN(@compString)) = @compString
  BEGIN
    SET @tempString = SUBSTRING(@products, @lastPosition, @iCounter - @lastPosition)
    SET @iCounter2 = 1
    WHILE @iCounter2 <= LEN(@tempString)
    BEGIN
      IF SUBSTRING(@tempString, @iCounter2, 1) = '-'
      BEGIN
        INSERT INTO @productTable VALUES ( SUBSTRING(@tempString, 1, @iCounter2 - 1), CAST(RIGHT(@tempString, LEN(@tempString) - @iCounter2) as int) )
        SET @iCounter2 = LEN(@tempString)
      END 
      SET @iCounter2 = @iCounter2 + 1
    END
    SET @iCounter = @iCounter + LEN(@compString) 
    SET @lastPosition = @iCounter
  END
  SET @iCounter = @iCounter + 1
END
SET @tempString = SUBSTRING(@products, @lastPosition, @iCounter - @lastPosition)
SET @iCounter2 = 1
WHILE @iCounter2 <= LEN(@tempString)
BEGIN
  IF SUBSTRING(@tempString, @iCounter2, 1) = '-'
  BEGIN
        INSERT INTO @productTable VALUES ( SUBSTRING(@tempString, 1, @iCounter2 - 1), CAST(RIGHT(@tempString, LEN(@tempString) - @iCounter2) as int) )
    SET @iCounter2 = LEN(@tempString)
  END 
  SET @iCounter2 = @iCounter2 + 1
END

RETURN
END

