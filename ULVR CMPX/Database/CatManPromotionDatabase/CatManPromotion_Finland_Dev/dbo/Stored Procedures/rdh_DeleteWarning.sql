Create procedure rdh_DeleteWarning
@WarningID int

AS

DELETE FROM 
  WarningsUser
WHERE 
  PK_UserWarningID = @WarningID

