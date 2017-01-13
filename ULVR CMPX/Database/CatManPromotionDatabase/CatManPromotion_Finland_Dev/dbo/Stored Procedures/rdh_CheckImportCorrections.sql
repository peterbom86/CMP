CREATE PROCEDURE rdh_CheckImportCorrections

AS

INSERT INTO SAP_DeletedCharacteristics (
FK_CharacteristicsID, FK_FileImportID, MATERIAL,
 Name, Value1, Value2 )
SELECT PK_CharacteristicID, PK_FileImportID, C.MATERIAL,
 Name, Value1, Value2
FROM SAP_Characteristics C
  INNER JOIN SAP_FileImport ON PK_FileImportID = C.FK_FileImportID
  INNER JOIN SAP_MatInfo MI ON PK_FileImportID = MI.FK_FileImportID
  INNER JOIN SAP_ManualLoadCorrections MLC ON CAST(CAST(MI.MATERIAL as bigint) as nvarchar(50)) = MLC.Material
WHERE C.Name LIKE 'Z3_TCODE' AND NoTcode = 1 AND IsHandled = 0

DELETE FROM C
FROM SAP_Characteristics C
  INNER JOIN SAP_FileImport ON PK_FileImportID = C.FK_FileImportID
  INNER JOIN SAP_MatInfo MI ON PK_FileImportID = MI.FK_FileImportID
  INNER JOIN SAP_ManualLoadCorrections MLC ON CAST(CAST(MI.MATERIAL as bigint) as nvarchar(50)) = MLC.Material
WHERE C.Name LIKE 'Z3_TCODE' AND NoTcode = 1 AND IsHandled = 0
