CREATE  PROCEDURE rdh_DeleteWarnings
  @WarningID int

AS

DELETE FROM Warnings
WHERE PK_WarningID = @WarningID





