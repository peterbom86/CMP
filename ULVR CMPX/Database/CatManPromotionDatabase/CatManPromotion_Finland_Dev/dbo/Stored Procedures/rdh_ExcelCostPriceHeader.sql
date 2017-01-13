CREATE PROCEDURE [dbo].[rdh_ExcelCostPriceHeader]

AS

SELECT PK_CostPriceHeaderID, PeriodFrom, PeriodTo, CreatedBy, CreatedDate
FROM CostPriceHeader
ORDER BY PeriodFrom DESC
