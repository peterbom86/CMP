CREATE PROCEDURE [dbo].rdh_ExcelBaseDiscountCheckerKassevarer 
  @ProductID varchar(50),
  @ParticipatorID int,
  @Period datetime

AS

SELECT BaseDiscountTypes.Label BaseDiscountType, Products.ProductCode, Products.Label ProductName, PH.Node PHNode, PH.Label PHName, PH.Level PHLevel, 
  Participators.Label Chain, CH.Node CHNode, CH.Label CHName, CH.LEVEL CHLevel, Value Discount, BaseDiscountsEdit.PeriodFrom, BaseDiscountsEdit.PeriodTo,
  BaseDiscountsEdit.FK_FileImportID FileImportID
FROM BaseDiscountsEdit
  INNER JOIN 
(SELECT PK_ProductID ProductID, ProductCode, PH1.PK_ProductHierarchyID PH1ProductHierarchyID, PH2.PK_ProductHierarchyID PH2ProductHierarchyID, 
  PH3.PK_ProductHierarchyID PH3ProductHierarchyID, PH4.PK_ProductHierarchyID PH4ProductHierarchyID, 
  PH5.PK_ProductHierarchyID PH5ProductHierarchyID, PH6.PK_ProductHierarchyID PH6ProductHierarchyID
FROM Products
  INNER JOIN ProductHierarchies PH1 ON PK_ProductID = PH1.FK_ProductID
  INNER JOIN ProductHierarchies PH2 ON PH1.FK_ProductHierarchyParentID = PH2.PK_ProductHierarchyID
  INNER JOIN ProductHierarchies PH3 ON PH2.FK_ProductHierarchyParentID = PH3.PK_ProductHierarchyID
  INNER JOIN ProductHierarchies PH4 ON PH3.FK_ProductHierarchyParentID = PH4.PK_ProductHierarchyID
  INNER JOIN ProductHierarchies PH5 ON PH4.FK_ProductHierarchyParentID = PH5.PK_ProductHierarchyID
  INNER JOIN ProductHierarchies PH6 ON PH5.FK_ProductHierarchyParentID = PH6.PK_ProductHierarchyID 
  INNER JOIN ProductHierarchyLevels PL6 ON PH6.FK_ProductHierarchyLevelID = PL6.PK_ProductHierarchyLevelID
  INNER JOIN ProductHierarchyNames PN6 ON PL6.FK_ProductHierarchyNameID = PN6.PK_ProductHierarchyNameID WHERE IsPricingHierarchy = 1) ProductHierarchies
    ON PH6ProductHierarchyID = FK_ProductHierarchyID OR
      PH5ProductHierarchyID = FK_ProductHierarchyID OR
      PH4ProductHierarchyID = FK_ProductHierarchyID OR
      PH3ProductHierarchyID = FK_ProductHierarchyID OR
      PH2ProductHierarchyID = FK_ProductHierarchyID OR
      PH1ProductHierarchyID = FK_ProductHierarchyID OR
      ProductID = FK_ProductID
  LEFT JOIN Products ON BaseDiscountsEdit.FK_ProductID = Products.PK_ProductID
  LEFT JOIN (SELECT PK_ProductHierarchyID, PH.Node, PH.Label, PK_ProductHierarchyLevelID, PL.Label Level FROM ProductHierarchies PH
    INNER JOIN ProductHierarchyLevels PL ON PK_ProductHIerarchyLevelID = FK_ProductHierarchyLevelID) PH ON BaseDiscountsEdit.FK_ProductHierarchyID = PH.PK_ProductHierarchyID
  INNER JOIN 
(SELECT CH1.FK_ParticipatorID ParticipatorID, CH1.PK_CustomerHierarchyID CH1CustomerHierarchyID, CH2.PK_CustomerHierarchyID CH2CustomerHierarchyID, 
  CH3.PK_CustomerHierarchyID CH3CustomerHierarchyID, CH4.PK_CustomerHierarchyID CH4CustomerHierarchyID, 
  CH5.PK_CustomerHierarchyID CH5CustomerHierarchyID, CH6.PK_CustomerHierarchyID CH6CustomerHierarchyID, 
  CH7.PK_CustomerHierarchyID CH7CustomerHierarchyID, CH8.PK_CustomerHierarchyID CH8CustomerHierarchyID
FROM Participators
  INNER JOIN CustomerHierarchies CH1 ON PK_ParticipatorID = CH1.FK_ParticipatorID
  INNER JOIN CustomerHierarchies CH2 ON CH1.FK_CustomerHierarchyParentID = CH2.PK_CustomerHierarchyID
  INNER JOIN CustomerHierarchies CH3 ON CH2.FK_CustomerHierarchyParentID = CH3.PK_CustomerHierarchyID
  INNER JOIN CustomerHierarchies CH4 ON CH3.FK_CustomerHierarchyParentID = CH4.PK_CustomerHierarchyID
  INNER JOIN CustomerHierarchies CH5 ON CH4.FK_CustomerHierarchyParentID = CH5.PK_CustomerHierarchyID
  INNER JOIN CustomerHierarchies CH6 ON CH5.FK_CustomerHierarchyParentID = CH6.PK_CustomerHierarchyID
  INNER JOIN CustomerHierarchies CH7 ON CH6.FK_CustomerHierarchyParentID = CH7.PK_CustomerHierarchyID
  INNER JOIN CustomerHierarchies CH8 ON CH7.FK_CustomerHierarchyParentID = CH8.PK_CustomerHierarchyID) CustomerHierarchies
    ON CH8CustomerHierarchyID = FK_CustomerHierarchyID OR
      CH7CustomerHierarchyID = FK_CustomerHierarchyID OR
      CH6CustomerHierarchyID = FK_CustomerHierarchyID OR
      CH5CustomerHierarchyID = FK_CustomerHierarchyID OR
      CH4CustomerHierarchyID = FK_CustomerHierarchyID OR
      CH3CustomerHierarchyID = FK_CustomerHierarchyID OR
      CH2CustomerHierarchyID = FK_CustomerHierarchyID OR
      CH1CustomerHierarchyID = FK_CustomerHierarchyID OR
      ParticipatorID = FK_ParticipatorID
  LEFT JOIN Participators ON BaseDiscountsEdit.FK_ParticipatorID = Participators.PK_ParticipatorID
  LEFT JOIN (SELECT PK_CustomerHierarchyID, CH.Node, CH.Label, PK_CustomerHierarchyLevelID, CL.Label Level FROM CustomerHierarchies CH
    INNER JOIN CustomerHierarchyLevels CL ON PK_CustomerHIerarchyLevelID = FK_CustomerHierarchyLevelID) CH ON BaseDiscountsEdit.FK_CustomerHierarchyID = CH.PK_CustomerHierarchyID
  INNER JOIN BaseDiscountTypes ON PK_BaseDiscountTypeID = FK_BaseDiscountTypeID
WHERE ParticipatorID = @ParticipatorID AND ProductHierarchies.ProductID = @ProductID
  AND BaseDiscountsEdit.PeriodFrom <= @Period AND BaseDiscountsEdit.PeriodTo >= @Period
ORDER BY PK_BaseDiscountTypeID, ISNULL(PK_CustomerHierarchyLevelID, 999999999), ISNULL(PK_ProductHierarchyLevelID, 999999999)


