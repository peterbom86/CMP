CREATE PROC dbo.rdh_ImportCommonCodeChanges

AS

--DROP TABLE #tempProductList
-- Master Data procedure
CREATE TABLE #tempProductList (
  CommonCode nvarchar(20) PRIMARY KEY,
  ProductCode nvarchar(50),
  CommonCodeExists BIT,
  ProductCodeIsNew BIT,
  ProductCodeExists BIT,
  ZeroCommonCodesOnOld BIT,
  OneCommonCodeOnNew BIT,
  ValidityOrder INT,
  MinValidityOrder INT,
  MaxCommonCode NVARCHAR(20),
  IsInAssortment BIT,
  MaxIsInAssortment bit  )

INSERT INTO #tempProductList ( CommonCode, ProductCode )
SELECT CAST(smtl.Material AS BIGINT) CommonCode,
  CASE 
	WHEN ISNULL(sctlCCode.Value2, '') <> '' AND sctlCCode.Value2 <> '?' THEN sctlCCode.Value2
    WHEN ISNULL(NoTCode, 0) = 1 THEN CAST(CAST(smtl.Material AS BIGINT) AS NVARCHAR)
    WHEN ISNULL(sctl.Value2, '') <> '' AND sctl.Value2 <> '?' THEN sctl.Value2
-- Removed the leading zeros according to mail from Andrea - po 2012-10-22
/*    WHEN ISNULL(ShortEAN, '') <> '' AND NodeGroup IN ('12', '6G', '6H', '6I', '6U') THEN 
       REPLICATE('0', 5 - 
         CASE WHEN LEN(CAST(CAST(ShortEAN AS BIGINT) AS NVARCHAR)) > 5 
              THEN 5 
              ELSE LEN(CAST(CAST(ShortEAN AS BIGINT) AS NVARCHAR)) END )
         + CAST(CAST(ShortEAN AS BIGINT) AS NVARCHAR)*/
	WHEN ISNULL(ShortEAN, '') <> '' AND NodeGroup IN ('12', '6G', '6H', '6I', '6U') THEN 
		CAST(CAST(ShortEAN AS BIGINT) AS NVARCHAR)
    ELSE CAST(CAST(smtl.Material AS BIGINT) AS NVARCHAR)
  END ProductCode
FROM SAP_MATINFO_TotalList AS smtl
  LEFT JOIN dbo.SAP_Characteristics_TotalList as sctlCCode ON sctlCCode.Material = smtl.Material AND sctlCCode.Name = 'Z_CCODEND'
  LEFT JOIN SAP_Characteristics_TotalList AS sctl ON sctl.Material = smtl.Material AND sctl.Name = 'Z3_TCODE'
  LEFT JOIN SAP_ManualLoadCorrections AS smlc ON CAST(smtl.Material AS BIGINT) = smlc.MATERIAL
WHERE NodeGroup <> '' AND ItemCategory IN ('ZNOR', 'Z5BM') AND
  smtl.Material IN ( SELECT Material FROM SAP_PriceHierarchy_TotalList AS sphtl WHERE Name = 'PROD_HIER' AND Key1 <> '' AND Key2 <> '' AND Key3 <> '' ) AND
  smtl.Material IN ( SELECT Material FROM SAP_UOM_TotalList AS sutl ) 

UPDATE tpl
SET CommonCodeExists = CASE WHEN cc.CommonCode IS NULL THEN 0 ELSE 1 END
FROM #tempProductList AS tpl
  LEFT JOIN CommonCodes AS cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI

UPDATE tpl
SET ProductCodeIsNew = CASE WHEN PK_ProductID IS NULL THEN 1 
                            WHEN tpl.ProductCode <> p.ProductCode COLLATE Danish_Norwegian_CI_AI THEN 1
                            ELSE 0 END
FROM #tempProductList AS tpl
  LEFT JOIN CommonCodes AS cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
  LEFT JOIN Products AS p ON cc.FK_ProductID = p.PK_ProductID

UPDATE tpl
SET ProductCodeExists = CASE WHEN PK_ProductID IS NULL THEN 0 ELSE 1 END
FROM #tempProductList AS tpl
  LEFT JOIN Products AS p ON tpl.ProductCode = p.ProductCode COLLATE Danish_Norwegian_CI_AI


UPDATE tpl
SET ZeroCommonCodesOnOld = CASE WHEN number IS NULL THEN 1 ELSE 0 END
FROM #tempProductList AS tpl
  LEFT JOIN CommonCodes AS cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
  LEFT JOIN Products AS p ON cc.FK_ProductID = p.PK_ProductID
  LEFT JOIN ( SELECT ProductCode, COUNT(*) AS number FROM #tempProductList AS tpl2 GROUP BY ProductCode ) SubQ ON p.ProductCode COLLATE Danish_Norwegian_CI_AI = SubQ.ProductCode

UPDATE tpl
SET OneCommonCodeOnNew = CASE WHEN number = 1 THEN 1 ELSE 0 END
FROM #tempProductList AS tpl
  LEFT JOIN ( SELECT ProductCode, COUNT(*) AS number FROM #tempProductList AS tpl2 GROUP BY ProductCode ) SubQ ON tpl.ProductCode = SubQ.ProductCode

UPDATE tpl
SET IsInAssortment = CASE WHEN SubQ.CommonCode IS NULL OR ValidityOrder > 10 THEN 0 ELSE 1 END
FROM #tempProductList AS tpl
  LEFT JOIN (SELECT DISTINCT CommonCode
              FROM Participators AS p
                INNER JOIN Listings AS l ON p.PK_ParticipatorID = l.FK_ParticipatorID
                INNER JOIN ListingTypes AS lt ON l.FK_ListingTypeID = lt.PK_ListingTypeID
                INNER JOIN Products AS p2 ON PK_ProductID = FK_ProductID
                INNER JOIN CommonCodes AS cc ON p2.PK_ProductID = cc.FK_ProductID
              WHERE p.Label IN ( 'default', 'Frisko_ny', 'Frisko_Ben & Jerry' ) AND PK_ListingTypeID = 1) SubQ ON tpl.CommonCode = SubQ.CommonCode COLLATE Danish_Norwegian_CI_AI

UPDATE tpl
SET MaxIsInAssortment = SubQ.MaxIsInAssortment
FROM #tempProductList AS tpl
  INNER JOIN (SELECT ProductCode, MAX(CAST(IsInAssortment AS INT)) MaxIsInAssortment
              FROM #tempProductList AS tpl
              GROUP BY ProductCode) SubQ ON tpl.ProductCode = SubQ.ProductCode

UPDATE tpl
SET ValidityOrder = spsl.ValidityOrder
FROM #tempProductList AS tpl
  INNER JOIN SAP_MATINFO_TotalList AS smtl ON CommonCode = CAST(Material AS BIGINT)
  INNER JOIN SAP_ProductStatusLink AS spsl ON smtl.Status = spsl.STATUS

UPDATE tpl
SET MinValidityOrder = SubQ.MinValidityOrder
FROM #tempProductList AS tpl
  INNER JOIN (SELECT tpl.ProductCode, MIN(tpl.ValidityOrder) MinValidityOrder
              FROM #tempProductList AS tpl
                INNER JOIN #tempProductList AS tpl2 ON tpl.ProductCode = tpl2.ProductCode AND tpl.IsInAssortment = tpl2.MaxIsInAssortment
              GROUP BY tpl.ProductCode) SubQ ON tpl.ProductCode = SubQ.ProductCode

UPDATE tpl
SET MaxCommonCode = SubQ.MaxCommonCode
FROM #tempProductList AS tpl
  INNER JOIN (SELECT tpl.ProductCode, MAX(CAST(tpl.CommonCode AS BIGINT)) MaxCommonCode
              FROM #tempProductList AS tpl
                INNER JOIN #tempProductList AS tpl2 ON tpl.ProductCode = tpl2.ProductCode AND tpl.ValidityOrder = tpl2.MinValidityOrder AND tpl.IsInAssortment = tpl2.MaxIsInAssortment
              GROUP BY tpl.ProductCode) SubQ ON tpl.ProductCode = SubQ.ProductCode
 
-- Situation 4

INSERT INTO Products ( ProductCode, Label, FK_ProductStatusID, Description, PiecesPerConsumerUnit,
   FK_ProductTypeID, ItemCategory, Volume, Weight, IsMixedGoods )
SELECT tpl.ProductCode, '##Under Construction', 0, '', 1, (SELECT PK_ProductTypeID FROM ProductTypes WHERE IsDefault = 1),
  smtl.ItemCategory, smtl.Volume, smtl.Weight, CASE WHEN smtl.ItemCategory = 'Z5BM' THEN 1 ELSE 0 END
FROM #tempProductList AS tpl
  INNER JOIN SAP_MATINFO_TotalList AS smtl ON CommonCode = CAST(CAST(Material AS BIGINT) AS NVARCHAR)
  LEFT JOIN Products AS p ON tpl.ProductCode = p.ProductCode COLLATE Danish_Norwegian_CI_AI
WHERE CommonCodeExists = 1 AND ProductCodeIsNew = 1 AND ProductCodeExists = 0 AND ZeroCommonCodesOnOld = 0 --AND OneCommonCodeOnNew = 1
  AND PK_ProductID IS NULL

UPDATE cc
SET FK_ProductID = PK_ProductID
FROM #tempProductList AS tpl
  INNER JOIN Products AS p ON tpl.ProductCode = p.ProductCode COLLATE Danish_Norwegian_CI_AI
  INNER JOIN CommonCodes cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
WHERE CommonCodeExists = 1 AND ProductCodeIsNew = 1 AND ProductCodeExists = 0 AND ZeroCommonCodesOnOld = 0 --AND OneCommonCodeOnNew = 1
	AND p.PK_ProductID <> cc.FK_ProductID

INSERT INTO CommonCodePeriod ( FK_CommonCodeID, PeriodFrom, PeriodTo )
SELECT PK_CommonCodeID, '2000-01-01', '2099-12-31'
FROM #tempProductList AS tpl
	INNER JOIN CommonCodes cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
	LEFT JOIN CommonCodePeriod ccp ON cc.PK_CommonCodeID = ccp.FK_CommonCodeID
WHERE CommonCodeExists = 1 AND ProductCodeIsNew = 1 AND ProductCodeExists = 0 AND ZeroCommonCodesOnOld = 0 --AND OneCommonCodeOnNew = 1
	AND ccp.PK_CommonCodePeriodID IS Null


-- Situation 9
INSERT INTO CommonCodes ( FK_ProductID, CommonCode, TCode, Active )
SELECT PK_ProductID, tpl.CommonCode, p.ProductCode, 0
FROM #tempProductList AS tpl
  INNER JOIN Products AS p ON tpl.ProductCode = p.ProductCode COLLATE Danish_Norwegian_CI_AI
  LEFT JOIN CommonCodes AS cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
WHERE CommonCodeExists = 0 AND ProductCodeIsNew = 1 AND ProductCodeExists = 1 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 0
  AND PK_CommonCodeID IS NULL
  
-- Situation 8
INSERT INTO Products ( ProductCode, Label, FK_ProductStatusID, Description, PiecesPerConsumerUnit,
   FK_ProductTypeID, ItemCategory, Volume, Weight, IsMixedGoods )
SELECT tpl.ProductCode, '##Under Construction', 0, '', 1, (SELECT PK_ProductTypeID FROM ProductTypes WHERE IsDefault = 1),
  smtl.ItemCategory, smtl.Volume, smtl.Weight, CASE WHEN smtl.ItemCategory = 'Z5BM' THEN 1 ELSE 0 END
FROM #tempProductList AS tpl
  INNER JOIN SAP_MATINFO_TotalList AS smtl ON CommonCode = CAST(CAST(Material AS BIGINT) AS NVARCHAR)
  LEFT JOIN Products AS p ON tpl.ProductCode = p.ProductCode COLLATE Danish_Norwegian_CI_AI
WHERE CommonCodeExists = 0 AND ProductCodeIsNew = 1 AND ProductCodeExists = 0 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 1
  AND PK_ProductID IS NULL

INSERT INTO CommonCodes ( FK_ProductID, CommonCode, TCode, Active )
SELECT PK_ProductID, tpl.CommonCode, p.ProductCode, 1
FROM #tempProductList AS tpl
  INNER JOIN SAP_MATINFO_TotalList AS smtl ON CommonCode = CAST(CAST(Material AS BIGINT) AS NVARCHAR)
  INNER JOIN Products AS p ON tpl.ProductCode = p.ProductCode COLLATE Danish_Norwegian_CI_AI
  LEFT JOIN CommonCodes AS cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
WHERE CommonCodeExists = 0 AND ProductCodeIsNew = 1 AND ProductCodeExists = 0 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 1
  AND PK_CommonCodeID IS NULL

INSERT INTO CommonCodePeriod ( FK_CommonCodeID, PeriodFrom, PeriodTo )
SELECT PK_CommonCodeID, '2000-01-01', '2099-12-31'
FROM #tempProductList AS tpl
  INNER JOIN SAP_MATINFO_TotalList AS smtl ON CommonCode = CAST(CAST(Material AS BIGINT) AS NVARCHAR)
  INNER JOIN Products AS p ON tpl.ProductCode = p.ProductCode COLLATE Danish_Norwegian_CI_AI
  INNER JOIN CommonCodes AS cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
  LEFT JOIN CommonCodePeriod AS ccp ON cc.PK_CommonCodeID = ccp.FK_CommonCodeID
WHERE CommonCodeExists = 0 AND ProductCodeIsNew = 1 AND ProductCodeExists = 0 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 1
  AND PK_CommonCodePeriodID IS NULL
  
-- Situation 10
INSERT INTO Products ( ProductCode, Label, FK_ProductStatusID, Description, PiecesPerConsumerUnit,
   FK_ProductTypeID, ItemCategory, Volume, Weight, IsMixedGoods )
SELECT DISTINCT tpl.ProductCode, '##Under Construction', 0, '', 1, (SELECT PK_ProductTypeID FROM ProductTypes WHERE IsDefault = 1),
  '', 0, 0, 0
FROM #tempProductList AS tpl
  INNER JOIN SAP_MATINFO_TotalList AS smtl ON CommonCode = CAST(CAST(Material AS BIGINT) AS NVARCHAR)
  LEFT JOIN Products AS p ON tpl.ProductCode = p.ProductCode COLLATE Danish_Norwegian_CI_AI
WHERE CommonCodeExists = 0 AND ProductCodeIsNew = 1 AND ProductCodeExists = 0 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 0
  AND PK_ProductID IS NULL

INSERT INTO CommonCodes ( FK_ProductID, CommonCode, TCode, Active )
SELECT PK_ProductID, tpl.CommonCode, p.ProductCode, CASE WHEN ActiveCodes.CommonCode IS NULL THEN 0 ELSE 1 END
FROM #tempProductList AS tpl
  INNER JOIN SAP_MATINFO_TotalList AS smtl ON CommonCode = CAST(CAST(Material AS BIGINT) AS NVARCHAR)
  INNER JOIN Products AS p ON tpl.ProductCode = p.ProductCode COLLATE Danish_Norwegian_CI_AI
  LEFT JOIN (SELECT ProductCode, CommonCode
              FROM #tempProductList AS outerTpl
              WHERE EXISTS ( 
                SELECT ProductCode, MAX(CommonCode) MaxCommonCode
                FROM #tempProductList AS middleTpl
                WHERE EXISTS ( 
                  SELECT ProductCode, MIN(ValidityOrder) MinValidityOrder
                  FROM #tempProductList AS innerTpl
                  WHERE CommonCodeExists = 0 AND ProductCodeIsNew = 1 AND ProductCodeExists = 0 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 0
                  GROUP BY ProductCode
                  HAVING middleTpl.ProductCode = innerTpl.ProductCode AND middleTpl.ValidityOrder = MIN(innerTpl.ValidityOrder) )
                GROUP BY ProductCode
                HAVING outerTpl.ProductCode = middleTpl.ProductCode AND outerTpl.CommonCode = MAX(middleTpl.CommonCode) ) ) ActiveCodes ON tpl.CommonCode = ActiveCodes.CommonCode
  LEFT JOIN CommonCodes AS cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
WHERE CommonCodeExists = 0 AND ProductCodeIsNew = 1 AND ProductCodeExists = 0 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 0
  AND PK_CommonCodeID IS NULL

INSERT INTO CommonCodePeriod ( FK_CommonCodeID, PeriodFrom, PeriodTo )
SELECT PK_CommonCodeID, '2000-01-01', '2099-12-31'
FROM #tempProductList AS tpl
  INNER JOIN SAP_MATINFO_TotalList AS smtl ON CommonCode = CAST(CAST(Material AS BIGINT) AS NVARCHAR)
  INNER JOIN Products AS p ON tpl.ProductCode = p.ProductCode COLLATE Danish_Norwegian_CI_AI
  INNER JOIN (SELECT ProductCode, CommonCode
              FROM #tempProductList AS outerTpl
              WHERE EXISTS ( 
                SELECT ProductCode, MAX(CommonCode) MaxCommonCode
                FROM #tempProductList AS middleTpl
                WHERE EXISTS ( 
                  SELECT ProductCode, MIN(ValidityOrder) MinValidityOrder
                  FROM #tempProductList AS innerTpl
                  WHERE CommonCodeExists = 0 AND ProductCodeIsNew = 1 AND ProductCodeExists = 0 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 0
                  GROUP BY ProductCode
                  HAVING middleTpl.ProductCode = innerTpl.ProductCode AND middleTpl.ValidityOrder = MIN(innerTpl.ValidityOrder) )
                GROUP BY ProductCode
                HAVING outerTpl.ProductCode = middleTpl.ProductCode AND outerTpl.CommonCode = MAX(middleTpl.CommonCode) ) ) ActiveCodes ON tpl.CommonCode = ActiveCodes.CommonCode
  INNER JOIN CommonCodes AS cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
  LEFT JOIN CommonCodePeriod AS ccp ON cc.PK_CommonCodeID = ccp.FK_CommonCodeID
WHERE CommonCodeExists = 0 AND ProductCodeIsNew = 1 AND ProductCodeExists = 0 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 0
  AND PK_CommonCodePeriodID IS NULL

-- Situation 3
UPDATE p
SET ProductCode = tpl.ProductCode
FROM #tempProductList AS tpl
  INNER JOIN CommonCodes AS cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
  INNER JOIN Products AS p ON cc.FK_ProductID = p.PK_ProductID
WHERE CommonCodeExists = 1 AND ProductCodeIsNew = 1 AND ProductCodeExists = 0 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 1
  AND p.ProductCode <> tpl.ProductCode COLLATE Danish_Norwegian_CI_AI


-- Situation 6

-- Set the productcode on the chosen material
UPDATE p
SET ProductCode = tpl.ProductCode
FROM #tempProductList AS tpl
  INNER JOIN CommonCodes AS cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
  LEFT JOIN Products AS p ON cc.FK_ProductID = p.PK_ProductID
WHERE CommonCodeExists = 1 AND ProductCodeIsNew = 1 AND ProductCodeExists = 0 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 0
  AND tpl.CommonCode = MaxCommonCode

-- Delete Periods on invalid products
DELETE FROM ccp
FROM #tempProductList AS tpl
  INNER JOIN CommonCodes AS cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
  INNER JOIN CommonCodePeriod AS ccp ON PK_CommonCodeID = FK_CommonCodeID
WHERE CommonCodeExists = 1 AND ProductCodeIsNew = 1 AND ProductCodeExists = 0 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 0
  AND tpl.CommonCode <> MaxCommonCode

-- Change the campaigns on the old codes to the new code
UPDATE al
SET FK_ProductID = CASE WHEN al.FK_ProductID = p.PK_ProductID THEN p2.PK_ProductID ELSE al.FK_ProductID END,
  FK_SalesUnitID = CASE WHEN al.FK_SalesUnitID = p.PK_ProductID THEN p2.PK_ProductID ELSE al.FK_SalesUnitID END
FROM #tempProductList AS tpl
  INNER JOIN CommonCodes AS cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
  INNER JOIN Products AS p ON cc.FK_ProductID = p.PK_ProductID
  INNER JOIN Products AS p2 ON tpl.ProductCode = p2.ProductCode COLLATE Danish_Norwegian_CI_AI
  INNER JOIN ActivityLines AS al ON p.PK_ProductID = al.FK_ProductID OR p.PK_ProductID = FK_SalesUnitID
WHERE CommonCodeExists = 1 AND ProductCodeIsNew = 1 AND ProductCodeExists = 0 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 0
  AND tpl.CommonCode <> MaxCommonCode

-- Find products to delete
SELECT PK_ProductID
INTO #tempSituation6
FROM #tempProductList AS tpl
  INNER JOIN CommonCodes AS cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
  INNER JOIN Products AS p ON cc.FK_ProductID = p.PK_ProductID
WHERE CommonCodeExists = 1 AND ProductCodeIsNew = 1 AND ProductCodeExists = 0 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 0
  AND tpl.CommonCode <> MaxCommonCode AND p.ProductCode <> tpl.ProductCode COLLATE Danish_Norwegian_CI_AI

--  Update the link to the correct product
UPDATE cc
SET FK_ProductID = p.PK_ProductID
FROM #tempProductList AS tpl
  LEFT JOIN Products AS p ON p.ProductCode = tpl.ProductCode COLLATE Danish_Norwegian_CI_AI
  LEFT JOIN CommonCodes AS cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
WHERE CommonCodeExists = 1 AND ProductCodeIsNew = 1 AND ProductCodeExists = 0 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 0
  AND tpl.CommonCode <> MaxCommonCode COLLATE Danish_Norwegian_CI_AI

-- Delete details on the old codes
DELETE FROM ccp
FROM #tempSituation6 AS ts
  INNER JOIN CommonCodes AS cc ON ts.PK_ProductID = cc.FK_ProductID
  INNER JOIN CommonCodePeriod AS ccp ON cc.PK_CommonCodeID = ccp.FK_CommonCodeID

DELETE FROM alte
FROM #tempSituation6 AS ts
  INNER JOIN CommonCodes AS cc ON ts.PK_ProductID = cc.FK_ProductID
  INNER JOIN ActivityLinesToESAP AS alte ON cc.PK_CommonCodeID = alte.FK_CommonCodeID

DELETE FROM boml
FROM #tempSituation6 AS ts
  INNER JOIN BillOfMaterials AS bom ON ts.PK_ProductID = bom.FK_HeaderProductID
  INNER JOIN BillOfMaterialLines AS boml ON bom.PK_BillOfMaterialID = boml.FK_BillOfMaterialID

DELETE FROM bom
FROM #tempSituation6 AS ts
  INNER JOIN BillOfMaterials AS bom ON ts.PK_ProductID = bom.FK_HeaderProductID

DELETE FROM p
FROM #tempSituation6 AS ts
  INNER JOIN Prices AS p ON ts.PK_ProductID = p.FK_ProductID

DELETE FROM ec
FROM #tempSituation6 AS ts
  INNER JOIN EANCodes AS ec ON ts.PK_ProductID = ec.ProductID

DELETE FROM ph
FROM #tempSituation6 AS ts
  INNER JOIN ProductHierarchies AS ph ON ts.PK_ProductID = ph.FK_ProductID

DELETE FROM al
FROM #tempSituation6 AS ts
  INNER JOIN AllocationLines AS al ON ts.PK_ProductID = al.FK_ProductID

DELETE FROM l
FROM #tempSituation6 AS ts
  INNER JOIN Listings AS l ON ts.PK_ProductID = l.FK_ProductID

DELETE FROM bd
FROM #tempSituation6 AS ts
  INNER JOIN BaseDiscounts AS bd ON ts.PK_ProductID = bd.FK_ProductID

DELETE FROM bde
FROM #tempSituation6 AS ts
  INNER JOIN BaseDiscountsEdit AS bde ON ts.PK_ProductID = bde.FK_ProductID

DELETE FROM pc
FROM #tempSituation6 AS ts
  INNER JOIN Prices_Consolidation AS pc ON ts.PK_ProductID = pc.FK_ProductID

DELETE FROM boml
FROM #tempSituation6 AS ts
  INNER JOIN BillOfMaterialLines AS boml ON ts.PK_ProductID = boml.FK_ComponentProductID

DELETE FROM p
FROM #tempSituation6 AS ts
  INNER JOIN Products AS p ON ts.PK_ProductID = p.PK_ProductID

DROP TABLE #tempSituation6

  
-- Situation 5
UPDATE al
SET FK_ProductID = CASE WHEN al.FK_ProductID = p.PK_ProductID THEN p2.PK_ProductID ELSE al.FK_ProductID END,
  FK_SalesUnitID = CASE WHEN al.FK_SalesUnitID = p.PK_ProductID THEN p2.PK_ProductID ELSE al.FK_SalesUnitID END
FROM #tempProductList AS tpl
  INNER JOIN CommonCodes AS cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
  INNER JOIN Products AS p ON cc.FK_ProductID = p.PK_ProductID
  INNER JOIN Products AS p2 ON tpl.ProductCode = p2.ProductCode COLLATE Danish_Norwegian_CI_AI
  INNER JOIN ActivityLines AS al ON p.PK_ProductID = al.FK_ProductID OR p.PK_ProductID = FK_SalesUnitID
WHERE CommonCodeExists = 1 AND ProductCodeIsNew = 1 AND ProductCodeExists = 1 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 0

-- Delete ccperiods
DELETE FROM ccp
FROM #tempProductList AS tpl
  INNER JOIN CommonCodes AS cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
  INNER JOIN CommonCodePeriod AS ccp ON cc.PK_CommonCodeID = ccp.FK_CommonCodeID
WHERE CommonCodeExists = 1 AND ProductCodeIsNew = 1 AND ProductCodeExists = 1 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 0
  

-- Find Products to delete
SELECT PK_ProductID
INTO #tempSituation5
FROM #tempProductList AS tpl
  INNER JOIN CommonCodes AS cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
  INNER JOIN Products AS p ON cc.FK_ProductID = p.PK_ProductID
WHERE CommonCodeExists = 1 AND ProductCodeIsNew = 1 AND ProductCodeExists = 1 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 0

-- Update cc to Product link on not active product
UPDATE cc
SET FK_ProductID = PK_ProductID
FROM #tempProductList AS tpl
  INNER JOIN CommonCodes AS cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
  INNER JOIN Products AS p ON tpl.ProductCode = p.ProductCode COLLATE Danish_Norwegian_CI_AI
WHERE CommonCodeExists = 1 AND ProductCodeIsNew = 1 AND ProductCodeExists = 1 AND ZeroCommonCodesOnOld = 1 AND OneCommonCodeOnNew = 0


-- Delete not active product
DELETE FROM alte
FROM #tempSituation5 AS ts
  INNER JOIN CommonCodes AS cc ON ts.PK_ProductID = cc.FK_ProductID
  INNER JOIN ActivityLinesToESAP AS alte ON cc.PK_CommonCodeID = alte.FK_CommonCodeID

DELETE FROM boml
FROM #tempSituation5 AS ts
  INNER JOIN BillOfMaterials AS bom ON ts.PK_ProductID = bom.FK_HeaderProductID
  INNER JOIN BillOfMaterialLines AS boml ON bom.PK_BillOfMaterialID = boml.FK_BillOfMaterialID

DELETE FROM bom
FROM #tempSituation5 AS ts
  INNER JOIN BillOfMaterials AS bom ON ts.PK_ProductID = bom.FK_HeaderProductID

DELETE FROM p
FROM #tempSituation5 AS ts
  INNER JOIN Prices AS p ON ts.PK_ProductID = p.FK_ProductID

DELETE FROM ec
FROM #tempSituation5 AS ts
  INNER JOIN EANCodes AS ec ON ts.PK_ProductID = ec.ProductID

DELETE FROM ph
FROM #tempSituation5 AS ts
  INNER JOIN ProductHierarchies AS ph ON ts.PK_ProductID = ph.FK_ProductID

DELETE FROM al
FROM #tempSituation5 AS ts
  INNER JOIN AllocationLines AS al ON ts.PK_ProductID = al.FK_ProductID

DELETE FROM l
FROM #tempSituation5 AS ts
  INNER JOIN Listings AS l ON ts.PK_ProductID = l.FK_ProductID

DELETE FROM bd
FROM #tempSituation5 AS ts
  INNER JOIN BaseDiscounts AS bd ON ts.PK_ProductID = bd.FK_ProductID

DELETE FROM bde
FROM #tempSituation5 AS ts
  INNER JOIN BaseDiscountsEdit AS bde ON ts.PK_ProductID = bde.FK_ProductID

DELETE FROM pc
FROM #tempSituation5 AS ts
  INNER JOIN Prices_Consolidation AS pc ON ts.PK_ProductID = pc.FK_ProductID

DELETE FROM boml
FROM #tempSituation5 AS ts
  INNER JOIN BillOfMaterialLines AS boml ON ts.PK_ProductID = boml.FK_ComponentProductID

DELETE FROM p
FROM #tempSituation5 AS ts
  INNER JOIN Products AS p ON ts.PK_ProductID = p.PK_ProductID

DROP TABLE #tempSituation5

-- New Situation
UPDATE cc SET FK_ProductID = PK_ProductID
FROM #tempProductList tpl
	INNER JOIN dbo.CommonCodes as cc ON tpl.CommonCode = cc.CommonCode COLLATE Danish_Norwegian_CI_AI
	INNER JOIN dbo.Products as p ON p.ProductCode = tpl.ProductCode COLLATE Danish_Norwegian_CI_AI
WHERE ProductCodeIsNew = 1
	AND ProductCodeExists = 1
	AND ZeroCommonCodesOnOld = 0
	

DROP TABLE #tempProductList

UPDATE ccp
SET PeriodFrom = '2000-01-01'
FROM dbo.CommonCodePeriod as ccp
	INNER JOIN dbo.CommonCodes as cc on ccp.FK_CommonCodeID = cc.PK_CommonCodeID
	INNER JOIN (SELECT FK_ProductID, MIN(ccp.PeriodFrom) MinPeriodFrom
				FROM dbo.CommonCodePeriod as ccp
					INNER JOIN dbo.CommonCodes as cc ON ccp.FK_CommonCodeID = cc.PK_CommonCodeID
				GROUP BY FK_ProductID) Sub 
		ON cc.FK_ProductID = Sub.FK_ProductID AND ccp.PeriodFrom = MinPeriodFrom
WHERE ccp.PeriodFrom <> '2000-01-01'

UPDATE ccp
SET PeriodTo = '2099-12-31'
FROM dbo.CommonCodePeriod as ccp
	INNER JOIN dbo.CommonCodes as cc ON ccp.FK_CommonCodeID = cc.PK_CommonCodeID
	INNER JOIN (SELECT FK_ProductID, MAX(ccp.PeriodTo) MaxPeriodTo
				FROM dbo.CommonCodePeriod as ccp
					INNER JOIN dbo.CommonCodes as cc ON ccp.FK_CommonCodeID = cc.PK_CommonCodeID
				GROUP BY FK_ProductID) Sub
		ON cc.FK_ProductID = Sub.FK_ProductID AND ccp.PeriodTo = MaxPeriodTo
WHERE ccp.PeriodTo <> '2099-12-31'

UPDATE ccp
SET PeriodTo = Sub2.PeriodFrom - 1
FROM
	dbo.CommonCodePeriod as ccp
		INNER JOIN dbo.CommonCodes as cc on ccp.FK_CommonCodeID = cc.PK_CommonCodeID
		INNER JOIN (SELECT FK_ProductID, ccp.PeriodFrom, ccp.PeriodTo, ROW_NUMBER() OVER (PARTITION BY FK_ProductID ORDER BY ccp.PeriodFrom) RowNumber
		FROM dbo.CommonCodePeriod as ccp
			INNER JOIN dbo.CommonCodes as cc ON ccp.FK_CommonCodeID = cc.PK_CommonCodeID
		) Sub1 ON cc.FK_ProductID = Sub1.FK_ProductID AND ccp.PeriodFrom = Sub1.PeriodFrom
	INNER JOIN (SELECT FK_ProductID, ccp.PeriodFrom, ccp.PeriodTo, ROW_NUMBER() OVER (PARTITION BY FK_ProductID ORDER BY ccp.PeriodFrom) RowNumber
		FROM dbo.CommonCodePeriod as ccp
			INNER JOIN dbo.CommonCodes as cc ON ccp.FK_CommonCodeID = cc.PK_CommonCodeID
		) Sub2 ON Sub1.FK_ProductID = Sub2.FK_ProductID
		AND Sub1.RowNumber + 1 = Sub2.RowNumber
WHERE Sub1.PeriodTo <> Sub2.PeriodFrom - 1





/*
SELECT CASE WHEN CommonCodeExists = 1 THEN 'CC ex' ELSE 'CC non-ex' END CommonCodeExists, 
  CASE WHEN ProductCodeIsNew = 1 THEN 'Prod ny' ELSE 'Prod gl' END ProductCodeIsNew, 
  CASE WHEN ProductCodeExists = 1 THEN 'Prod ex' ELSE 'Prod non ex' END ProductCodeExists, 
  CASE WHEN ZeroCommonCodesOnOld = 1 THEN '0 CC på gl prod' ELSE '1+ CC på gl prod' END ZeroCommonCodesOnOld, 
  CASE WHEN OneCommonCodeOnNew = 1 THEN '1 CC på ny prod' ELSE '2+ CC på ny prod' END OneCommonCodeOnNew, 
  COUNT(*)
FROM #tempProductList AS tpl
GROUP BY CommonCodeExists, ProductCodeIsNew, ProductCodeExists, ZeroCommonCodesOnOld, OneCommonCodeOnNew
ORDER BY 1, 2, 3, 4, 5

*/




