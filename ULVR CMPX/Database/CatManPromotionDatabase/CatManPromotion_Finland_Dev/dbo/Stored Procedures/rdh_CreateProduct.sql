CREATE PROCEDURE rdh_CreateProduct AS
INSERT INTO tblProducts ( Label, PeriodFrom ) VALUES ( 'new_product', getdate() )
SELECT MAX( PK_ProductID ) FROM Products 



