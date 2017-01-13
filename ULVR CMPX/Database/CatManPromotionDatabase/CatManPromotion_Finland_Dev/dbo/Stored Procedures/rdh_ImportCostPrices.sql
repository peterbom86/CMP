CREATE PROCEDURE rdh_ImportCostPrices

AS

UPDATE Prices
SET Value = ISNULL(CAST(STD_PRICE as float), 0.0)
FROM OPENQUERY( LDWH_DK, 'SELECT * FROM CMP_PRODUCTS') BW_Products
  INNER JOIN CommonCodes ON BW_Products.PRODUCTCODE COLLATE Danish_Norwegian_CI_AS = CommonCodes.CommonCode
  INNER JOIN CommonCodePeriod ON PK_CommonCodeID = FK_CommonCodeID AND CommonCodePeriod.PeriodFrom <= GETDATE() 
    AND CommonCodePeriod.PeriodTo >= GETDATE()
  INNER JOIN Products ON PK_ProductID = FK_ProductID
  INNER JOIN Prices ON PK_ProductID = Prices.FK_ProductID AND FK_PriceTypeID = 3 --AND 
--    Prices.PeriodFrom <= GETDATE() AND Prices.PeriodTo >= GETDATE()
WHERE Prices.Value = 0 AND ISNULL(CAST(STD_PRICE as float), 0.0) <> 0.0

INSERT INTO Prices (FK_PriceTypeID, FK_ProductID, Value, PeriodFrom, PeriodTo)
SELECT 3, PK_ProductID, CAST(STD_PRICE as float), CAST(FLOOR(CAST(GETDATE() AS float)) AS datetime), '2099-12-31'
FROM OPENQUERY( LDWH_DK, 'SELECT * FROM CMP_PRODUCTS') BW_Products
  INNER JOIN CommonCodes ON BW_Products.PRODUCTCODE COLLATE Danish_Norwegian_CI_AS = CommonCodes.CommonCode
  INNER JOIN CommonCodePeriod ON PK_CommonCodeID = FK_CommonCodeID AND CommonCodePeriod.PeriodFrom <= GETDATE() 
    AND CommonCodePeriod.PeriodTo >= GETDATE()
  INNER JOIN Products ON PK_ProductID = FK_ProductID
  INNER JOIN Prices ON PK_ProductID = Prices.FK_ProductID AND FK_PriceTypeID = 3 AND 
    Prices.PeriodFrom <= GETDATE() AND Prices.PeriodTo >= GETDATE()
WHERE  Prices.Value <> CAST(STD_PRICE as float)

UPDATE Prices
SET PeriodTo = CAST(FLOOR(CAST(GETDATE() AS float)) - 1 AS datetime)
FROM OPENQUERY( LDWH_DK, 'SELECT * FROM CMP_PRODUCTS') BW_Products
  INNER JOIN CommonCodes ON BW_Products.PRODUCTCODE COLLATE Danish_Norwegian_CI_AS = CommonCodes.CommonCode
  INNER JOIN CommonCodePeriod ON PK_CommonCodeID = FK_CommonCodeID AND CommonCodePeriod.PeriodFrom <= GETDATE() 
    AND CommonCodePeriod.PeriodTo >= GETDATE()
  INNER JOIN Products ON PK_ProductID = FK_ProductID
  INNER JOIN Prices ON PK_ProductID = Prices.FK_ProductID AND FK_PriceTypeID = 3 AND 
    Prices.PeriodFrom <= GETDATE() AND Prices.PeriodTo >= GETDATE()
WHERE Prices.Value <> STD_PRICE

INSERT INTO Prices ( FK_PriceTypeID, FK_ProductID, Value, PeriodFrom, PeriodTo )
SELECT 3, Pr.FK_ProductID, 0, CAST(FLOOR(CAST(GETDATE() as float)) as datetime), Pr.PeriodTo
FROM Prices Pr
  INNER JOIN Products ON PK_ProductID = FK_ProductID
  INNER JOIN CommonCodes CC ON PK_ProductID = CC.FK_ProductID
  INNER JOIN CommonCodePeriod CCP ON PK_CommonCodeID = FK_CommonCodeID AND CCP.PeriodFrom <= GETDATE() AND CCP.PeriodTo >= GETDATE()
  LEFT JOIN OPENQUERY( LDWH_DK, 'SELECT * FROM CMP_PRODUCTS') BW_Products ON BW_Products.PRODUCTCODE COLLATE Danish_Norwegian_CI_AS = CC.CommonCode
WHERE FK_PriceTypeID = 3 AND Value <> 0 AND Pr.PeriodFrom <= GETDATE() AND Pr.PeriodTo >= GETDATE() AND BW_Products.PRODUCTCODE IS Null

UPDATE Pr
SET PeriodTo = CAST(FLOOR(CAST(GETDATE() AS float)) - 1 AS datetime)
FROM Prices Pr
  INNER JOIN Products ON PK_ProductID = FK_ProductID
  INNER JOIN CommonCodes CC ON PK_ProductID = CC.FK_ProductID
  INNER JOIN CommonCodePeriod CCP ON PK_CommonCodeID = FK_CommonCodeID AND CCP.PeriodFrom <= GETDATE() AND CCP.PeriodTo >= GETDATE()
  LEFT JOIN OPENQUERY( LDWH_DK, 'SELECT * FROM CMP_PRODUCTS') BW_Products ON BW_Products.PRODUCTCODE COLLATE Danish_Norwegian_CI_AS = CC.CommonCode
WHERE FK_PriceTypeID = 3 AND Value <> 0 AND Pr.PeriodFrom <= GETDATE() AND Pr.PeriodTo >= GETDATE() AND BW_Products.PRODUCTCODE IS Null

INSERT INTO Prices (FK_PriceTypeID, FK_ProductID, Value, PeriodFrom, PeriodTo)
SELECT 3, PK_ProductID, ISNULL(STD_PRICE, 0), '2001-01-01', '2099-12-31'
FROM OPENQUERY( LDWH_DK, 'SELECT * FROM CMP_PRODUCTS') BW_Products
  INNER JOIN CommonCodes ON BW_Products.PRODUCTCODE COLLATE Danish_Norwegian_CI_AS = CommonCodes.CommonCode
  INNER JOIN CommonCodePeriod ON PK_CommonCodeID = FK_CommonCodeID AND CommonCodePeriod.PeriodFrom <= GETDATE() 
    AND CommonCodePeriod.PeriodTo >= GETDATE()
  INNER JOIN Products ON PK_ProductID = FK_ProductID
  LEFT JOIN Prices ON PK_ProductID = Prices.FK_ProductID AND FK_PriceTypeID = 3
WHERE PK_PriceID IS Null

INSERT INTO Prices (FK_PriceTypeID, FK_ProductID, Value, PeriodFrom, PeriodTo)
SELECT 3, PK_ProductID, 0, '2001-01-01', '2099-12-31'
FROM Products
  LEFT JOIN Prices ON PK_ProductID = FK_ProductID AND FK_PriceTypeID = 3
WHERE PK_PriceID IS Null
