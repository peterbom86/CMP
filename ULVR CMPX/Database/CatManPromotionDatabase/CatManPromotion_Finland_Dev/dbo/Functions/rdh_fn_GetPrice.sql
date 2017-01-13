CREATE FUNCTION dbo.rdh_fn_GetPrice 
  (@ProductID int,
   @ParticipatorID int,
   @Date datetime,
   @PriceTypeID int)

RETURNS float

AS

BEGIN

DECLARE @Price float

SELECT TOP 1 @Price = 
  CASE Pieces
    WHEN 0 THEN Value 
    ELSE Value / CASE WHEN IsPercentage = 1 THEN 1 ELSE Pieces / PiecesPerConsumerUnit END
  END FROM Prices Pr
  INNER JOIN Products P ON Pr.FK_ProductID = P.PK_ProductID
  INNER JOIN EANCodes E ON P.PK_ProductID = E.ProductID AND E.FK_EANTypeID = 2
  INNER JOIN PriceTypes PT ON Pr.FK_PriceTypeID = PT.PK_PriceTypeID
WHERE
  (FK_ParticipatorID = @ParticipatorID OR FK_ParticipatorID IS Null) AND 
  PK_ProductID = @ProductID AND Pr.PeriodFrom <= @Date AND Pr.PeriodTo >= @Date AND
  FK_PriceTypeID = @PriceTypeID
ORDER BY
  FK_ParticipatorID DESC, PK_PriceID DESC  

RETURN ISNULL(@Price, 0)

END


