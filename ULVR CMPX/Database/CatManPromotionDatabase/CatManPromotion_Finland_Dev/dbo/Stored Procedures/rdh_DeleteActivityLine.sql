CREATE PROCEDURE rdh_DeleteActivityLine( @ActivityLineID INT ) 

AS

DELETE FROM ActivityLinesToESAP WHERE FK_ActivityLineID = @ActivityLineID

--ACTIVITYDISCOUNTS
DELETE FROM CampaignDiscounts WHERE FK_ActivityLineID = @ActivityLineID

--ACTIVITYLINE
DELETE FROM ActivityLines WHERE PK_ActivityLineID = @ActivityLineID

