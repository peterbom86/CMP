--PO 5/3-2007
CREATE  PROCEDURE rdh_DeleteCampaignDiscountOnInvoiceUpload
  @UploadID int

AS

BEGIN TRANSACTION
DELETE FROM SettlementDiscounts
WHERE FK_SettlementLineID IN (
  SELECT PK_SettlementLineID
  FROM SettlementLines
  WHERE FK_SettlementID IN (
    SELECT SettlementID
    FROM tblUploadCampaignDiscountOnInvoiceLines
    WHERE UploadID = @UploadID AND SettlementID IS NOT Null))

DELETE FROM SettlementLines
WHERE FK_SettlementID IN (
  SELECT SettlementID 
  FROM tblUploadCampaignDiscountOnInvoiceLines
  WHERE UploadID = @UploadID AND SettlementID IS NOT Null)

DELETE FROM Settlements
WHERE PK_SettlementID IN (
  SELECT SettlementID
  FROM tblUploadCampaignDiscountOnInvoiceLines
  WHERE UploadID = @UploadID AND SettlementID IS NOT Null)

DELETE FROM tblUploadCampaignDiscountOnInvoiceLines
WHERE UploadID = @UploadID

DELETE FROM tblUploadCampaignDiscountOnInvoice
WHERE UploadID = @UploadID
COMMIT TRANSACTION

