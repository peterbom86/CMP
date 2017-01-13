CREATE  procedure rdh_DeleteEvent
@EventID int

AS

DELETE FROM EventCalender WHERE PK_EventID = @EventID


