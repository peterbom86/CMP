CREATE PROCEDURE rdh_ExistsSettlement (
@SettlementID INT )
AS
SELECT 
  CASE COUNT( PK_SettlementID ) 
    WHEN 0 THEN 0 
    WHEN NULL THEN 0 
    ELSE 1 
  END 
  AS SettlementExists 
  FROM Settlements 
  WHERE (  PK_SettlementID = @SettlementID )


