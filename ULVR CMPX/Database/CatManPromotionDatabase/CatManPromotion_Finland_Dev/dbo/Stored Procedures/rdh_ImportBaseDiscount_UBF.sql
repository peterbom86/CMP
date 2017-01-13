CREATE    PROCEDURE rdh_ImportBaseDiscount_UBF

AS

BEGIN TRANSACTION
DELETE FROM BaseDiscountsEdit WHERE FK_BaseDiscountTypeID BETWEEN 10 AND 20

INSERT INTO BaseDiscountsEdit (FK_ParticipatorID, FK_CustomerHierarchyID, FK_ProductID, FK_ProductHierarchyID, FK_PriceBaseID, FK_BaseDiscountTypeID, Value,
  FK_ValueTypeID, FK_VolumeBaseID, OnInvoice, PeriodFrom, PeriodTo)
SELECT Null, PK_CustomerHierarchyID, PK_ProductID, CASE ISNULL(PK_ProductID, -1) WHEN -1 THEN PH.PK_ProductHierarchyID ELSE Null END, 
  1, PK_BaseDiscountTypeID, -CAST(REPLACE(REPLACE(Rate, '.', ''), ',', '.') AS float) / 100.0, 1, 1, 1, CONVERT(Datetime, ValidOn, 104), CONVERT(Datetime, ValidTo, 104)
--  Products.PK_ProductHierarchyID, PH.PK_ProductHierarchyID, ISNULL(Products.PK_ProductHierarchyID, PH.PK_ProductHierarchyID), *
FROM tblUploadBaseDiscount_UBF
  INNER JOIN (
    SELECT PK_CustomerHierarchyID, CH.Node
    FROM CustomerHierarchies CH
    INNER JOIN (
      SELECT Min(FK_CustomerHierarchyLevelID) MinCustomerHierarchyLevelID, CH.Node
      FROM CustomerHierarchies CH
        INNER JOIN CustomerHierarchyLevels ON PK_CustomerHierarchyLevelID = FK_CustomerHierarchyLevelID
      GROUP BY CH.Node) SubQ ON CH.Node = SubQ.Node AND FK_CustomerHierarchyLevelID = MinCustomerHierarchyLevelID) SubQ ON Customer = Node
  LEFT JOIN (    
    SELECT PK_ProductID, ProductCode, LEFT(PH2.Label, 2) Prefix, PH1.PK_ProductHierarchyID
    FROM ProductHierarchies PH1
    INNER JOIN ProductHierarchies PH2 ON PH2.PK_ProductHierarchyID = PH1.FK_ProductHierarchyParentID
    INNER JOIN Products ON PK_ProductID = PH1.FK_ProductID
    WHERE PH2.FK_ProductHierarchyLevelID = 23) Products ON Material = ProductCode AND ISNULL(MG, Products.Prefix) = Products.Prefix
  INNER JOIN BaseDiscountTypes BDT ON ConditionType = LEFT(RIGHT(BDT.Label, 5), 4)
  LEFT JOIN (
    SELECT PK_ProductHierarchyID, PH.Node, PH.Label, LEFT(PH.Label, 2) Prefix
    FROM ProductHierarchyLevels
    INNER JOIN ProductHierarchies PH ON PK_ProductHierarchyLevelID = FK_ProductHierarchyLevelID
    WHERE FK_ProductHierarchyNameID = 6) PH ON ISNULL(MG, PH.Prefix) = PH.Prefix AND
      ISNULL(MainGroup, MG) + ISNULL(REPLICATE('0', 4 - LEN([Group])) + [Group], '') + ISNULL(REPLICATE('0', 4 - LEN([SubGroup])) + [SubGroup], '') = PH.Node AND Material IS Null
WHERE Rate IS NOT Null AND ISNULL(Products.PK_ProductHierarchyID, PH.PK_ProductHierarchyID) IS NOT Null -- AND BDT.Label IS Null--AND Node IS Null
COMMIT TRANSACTION



