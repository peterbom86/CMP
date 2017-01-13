CREATE  PROCEDURE rdh_DeactivateMaterialChangeVer2
  @MaterialChangeID int,
  @UserID int

AS

UPDATE MaterialChanges
SET Deactivated = 1, 
  DeactivatedDate = GETDATE(),
  DeactivatedBy = @UserID
WHERE PK_MaterialChangeID = @MaterialChangeID


