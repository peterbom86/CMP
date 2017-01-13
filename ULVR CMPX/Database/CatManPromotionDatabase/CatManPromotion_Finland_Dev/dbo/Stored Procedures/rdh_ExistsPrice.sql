CREATE PROCEDURE rdh_ExistsPrice (
@PriceID INT )
AS
SELECT 
  CASE COUNT( PK_PriceID ) 
    WHEN 0 THEN 0 
    WHEN NULL THEN 0 
    ELSE 1 
  END 
  AS PriceExists 
  FROM Prices 
  WHERE (  PK_PriceID = @PriceID )


