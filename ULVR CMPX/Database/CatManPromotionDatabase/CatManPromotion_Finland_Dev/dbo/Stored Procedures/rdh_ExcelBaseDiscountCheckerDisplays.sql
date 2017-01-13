CREATE PROC dbo.rdh_ExcelBaseDiscountCheckerDisplays
  @ProductID INT, -- varchar(50),
  @ParticipatorID int,
  @Period datetime

AS

SELECT PK_BaseDiscountTypeID, BaseDiscountTypes.Label BaseDiscountType, Comp.ProductCode, Comp.Label ProductName, 
  Prices.Value / CAST(EANCodes.Pieces / Products.PiecesPerConsumerUnit as float) Price, BOML.Pieces / Products.PiecesPerConsumerUnit Pieces, BaseDiscounts.Value Discount, 
  BaseDiscounts.Value * (CAST(BOML.Pieces / Products.PiecesPerConsumerUnit as float) * Prices.Value / CAST(EANCodes.Pieces / Products.PiecesPerConsumerUnit as float) / TotalPrice) CalcDiscount, 
  CASE WHEN Prices.PeriodFrom >= BaseDiscounts.PeriodFrom THEN Prices.PeriodFrom ELSE BaseDiscounts.PeriodFrom END PeriodFrom,
  CASE WHEN Prices.PeriodTo <= BaseDiscounts.PeriodTo THEN Prices.PeriodTo ELSE BaseDiscounts.PeriodTo END PeriodTo, TotalPrice
INTO #tempCalcDiscounts
FROM Products
  INNER JOIN BillOfMaterials ON PK_ProductID = FK_HeaderProductID
  INNER JOIN BillOfMaterialLines BOML ON PK_BillOfMaterialID = FK_BillOfMaterialID
  INNER JOIN Products Comp ON Comp.PK_ProductID = FK_ComponentProductID
  INNER JOIN EANCodes ON Comp.PK_ProductID = ProductID AND FK_EANTypeID = 2
  INNER JOIN Prices ON FK_ComponentProductID = Prices.FK_ProductID AND FK_PriceTypeID = 1 AND Prices.PeriodFrom <= @Period AND Prices.PeriodTo >= @Period
  INNER JOIN (
    SELECT FK_BillOfMaterialID, SUM(CAST(BOML.Pieces as float) / CAST(EANCodes.Pieces / PiecesPerConsumerUnit as float) * Prices.Value) TotalPrice
    FROM BillOfMaterialLines BOML
      INNER JOIN EANCodes ON FK_ComponentProductID = ProductID AND FK_EANTypeID = 2
      INNER JOIN dbo.Products as p ON dbo.EANCodes.ProductID = p.PK_ProductID
      INNER JOIN Prices ON FK_ComponentProductID = Prices.FK_ProductID AND FK_PriceTypeID = 1 AND Prices.PeriodFrom <= @Period AND Prices.PeriodTo >= @Period
    GROUP BY FK_BillOfMaterialID) TotalPrices ON PK_BillOfMaterialID = TotalPrices.FK_BillOfMaterialID
  INNER JOIN BaseDiscounts ON FK_ComponentProductID = BaseDiscounts.FK_ProductID AND BaseDiscounts.FK_ParticipatorID = @ParticipatorID AND BaseDiscounts.PeriodFrom <= @Period AND BaseDiscounts.PeriodTo >= @Period
  INNER JOIN BaseDiscountTypes ON PK_BaseDiscountTypeID = FK_BaseDiscountTypeID
WHERE Products.PK_ProductID = @ProductID AND IsValidForRunUp = 1
ORDER BY PK_BaseDiscountTypeID

SELECT 1 SortOrder, PK_BaseDiscountTypeID, BaseDiscountType, ProductCode, ProductName, Price, Pieces, Discount, CalcDiscount, PeriodFrom, PeriodTo
FROM #tempCalcDiscounts
UNION SELECT 2, PK_BaseDiscountTypeID, BaseDiscountType, '', '', TotalPrice / SUM(Pieces), Null, Null, SUM(CalcDiscount), 
  MAX(PeriodFrom) PeriodFrom, MIN(PeriodTo) PeriodTo
FROM #tempCalcDiscounts
GROUP BY PK_BaseDiscountTypeID, BaseDiscountType, TotalPrice
ORDER BY 2, 1

DROP TABLE #tempCalcDiscounts
