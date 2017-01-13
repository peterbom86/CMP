CREATE PROCEDURE [dbo].[rdh_ImportMaterials_Sirius_initialCheck] 

AS 

---------------------------------------------------------------------- 
--                 Perform BOM load corrections                     -- 
---------------------------------------------------------------------- 
--Print 'BOM Load Corrections' 
--EXEC rdh_ImportBOM_ManualLoadCorrections 
--Not needed anymore - the load is done from TotalList instead
---------------------------------------------------------------------- 
--                     Perform load corrections                     -- 
---------------------------------------------------------------------- 
Print 'Load Corrections ' 
EXEC rdh_CheckImportCorrections 

---------------------------------------------------------------------- 
--                   Do not import errorous files                   -- 
---------------------------------------------------------------------- 
PRINT 'Do not import errorous files ' 
UPDATE FI 
SET IsHandled = 1, 
  HandledDate = GETDATE() 
FROM SAP_FileImport FI 
WHERE IsHandled = 0 AND PK_FileImportID IN ( 
  SELECT FK_FileImportID FROM SAP_Errors)

---------------------------------------------------------------------- 
--      Only import the latest file of a given material             -- 
---------------------------------------------------------------------- 
PRINT 'Only import the latest file of a given material' 
UPDATE FI 
SET IsHandled = 1, 
  HandledDate = GETDATE() 
FROM SAP_FileImport FI 
WHERE IsHandled = 0 AND FK_FileTypeID = 2 AND PK_FileImportID NOT IN ( 
  SELECT MAX(PK_FileImportID) MaxID 
  FROM SAP_FileImport 
    INNER JOIN SAP_MATINFO ON PK_FileImportID = FK_FileImportID 
  WHERE IsHandled = 0 
  GROUP BY MATERIAL) 

---------------------------------------------------------------------- 
--       Do not import products with questionmarks in T-code        -- 
---------------------------------------------------------------------- 
/*
Handled in CommonCodeChanges

UPDATE FI 
SET IsHandled = 1, 
  HandledDate = GETDATE() 
FROM SAP_FileImport FI 
  INNER JOIN SAP_Characteristics C ON PK_FileImportID = FK_FileImportID 
WHERE IsHandled = 0 AND C.Name = 'Z3_TCODE' AND C.Value2 = '?' 
*/
---------------------------------------------------------------------- 
--                 Check multiple t-codes                           -- 
---------------------------------------------------------------------- 
PRINT 'Check multiple t-codes' 
INSERT INTO SAP_Errors (FK_FileImportID, Caller, Segment, Description, SystemError ) 
SELECT PK_FileImportID, 'import_CreateProducts', 'Y1MM_CLASS_CHARACTERISTICS', 'Multiple T-codes per material', 'Multiple T-codes per material' 
FROM SAP_FileImport FI 
  INNER JOIN SAP_MATINFO MI ON PK_FileImportID = MI.FK_FileImportID 
  INNER JOIN SAP_Characteristics C ON PK_FileImportID = C.FK_FileImportID AND C.Name = 'Z3_TCODE' 
WHERE IsHandled = 0 
GROUP BY PK_FileImportID 
HAVING COUNT(*) > 1 
/*
Dubletterne er slettet i stedet for at annullere indlæsningen
UPDATE FI 
SET IsHandled = 1, 
  HandledDate = GETDATE() 
FROM SAP_FileImport FI 
WHERE PK_FileImportID IN ( 
  SELECT PK_FileImportID 
  FROM SAP_FileImport FI 
    INNER JOIN SAP_MATINFO MI ON PK_FileImportID = MI.FK_FileImportID 
    INNER JOIN SAP_Characteristics C ON PK_FileImportID = C.FK_FileImportID AND C.Name = 'Z3_TCODE' 
  WHERE IsHandled = 0 
  GROUP BY PK_FileImportID 
  HAVING COUNT(*) > 1)
*/
DELETE FROM sc
FROM dbo.SAP_Characteristics as sc
	INNER JOIN (
	  SELECT PK_FileImportID, MIN(PK_CharacteristicID) MinCharacteristicID
	  FROM SAP_FileImport FI 
		INNER JOIN SAP_Characteristics C ON PK_FileImportID = C.FK_FileImportID AND C.Name = 'Z3_TCODE' 
	  WHERE IsHandled = 0 
	  GROUP BY PK_FileImportID
	  HAVING COUNT(*) > 1) Sub ON sc.FK_FileImportID = Sub.PK_FileImportID AND sc.Name = 'Z3_TCODE' AND MinCharacteristicID <> sc.PK_CharacteristicID


---------------------------------------------------------------------- 
--       BOM correction. Flag invalid components under same header  -- 
---------------------------------------------------------------------- 
--SELECT 
--	FK_FileImportID, MATERIAL_HEADER
--INTO #BOM_ERRORS
--FROM 
--	dbo.SAP_BOM
--GROUP BY 
--	FK_FileImportID, MATERIAL_HEADER, MATERIAL_COMPONENT
--HAVING 
--	COUNT(MATERIAL_COMPONENT)>1

--UPDATE SB
--SET 
--	SB.Valid = 0, SB.[Exception] = 'Duplicate components under same header'
--FROM
--	dbo.SAP_BOM SB
--	INNER JOIN #BOM_ERRORS BE ON SB.FK_FileImportID = BE.FK_FileImportID AND SB.MATERIAL_HEADER = BE.MATERIAL_HEADER
--DROP TABLE #BOM_ERRORS