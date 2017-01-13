CREATE PROCEDURE [dbo].[rdh_ImportSAPMATINFO_TotalList_Sirius]

AS

SELECT PK_MatInfoID, FK_FileImportID, MATERIAL, STATUS, VOLUME, WEIGHT, NODEGROUP, ITEMCATEGORY, SHORTEAN, DIVISION
INTO #newMatInfo
FROM SAP_MATINFO
WHERE EXISTS (
  SELECT MAX(PK_MatInfoID) MaxMatInfoID
  FROM (
    SELECT MAX(ImportDate) MaxImportDate, MATERIAL
    FROM SAP_FileImport
      INNER JOIN SAP_MATINFO ON PK_FileImportID = FK_FileImportID
    WHERE IsHandled = 0
    GROUP BY MATERIAL) LatestImports
      INNER JOIN SAP_MATINFO MI ON LatestImports.MATERIAL = MI.MATERIAL
      INNER JOIN SAP_FileImport FI ON PK_FileImportID = FK_FileImportID AND FI.ImportDate = MaxImportDate
  GROUP BY LatestImports.MATERIAL
  HAVING SAP_MATINFO.PK_MatInfoID = MAX(MI.PK_MatInfoID))

UPDATE TL
SET FK_FileImportID = #newMatInfo.FK_FileImportID,
  Material = #newMatInfo.MATERIAL,
  Status = #newMatInfo.STATUS,
  Volume = #newMatInfo.VOLUME,
  Weight = #newMatInfo.WEIGHT,
  NodeGroup = #newMatInfo.NODEGROUP,
  ItemCategory = #newMatInfo.ITEMCATEGORY,
  ShortEAN = #newMatInfo.SHORTEAN,
  Division = #newMatInfo.DIVISION
FROM SAP_MATINFO_TotalList TL
  INNER JOIN #newMatInfo ON TL.Material = #newMatInfo.MATERIAL
WHERE TL.Material <> #newMatInfo.MATERIAL OR
  TL.Status <> #newMatInfo.STATUS OR
  TL.Volume <> #newMatInfo.VOLUME OR
  TL.Weight <> #newMatInfo.WEIGHT OR
  TL.NodeGroup <> #newMatInfo.NODEGROUP OR
  TL.ItemCategory <> #newMatInfo.ITEMCATEGORY OR
  ISNULL(TL.ShortEAN, '-1') <> ISNULL(#newMatInfo.SHORTEAN, '-1') OR
  ISNULL(TL.Division, '-1') <> ISNULL(#newMatInfo.DIVISION, '-1')

INSERT INTO SAP_MATINFO_TotalList ( FK_MatInfoID, FK_FileImportID, Material, Status, Volume, Weight, NodeGroup, ItemCategory, ShortEAN, Division )
SELECT PK_MatInfoID, FK_FileImportID, MATERIAL, STATUS, VOLUME, WEIGHT, NODEGROUP, ITEMCATEGORY, SHORTEAN, DIVISION
FROM #newMatInfo
WHERE MATERIAL NOT IN (SELECT Material FROM SAP_MATINFO_TotalList)

DROP TABLE #newMatInfo

