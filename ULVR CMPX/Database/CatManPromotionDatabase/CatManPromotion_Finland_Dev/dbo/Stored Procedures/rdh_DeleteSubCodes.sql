CREATE  PROCEDURE rdh_DeleteSubCodes
  @SubCodeID int

AS

DELETE FROM CommonCodes
WHERE PK_CommonCodeID = @SubCodeID





