CREATE PROCEDURE [dbo].[rdh_ImportSAPProductNames_TotalList_Sirius]

AS

SELECT PK_FileNameID, FK_FileImportID, MATERIAL, LanguageCode, ProductName
INTO #newProductNames
FROM SAP_ProductNames
WHERE EXISTS (
  SELECT MAX(PK_FileNameID) MaxFileNameID
  FROM (
    SELECT MAX(ImportDate) MaxImportDate, MATERIAL, LanguageCode
    FROM SAP_FileImport
      INNER JOIN SAP_ProductNames ON PK_FileImportID = FK_FileImportID
    WHERE IsHandled = 0
    GROUP BY MATERIAL, LanguageCode) LatestImports
      INNER JOIN SAP_ProductNames PN ON LatestImports.MATERIAL = PN.MATERIAL AND LatestImports.LanguageCode = PN.LanguageCode
      INNER JOIN SAP_FileImport FI ON PK_FileImportID = FK_FileImportID AND FI.ImportDate = MaxImportDate
  GROUP BY LatestImports.MATERIAL, LatestImports.LanguageCode
  HAVING SAP_ProductNames.PK_FileNameID = MAX(PN.PK_FileNameID))

UPDATE TL
SET FK_FileNameID = #newProductNames.PK_FileNameID,
  FK_FileImportID = #newProductNames.FK_FileImportID,
  Material = #newProductNames.MATERIAL,
  LanguageCode = #newProductNames.LanguageCode,
  ProductName = #newProductNames.ProductName
FROM SAP_ProductNames_TotalList TL
  INNER JOIN #newProductNames ON TL.Material = #newProductNames.MATERIAL AND TL.LanguageCode = #newProductNames.LanguageCode
WHERE TL.Material <> #newProductNames.MATERIAL OR
  TL.LanguageCode <> #newProductNames.LanguageCode OR
  TL.ProductName <> #newProductNames.ProductName


INSERT INTO SAP_ProductNames_TotalList ( FK_FileNameID, FK_FileImportID, Material, LanguageCode, ProductName )
SELECT PK_FileNameID, FK_FileImportID, MATERIAL, LanguageCode, ProductName
FROM #newProductNames n
WHERE NOT EXISTS (SELECT * FROM SAP_ProductNames_TotalList TL WHERE TL.Material = n.MATERIAL AND TL.LanguageCode = n.LanguageCode )

DROP TABLE #newProductNames


