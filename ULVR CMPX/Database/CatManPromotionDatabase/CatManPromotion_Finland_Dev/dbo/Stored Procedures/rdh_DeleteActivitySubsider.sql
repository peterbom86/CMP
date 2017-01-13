Create procedure rdh_DeleteActivitySubsider
@ActivitySubsiderID int

AS 

DELETE FROM ActivitySubsider WHERE PK_ActivitySubsiderID=@ActivitySubsiderID



