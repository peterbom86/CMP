CREATE PROCEDURE rdh_ExistsProduct( @ProductID INT )
AS
SELECT 
  CASE COUNT( PK_ProductID ) 
    WHEN 0 THEN 0 
    WHEN NULL THEN 0 
    ELSE 1 
  END 
  AS ProductExists 
  FROM Products 
  WHERE (  PK_ProductID = @ProductID )


