CREATE PROCEDURE rdh_DeactivateMaterialChange
  @MaterialChangeID int

AS

UPDATE MaterialChanges
SET Deactivated = 1
WHERE PK_MaterialChangeID = @MaterialChangeID

