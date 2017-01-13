--PO 5/3-2007
CREATE PROCEDURE rdh_GetUploadCampaignDiscountInfo

AS

SELECT UploadID, Label + ' ' + CONVERT(varchar, UploadDate, 105) + ' ' + CONVERT(varchar, UploadDate, 108) UploadDate
FROM tblUploadCampaignDiscountOnInvoice
ORDER BY UploadDate DESC

