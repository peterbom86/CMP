CREATE    PROCEDURE rdh_ImportTaxes

AS

DELETE FROM Prices
WHERE FK_PriceTypeID = 6

INSERT INTO Prices (FK_PriceTypeID, FK_ProductID, Value, PeriodFrom, PeriodTo)
SELECT DISTINCT 6, PK_ProductID, REPLACE(REPLACE(Rate, '.', ''), ',', '.'), CONVERT(datetime, ValidOn, 105), CONVERT(datetime, ValidTo, 105)
FROM tblUploadBaseDiscount_UBF
  INNER JOIN Products ON Material = ProductCode
WHERE ConditionType IN ('Z53B', 'Z53C') AND Customer = 6994

INSERT INTO Prices (FK_PriceTypeID, FK_ProductID, Value, PeriodFrom, PeriodTo)
SELECT 6, FK_ProductID, 0, '2001-01-01', MIN(PeriodFrom) - 1 PeriodFrom
FROM Prices
WHERE FK_PriceTypeID = 6
GROUP BY FK_ProductID
HAVING MIN(PeriodFrom) > '2001-01-01'

INSERT INTO Prices (FK_PriceTypeID, FK_ProductID, Value, PeriodFrom, PeriodTo)
SELECT 6, FK_ProductID, 0, MAX(PeriodTo) - 1, '2099-12-31'
FROM Prices
WHERE FK_PriceTypeID = 6
GROUP BY FK_ProductID
HAVING MAX(PeriodTo) < '2099-12-31'

INSERT INTO Prices (FK_PriceTypeID, FK_ProductID, Value, PeriodFrom, PeriodTo)
SELECT 6, PK_ProductID, 0, '2001-01-01', '2099-12-31'
FROM Products
WHERE IsMixedGoods = 0 AND
  PK_ProductID NOT IN (SELECT FK_ProductID FROM Prices WHERE FK_PriceTypeID = 6)




