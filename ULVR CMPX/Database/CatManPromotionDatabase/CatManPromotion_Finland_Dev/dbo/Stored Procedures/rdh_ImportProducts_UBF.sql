CREATE   PROCEDURE rdh_ImportProducts_UBF

AS

INSERT INTO Products (ProductCode, Label, FK_ProductStatusID, PiecesPerConsumerUnit, FK_ProductTypeID, ItemCategory, Volume, Weight, 
  ProductChange, IsMixedGoods)
SELECT ProductsBW.ProductCode, ProductsBW.Label, 0, 1, 
  CASE ProductsBW.ITEMCATEGORY
    WHEN 'ZNOR' THEN 5
    ELSE CASE
      WHEN CAST(PIECES_PAL AS float) / CAST(PIECES_ZCU AS float) <= 4 THEN 2
      ELSE 3
    END
  END, ProductsBW.ITEMCATEGORY, ISNULL(ProductsBW.Volume, '0'), ProductsBW.Weight, '*', 
  CASE ProductsBW.ITEMCATEGORY
    WHEN 'Z5BM' THEN 1
    ELSE 0
  END
FROM OPENQUERY(LDWH_DK, 'SELECT * FROM CMP_PRODUCTS') ProductsBW
WHERE ProductCode COLLATE Danish_Norwegian_CI_AS NOT IN (
    SELECT ProductCode FROM Products) AND
  NODE_GROUP IN ('68', '69')

INSERT INTO CommonCodes (FK_ProductID, CommonCode, TCode, Active)
SELECT PK_ProductID, ProductCode, ProductCode, 1
FROM Products
WHERE PK_ProductID NOT IN (SELECT FK_ProductID FROM CommonCodes)

UPDATE P 
SET Label = ProductsBW.Label
FROM Products P
  INNER JOIN OPENQUERY(LDWH_DK, 'SELECT * FROM CMP_PRODUCTS') ProductsBW ON P.ProductCode = ProductsBW.ProductCode COLLATE Danish_Norwegian_CI_AS
WHERE P.FK_ProductStatusID = 0

UPDATE P
SET Weight = ProductsBW.Weight,
  ItemCategory = ProductsBW.ItemCategory
FROM Products P
  INNER JOIN OPENQUERY(LDWH_DK, 'SELECT * FROM CMP_PRODUCTS') ProductsBW ON P.ProductCode = ProductsBW.ProductCode COLLATE Danish_Norwegian_CI_AS

UPDATE Products
SET FK_ProductStatusID = 6
WHERE ProductCode NOT IN (SELECT ProductCode COLLATE Danish_Norwegian_CI_AS FROM OPENQUERY(LDWH_DK, 'SELECT * FROM CMP_PRODUCTS') WHERE NODE_GROUP IN ('68', '69'))
  AND FK_ProductStatusID <> 0

UPDATE Products
SET FK_ProductStatusID = 2
WHERE ProductCode IN (SELECT ProductCode COLLATE Danish_Norwegian_CI_AS FROM OPENQUERY(LDWH_DK, 'SELECT * FROM CMP_PRODUCTS') WHERE NODE_GROUP IN ('68', '69'))
  AND FK_ProductStatusID = 6

UPDATE Products
SET IsMixedGoods =
  CASE ItemCategory
    WHEN 'ZNOR' THEN 0
    WHEN 'Z5BM' THEN 1
  END
WHERE ItemCategory IN ('ZNOR', 'Z5BM')

INSERT INTO EANCodes (FK_EANTypeID, ProductID, EANCode, Pieces)
SELECT PK_EANTypeID, PK_ProductID, 
  CASE PK_EANTypeID
    WHEN 1 THEN ISNULL(EANCODE_ZCU, '')
    WHEN 2 THEN ISNULL(EANCODE_ZUN, '')
    WHEN 3 THEN ''
    WHEN 4 THEN ''
    WHEN 5 THEN ''
    ELSE ''
  END, 
  CASE PK_EANTypeID
    WHEN 1 THEN 1
    WHEN 2 THEN ISNULL(PIECES_ZCU, 1)
    WHEN 3 THEN ISNULL(PIECES_ZLA, ISNULL(PIECES_PAL, ISNULL(PIECES_ZCU, 1)))
    WHEN 4 THEN ISNULL(PIECES_PAL, ISNULL(PIECES_ZCU, 1))
    WHEN 5 THEN ISNULL(PIECES_ZCU, 1)
    ELSE 0
  END
FROM Products P
  INNER JOIN OPENQUERY(LDWH_DK, 'SELECT * FROM CMP_PRODUCTS') ProductsBW ON P.ProductCode = ProductsBW.ProductCode COLLATE Danish_Norwegian_CI_AS, 
    EANTypes
WHERE NOT EXISTS (SELECT * FROM EANCodes WHERE PK_ProductID = ProductID AND PK_EANTypeID = FK_EANTypeID)

UPDATE EAN
SET EANCode = 
  CASE FK_EANTypeID
    WHEN 1 THEN ISNULL(EANCODE_ZCU, '')
    WHEN 2 THEN ISNULL(EANCODE_ZUN, '')
    WHEN 3 THEN ''
    WHEN 4 THEN ''
    WHEN 5 THEN ''
    ELSE ''
  END, 
  Pieces = 
  CASE FK_EANTypeID
    WHEN 1 THEN 1
    WHEN 2 THEN ISNULL(PIECES_ZCU, 1)
    WHEN 3 THEN ISNULL(PIECES_ZLA, ISNULL(PIECES_PAL, ISNULL(PIECES_ZCU, 1)))
    WHEN 4 THEN ISNULL(PIECES_PAL, ISNULL(PIECES_ZCU, 1))
    WHEN 5 THEN ISNULL(PIECES_ZCU, 1)
    ELSE 0
  END
FROM EANCodes EAN
  INNER JOIN Products P ON PK_ProductID = ProductID
  INNER JOIN OPENQUERY(LDWH_DK, 'SELECT * FROM CMP_PRODUCTS') ProductsBW ON P.ProductCode = ProductsBW.ProductCode COLLATE Danish_Norwegian_CI_AS
WHERE
  EANCode <>
  CASE FK_EANTypeID
    WHEN 1 THEN ISNULL(EANCODE_ZCU, '')
    WHEN 2 THEN ISNULL(EANCODE_ZUN, '')
    WHEN 3 THEN ''
    WHEN 4 THEN ''
    WHEN 5 THEN ''
    ELSE ''
  END COLLATE Danish_Norwegian_CI_AS OR 
  Pieces <> 
  CASE FK_EANTypeID
    WHEN 1 THEN 1    WHEN 2 THEN ISNULL(PIECES_ZCU, 1)
    WHEN 3 THEN ISNULL(PIECES_ZLA, ISNULL(PIECES_PAL, ISNULL(PIECES_ZCU, 1)))
    WHEN 4 THEN ISNULL(PIECES_PAL, ISNULL(PIECES_ZCU, 1))
    WHEN 5 THEN ISNULL(PIECES_ZCU, 1)
    ELSE 0
  END 



