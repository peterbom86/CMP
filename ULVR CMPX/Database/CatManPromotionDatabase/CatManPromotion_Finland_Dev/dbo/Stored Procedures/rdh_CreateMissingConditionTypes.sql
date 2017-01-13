CREATE PROCEDURE [dbo].[rdh_CreateMissingConditionTypes]

AS

TRUNCATE TABLE MissingConditionTypes

CREATE TABLE #tempCC ( -- Contains all ProductID's and the underlying CC's with more than 1 CC
  CommonCodeID int PRIMARY KEY, 
  ProductID int,
  CommonCode varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS )

INSERT INTO #tempCC ( CommonCodeID, ProductID, CommonCode )
SELECT PK_CommonCodeID, CC.FK_ProductID, CommonCode
FROM CommonCodes CC
  INNER JOIN (SELECT FK_ProductID FROM CommonCodes GROUP BY FK_ProductID HAVING COUNT(*) > 1) MultCC ON MultCC.FK_ProductID = CC.FK_ProductID
  INNER JOIN SAP_MATINFO_TotalList TL ON CAST(CAST(Material as bigint) as varchar(50)) = CommonCode
  INNER JOIN SAP_ProductStatusLink PSL ON TL.Status = PSL.Status
  INNER JOIN ProductStatus ON PK_ProductStatusID = FK_ProductStatusID
WHERE IsHidden = 0


CREATE TABLE #tempTest ( 
  PK_TestID int IDENTITY(1, 1) PRIMARY KEY,
  ConditionType varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
  ProductID int,
  Hierarchy varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
  Date datetime,
  CommonCodeID int,
  Value float )

INSERT INTO #tempTest ( ConditionType, ProductID, Hierarchy, Date ) 
SELECT ConditionType, CC1.ProductID, Node, PeriodFrom
FROM SAP_ConditionTypes_TotalList
  INNER JOIN #tempCC CC1 ON CAST(CAST(Material as bigint) as varchar(20)) = CC1.CommonCode
  LEFT JOIN CustomerHierarchies ON REPLICATE('0', 12 - LEN(SUBSTRING(Hierarchy, 7, 10))) + SUBSTRING(Hierarchy, 7, 10) = REPLICATE('0', 12 - LEN(Node)) + Node
WHERE Material <> '' AND (ConditionType <> 'Z501' OR LEFT(Hierarchy, 6) <> '521020') AND PeriodTo >= GETDATE()
UNION
SELECT ConditionType, CC1.ProductID, Node, PeriodTo + 1
FROM SAP_ConditionTypes_TotalList
  INNER JOIN #tempCC CC1 ON CAST(CAST(Material as bigint) as varchar(20)) = CC1.CommonCode
  LEFT JOIN CustomerHierarchies ON REPLICATE('0', 12 - LEN(SUBSTRING(Hierarchy, 7, 10))) + SUBSTRING(Hierarchy, 7, 10) = REPLICATE('0', 12 - LEN(Node)) + Node
WHERE Material <> '' AND (ConditionType <> 'Z501' OR LEFT(Hierarchy, 6) <> '521020') AND PeriodTo + 1 >= GETDATE()
ORDER BY 1, 2, 3, 4

INSERT INTO #tempTest ( ConditionType, ProductID, Hierarchy, Date, CommonCodeID )
SELECT ConditionType, TT.ProductID, Hierarchy, Date, CC.CommonCodeID
FROM #tempTest TT
  INNER JOIN #tempCC CC ON TT.ProductID = CC.ProductID

DELETE FROM #tempTest
WHERE CommonCodeID IS Null

INSERT INTO #tempTest ( ConditionType, ProductID, Hierarchy, Date, CommonCodeID, Value )
SELECT DISTINCT TT.ConditionType, TT.ProductID, TT.Hierarchy, TT.Date, TT.CommonCodeID, ISNULL(TL.Value, 0)
FROM SAP_ConditionTypes_TotalList TL
  INNER JOIN #tempCC CC1 ON CAST(CAST(Material as bigint) as varchar(20)) = CC1.CommonCode
  LEFT JOIN CustomerHierarchies ON REPLICATE('0', 12 - LEN(SUBSTRING(Hierarchy, 7, 10))) + SUBSTRING(Hierarchy, 7, 10) = REPLICATE('0', 12 - LEN(Node)) + Node
  RIGHT JOIN #tempTest TT ON TT.ConditionType = TL.ConditionType AND CC1.CommonCodeID = TT.CommonCodeID AND ISNULL(TT.Hierarchy, '') = ISNULL(Node, '') AND
    PeriodFrom <= Date AND PeriodTo >= Date
WHERE ISNULL(Material, '-1') <> '' AND (TT.ConditionType <> 'Z501' OR LEFT(ISNULL(TL.Hierarchy, ''), 6) <> '521020')

DELETE FROM #tempTest
WHERE Value IS Null


INSERT INTO MissingConditionTypes (ConditionType, Hierarchy, ProductCode, ProductName, CommonCode, Date, PeriodFrom, PeriodTo, Value )
SELECT TT.ConditionType, TT.Hierarchy, ProductCode, Products.Label ProductName, CommonCode, TT.Date, TL.PeriodFrom, TL.PeriodTo, TT.Value
FROM #tempTest TT
  INNER JOIN (SELECT ConditionType, ProductID, Hierarchy, Date, AVG(Value) AvgValue
              FROM #tempTest GROUP BY ConditionType, ProductID, Hierarchy, Date) AvgValues ON TT.ConditionType = AvgValues.ConditionType AND
                TT.ProductID = AvgValues.ProductID AND ISNULL(TT.Hierarchy, '') = ISNULL(AvgValues.Hierarchy, '') AND TT.Date = AvgValues.Date
  INNER JOIN Products ON PK_ProductID = TT.ProductID
  INNER JOIN CommonCodes ON PK_CommonCodeID = TT.CommonCodeID
--  LEFT JOIN CustomerHierarchies ON TT.Hierarchy = Node
  LEFT JOIN SAP_ConditionTypes_TotalList TL ON TT.ConditionType = TL.ConditionType AND CommonCode = CAST(Material as bigint) AND TL.PeriodFrom <= TT.Date AND TL.PeriodTo >= TT.Date AND
    REPLICATE('0', 12 - LEN(SUBSTRING(TL.Hierarchy, 7, 10))) + SUBSTRING(TL.Hierarchy, 7, 10) = ISNULL(REPLICATE('0', 12 - LEN(TT.Hierarchy)) + TT.Hierarchy, REPLICATE('0', 12 - LEN(SUBSTRING(TL.Hierarchy, 7, 10))) + SUBSTRING(TL.Hierarchy, 7, 10))
WHERE ROUND(TT.Value, 2) <> ROUND(AvgValue, 2)
ORDER BY 1, 2, 3, 4, 5, 6, 7, 8

DROP TABLE #tempCC
DROP TABLE #tempTest
