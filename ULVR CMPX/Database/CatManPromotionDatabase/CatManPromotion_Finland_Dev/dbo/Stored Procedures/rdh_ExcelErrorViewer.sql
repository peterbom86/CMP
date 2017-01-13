CREATE PROCEDURE [dbo].rdh_ExcelErrorViewer
  @PeriodFrom datetime,
  @PeriodTo datetime
  
AS

SELECT PK_FileImportID FileImportID, sfi.ImportDate, RIGHT(FileName, PATINDEX('%\%', REVERSE(FileName)) - 1) FileName,
  Caller, Segment, Description, se.SystemError, sse.FriendlyError, sm.MATERIAL
FROM dbo.SAP_FileImport AS sfi
  INNER JOIN dbo.SAP_Errors AS se ON sfi.PK_FileImportID = se.FK_FileImportID
  LEFT JOIN SAP_SystemErrors AS sse ON se.SystemError = sse.SystemError
  LEFT JOIN dbo.SAP_MATINFO AS sm ON sfi.PK_FileImportID = sm.FK_FileImportID
WHERE sfi.ImportDate BETWEEN @PeriodFrom AND @PeriodTo
