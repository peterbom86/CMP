Create Procedure rdh_DeletePricePeriod

@PriceID int

AS

DELETE FROM Prices 
WHERE PK_PriceID=@PriceID




