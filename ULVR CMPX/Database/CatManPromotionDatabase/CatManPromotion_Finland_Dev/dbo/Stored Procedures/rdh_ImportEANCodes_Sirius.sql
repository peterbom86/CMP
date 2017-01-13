CREATE PROC dbo.rdh_ImportEANCodes_Sirius

AS

CREATE TABLE #tempEANCodes ( FK_EANTypeID int, ProductID int, EANCode varchar(50), Pieces int)

INSERT INTO #tempEANCodes ( FK_EANTypeID, ProductID, EANCode, Pieces )
SELECT PK_EANTypeID, PK_ProductID, 
  CASE PK_EANTypeID 
    WHEN 5 THEN ''
    ELSE ISNULL(TL.EAN, '')
  END,
  CASE PK_EANTypeID 
    WHEN 1 THEN 1
    ELSE ISNULL(ZCU.PCS_REZ, 1)
  END *
  CASE PK_EANTypeID
    WHEN 1 THEN 1
    WHEN 5 THEN 1
    ELSE CAST(ISNULL(TL.PCS_REN, 1) as float) /
		CASE PK_EANTypeID
			WHEN 3 THEN CAST(ISNULL(TL.PCS_REZ, 1) as float)
			ELSE 1
		END
  END
FROM 
  (SELECT PK_ProductID, CommonCode, PK_EANTypeID
   FROM Products
     INNER JOIN CommonCodes CC ON PK_ProductID = CC.FK_ProductID AND CC.Active = 1, EANTypes
   WHERE IsMixedGoods = 0 AND EXISTS (SELECT * FROM SAP_UOM_TotalList TL WHERE CC.CommonCode = CAST(CAST(TL.MATERIAL as bigint) as varchar))) Products
   LEFT JOIN SAP_UOM_TotalList TL ON CAST(CAST(TL.MATERIAL as bigint) AS varchar) = CommonCode AND
     CASE PK_EANTypeID 
       WHEN 1 THEN 'ZCU' 
       WHEN 2 THEN 'CS'
       WHEN 3 THEN 'ZLA'
       WHEN 4 THEN 'PAL'
       WHEN 5 THEN 'ZCU'
     END = TL.Unit
   LEFT JOIN SAP_UOM_TotalList ZCU ON CAST(CAST(ZCU.MATERIAL as bigint) AS varchar) = CommonCode AND ZCU.Unit = 'ZCU'
ORDER BY 2, 1

INSERT INTO #tempEANCodes ( FK_EANTypeID, ProductID, EANCode, Pieces )
SELECT PK_EANTypeID, PK_ProductID,
  CASE PK_EANTypeID 
    WHEN 5 THEN ''
    ELSE ISNULL(TL.EAN, '')
  END, 
  CASE PK_EANTypeID
    WHEN 1 THEN 1
    ELSE ISNULL(SumPieces, 1)
  END *
  CASE PK_EANTypeID
    WHEN 3 THEN CAST(ISNULL(TL.PCS_REN, 1) as int) / CAST(ISNULL(TL.PCS_REZ, 1) as int)
    WHEN 4 THEN ISNULL(TL.PCS_REN, 1)
    ELSE 1
  END
FROM 
  (SELECT PK_ProductID, CommonCode, PK_EANTypeID
   FROM Products
     INNER JOIN CommonCodes CC ON PK_ProductID = CC.FK_ProductID AND CC.Active = 1, EANTypes
   WHERE IsMixedGoods = 1 AND EXISTS (SELECT * FROM SAP_UOM_TotalList TL WHERE CC.CommonCode = CAST(CAST(TL.MATERIAL as bigint) as varchar))) Products
  INNER JOIN 
    (SELECT FK_HeaderProductID, SUM(Pieces) SumPieces 
     FROM BillOfMaterials 
       INNER JOIN BillOfMaterialLines ON PK_BillOfMaterialID = FK_BillOfMaterialID
     GROUP BY FK_HeaderProductID) BOM ON PK_ProductID = FK_HeaderProductID
   LEFT JOIN SAP_UOM_TotalList TL ON CAST(CAST(TL.MATERIAL as bigint) AS varchar) = CommonCode AND
     CASE PK_EANTypeID 
       WHEN 1 THEN 'ZCU' 
       WHEN 2 THEN 'CS'
       WHEN 3 THEN 'ZLA'
       WHEN 4 THEN 'PAL'
       WHEN 5 THEN 'ZCU'
     END = TL.Unit
ORDER BY 2, 1

INSERT INTO EANCodes ( FK_EANTypeID, ProductID, EANCode, Pieces )
SELECT FK_EANTypeID, ProductID, EANCode, Pieces
FROM #tempEANCodes tEAN
WHERE NOT EXISTS (
  SELECT * FROM EANCodes EAN WHERE tEAN.ProductID = EAN.ProductID AND tEAN.FK_EANTypeID = EAN.FK_EANTypeID)
ORDER BY 2, 1

UPDATE EAN
SET EANCode = tEAN.EANCode,
  Pieces = tEAN.Pieces
FROM #tempEANCodes tEAN
  INNER JOIN EANCodes EAN ON tEAN.ProductID = EAN.ProductID AND tEAN.FK_EANTypeID = EAN.FK_EANTypeID
WHERE tEAN.Pieces <> EAN.Pieces OR tEAN.EANCode <> EAN.EANCode COLLATE Danish_Norwegian_CI_AS

DROP TABLE #tempEANCodes
