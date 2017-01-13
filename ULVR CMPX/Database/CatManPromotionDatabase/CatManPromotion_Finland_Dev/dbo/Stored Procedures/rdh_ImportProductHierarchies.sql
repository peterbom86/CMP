-- 2007-02-15 PO
-- 2007-07-19 PO NODE_PRICING skal være 12 cifret

CREATE   PROCEDURE rdh_ImportProductHierarchies

AS

INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, Node, Label)
SELECT DISTINCT 20, PH1.PK_ProductHierarchyID, NODE_GROUP, NODE_GROUP + '_'
FROM OPENQUERY(LDWH_DK, 'SELECT * FROM CMP_PRODUCTS')
  LEFT JOIN ProductHierarchies PH2 ON PH2.Node = NODE_Group COLLATE Danish_Norwegian_CI_AS AND PH2.FK_ProductHierarchyLevelID = 20
  INNER JOIN ProductHierarchies PH1 ON PH1.FK_ProductHierarchyLevelID = 19
WHERE NODE_GROUP IS NOT Null AND PH2.Node IS Null

INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, Node, Label)
SELECT DISTINCT 21, PH1.PK_ProductHierarchyID, LEFT(NODE_PRICING, 4), NODE_GROUP + '_' + LEFT(NODE_PRICING, 4)
FROM OPENQUERY(LDWH_DK, 'SELECT * FROM CMP_PRODUCTS')
  LEFT JOIN ProductHierarchies PH2 ON Node = LEFT(NODE_PRICING, 4) COLLATE Danish_Norwegian_CI_AS AND 
    LEFT(PH2.Label, 2) = NODE_GROUP COLLATE Danish_Norwegian_CI_AS AND PH2.FK_ProductHierarchyLevelID = 21 
  INNER JOIN ProductHierarchies PH1 ON PH1.Node = NODE_GROUP COLLATE Danish_Norwegian_CI_AS
WHERE NODE_PRICING IS NOT null AND LEN(NODE_PRICING) = 12 AND PH2.Node IS Null

INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, Node, Label)
SELECT DISTINCT 22, PH1.PK_ProductHierarchyID, LEFT(NODE_PRICING, 8), NODE_GROUP + '_' + LEFT(NODE_PRICING, 8)
FROM OPENQUERY(LDWH_DK, 'SELECT * FROM CMP_PRODUCTS')
  LEFT JOIN ProductHierarchies PH2 ON Node = LEFT(NODE_PRICING, 8) COLLATE Danish_Norwegian_CI_AS AND 
    LEFT(PH2.Label, 2) = NODE_GROUP COLLATE Danish_Norwegian_CI_AS AND PH2.FK_ProductHierarchyLevelID = 22 
  INNER JOIN ProductHierarchies PH1 ON PH1.Node = LEFT(NODE_PRICING, 4) COLLATE Danish_Norwegian_CI_AS AND
    LEFT(PH1.Label, 2) = NODE_GROUP COLLATE Danish_Norwegian_CI_AS
WHERE NODE_PRICING IS NOT null AND LEN(NODE_PRICING) = 12 AND PH2.Node IS Null

INSERT INTO ProductHierarchies (FK_ProductHierarchyLevelID, FK_ProductHierarchyParentID, Node, Label)
SELECT DISTINCT 23, PH1.PK_ProductHierarchyID, NODE_PRICING, NODE_GROUP + '_' + NODE_PRICING
FROM OPENQUERY(LDWH_DK, 'SELECT * FROM CMP_PRODUCTS')
  LEFT JOIN ProductHierarchies PH2 ON Node = NODE_PRICING COLLATE Danish_Norwegian_CI_AS AND 
    LEFT(PH2.Label, 2) = NODE_GROUP COLLATE Danish_Norwegian_CI_AS AND PH2.FK_ProductHierarchyLevelID = 23
  INNER JOIN ProductHierarchies PH1 ON PH1.Node = LEFT(NODE_PRICING, 8) COLLATE Danish_Norwegian_CI_AS AND
    LEFT(PH1.Label, 2) = NODE_GROUP COLLATE Danish_Norwegian_CI_AS
WHERE NODE_PRICING IS NOT null AND LEN(NODE_PRICING) = 12 AND PH2.Node IS Null

UPDATE PH1
SET FK_ProductHierarchyParentID = PH3.PK_ProductHierarchyID
FROM OPENQUERY(LDWH_DK, 'SELECT * FROM CMP_PRODUCTS') BWProducts
  INNER JOIN Products ON Products.ProductCode = BWProducts.PRODUCTCODE COLLATE Danish_Norwegian_CI_AS
  INNER JOIN ProductHierarchies PH1 ON PK_ProductID = PH1.FK_ProductID
  INNER JOIN ProductHierarchies PH2 ON PH1.FK_ProductHierarchyParentID = PH2.PK_ProductHierarchyID AND
    PH2.FK_ProductHierarchyLevelID = 23
  INNER JOIN ProductHierarchies PH3 ON PH3.Node = NODE_PRICING COLLATE Danish_Norwegian_CI_AS AND
    LEFT(PH3.Label, 2) = NODE_GROUP COLLATE Danish_Norwegian_CI_AS
WHERE PH2.PK_ProductHierarchyID <> PH3.PK_ProductHierarchyID

INSERT INTO ProductHierarchies (FK_ProductHierarchyParentID, FK_ProductID)
SELECT PH2.PK_ProductHierarchyID, PK_ProductID
FROM OPENQUERY(LDWH_DK, 'SELECT * FROM CMP_PRODUCTS') BWProducts
  INNER JOIN Products ON Products.ProductCode = BWProducts.PRODUCTCODE COLLATE Danish_Norwegian_CI_AS
  LEFT JOIN (
    SELECT PH2.PK_ProductHierarchyID, PH1.FK_ProductID FROM ProductHierarchies PH1 
      INNER JOIN ProductHierarchies PH2 ON PH1.FK_ProductHierarchyParentID = PH2.PK_ProductHierarchyID AND
        PH2.FK_ProductHierarchyLevelID = 23) PH1 ON PK_ProductID = PH1.FK_ProductID
  INNER JOIN ProductHierarchies PH2 ON PH2.Node = NODE_PRICING COLLATE Danish_Norwegian_CI_AS AND
    LEFT(PH2.Label, 2) = NODE_GROUP COLLATE Danish_Norwegian_CI_AS
WHERE PH1.FK_ProductID IS Null



