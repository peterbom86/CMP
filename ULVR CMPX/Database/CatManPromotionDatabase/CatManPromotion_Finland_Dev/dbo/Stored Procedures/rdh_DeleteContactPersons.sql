CREATE PROCEDURE rdh_DeleteContactPersons
  @ContactPersonID int,
  @ParticipatorID int

AS

DELETE FROM ParticipatorContactPerson
WHERE FK_ContactPersonID = @ContactPersonID AND
  FK_ParticipatorID = @ParticipatorID


DELETE FROM ContactPersons
WHERE PK_ContactPersonID = @ContactPersonID




