CREATE PROCEDURE rdh_DeleteExternalCustomerLinks
  @ExternalCustomerLinkLineID int

AS

DECLARE @ParticipatorID int
SELECT @ParticipatorID = FK_ParticipatorID
FROM ExternalCustomerLinkLines
WHERE PK_ExternalCustomerLinkLineID = @ExternalCustomerLinkLineID

SET @ParticipatorID = ISNULL( @ParticipatorID, 0)

DELETE FROM ExternalCustomerLinkLines
WHERE PK_ExternalCustomerLinkLineID = @ExternalCustomerLinkLineID

EXEC rdh_SelectExternalCustomerLinks @ParticipatorID
