CREATE  PROCEDURE rdh_ImportPrices

AS

DELETE FROM Prices
FROM Prices
  INNER JOIN Products ON PK_ProductID = Prices.FK_ProductID AND FK_PriceTypeID = 1
WHERE IsMixedGoods = 1 OR (IsMixedGoods = 0 AND ProductCode IN (
  SELECT FK_ProductID COLLATE Danish_Norwegian_CI_AS FROM OPENQUERY(LDWH_DK, 'SELECT * FROM CMP_PROD_BASE_PRICE')))

INSERT INTO Prices (FK_PriceTypeID, FK_ProductID, Value, PeriodFrom, PeriodTo)
SELECT 1, PK_ProductID, ISNULL(RATE, 0), BWPrices.PERIODFROM, BWPrices.PERIODTO
FROM Products
  INNER JOIN OPENQUERY(LDWH_DK, 'SELECT * FROM CMP_PROD_BASE_PRICE') BWPrices ON ProductCode = FK_ProductID COLLATE Danish_Norwegian_CI_AS 
WHERE NOT EXISTS (SELECT * FROM Prices WHERE Prices.FK_ProductID = PK_ProductID AND FK_PriceTypeID = 1)

