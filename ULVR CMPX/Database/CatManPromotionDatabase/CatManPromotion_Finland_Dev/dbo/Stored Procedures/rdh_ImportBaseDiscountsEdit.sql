CREATE PROC dbo.rdh_ImportBaseDiscountsEdit 

AS

CREATE TABLE #tempPricingHierarchy (
  PK_ProductHierarchyID int PRIMARY KEY,
  Node varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
  NodeGroup varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS )

INSERT INTO #tempPricingHierarchy ( PK_ProductHierarchyID, Node, NodeGroup )
SELECT PH4.PK_ProductHierarchyID, PH4.Node, PH1.Node
FROM ProductHierarchies PH4 
  INNER JOIN ProductHierarchies PH3 ON PH4.FK_ProductHierarchyParentID = PH3.PK_ProductHierarchyID
  INNER JOIN ProductHierarchies PH2 ON PH3.FK_ProductHierarchyParentID = PH2.PK_ProductHierarchyID
  INNER JOIN ProductHierarchies PH1 ON PH2.FK_ProductHierarchyParentID = PH1.PK_ProductHierarchyID
WHERE PH1.FK_ProductHierarchyLevelID = 20
UNION
SELECT PH3.PK_ProductHierarchyID, PH3.Node, PH1.Node
FROM ProductHierarchies PH3
  INNER JOIN ProductHierarchies PH2 ON PH3.FK_ProductHierarchyParentID = PH2.PK_ProductHierarchyID
  INNER JOIN ProductHierarchies PH1 ON PH2.FK_ProductHierarchyParentID = PH1.PK_ProductHierarchyID
WHERE PH1.FK_ProductHierarchyLevelID = 20
UNION
SELECT PH2.PK_ProductHierarchyID, PH2.Node, PH1.Node
FROM ProductHierarchies PH2
  INNER JOIN ProductHierarchies PH1 ON PH2.FK_ProductHierarchyParentID = PH1.PK_ProductHierarchyID
WHERE PH1.FK_ProductHierarchyLevelID = 20

SELECT DISTINCT ConditionType, Calculation
INTO #tempConditionTypeCalculations
FROM dbo.SAP_ConditionTypes_TotalList AS scttl
  INNER JOIN BaseDiscountTypes ON Label LIKE '%(' + ConditionType + ')%'
    

INSERT INTO dbo.BaseDiscountTypes ( Label , FK_PriceBaseID , IsDefault , FK_ValueTypeID , FK_VolumeBaseID , OnInvoice ,
          IsBaseDiscount , IsValidForRunUp , IsPriceAgreement , IsCannibalisationFactor
        )
SELECT REPLACE(bdt.Label, '(' + ConditionType + ')', '(' + ConditionType + '_amount)'), bdt.FK_PriceBaseID, 0, 2, bdt.FK_VolumeBaseID,
	bdt.OnInvoice, bdt.IsBaseDiscount, bdt.IsValidForRunUp, bdt.IsPriceAgreement, bdt.IsCannibalisationFactor
FROM dbo.BaseDiscountTypes AS bdt
  INNER JOIN #tempConditionTypeCalculations AS tctc ON bdt.Label LIKE '%(' + ConditionType + ')%' AND Calculation = 'C'
  LEFT JOIN dbo.BaseDiscountTypes AS bdt2 ON bdt2.Label LIKE '%(' + ConditionType + '_amount)%'
WHERE bdt2.PK_BaseDiscountTypeID IS NULL

DROP TABLE #tempConditionTypeCalculations
  
CREATE TABLE #tempBaseDiscountTable (
  PK_TempID int IDENTITY(1, 1) PRIMARY KEY,
  FK_ParticipatorID int,
  FK_CustomerHierarchyID int,
  FK_ProductID int,
  FK_ProductHierarchyID int,
  FK_BaseDiscountTypeID int, 
  Value float, 
  PeriodFrom datetime, 
  PeriodTo datetime,
  FK_FileImportID int)

INSERT INTO #tempBaseDiscountTable ( FK_ParticipatorID, FK_CustomerHierarchyID, FK_ProductID, FK_ProductHierarchyID, FK_BasediscountTypeID, 
  Value, PeriodFrom, PeriodTo, FK_FileImportID )   
SELECT Null ParticipatorID, PK_CustomerHierarchyID, CASE ISNULL(CommonCode, 'NoCode') WHEN 'NoCode' THEN Null ELSE CC.FK_ProductID END ProductID, 
  CASE ISNULL(CommonCode, 'NoCode') WHEN 'NoCode' THEN ISNULL(PH2.PK_ProductHierarchyID, PH.PK_ProductHierarchyID) ELSE Null END ProductHierarchyID,
  PK_BaseDiscountTypeID, CASE WHEN Calculation = 'A' THEN -Value / 100 WHEN Calculation = 'C' THEN -Value * CASE WHEN QTYType = 'ZCU' THEN ( ec.Pieces / p.PiecesPerConsumerUnit )  ELSE 1 END ELSE 0 END Value, 
  CASE WHEN TL.PeriodFrom < '2007-11-05' THEN '2007-11-05' ELSE TL.PeriodFrom END PeriodFrom, TL.PeriodTo, 
  MAX(FK_FileImportID)
FROM SAP_ConditionTypes_TotalList TL
  INNER JOIN BaseDiscountTypes ON (Label LIKE '%(' + ConditionType + ')%' AND Calculation = 'A') OR (Label LIKE '%(' + ConditionType + '_amount)%' AND Calculation = 'C')
  INNER JOIN CustomerHierarchies CH ON CASE 
	WHEN ConditionType = 'Z500' THEN CAST(CAST(SUBSTRING(HIERARCHY,14,10) as int) as varchar)
	WHEN ConditionType NOT IN ('Z669', 'Z501', 'Z500') THEN CAST(CAST(SUBSTRING(HIERARCHY,7,10) as int) as varchar) ELSE '-1' END = CH.Node
  LEFT JOIN CommonCodes CC ON CAST(CAST(MATERIAL as bigint) as varchar) = CommonCode AND Active = 1
  LEFT JOIN dbo.Products AS p ON CC.FK_ProductID = p.PK_ProductID
  LEFT JOIN dbo.EANCodes AS ec ON p.PK_ProductID = ec.ProductID AND FK_EANTypeID = 2
  LEFT JOIN ProductHierarchies PH ON SUBSTRING(HIERARCHY,31,2) = PH.Node
  LEFT JOIN #tempPricingHierarchy PH2 ON SUBSTRING(HIERARCHY,19,12) = PH2.Node AND CASE WHEN LTRIM(SUBSTRING(HIERARCHY,31,2)) <> '' THEN SUBSTRING(HIERARCHY,31,2) ELSE PH2.NodeGroup END = PH2.NodeGroup
WHERE --LEN(Hierarchy) <> 36 AND 
  ISNULL(CommonCode, 'NoCode') = CASE WHEN Material = '' THEN 'NoCode' ELSE CAST(CAST(MATERIAL as bigint) as varchar) END AND
  ISNULL(PH.Node, 'NoCode') = CASE WHEN LEN(Hierarchy) = 36 THEN 'NoCode' WHEN ConditionType = 'Z500' THEN 'NoCode' WHEN LTRIM(SUBSTRING(HIERARCHY,31,2)) = '' THEN 'NoCode' ELSE SUBSTRING(HIERARCHY,31,2) END AND
  ISNULL(PH2.Node, 'NoCode') = CASE WHEN LEN(Hierarchy) = 36 THEN 'NoCode' WHEN ConditionType = 'Z500' THEN 'NoCode' WHEN LTRIM(SUBSTRING(HIERARCHY,19,12)) = '' THEN 'NoCode' ELSE SUBSTRING(HIERARCHY,19,12) END AND
  TL.PeriodTo >= '2007-11-05'
GROUP BY PK_CustomerHierarchyID, CASE ISNULL(CommonCode, 'NoCode') WHEN 'NoCode' THEN Null ELSE CC.FK_ProductID END, 
  CASE ISNULL(CommonCode, 'NoCode') WHEN 'NoCode' THEN ISNULL(PH2.PK_ProductHierarchyID, PH.PK_ProductHierarchyID) ELSE Null END,
  PK_BaseDiscountTypeID, CASE WHEN Calculation = 'A' THEN -Value / 100 WHEN Calculation = 'C' THEN -Value * CASE WHEN QTYType = 'ZCU' THEN ( ec.Pieces / p.PiecesPerConsumerUnit ) ELSE 1 END ELSE 0 END, 
  CASE WHEN TL.PeriodFrom < '2007-11-05' THEN '2007-11-05' ELSE TL.PeriodFrom END, TL.PeriodTo
ORDER BY 3

DELETE FROM BDE
FROM BaseDiscountsEdit BDE
  INNER JOIN BaseDiscountTypes ON PK_BaseDiscountTypeID = FK_BaseDiscountTypeID 
WHERE (IsBaseDiscount = 1 OR FK_BaseDiscountTypeID IN ( 40, 41, 42)) AND PeriodFrom >= '2007-11-05'

/* No need to update BaseDiscountsEdit. The old data is deleted and the new is inserted - this handles wrongly imported data
DELETE FROM BDE
FROM #tempBaseDiscountTable TBT
  INNER JOIN BaseDiscountsEdit BDE ON ISNULL(TBT.FK_ParticipatorID, -1) = ISNULL(BDE.FK_ParticipatorID, -1) AND
    ISNULL(TBT.FK_CustomerHierarchyID, -1) = ISNULL(BDE.FK_CustomerHierarchyID, -1) AND ISNULL(TBT.FK_ProductID, -1) = ISNULL(BDE.FK_ProductID, -1) AND
    ISNULL(TBT.FK_ProductHierarchyID, -1) = ISNULL(BDE.FK_ProductHierarchyID, -1) AND TBT.FK_BaseDiscountTypeID = BDE.FK_BaseDiscountTypeID
WHERE BDE.PeriodFrom >= TBT.PeriodFrom AND BDE.PeriodTo <= TBT.PeriodTo

INSERT INTO BaseDiscountsEdit ( FK_ParticipatorID, FK_CustomerHierarchyID, FK_ProductID, FK_ProductHierarchyID, FK_PriceBaseID, FK_BasediscountTypeID, 
  Value, FK_ValueTypeID, FK_VolumeBaseID, OnInvoice, PeriodFrom, PeriodTo, FK_FileImportID )   
SELECT BDE.FK_ParticipatorID, BDE.FK_CustomerHierarchyID, BDE.FK_ProductID, BDE.FK_ProductHierarchyID, BDT.FK_PriceBaseID, BDE.FK_BaseDiscountTypeID,
  BDE.Value, BDT.FK_ValueTypeId, BDT.FK_VolumeBaseID, BDT.OnInvoice, TBT.PeriodTo + 1, BDE.PeriodTo, BDE.FK_FileImportID
FROM #tempBaseDiscountTable TBT
  INNER JOIN BaseDiscountsEdit BDE ON ISNULL(TBT.FK_ParticipatorID, -1) = ISNULL(BDE.FK_ParticipatorID, -1) AND
    ISNULL(TBT.FK_CustomerHierarchyID, -1) = ISNULL(BDE.FK_CustomerHierarchyID, -1) AND ISNULL(TBT.FK_ProductID, -1) = ISNULL(BDE.FK_ProductID, -1) AND
    ISNULL(TBT.FK_ProductHierarchyID, -1) = ISNULL(BDE.FK_ProductHierarchyID, -1) AND TBT.FK_BaseDiscountTypeID = BDE.FK_BaseDiscountTypeID
  INNER JOIN BaseDiscountTypes BDT ON PK_BaseDiscountTypeID = TBT.FK_BaseDiscountTypeID
WHERE BDE.PeriodFrom < TBT.PeriodFrom AND BDE.PeriodTo > TBT.PeriodTo
  
UPDATE BDE
SET PeriodTo = TBT.PeriodFrom - 1
FROM #tempBaseDiscountTable TBT
  INNER JOIN BaseDiscountsEdit BDE ON ISNULL(TBT.FK_ParticipatorID, -1) = ISNULL(BDE.FK_ParticipatorID, -1) AND
    ISNULL(TBT.FK_CustomerHierarchyID, -1) = ISNULL(BDE.FK_CustomerHierarchyID, -1) AND ISNULL(TBT.FK_ProductID, -1) = ISNULL(BDE.FK_ProductID, -1) AND
    ISNULL(TBT.FK_ProductHierarchyID, -1) = ISNULL(BDE.FK_ProductHierarchyID, -1) AND TBT.FK_BaseDiscountTypeID = BDE.FK_BaseDiscountTypeID
WHERE BDE.PeriodFrom <= TBT.PeriodFrom AND BDE.PeriodTo >= TBT.PeriodFrom
  
UPDATE BDE
SET PeriodFrom = TBT.PeriodTo + 1
FROM #tempBaseDiscountTable TBT
  INNER JOIN BaseDiscountsEdit BDE ON ISNULL(TBT.FK_ParticipatorID, -1) = ISNULL(BDE.FK_ParticipatorID, -1) AND
    ISNULL(TBT.FK_CustomerHierarchyID, -1) = ISNULL(BDE.FK_CustomerHierarchyID, -1) AND ISNULL(TBT.FK_ProductID, -1) = ISNULL(BDE.FK_ProductID, -1) AND
    ISNULL(TBT.FK_ProductHierarchyID, -1) = ISNULL(BDE.FK_ProductHierarchyID, -1) AND TBT.FK_BaseDiscountTypeID = BDE.FK_BaseDiscountTypeID
WHERE BDE.PeriodFrom >= TBT.PeriodFrom AND BDE.PeriodFrom <= TBT.PeriodTo
*/

INSERT INTO BaseDiscountsEdit ( FK_ParticipatorID, FK_CustomerHierarchyID, FK_ProductID, FK_ProductHierarchyID, FK_PriceBaseID, FK_BasediscountTypeID, 
  Value, FK_ValueTypeID, FK_VolumeBaseID, OnInvoice, PeriodFrom, PeriodTo, FK_FileImportID )   
SELECT TBT.FK_ParticipatorID, TBT.FK_CustomerHierarchyID, TBT.FK_ProductID, TBT.FK_ProductHierarchyID, BDT.FK_PriceBaseID, TBT.FK_BaseDiscountTypeID,
  TBT.Value, BDT.FK_ValueTypeID, BDT.FK_VolumeBaseID, OnInvoice, TBT.PeriodFrom, TBT.PeriodTo, TBT.FK_FileImportID
FROM #tempBaseDiscountTable TBT
  INNER JOIN BaseDiscountTypes BDT ON PK_BaseDiscountTypeID = FK_BaseDiscountTypeID

DROP TABLE #tempBaseDiscountTable
DROP TABLE #tempPricingHierarchy
