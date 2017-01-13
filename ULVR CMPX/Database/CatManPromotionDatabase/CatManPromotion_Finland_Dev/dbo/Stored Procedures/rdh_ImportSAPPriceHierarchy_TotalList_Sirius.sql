CREATE PROCEDURE [dbo].[rdh_ImportSAPPriceHierarchy_TotalList_Sirius]

AS

SELECT PK_PriceHierarchyID, FK_FileImportID, MATERIAL, NAME, KEY1, KEY2, KEY3, VALUE1, VALUE2, VALUE3
INTO #newPriceHierarchy
FROM SAP_PriceHierarchy
WHERE EXISTS (
  SELECT MAX(PK_PriceHierarchyID) MaxPriceHierarchyID
  FROM (
    SELECT MAX(ImportDate) MaxImportDate, MATERIAL, NAME
    FROM SAP_FileImport
      INNER JOIN SAP_PriceHierarchy ON PK_FileImportID = FK_FileImportID
    WHERE IsHandled = 0
    GROUP BY MATERIAL, NAME) LatestImports
      INNER JOIN SAP_PriceHierarchy PH ON LatestImports.MATERIAL = PH.MATERIAL AND LatestImports.NAME = PH.NAME
      INNER JOIN SAP_FileImport FI ON PK_FileImportID = FK_FileImportID AND FI.ImportDate = MaxImportDate
  GROUP BY LatestImports.MATERIAL, LatestImports.NAME
  HAVING SAP_PriceHierarchy.PK_PriceHierarchyID = MAX(PH.PK_PriceHierarchyID))

UPDATE TL
SET FK_PriceHierarchyID = #newPriceHierarchy.PK_PriceHierarchyID,
  FK_FileImportID = #newPriceHierarchy.FK_FileImportID,
  Material = #newPriceHierarchy.MATERIAL,
  Name = #newPriceHierarchy.NAME,
  Key1 = #newPriceHierarchy.KEY1,
  Key2 = #newPriceHierarchy.KEY2,
  Key3 = #newPriceHierarchy.KEY3,
  Value1 = #newPriceHierarchy.VALUE1,
  Value2 = #newPriceHierarchy.VALUE2,
  Value3 = #newPriceHierarchy.VALUE3
FROM SAP_PriceHierarchy_TotalList TL
  INNER JOIN #newPriceHierarchy ON TL.Material = #newPriceHierarchy.MATERIAL AND TL.Name = #newPriceHierarchy.NAME
WHERE TL.Material <> #newPriceHierarchy.MATERIAL OR
  TL.Name <> #newPriceHierarchy.NAME OR
  TL.Key1 <> #newPriceHierarchy.KEY1 OR
  TL.Key2 <> #newPriceHierarchy.KEY2 OR
  TL.Key3 <> #newPriceHierarchy.KEY3 OR
  TL.Value1 <> #newPriceHierarchy.VALUE1 OR
  TL.Value2 <> #newPriceHierarchy.VALUE2 OR
  TL.Value3 <> #newPriceHierarchy.VALUE3

INSERT INTO SAP_PriceHierarchy_TotalList ( FK_PriceHierarchyID, FK_FileImportID, Material, Name, Key1, Key2, Key3, Value1, Value2, Value3 )
SELECT PK_PriceHierarchyID, FK_FileImportID, MATERIAL, NAME, KEY1, KEY2, KEY3, VALUE1, VALUE2, VALUE3
FROM #newPriceHierarchy n
WHERE NOT EXISTS (SELECT * FROM SAP_PriceHierarchy_TotalList TL WHERE TL.Material = n.MATERIAL AND TL.Name = n.NAME )

DROP TABLE #newPriceHierarchy


