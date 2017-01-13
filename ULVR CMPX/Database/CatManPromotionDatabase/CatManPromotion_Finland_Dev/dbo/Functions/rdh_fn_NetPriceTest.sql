CREATE FUNCTION rdh_fn_NetPriceTest ( @Period datetime, @ProductID int, @ParticipatorID int)
RETURNS @NetPriceTable TABLE ( ParticipatorID int, ProductID int, GrossPrice float, BaseDiscount float, PromptPayment float, Pieces float, NetPrice float )

AS

BEGIN

INSERT @NetPriceTable ( ParticipatorID, ProductID, GrossPrice )
SELECT PK_ParticipatorID, FK_ProductID, Value
FROM Prices, Participators
WHERE (PK_ParticipatorID = @ParticipatorID OR @ParticipatorID = -1) AND
  (FK_ProductID = @ProductID OR @ProductID = -1) AND
  PeriodFrom <= @Period AND
  PeriodTo >= @Period AND
  FK_PriceTypeID = 1

UPDATE @NetPriceTable
SET BaseDiscount = SumBaseDiscount
FROM 
(SELECT FK_ParticipatorID, FK_ProductID, Sum(BaseDiscount) SumBaseDiscount
FROM (SELECT FK_ParticipatorID, FK_ProductID, 
        ROUND(CASE FK_ValueTypeID 
                WHEN 1 THEN ISNULL([Value],0)* GrossPrice
                ELSE ISNULL([Value],0)
              END, 2) AS BaseDiscount
      FROM BaseDiscounts
        INNER JOIN @NetPriceTable ON FK_ParticipatorID = ParticipatorID AND FK_ProductID = ProductID AND
          PeriodFrom <= @Period AND PeriodTo >= @Period AND FK_PriceBaseID = 1) SubBaseDiscounts
GROUP BY FK_ParticipatorID, FK_ProductID) SourceBaseDiscount
WHERE ParticipatorID = FK_ParticipatorID AND ProductID = FK_ProductID

UPDATE @NetPriceTable
SET PromptPayment = SumBaseDiscount
FROM 
(SELECT FK_ParticipatorID, FK_ProductID, Sum(BaseDiscount) SumBaseDiscount
FROM (SELECT FK_ParticipatorID, FK_ProductID, 
        ROUND(CASE FK_ValueTypeID 
                WHEN 1 THEN ISNULL([Value],0)* (GrossPrice - BaseDiscount)
                ELSE ISNULL([Value],0)
              END, 2) AS BaseDiscount
      FROM BaseDiscounts
        INNER JOIN @NetPriceTable ON FK_ParticipatorID = ParticipatorID AND FK_ProductID = ProductID AND
          PeriodFrom <= @Period AND PeriodTo >= @Period AND FK_PriceBaseID = 2) SubBaseDiscounts
GROUP BY FK_ParticipatorID, FK_ProductID) SourceBaseDiscount
WHERE ParticipatorID = FK_ParticipatorID AND ProductID = FK_ProductID

UPDATE N
SET Pieces = E.Pieces
FROM @NetPriceTable N, EANCodes E
WHERE N.ProductID = E.ProductID AND FK_EANTypeID = 2

UPDATE @NetPriceTable
SET NetPrice = (ISNULL(GrossPrice, 0) - ISNULL(BaseDiscount, 0) - ISNULL(PromptPayment, 0)) / ISNULL(Pieces, 1)

RETURN

END



