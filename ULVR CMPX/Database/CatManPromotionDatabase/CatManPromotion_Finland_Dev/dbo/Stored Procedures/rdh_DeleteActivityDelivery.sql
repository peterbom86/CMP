CREATE  PROCEDURE rdh_DeleteActivityDelivery(@ActivityID INT ) AS
DELETE FROM ActivityDeliveries
WHERE FK_ActivityID = @ActivityID





