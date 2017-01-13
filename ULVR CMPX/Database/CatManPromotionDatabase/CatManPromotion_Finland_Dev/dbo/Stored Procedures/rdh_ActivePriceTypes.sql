Create procedure rdh_ActivePriceTypes AS

SELECT dbo.PriceTypes.PK_PriceTypeID, dbo.PriceTypes.Label
FROM dbo.PriceTypes INNER JOIN dbo.Prices ON 
dbo.PriceTypes.PK_PriceTypeID = dbo.Prices.FK_PriceTypeID
GROUP BY dbo.PriceTypes.PK_PriceTypeID, dbo.PriceTypes.Label
ORDER BY dbo.PriceTypes.PK_PriceTypeID



