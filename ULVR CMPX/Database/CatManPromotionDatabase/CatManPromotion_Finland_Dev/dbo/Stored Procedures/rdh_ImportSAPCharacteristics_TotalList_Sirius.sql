CREATE PROCEDURE [dbo].[rdh_ImportSAPCharacteristics_TotalList_Sirius]

AS

SELECT PK_CharacteristicID, FK_FileImportID, MATERIAL, Name, Value1, Value2
INTO #newCharacteristics
FROM SAP_Characteristics
WHERE Value2 <> '?' AND EXISTS (
  SELECT MAX(PK_CharacteristicID) MaxCharacteristicID
  FROM (
    SELECT MAX(ImportDate) MaxImportDate, MATERIAL, Name
    FROM SAP_FileImport
      INNER JOIN SAP_Characteristics ON PK_FileImportID = FK_FileImportID
    WHERE IsHandled = 0
    GROUP BY MATERIAL, Name) LatestImports
      INNER JOIN SAP_Characteristics C ON LatestImports.MATERIAL = C.MATERIAL AND LatestImports.Name = C.Name
      INNER JOIN SAP_FileImport FI ON PK_FileImportID = FK_FileImportID AND FI.ImportDate = MaxImportDate
  GROUP BY LatestImports.MATERIAL, LatestImports.Name
  HAVING SAP_Characteristics.PK_CharacteristicID = MAX(C.PK_CharacteristicID))

UPDATE TL
SET FK_FileImportID = #newCharacteristics.FK_FileImportID,
  Material = #newCharacteristics.MATERIAL,
  Name = #newCharacteristics.Name,
  Value1 = #newCharacteristics.Value1,
  Value2 = #newCharacteristics.Value2
FROM SAP_Characteristics_TotalList TL
  INNER JOIN #newCharacteristics ON TL.Material = #newCharacteristics.MATERIAL AND TL.Name = #newCharacteristics.Name
WHERE TL.Material <> #newCharacteristics.MATERIAL OR
  TL.Name <> #newCharacteristics.Name OR
  TL.Value1 <> #newCharacteristics.Value1 OR
  TL.Value2 <> #newCharacteristics.Value2

INSERT INTO SAP_Characteristics_TotalList ( FK_CharacteristicID, FK_FileImportID, Material, Name, Value1, Value2 )
SELECT PK_CharacteristicID, FK_FileImportID, MATERIAL, Name, Value1, Value2
FROM #newCharacteristics n
WHERE NOT EXISTS (SELECT * FROM SAP_Characteristics_TotalList TL WHERE TL.Material = n.MATERIAL AND TL.Name = n.Name )

DROP TABLE #newCharacteristics


