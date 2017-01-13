CREATE PROCEDURE [dbo].[rdh_ImportSAPConditionTypes_TotalList_Sirius]

AS
/*
OPRETTER TOTALLISTE PBA: INDLÆST CONDITIONSTYPES FRA SAP_CONDITIONTTYPES OG GENERERER SENESTE AKTUELLE LISTE.
TAGER KUN DEM HVOR ISHANDLED = 0

UPDATE FI
SET IsHandled = 1
FROM SAP_FileImport FI
  INNER JOIN SAP_ConditionTypes CT ON PK_FileImportID = FK_FileImportID
WHERE IsHandled = 0 AND LEN(HIERARCHY) = 36 AND CONDITIONTYPE <> 'Z501'
*/
UPDATE FI
SET IsHandled = 1
FROM SAP_FileImport FI
  INNER JOIN SAP_ConditionTypes CT ON PK_FileImportID = FK_FileImportID
WHERE IsHandled = 0 AND (MATERIAL >= '000000002147483648')-- OR HIERARCHY NOT LIKE '%EUR%')

UPDATE FI
SET IsHandled = 1
FROM SAP_FileImport FI
  INNER JOIN SAP_ConditionTypes CT ON PK_FileImportID = FK_FileImportID
WHERE IsHandled = 0 AND PK_FileImportID NOT IN (
  SELECT MAX(PK_FileImportID)
  FROM SAP_FileImport FI
    INNER JOIN SAP_ConditionTypes CT ON PK_FileImportID = FK_FileImportID
  WHERE IsHandled = 0 --AND CONDITIONTYPE = 'Z501'
  GROUP BY CONDITIONTYPE, MATERIAL, HIERARCHY, DATEFROM, DATETO)

CREATE TABLE #tempPriceTable (
  CONDITIONTYPE nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
  MATERIAL nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
  HIERARCHY nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
  DATEFROM nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
  DATETO nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
  RATE nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
  QTYTYPE nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
  FK_FileImportID INT,
  CALCULATION NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
  AMOUNTTYPE NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS
)

DECLARE @ConditionType nvarchar(50)
DECLARE @Material nvarchar(50)
DECLARE @Hierarchy nvarchar(50)
DECLARE @DateFrom nvarchar(50)
DECLARE @DateTo nvarchar(50)
DECLARE @Rate nvarchar(50)
DECLARE @QTYType nvarchar(50)
DECLARE @FileImportID INT
DECLARE @Calculation NVARCHAR(50)
DECLARE @AmountType NVARCHAR(50)

DECLARE ConditionType_Cursor CURSOR FOR
SELECT CONDITIONTYPE, MATERIAL, 
	CASE WHEN CONDITIONTABLE = '793' THEN STUFF(HIERARCHY, 19, 0, '              ') ELSE HIERARCHY END HIERARCHY, DATEFROM, DATETO, RATE, QTYTYPE, FK_FileImportID, CALCULATION, AMOUNTTYPE
FROM SAP_FileImport FI
  INNER JOIN SAP_ConditionTypes CT ON PK_FileImportID = FK_FileImportID
WHERE IsHandled = 0 AND 
  EXISTS (
  SELECT SubCT.CONDITIONTYPE, SubCT.MATERIAL, 
	CASE WHEN SubCT.CONDITIONTABLE = '793' THEN STUFF(SubCT.HIERARCHY, 19, 0, '              ') ELSE HIERARCHY END HIERARCHY
  FROM SAP_FileImport SubFI
    INNER JOIN SAP_ConditionTypes SubCT ON SubFI.PK_FileImportID = SubCT.FK_FileImportID
  WHERE IsHandled = 0 AND CT.CONDITIONTYPE = SubCT.CONDITIONTYPE AND CT.MATERIAL = SubCT.MATERIAL AND 
	CASE WHEN CT.CONDITIONTABLE = '793' THEN STUFF(CT.HIERARCHY, 19, 0, '              ') ELSE HIERARCHY END = 
		CASE WHEN SubCT.CONDITIONTABLE = '793' THEN STUFF(SubCT.HIERARCHY, 19, 0, '              ') ELSE HIERARCHY END
  GROUP BY SubCT.CONDITIONTYPE, SubCT.MATERIAL, CASE WHEN SubCT.CONDITIONTABLE = '793' THEN STUFF(SubCT.HIERARCHY, 19, 0, '              ') ELSE HIERARCHY END
  HAVING COUNT(*) > 1 )
ORDER BY CONDITIONTYPE, MATERIAL, HIERARCHY, DATEFROM, DATETO

OPEN ConditionType_Cursor

FETCH NEXT FROM ConditionType_Cursor
INTO @ConditionType, @Material, @Hierarchy, @DateFrom, @DateTo, @Rate, @QTYType, @FileImportID, @Calculation, @AmountType

WHILE @@FETCH_STATUS = 0
BEGIN
  DELETE
  FROM #tempPriceTable
  WHERE CONDITIONTYPE = @ConditionType AND MATERIAL = @Material AND HIERARCHY = @Hierarchy AND DATEFROM >= @DateFrom AND DATETO <= @DateTo

  INSERT INTO #tempPriceTable
  SELECT CONDITIONTYPE, MATERIAL, HIERARCHY, CONVERT(nvarchar(50), CONVERT(datetime, CASE WHEN @DateTo > '20991231' THEN '20991231' ELSE @DateTo END, 112) + 1, 112), DATETO, RATE, QTYTYPE, FK_FileImportID, CALCULATION, AMOUNTTYPE
  FROM #tempPriceTable
  WHERE CONDITIONTYPE = @ConditionType AND MATERIAL = @Material AND HIERARCHY = @Hierarchy AND DATEFROM < @DateFrom AND DATETO > @DateTo
  
  UPDATE TPT
  SET DATETO = CONVERT(nvarchar(50), CONVERT(datetime, CASE WHEN @DateFrom > '20991231' THEN '20991231' ELSE @DateFrom END, 112) - 1, 112)
  FROM #tempPriceTable TPT
  WHERE CONDITIONTYPE = @ConditionType AND MATERIAL = @Material AND HIERARCHY = @Hierarchy AND DATEFROM <= @DateFrom AND DATETO >= @DateFrom
  
  UPDATE TPT
  SET DATEFROM = CONVERT(nvarchar(50), CONVERT(datetime, CASE WHEN @DateTo > '20991231' THEN '20991231' ELSE @DateTo END, 112) + 1, 112)
  FROM #tempPriceTable TPT
  WHERE CONDITIONTYPE = @ConditionType AND MATERIAL = @Material AND HIERARCHY = @Hierarchy AND DATEFROM >= @DateFrom AND DATEFROM <= @DateTo

  INSERT INTO #tempPriceTable
  SELECT @ConditionType, @Material, @Hierarchy, CASE WHEN @DateFrom > '20991231' THEN '20991231' ELSE @DateFrom END, CASE WHEN @DateTo > '20991231' THEN '20991231' ELSE @DateTo END, @Rate, @QTYType, @FileImportID, @Calculation, @AmountType

  FETCH NEXT FROM ConditionType_Cursor
  INTO @ConditionType, @Material, @Hierarchy, @DateFrom, @DateTo, @Rate, @QTYType, @FileImportID, @Calculation, @AmountType
END

CLOSE ConditionType_Cursor
DEALLOCATE ConditionType_Cursor

UPDATE FI
SET IsHandled = 1
FROM SAP_FileImport FI
  INNER JOIN SAP_ConditionTypes CT ON PK_FileImportID = FK_FileImportID
WHERE IsHandled = 0 AND 
  EXISTS (
  SELECT SubCT.CONDITIONTYPE, SubCT.MATERIAL, CASE WHEN SubCT.CONDITIONTABLE = '793' THEN STUFF(SubCT.HIERARCHY, 19, 0, '              ') ELSE SubCT.HIERARCHY END HIERARCHY
  FROM SAP_FileImport SubFI
    INNER JOIN SAP_ConditionTypes SubCT ON SubFI.PK_FileImportID = SubCT.FK_FileImportID
  WHERE IsHandled = 0 AND CT.CONDITIONTYPE = SubCT.CONDITIONTYPE AND CT.MATERIAL = SubCT.MATERIAL AND 
	CASE WHEN CT.CONDITIONTABLE = '793' THEN STUFF(CT.HIERARCHY, 19, 0, '              ') ELSE CT.HIERARCHY END = 
		CASE WHEN SubCT.CONDITIONTABLE = '793' THEN STUFF(SubCT.HIERARCHY, 19, 0, '              ') ELSE SubCT.HIERARCHY END
  GROUP BY SubCT.CONDITIONTYPE, SubCT.MATERIAL, CASE WHEN SubCT.CONDITIONTABLE = '793' THEN STUFF(SubCT.HIERARCHY, 19, 0, '              ') ELSE SubCT.HIERARCHY END
  HAVING COUNT(*) > 1 )

INSERT INTO #tempPriceTable
SELECT CONDITIONTYPE, MATERIAL, CASE WHEN CONDITIONTABLE = '793' THEN STUFF(HIERARCHY, 19, 0, '              ') ELSE HIERARCHY END HIERARCHY, CASE WHEN DATEFROM > '20991231' THEN '20991231' ELSE DATEFROM END, CASE WHEN DATETO > '20991231' THEN '20991231' ELSE DATETO END, RATE, QTYTYPE, PK_FileImportID, CALCULATION, AMOUNTTYPE
FROM SAP_FileImport FI
  INNER JOIN SAP_ConditionTypes CT ON PK_FileImportID = FK_FileImportID
WHERE IsHandled = 0
GROUP BY CONDITIONTYPE, MATERIAL, CASE WHEN CONDITIONTABLE = '793' THEN STUFF(HIERARCHY, 19, 0, '              ') ELSE HIERARCHY END, CASE WHEN DATEFROM > '20991231' THEN '20991231' ELSE DATEFROM END, CASE WHEN DATETO > '20991231' THEN '20991231' ELSE DATETO END, RATE, QTYTYPE, PK_FileImportID, CALCULATION, AMOUNTTYPE

-- 2014-02-08 - PO - Changed the order of the shortening to happen after the insert of new lines with only 1 occurrence
-- 2014-02-08 - Also changed the check of the PeriodFrom to be based of the DATEFROM-column instead of DATETO.
-- If a condition on the same conditiontype, material and hierarchy level has the same value and startdate
-- as an existing condition it is assumed that it is a shortening of the existing condition, and therefore
-- the existing condition is deleted.
DELETE FROM CTP
FROM #tempPriceTable TPT
  INNER JOIN SAP_ConditionTypes_TotalList CTP ON TPT.CONDITIONTYPE = CTP.CONDITIONTYPE AND TPT.MATERIAL = CTP.MATERIAL AND TPT.HIERARCHY = CTP.HIERARCHY AND
    PeriodFrom = CONVERT ( datetime, DATEFROM, 112 ) AND PeriodTo > CONVERT( datetime, DATETO, 112 ) AND CASE WHEN RIGHT(RATE, 1) = '-' THEN - CAST(LEFT(RATE, LEN(RATE) - 1) as float) ELSE CAST(RATE as float) END = Value

DELETE FROM CTP
FROM #tempPriceTable TPT
  INNER JOIN SAP_ConditionTypes_TotalList CTP ON TPT.CONDITIONTYPE = CTP.CONDITIONTYPE AND TPT.MATERIAL = CTP.MATERIAL AND TPT.HIERARCHY = CTP.HIERARCHY
WHERE PeriodFrom >= CONVERT ( datetime, DATEFROM, 112 ) AND PeriodTo <= CONVERT ( datetime, DATETO, 112 )

INSERT INTO SAP_ConditionTypes_TotalList ( ConditionType, Material, Hierarchy, PeriodFrom, PeriodTo, Value, QTYType, FK_FileImportID, Calculation, AmountType )
SELECT TPT.CONDITIONTYPE, TPT.MATERIAL, TPT.HIERARCHY, CONVERT(datetime, DATETO, 112) + 1, PeriodTo, Value, TPT.QTYType, CTP.FK_FileImportID, TPT.Calculation, TPT.AmountType 
FROM #tempPriceTable TPT
  INNER JOIN SAP_ConditionTypes_TotalList CTP ON TPT.CONDITIONTYPE = CTP.CONDITIONTYPE AND TPT.MATERIAL = CTP.MATERIAL AND TPT.HIERARCHY = CTP.HIERARCHY
WHERE PeriodFrom < CONVERT ( datetime, DATEFROM, 112 ) AND PeriodTo > CONVERT ( datetime, DATETO, 112 )
  
UPDATE CTP
SET PeriodTo = CONVERT(datetime, DATEFROM, 112) - 1
FROM #tempPriceTable TPT
  INNER JOIN SAP_ConditionTypes_TotalList CTP ON TPT.CONDITIONTYPE = CTP.CONDITIONTYPE AND TPT.MATERIAL = CTP.MATERIAL AND TPT.HIERARCHY = CTP.HIERARCHY
WHERE PeriodFrom < CONVERT ( datetime, DATEFROM, 112 ) AND PeriodTo >= CONVERT ( datetime, DATEFROM, 112 )
  
UPDATE CTP
SET PeriodFrom = CONVERT(datetime, DATETO, 112) + 1
FROM #tempPriceTable TPT
  INNER JOIN SAP_ConditionTypes_TotalList CTP ON TPT.CONDITIONTYPE = CTP.CONDITIONTYPE AND TPT.MATERIAL = CTP.MATERIAL AND TPT.HIERARCHY = CTP.HIERARCHY
WHERE PeriodTo > CONVERT( datetime, DATETO, 112 ) AND PeriodFrom <= CONVERT ( datetime, DATETO, 112 )

INSERT INTO SAP_ConditionTypes_TotalList ( ConditionType, Material, Hierarchy, PeriodFrom, PeriodTo, Value, QTYType, FK_FileImportID, Calculation, AmountType )
SELECT CONDITIONTYPE, MATERIAL, HIERARCHY, CONVERT ( datetime, DATEFROM, 112 ), CONVERT ( datetime, DATETO, 112 ), 
  CASE WHEN RIGHT(RATE, 1) = '-' THEN - CAST(LEFT(RATE, LEN(RATE) - 1) as float) ELSE CAST(RATE as float) END, QTYType, FK_FileImportID, CALCULATION, AMOUNTTYPE
FROM #tempPriceTable TPT

DROP TABLE #tempPriceTable

UPDATE FI
SET IsHandled = 1
FROM SAP_FileImport FI
  INNER JOIN SAP_ConditionTypes CT ON PK_FileImportID = FK_FileImportID
WHERE IsHandled = 0

DELETE FROM TL
FROM SAP_ConditionTypes_TotalList TL
WHERE EXISTS (
  SELECT ConditionType, Material, Hierarchy, PeriodFrom, PeriodTo, MAX(UploadID)
  FROM SAP_ConditionTypes_TotalList SubTL
  GROUP BY ConditionType, Material, Hierarchy, PeriodFrom, PeriodTo
  HAVING COUNT(*) > 1 AND SubTL.ConditionType = TL.ConditionType AND SubTL.Material = TL.Material AND
    SubTL.Hierarchy = TL.Hierarchy AND SubTL.PeriodFrom = TL.PeriodFrom AND SubTL.PeriodTo = TL.PeriodTo AND TL.UploadID <> MAX(SubTL.UploadID) )
