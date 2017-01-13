CREATE PROCEDURE [dbo].rdh_ExcelSupplyCostHeader

AS

SELECT PK_SupplyCostHeaderID, PeriodFrom, PeriodTo, CreatedBy, CreatedDate
FROM SupplyCostHeader
ORDER BY PeriodFrom DESC
