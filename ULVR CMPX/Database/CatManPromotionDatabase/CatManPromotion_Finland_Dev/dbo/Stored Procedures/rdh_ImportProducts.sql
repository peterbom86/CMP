-- 20070514 - PO - Nyt pricinghieraki
CREATE           PROCEDURE rdh_ImportProducts

AS

BEGIN TRANSACTION
/* Deletes Products */
SELECT PK_ProductID
INTO #TempProductsToBeDeleted
FROM Products 
WHERE 
  ProductCode NOT IN (
    SELECT TCode FROM tblBaseMaterial) AND 
  PK_ProductID NOT IN (
    SELECT FK_SalesUnitID FROM ActivityLines) AND
  PK_ProductID NOT IN (
    SELECT FK_ProductID FROM ActivityLines) AND
  PK_ProductID NOT IN (
    SELECT FK_ComponentProductID FROM BillOfMaterialLines
      INNER JOIN BillOfMaterials ON FK_BillOfMaterialID = PK_BillOfMaterialID
      INNER JOIN Products ON FK_HeaderProductID = PK_ProductID 
      INNER JOIN ActivityLines ON PK_ProductID = FK_SalesUnitID)

BEGIN TRANSACTION
DELETE
FROM EANCodes WHERE ProductID IN (
  SELECT PK_ProductID FROM #TempProductsToBeDeleted)

DELETE
FROM CommonCodes WHERE FK_ProductID IN (
  SELECT PK_ProductID FROM #TempProductsToBeDeleted)

DELETE
FROM BillOfMaterialLines WHERE FK_ComponentProductID IN (
  SELECT PK_ProductID FROM #TempProductsToBeDeleted)

DELETE
FROM BillOfMaterialLines WHERE FK_BillOfMaterialID IN (
  SELECT PK_BillOfMaterialID
  FROM BillOfMaterials WHERE FK_HeaderProductID IN (
    SELECT PK_ProductID FROM #TempProductsToBeDeleted))

DELETE
FROM BillOfMaterials WHERE FK_HeaderProductID IN (
  SELECT PK_ProductID FROM #TempProductsToBeDeleted)

DELETE
FROM Prices WHERE FK_ProductID IN (
  SELECT PK_ProductID FROM #TempProductsToBeDeleted)

DELETE
FROM BaseDiscounts WHERE FK_ProductID IN (
  SELECT PK_ProductID FROM #TempProductsToBeDeleted)

DELETE
FROM BaseDiscountsEdit WHERE FK_ProductID IN (
  SELECT PK_ProductID FROM #TempProductsToBeDeleted)

DELETE
FROM Listings WHERE FK_ProductID IN (
  SELECT PK_ProductID FROM #TempProductsToBeDeleted)

DELETE
FROM AllocationLines WHERE FK_ProductID IN (
  SELECT PK_ProductID FROM #TempProductsToBeDeleted)

DELETE
FROM Products WHERE PK_ProductID IN (
  SELECT PK_ProductID FROM #TempProductsToBeDeleted)

COMMIT TRANSACTION

DROP TABLE #TempProductsToBeDeleted





/* Insert New Products */
INSERT INTO Products (ProductCode, Label, FK_ProductStatusID, Description, PiecesPerConsumerUnit, FK_ProductTypeID, ItemCategory, Volume, Weight, ProductChange, Comment)
SELECT DISTINCT TCode, '', 0, '', 1, (SELECT PK_ProductTypeID FROM ProductTypes WHERE IsDefault = 1), '', 1, 1, '*', ''  FROM tblBaseMaterial
WHERE TCode NOT IN (SELECT ProductCode FROM Products) AND
  SalesStatus <> '01'

/* Insert New Common Codes */
INSERT INTO CommonCodes (FK_ProductID, CommonCode, TCode, Active)
SELECT PK_ProductID, CAST(CAST(Common AS int) as varchar), ProductCode, 0 FROM Products 
  INNER JOIN tblBaseMaterial ON ProductCode = TCode
WHERE NOT EXISTS (SELECT * FROM CommonCodes WHERE CAST(CAST(Common AS int) as varchar(8)) = CommonCode AND PK_ProductID = FK_ProductID)

/* Delete invalid Common Codes */
DELETE FROM CommonCodes WHERE PK_CommonCodeID IN (
SELECT PK_CommonCodeID FROM Products
  INNER JOIN CommonCodes ON FK_ProductID = PK_ProductID
WHERE NOT EXISTS (SELECT * FROM tblBaseMaterial WHERE CAST(CAST(Common AS int) as varchar(8)) = CommonCode AND PK_ProductID = FK_ProductID))

DELETE FROM ActivityLinesToESAP
WHERE FK_CommonCodeID IN (
  SELECT PK_CommonCodeID
  FROM CommonCodes
    INNER JOIN Products ON PK_ProductID = FK_ProductID
    INNER JOIN tblBaseMaterial ON tblBaseMaterial.Common LIKE '%00000000' + CommonCode
  WHERE CommonCodes.TCode <> tblBaseMaterial.TCode)

DELETE FROM CommonCodes
WHERE PK_CommonCodeID IN (
  SELECT PK_CommonCodeID
  FROM CommonCodes
    INNER JOIN Products ON PK_ProductID = FK_ProductID
    INNER JOIN tblBaseMaterial ON tblBaseMaterial.Common LIKE '%00000000' + CommonCode
  WHERE CommonCodes.TCode <> tblBaseMaterial.TCode)

/* Reset Active Common Codes */
UPDATE CommonCodes SET Active = 0

/* Select Active Common Code */

/* Hvis en TCode har en common code med salgsstatus 34 (Live) 
   og samtidig er i material determination, så er det den
   common code der gælder */
UPDATE
  CC
SET
  Active = 1
FROM
  CommonCodes CC
WHERE EXISTS (
SELECT PK_ProductID, Max(CommonCode) MaxCommonCode
FROM
  CommonCodes
    INNER JOIN tblBaseMaterial ON CommonCode = CAST(CAST(tblBaseMaterial.Common AS int) as varchar)
    INNER JOIN Products ON PK_ProductID = FK_ProductID AND tblBaseMaterial.TCode = ProductCode
WHERE
  SalesStatus = '34' AND
  MaterialDetermination <> ''
GROUP BY
  PK_ProductID
HAVING
  CC.FK_ProductID = PK_ProductID AND CC.CommonCode = Max(CommonCodes.CommonCode))

/* Hvis en TCode har en common code med salgsstatus 34 (Live) 
   og men som ikke er i material determination, så er det den
   common code der gælder næstefter */
UPDATE
  CC
SET
  Active = 1
FROM
  CommonCodes CC
WHERE EXISTS (
SELECT PK_ProductID, Max(CommonCode) MaxCommonCode
FROM
  CommonCodes
    INNER JOIN tblBaseMaterial ON CommonCode = CAST(CAST(tblBaseMaterial.Common AS int) as varchar)
    INNER JOIN Products ON PK_ProductID = FK_ProductID AND tblBaseMaterial.TCode = ProductCode
WHERE
  SalesStatus = '34' AND
  tblBaseMaterial.TCode NOT IN (
    SELECT
      TCode
    FROM
      tblBaseMaterial
    WHERE
      SalesStatus = '34' AND
      MaterialDetermination <> '')
GROUP BY
  PK_ProductID
HAVING 
  CC.FK_ProductID = PK_ProductID AND CC.CommonCode = Max(CommonCodes.CommonCode))

/* Hvis en TCode ikke har en common code med salgsstatus 34, men
   en common code med en salgsstatus anderledes end 01, som er i 
   material determination, så er det den der gælder */
UPDATE
  CC
SET
  Active = 1
FROM 
  CommonCodes CC
WHERE EXISTS (
SELECT PK_ProductID, MAX(CommonCode) MaxCommonCode
FROM
  CommonCodes
    INNER JOIN tblBaseMaterial ON CommonCode = CAST(CAST(tblBaseMaterial.Common AS int) as varchar)
    INNER JOIN Products ON PK_ProductID = FK_ProductID AND tblBaseMaterial.TCode = ProductCode
WHERE
  SalesStatus <> '01' AND
  MaterialDetermination <> '' AND
  tblBaseMaterial.TCode NOT IN (
    SELECT
      TCode
    FROM
      tblBaseMaterial
    WHERE
      SalesStatus = '34')
GROUP BY
  PK_ProductID
HAVING 
  CC.FK_ProductID = PK_ProductID AND CC.CommonCode = Max(CommonCodes.CommonCode))


/* Hvis en TCode ikke har en common code med salgsstatus 34, eller
   en common code, der er i material determination, så er det den 
   største common code, der ikke har salgsstatus 01, der gælder */
UPDATE
  CC
SET
  Active = 1
FROM 
  CommonCodes CC
WHERE EXISTS (
SELECT PK_ProductID, MAX(CommonCode) MaxCommonCode
FROM
  CommonCodes
    INNER JOIN tblBaseMaterial ON CommonCode = CAST(CAST(tblBaseMaterial.Common AS int) as varchar)
    INNER JOIN Products ON PK_ProductID = FK_ProductID AND tblBaseMaterial.TCode = ProductCode
WHERE
  SalesStatus <> '01' AND
  tblBaseMaterial.TCode NOT IN (
    SELECT
      TCode
    FROM
      tblBaseMaterial
    WHERE
      SalesStatus = '34' OR
      (MaterialDetermination <> '' AND SalesStatus <> '01'))
GROUP BY
  PK_ProductID
HAVING 
  CC.FK_ProductID = PK_ProductID AND CC.CommonCode = Max(CommonCodes.CommonCode))



/* Hvis en TCode kun har common koder med salgsstatus 01,
   så tager den den største af disse */
UPDATE
  CC
SET
  Active = 1
FROM
  CommonCodes CC
WHERE EXISTS (
SELECT PK_ProductID, MAX(CommonCode) MaxCommonCode
FROM
  CommonCodes
    INNER JOIN tblBaseMaterial ON CommonCode = CAST(CAST(tblBaseMaterial.Common AS int) as varchar)
    INNER JOIN Products ON PK_ProductID = FK_ProductID AND tblBaseMaterial.TCode = ProductCode
WHERE
  SalesStatus = '01' AND
  tblBaseMaterial.TCode NOT IN (
    SELECT
      TCode
    FROM
      tblBaseMaterial
    WHERE
      SalesStatus <> '01')
GROUP BY
  PK_ProductID
HAVING
  CC.FK_ProductID = PK_ProductID AND CC.CommonCode = MAX(CommonCodes.CommonCode))

/* Hvis en TCode ikke har en activ common code i følge tblBaseMaterial */
UPDATE CC
SET Active = 1
FROM
  CommonCodes CC
WHERE EXISTS (
SELECT FK_ProductID, Max(CommonCode) AS MaxCommonCode FROM CommonCodes
WHERE Active = 0 AND
  FK_ProductID NOT IN (SELECT FK_ProductID FROM CommonCodes WHERE Active = 1)
GROUP BY FK_ProductID
HAVING CC.FK_ProductID = CommonCodes.FK_ProductID AND CC.CommonCode = Max(CommonCodes.CommonCode))

/* Opdaterer varetekst - hvis der ikke er opdateret en varetekst i forvejen,
   så bliver den opdater. Hvis der er opdateret skal den ikke rettes, da
   den formodentlig er i et bedre format */
UPDATE
  P
SET
  Label = Text
FROM
  Products P
    INNER JOIN CommonCodes ON PK_ProductID = FK_ProductID AND Active = 1
    INNER JOIN tblBaseMaterial ON CommonCode = CAST(CAST(tblBaseMaterial.Common AS int) AS varchar)
WHERE
  FK_ProductStatusID = 0

/* Opdaterer øvrige oplysninger i Materiale Masteren for produkter, der de
   common koder, der er valgt de de respektive TCodes */
UPDATE
  P
SET
  ItemCategory = tblBaseMaterial.ItemCategory,
  Weight = CAST(tblBaseMaterial.NetWeight AS float)
FROM
  Products P
    INNER JOIN CommonCodes ON PK_ProductID = FK_ProductID AND Active = 1
    INNER JOIN tblBaseMaterial ON CommonCode = CAST(CAST(tblBaseMaterial.Common AS int) AS varchar)

/* Opdaterer Produktstatus */
UPDATE 
  P
SET
  FK_ProductStatusID = 
    CASE SalesStatus
      WHEN '01' THEN 6
      WHEN '02' THEN 3
      WHEN '30' THEN 1
      WHEN '34' THEN 2
      WHEN '36' THEN 3
    END
FROM
  Products P
    INNER JOIN CommonCodes ON PK_ProductID = FK_ProductID AND Active = 1
    INNER JOIN tblBaseMaterial ON CommonCode = CAST(CAST(tblBaseMaterial.Common AS int) AS varchar)
WHERE
  FK_ProductStatusID NOT IN (0, 4)

UPDATE
  P
SET
  FK_ProductStatusID = 6
FROM
  Products P
    INNER JOIN CommonCodes ON PK_ProductID = FK_ProductID AND Active = 1
    INNER JOIN tblBaseMaterial ON CommonCode = CAST(CAST(tblBaseMaterial.Common AS int) AS varchar)
WHERE
  FK_ProductStatusID IN (0, 4) AND
  SalesStatus = '01'

UPDATE
  P
SET
  IsMixedGoods = 
    CASE ItemCategory
      WHEN 'LUMF' THEN 1
      WHEN 'ERLA' THEN 1
      WHEN 'NORM' THEN 0
    END
FROM Products P
WHERE
  ItemCategory IN ('LUMF', 'ERLA', 'NORM')

/* Opdaterer Bill Of Material */
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


INSERT INTO BillOfMaterialLines (FK_BillOfMaterialID, FK_ComponentProductID, Pieces)
SELECT PK_BillOfMaterialID, CompProd.PK_ProductID, (CAST(ItemQuantity AS float) / 1000) / CASE HeaderProd.PiecesPerConsumerUnit WHEN 0 THEN 1 ELSE HeaderProd.PiecesPerConsumerUnit END
FROM 
  Products HeaderProd
    INNER JOIN CommonCodes HeaderCC ON HeaderProd.PK_ProductID = HeaderCC.FK_ProductID AND HeaderCC.Active = 1
    INNER JOIN tblBaseMaterial ON HeaderCC.CommonCode = CAST(CAST(Common AS int) as varchar)
    INNER JOIN tblBaseBOM ON HeaderCC.CommonCode = CAST(CAST(Header AS int) as varchar)
    INNER JOIN CommonCodes CompCC ON CompCC.CommonCode = CAST(CAST(Component AS int) as varchar)
    INNER JOIN Products CompProd ON CompCC.FK_ProductID = CompProd.PK_ProductID
    INNER JOIN BillOfMaterials ON HeaderProd.PK_ProductID = FK_HeaderProductID
WHERE
  tblBaseMaterial.ItemCategory IN ('LUMF', 'ERLA')


INSERT INTO BillOfMaterialLines (FK_BillOfMaterialID, FK_ComponentProductID, Pieces)
SELECT PK_BillOfMaterialID, FK_HeaderProductID, 1
FROM BillOfMaterials
WHERE PK_BillOfMaterialID NOT IN (
  SELECT FK_BillOfMaterialID
  FROM BillOfMaterialLines)

UPDATE BillOfMaterialLines
SET Pieces = 1
WHERE Pieces = 0

/* Opdaterer EAN Koder */
DELETE 
FROM EANCodes

INSERT INTO EANCodes (FK_EANTypeID, ProductID, EANCode, Pieces)
SELECT 1, PK_ProductID, EAN, 1
FROM
  Products
    INNER JOIN CommonCodes ON PK_ProductID = FK_ProductID AND Active = 1
    INNER JOIN tblBaseMaterial ON CommonCode = CAST(CAST(Common AS int) AS varchar)

INSERT INTO EANCodes (FK_EANTypeID, ProductID, EANCode, Pieces)
SELECT 1, PK_ProductID, '', 1
FROM 
  Products
WHERE
  PK_ProductID NOT IN (
    SELECT ProductID FROM EANCodes WHERE FK_EANTypeID = 1)

INSERT INTO EANCodes (FK_EANTypeID, ProductID, EANCode, Pieces)
SELECT 2, PK_ProductID, ITF, 
  CASE
    WHEN Products.ItemCategory = 'ERLA' OR Products.ItemCategory = 'LUMF' THEN SumBomPieces
    ELSE Num
  END
FROM
  Products
    INNER JOIN CommonCodes ON PK_ProductID = FK_ProductID AND Active = 1
    INNER JOIN tblBaseMaterial ON CommonCode = CAST(CAST(tblBaseMaterial.Common AS int) AS varchar)
    INNER JOIN (SELECT FK_HeaderProductID, Sum(Pieces) AS SumBomPieces
                FROM BillOfMaterials INNER JOIN BillOfMaterialLines ON PK_BillOfMaterialID = FK_BillOfMaterialID
                GROUP BY FK_HeaderProductID) AS BillOfMaterials ON PK_ProductID = FK_HeaderProductID
    INNER JOIN tblBaseUOM ON CommonCode = CAST(CAST(tblBaseUOM.Common AS int) AS varchar) AND UOM = 'CS'

INSERT INTO EANCodes (FK_EANTypeID, ProductID, EANCode, Pieces)
SELECT 2, PK_ProductID, '', 1
FROM 
  Products
WHERE
  PK_ProductID NOT IN (
    SELECT ProductID FROM EANCodes WHERE FK_EANTypeID = 2)

INSERT INTO EANCodes (FK_EANTypeID, ProductID, EANCode, Pieces)
SELECT 3, PK_ProductID, '', 
  CASE 
    WHEN Products.ItemCategory = 'ERLA' OR Products.ItemCategory = 'LUMF' THEN Num * Pieces
    ELSE Num
  END
FROM
  Products
    INNER JOIN CommonCodes ON PK_ProductID = FK_ProductID AND Active = 1
    INNER JOIN EANCodes ON PK_ProductID = ProductID AND FK_EANTypeID = 2
    INNER JOIN tblBaseUOM ON CommonCode = CAST(CAST(Common AS int) AS varchar) AND UOM = 'LAY'

INSERT INTO EANCodes (FK_EANTypeID, ProductID, EANCode, Pieces)
SELECT 3, PK_ProductID, '', 1
FROM 
  Products
WHERE
  PK_ProductID NOT IN (
    SELECT ProductID FROM EANCodes WHERE FK_EANTypeID = 3)

INSERT INTO EANCodes (FK_EANTypeID, ProductID, EANCode, Pieces)
SELECT 4, PK_ProductID, '', 
  CASE 
    WHEN Products.ItemCategory = 'ERLA' OR Products.ItemCategory = 'LUMF' THEN Num * Pieces
    ELSE Num
  END
FROM
  Products
    INNER JOIN CommonCodes ON PK_ProductID = FK_ProductID AND Active = 1
    INNER JOIN EANCodes ON PK_ProductID = ProductID AND FK_EANTypeID = 2
    INNER JOIN tblBaseUOM ON CommonCode = CAST(CAST(Common AS int) AS varchar) AND UOM = 'PAL'

INSERT INTO EANCodes (FK_EANTypeID, ProductID, EANCode, Pieces)
SELECT 4, PK_ProductID, '', 1
FROM 
  Products
WHERE
  PK_ProductID NOT IN (
    SELECT ProductID FROM EANCodes WHERE FK_EANTypeID = 4)

INSERT INTO EANCodes (FK_EANTypeID, ProductID, EANCode, Pieces)
SELECT 5, PK_ProductID, '', 
  CASE
    WHEN Products.ItemCategory = 'ERLA' OR Products.ItemCategory = 'LUMF' THEN Pieces
    ELSE 1
  END 
FROM 
  Products
    INNER JOIN EANCodes ON PK_ProductID = ProductID AND FK_EANTypeID = 2

INSERT INTO EANCodes (FK_EANTypeID, ProductID, EANCode, Pieces)
SELECT 5, PK_ProductID, '', 1
FROM 
  Products
WHERE
  PK_ProductID NOT IN (
    SELECT ProductID FROM EANCodes WHERE FK_EANTypeID = 5)

/* Opdaterer Produkttype */
UPDATE P
SET
  FK_ProductTypeID =
    CASE 
      WHEN SumPallets.Pieces / SumCases.Pieces <= 4 THEN 2
      WHEN ItemCategory = 'ERLA' OR ItemCategory = 'LUMF' THEN 3
      WHEN ItemCategory = 'ZSAM' THEN 6
      ELSE 5
    END
FROM
  Products P
    INNER JOIN EANCodes SumPallets ON PK_ProductID = SumPallets.ProductID AND SumPallets.FK_EANTypeID = 4
    INNER JOIN EANCodes SumCases ON PK_ProductID = SumCases.ProductID AND SumCases.FK_EANTypeID = 2

/* Opdaterer Produkthieraki */
ALTER TABLE ProductHierarchies NOCHECK CONSTRAINT FK_ProductHierarchyDetails_ProductHierarchyDetails

DELETE
FROM ProductHierarchies
WHERE FK_ProductHierarchyParentID IN (
  SELECT PK_ProductHierarchyID FROM ProductHierarchies PH
    INNER JOIN ProductHierarchyLevels PHL ON PK_ProductHierarchyLevelID = FK_ProductHierarchyLevelID
    INNER JOIN ProductHierarchyNames PHN ON PK_ProductHierarchyNameID = FK_ProductHierarchyNameID
  WHERE PK_ProductHierarchyNameID IN (3, 4) AND PK_ProductHierarchyLevelID NOT IN (5, 11))

DELETE
FROM ProductHierarchies 
WHERE FK_ProductHierarchyLevelID IN (
SELECT PK_ProductHierarchyLevelID FROM ProductHierarchyNames PHN
  INNER JOIN ProductHierarchyLevels PHL ON PK_ProductHierarchyNameID = FK_ProductHierarchyNameID
WHERE PK_ProductHierarchyNameID IN (3, 4) AND PK_ProductHierarchyLevelID NOT IN (5, 11))

ALTER TABLE ProductHierarchies CHECK CONSTRAINT FK_ProductHierarchyDetails_ProductHierarchyDetails

INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, FK_ProductID, Node, Label, ShortName)
SELECT DISTINCT 6, PK_ProductHierarchyID, Null, TotalCompany, TotalCompanyText, Null
FROM tblBaseMaterial
  INNER JOIN ProductHierarchies ON FK_ProductHierarchyLevelID = 5
WHERE TotalCompany <> '00000000'

INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, FK_ProductID, Node, Label, ShortName)
SELECT DISTINCT 7, PK_ProductHierarchyID, Null, Market, MarketText, Null
FROM tblBaseMaterial
  INNER JOIN ProductHierarchies ON FK_ProductHierarchyLevelID = 6 AND Node = TotalCompany
WHERE Market <> '00000000'

INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, FK_ProductID, Node, Label, ShortName)
SELECT DISTINCT 8, PK_ProductHierarchyID, Null, EBF, EBFText, Null
FROM tblBaseMaterial
  INNER JOIN ProductHierarchies ON FK_ProductHierarchyLevelID = 7 AND Node = Market
WHERE EBF <> '00000000'

INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, FK_ProductID, Node, Label, ShortName)
SELECT DISTINCT 9, PK_ProductHierarchyID, Null, SPF, SPFText, Null
FROM tblBaseMaterial
  INNER JOIN ProductHierarchies ON FK_ProductHierarchyLevelID = 8 AND Node = EBF
WHERE SPF <> '00000000'

INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, FK_ProductID, Node, Label, ShortName)
SELECT DISTINCT 10, PK_ProductHierarchyID, Null, SPFV, SPFVText, Null
FROM tblBaseMaterial
  INNER JOIN ProductHierarchies ON FK_ProductHierarchyLevelID = 9 AND Node = SPF
WHERE SPFV <> '00000000'

INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, FK_ProductID, Node, Label, ShortName)
SELECT Null, PK_ProductHierarchyID, PK_ProductID, Null, Null, Null
FROM
  Products
    INNER JOIN CommonCodes ON PK_ProductID = FK_ProductID AND Active = 1
    INNER JOIN tblBaseMaterial ON CommonCode = CAST(CAST(Common AS int) AS varchar)
    INNER JOIN ProductHierarchies ON SPFV = Node AND FK_ProductHierarchyLevelID = 10

INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, FK_ProductID, Node, Label, ShortName)
SELECT DISTINCT 12, PK_ProductHierarchyID, Null, LocalBrand, LocalBrandText, Null
FROM tblBaseMaterial
  INNER JOIN ProductHierarchies ON FK_ProductHierarchyLevelID = 11
WHERE LocalBrand <> '00000000'

INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, FK_ProductID, Node, Label, ShortName)
SELECT DISTINCT 13, PK_ProductHierarchyID, Null, EBF, EBFText, Null
FROM tblBaseMaterial
  INNER JOIN ProductHierarchies ON FK_ProductHierarchyLevelID = 12 AND Node = LocalBrand
WHERE EBF <> '00000000'

INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, FK_ProductID, Node, Label, ShortName)
SELECT DISTINCT 14, PK_ProductHierarchyID, Null, SPF, SPFText, Null
FROM tblBaseMaterial
  INNER JOIN ProductHierarchies ON FK_ProductHierarchyLevelID = 13 AND Node = EBF
WHERE SPF <> '00000000'

INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, FK_ProductID, Node, Label, ShortName)
SELECT DISTINCT 15, PK_ProductHierarchyID, Null, SPFV, SPFVText, Null
FROM tblBaseMaterial
  INNER JOIN ProductHierarchies ON FK_ProductHierarchyLevelID = 14 AND Node = SPF
WHERE SPFV <> '00000000'

INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, FK_ProductID, Node, Label, ShortName)
SELECT Null, PK_ProductHierarchyID, PK_ProductID, Null, Null, Null
FROM
  Products
    INNER JOIN CommonCodes ON PK_ProductID = FK_ProductID AND Active = 1
    INNER JOIN tblBaseMaterial ON CommonCode = CAST(CAST(Common AS int) AS varchar)
    INNER JOIN ProductHierarchies ON SPFV = Node AND FK_ProductHierarchyLevelID = 15


INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, FK_ProductID, Node, Label, ShortName)
SELECT DISTINCT 17, PK_ProductHierarchyID, Null, TotalCompany, TotalCompanyText, Null
FROM tblBaseMaterial
  INNER JOIN ProductHierarchies ON FK_ProductHierarchyLevelID = 16
WHERE TotalCompany <> '00000000' AND
  TotalCompany NOT IN (SELECT Node FROM ProductHierarchies WHERE FK_ProductHierarchyLevelID = 17)


INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, FK_ProductID, Node, Label, ShortName)
SELECT DISTINCT 18, PH1.PK_ProductHierarchyID, Null, Market, MarketText, Null
FROM tblBaseMaterial
  INNER JOIN ProductHierarchies PH1 ON PH1.Node = TotalCompany
  LEFT JOIN ProductHierarchies PH2 ON PH2.Node = Market AND PH2.FK_ProductHierarchyLevelID = 18
WHERE Market <> '00000000' AND PH1.FK_ProductHierarchyLevelID = 17 AND PH2.PK_ProductHierarchyID IS Null

/*
INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, FK_ProductID, Node, Label, ShortName)
SELECT 18, Max(PK_ProductHierarchyID), Null, MaterialGroup, MaterialGroupText, Null
FROM (
  SELECT PK_ProductHierarchyID, Header.MaterialGroup, Header.MaterialGroupText
  FROM tblBaseMaterial Header
    INNER JOIN tblBaseBOM ON Header = Header.Common
    INNER JOIN tblBaseMaterial Component ON Component = Component.Common
    INNER JOIN ProductHierarchies ON Component.TotalCompany = Node AND FK_ProductHierarchyLevelID = 17
  WHERE Component.TotalCompany <> '00000000'
  UNION SELECT PK_ProductHierarchyID, MaterialGroup, MaterialGroupText
  FROM tblBaseMaterial
    INNER JOIN ProductHierarchies ON TotalCompany = Node AND FK_ProductHierarchyLevelID = 17
  WHERE TotalCompany <> '00000000') AS SubQ
WHERE MaterialGroup NOT IN (SELECT Node FROM ProductHierarchies WHERE FK_ProductHierarchyLevelID = 18)
GROUP BY MaterialGroup, MaterialGroupText
*/

DELETE
FROM ProductHierarchies
WHERE FK_ProductHierarchyParentID IN (
  SELECT PK_ProductHierarchyID
  FROM ProductHierarchies
  WHERE FK_ProductHierarchyLevelID = 18)

INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, FK_ProductID, Node, Label, ShortName)
SELECT DISTINCT Null, MIN(PK_ProductHierarchyID), Header.PK_ProductID, Null, Null, Null
FROM tblBaseMaterial BaseHeader
  INNER JOIN Products Header ON BaseHeader.TCode = Header.ProductCode
  INNER JOIN BillOfMaterials ON Header.PK_ProductID = FK_HeaderProductID
  INNER JOIN BillOfMaterialLines ON PK_BillOfMaterialID = FK_BillOfMaterialID
  INNER JOIN Products Comp ON Comp.PK_ProductID = FK_ComponentProductID
  INNER JOIN tblBaseMaterial BaseComp ON BaseComp.TCode = Comp.ProductCode
  INNER JOIN ProductHierarchies PH1 ON PH1.Node = BaseComp.Market AND FK_ProductHierarchyLevelID = 18
WHERE BaseHeader.ItemCategory IN ('LUMF', 'ERLA') --AND Header.ProductCode = 'T310510'
GROUP BY Header.PK_ProductID
UNION
SELECT DISTINCT Null, PK_ProductHierarchyID, PK_ProductID, Null, Null, Null
FROM tblBaseMaterial
  INNER JOIN Products ON TCode = ProductCode
  INNER JOIN ProductHierarchies PH1 ON PH1.Node = Market
WHERE FK_ProductHierarchyLevelID = 18


/*
INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, FK_ProductID, Node, Label, ShortName)
SELECT Null, PK_ProductHierarchyID, PK_ProductID, Null, Null, Null
FROM
  Products
    INNER JOIN CommonCodes ON PK_ProductID = FK_ProductID AND Active = 1
    INNER JOIN tblBaseMaterial ON CommonCode = CAST(CAST(Common AS int) AS varchar)
    INNER JOIN ProductHierarchies ON MaterialGroup = Node AND FK_ProductHierarchyLevelID = 18
*/
COMMIT TRANSACTION





