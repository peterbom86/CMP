CREATE PROCEDURE rdh_GetAllBaseDiscounts

AS

SELECT
  COALESCE(PK_CustomerHierarchyID, PK_ParticipatorID, -1) CustomerID, 
  ISNULL(CustomerHierarchyLevelName, CASE ISNULL(PK_ParticipatorID, -1) WHEN -1 THEN 'Alle Kunder' ELSE 'Kæde' END) CustomerLevelName,
  COALESCE(CustomerHierarchyNode, PK_ParticipatorID, '-1') CustomerNode, 
  COALESCE(CustomerHierarchyName, Participators.Label, 'Alle kunder') CustomerName,
  COALESCE(PK_ProductHierarchyID, PK_ProductID, -1) ProductID, 
  ISNULL(ProductHierarchyLevelName, CASE ISNULL(PK_ProductID, -1) WHEN -1 THEN 'Alle Produkter' ELSE 'Produkt' END) ProductLevelName,
  COALESCE(ProductHierarchyNode, ProductCode, '-1') ProductNode, 
  COALESCE(ProductHierarchyName, Products.Label, 'Alle kunder') ProductName,
  BaseDiscountTypes.Label BaseDiscountType, Value, BaseDiscountsEdit.PeriodFrom, BaseDiscountsEdit.PeriodTo FROM BaseDiscountsEdit
  LEFT JOIN (
    SELECT PK_CustomerHierarchyLevelID, CustomerHierarchyLevels.Label CustomerHierarchyLevelName, PK_CustomerHierarchyID, 
      CustomerHierarchies.Node CustomerHierarchyNode, CustomerHierarchies.Label CustomerHierarchyName
    FROM CustomerHierarchies 
      INNER JOIN CustomerHierarchyLevels ON PK_CustomerHierarchyLevelID = FK_CustomerHierarchyLevelID
    ) CustomerHierarchy ON PK_CustomerHierarchyID = FK_CustomerHierarchyID
  LEFT JOIN Participators ON PK_ParticipatorID = FK_ParticipatorID
  LEFT JOIN (
    SELECT PK_ProductHierarchyLevelID, ProductHierarchyLevels.Label ProductHierarchyLevelName, PK_ProductHierarchyID, 
      ProductHierarchies.Node ProductHierarchyNode, ProductHierarchies.Label ProductHierarchyName
    FROM ProductHierarchies 
      INNER JOIN ProductHierarchyLevels ON PK_ProductHierarchyLevelID = FK_ProductHierarchyLevelID
    ) ProductHierarchy ON PK_ProductHierarchyID = FK_ProductHierarchyID
  LEFT JOIN Products ON PK_ProductID = FK_ProductID
  INNER JOIN BaseDiscountTypes ON PK_BaseDiscountTypeID = FK_BaseDiscountTypeID
