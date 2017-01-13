CREATE PROCEDURE rdh_ChangeOwnerParticipator
  @NewOwnerID int,
  @ParticipatorID int

AS

UPDATE Campaigns
SET FK_OwnerUserID = @NewOwnerID
WHERE FK_ChainID = @ParticipatorID
