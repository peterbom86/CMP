

CREATE PROCEDURE rdh_ChangeOwnerUser
  @NewOwnerID int,
  @OldOwnerID int

AS

UPDATE Campaigns
SET FK_OwnerUserID = @NewOwnerID
WHERE FK_OwnerUserID = @OldOwnerID
