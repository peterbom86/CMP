CREATE Function rdh_fn_IsMixedGoods( @SalesUnitID INT )
Returns BIT
AS
BEGIN
DECLARE @Count INT
DECLARE @Flag BIT
SET @Count = 
  ( 
    SELECT 
      COUNT(BillOfMaterialLines.FK_ComponentProductID) AS [Count]
    FROM
      BillOfMaterials INNER JOIN
                  Products ON BillOfMaterials.FK_HeaderProductID = Products.PK_ProductID INNER JOIN
                  BillOfMaterialLines ON BillOfMaterials.PK_BillOfMaterialID = BillOfMaterialLines.FK_BillOfMaterialID
    GROUP BY 
      Products.PK_ProductID
    HAVING      
      (Products.PK_ProductID = @SalesUnitID)
  )
IF ( @Count > 1 )
  SET @Flag = 1
ELSE 
  SET @Flag = 0

return(@Flag)
END


