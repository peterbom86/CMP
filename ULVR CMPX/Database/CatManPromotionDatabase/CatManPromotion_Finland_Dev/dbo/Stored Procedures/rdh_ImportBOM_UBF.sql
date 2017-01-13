CREATE PROCEDURE rdh_ImportBOM_UBF

AS 

INSERT INTO BillOfMaterials (FK_HeaderProductID)
SELECT PK_ProductID
FROM Products
WHERE PK_ProductID NOT IN (
  SELECT FK_HeaderProductID FROM BillOfMaterials)

DELETE 
FROM BillOfMaterialLines

DELETE
FROM BillOfMaterials
WHERE FK_HeaderProductID NOT IN (
  SELECT PK_ProductID FROM Products)

-- OBS Der skal laves en indlæsning til BOM fra Excel.
INSERT INTO BillOfMaterialLines (FK_BillOfMaterialID, FK_ComponentProductID, Pieces)
SELECT DISTINCT PK_BillOfMaterialID, Component.PK_ProductID, Quantity * ComponentEAN.Pieces / [Base Quantity]
FROM tblUploadBOM_UBF
  INNER JOIN Products Header ON Material = Header.ProductCode
  INNER JOIN EANCodes HeaderEAN ON Header.PK_ProductID = HeaderEAN.ProductID AND HeaderEAN.FK_EANTypeID = 2
  INNER JOIN BillOfMaterials ON Header.PK_ProductID = FK_HeaderProductID
  INNER JOIN Products Component ON Component = Component.ProductCode
  INNER JOIN EANCodes ComponentEAN ON Component.PK_ProductID = ComponentEAN.ProductID AND ComponentEAN.FK_EANTypeID = 2
WHERE Header.IsMixedGoods = 1

INSERT INTO BillOfMaterialLines (FK_BillOfMaterialID, FK_ComponentProductID, Pieces)
SELECT PK_BillOfMaterialID, FK_HeaderProductID, 1
FROM BillOfMaterials
WHERE PK_BillOfMaterialID NOT IN (
  SELECT FK_BillOfMaterialID
  FROM BillOfMaterialLines)

UPDATE BillOfMaterialLines
SET Pieces = 1
WHERE Pieces = 0

UPDATE Products
SET IsMixedGoods = 0
WHERE IsMixedGoods = 1 AND PK_ProductID IN (
  SELECT FK_HeaderProductID
  FROM BillOfMaterials
    INNER JOIN BillOfMaterialLines ON PK_BillOfMaterialID = FK_BillOfMaterialID
  GROUP BY FK_HeaderProductID
  HAVING Sum(Pieces) = 1 AND Count(*) = 1)

-- Muligvis unødvendig
UPDATE EAN
  SET Pieces = 
    CASE FK_EANTypeID
      WHEN 1 THEN EAN.Pieces
      WHEN 2 THEN BOMPieces
      WHEN 3 THEN BOMPieces * LayerPieces / ColliPieces 
      WHEN 4 THEN BOMPieces * PalletPieces / ColliPieces 
      WHEN 5 THEN BOMPieces
    END
FROM EANCodes EAN INNER JOIN (
  SELECT PK_ProductID, Sum(BillOfMaterialLines.Pieces) BOMPieces, AVG(Colli.Pieces) ColliPieces, 
    AVG(Layer.Pieces) LayerPieces, AVG(Pallet.Pieces) PalletPieces, AVG(ZUN.Pieces) ZUNPieces
  FROM Products
    INNER JOIN EANCodes Colli ON PK_ProductID = Colli.ProductID AND Colli.FK_EANTypeID = 2
    INNER JOIN EANCodes Layer ON PK_ProductID = Layer.ProductID AND Layer.FK_EANTypeID = 3
    INNER JOIN EANCodes Pallet ON PK_ProductID = Pallet.ProductID AND Pallet.FK_EANTypeID = 4
    INNER JOIN EANCodes ZUN ON PK_ProductID = ZUN.ProductID AND ZUN.FK_EANTypeID = 5
    INNER JOIN BillOfMaterials ON PK_ProductID = FK_HeaderProductID
    INNER JOIN BillOfMaterialLines ON PK_BillOfMaterialID = FK_BillOfMaterialID
  WHERE IsMixedGoods = 1
  GROUP BY PK_ProductID
  HAVING Sum(BillOfMaterialLines.Pieces) <> AVG(Colli.Pieces)) SubQ ON PK_ProductID = ProductID
