-- 16.02.2007 - PO
-- 10.07.2008 - PO ændret at det er userid:1, der udfører.

CREATE PROCEDURE rdh_CleanUpUsedBOM

AS

--Henter den rigtige BOM i følge Master Data og sammenligner med den anvendte BOM i følge ActivityLines
SELECT DISTINCT ISNULL(ActiveSalesUnits.FK_ActivityID, AL.FK_ActivityID) ActivityID, ISNULL(BOM.FK_HeaderProductID, AL.FK_SalesUnitID) SalesUnitID
INTO #tempTable
FROM BillOfMaterials BOM
  INNER JOIN BillOfMaterialLines BOML ON PK_BillOfMaterialID = FK_BillOfMaterialID
  INNER JOIN (SELECT DISTINCT FK_ActivityID, FK_SalesUnitID FROM ActivityLines) ActiveSalesUnits ON FK_HeaderProductID = ActiveSalesUnits.FK_SalesUnitID
  FULL JOIN ActivityLines AL ON ActiveSalesUnits.FK_ActivityID = AL.FK_ActivityID AND FK_HeaderProductID = AL.FK_SalesUnitID AND FK_ComponentProductID = FK_ProductID
WHERE (FK_HeaderProductID IS Null OR AL.FK_SalesUnitID IS Null) AND NOT EXISTS (
  SELECT * FROM MaterialChanges MC INNER JOIN MaterialChangeLines MCL ON PK_MaterialChangeID = FK_MaterialChangeID
  WHERE CreatedBy = 1 AND Approved = 0 AND ISNULL(BOM.FK_HeaderProductID, AL.FK_SalesUnitID) = FK_OldProductID AND ISNULL(ActiveSalesUnits.FK_ActivityID, AL.FK_ActivityID) = MCL.FK_ActivityID)

INSERT INTO MaterialChanges (FK_OldProductID, FK_NewProductID, PeriodFrom, PeriodTo, Deactivated, CreatedDate, CreatedBy)
SELECT DISTINCT SalesUnitID, SalesUnitID, '2001-01-01', '2099-12-31', 0, GETDATE(), 1
FROM #tempTable

INSERT INTO MaterialChangeLines (FK_MaterialChangeID, FK_ActivityID, Approved, Changed)
SELECT PK_MaterialChangeID, ActivityID, 0, 0
FROM MaterialChanges
  INNER JOIN #tempTable ON FK_OldProductID = SalesUnitID
WHERE CreatedDate >= GETDATE() - '0:10:00'

DROP TABLE #tempTable

SELECT DISTINCT FK_ActivityId, FK_SalesUnitID
INTO #tempTable2
FROM (
SELECT FK_ActivityID, FK_SalesUnitID, FK_ProductID
FROM ActivityLines
GROUP BY FK_ActivityID, FK_SalesUnitID, FK_ProductID
HAVING Count(*) > 1) SubQ
WHERE NOT EXISTS (
  SELECT * FROM MaterialChanges MC
    INNER JOIN MaterialChangeLines MCL ON PK_MaterialChangeID = FK_MaterialChangeID
  WHERE Deactivated = 0 AND Approved = 0 AND SubQ.FK_ActivityID = MCL.FK_ActivityID AND
    SubQ.FK_SalesUnitID = MC.FK_OldProductID )
ORDER BY FK_ActivityID, FK_SalesUnitID

INSERT INTO MaterialChanges (FK_OldProductID, FK_NewProductId, PeriodFrom, PeriodTo, CreatedDate, CreatedBy)
SELECT DISTINCT FK_SalesUnitID, FK_SalesUnitID, '2001-01-01', '2099-12-31', '9999-12-31', 1
FROM #tempTable2

INSERT INTO MaterialChangeLines (FK_MaterialChangeId, FK_ActivityId, Approved, Changed)
SELECT PK_MaterialChangeID, FK_ActivityId, 0, 0
FROM #tempTable2
  INNER JOIN MaterialChanges ON CreatedBy = 1 AND CreatedDate = '9999-12-31' AND FK_OldProductID = FK_SalesUnitID

UPDATE MC
SET CreatedDate = GETDATE()
FROM MaterialChanges MC
WHERE CreatedBy = 1 AND CreatedDate = '9999-12-31'

DROP TABLE #tempTable2

