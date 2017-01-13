
CREATE  PROCEDURE rdh_DeleteActivity
@ActivityID int

AS

--ACTIVITYDISCOUNTS
DELETE FROM CampaignDiscounts WHERE FK_ActivityLineID IN 
(SELECT PK_ActivityLineID FROM ActivityLines WHERE FK_ActivityID=@ActivityID)

--ACTIVITYLINESTOESAP
DELETE FROM AL 
FROM ActivityLinesToESAP AL
  INNER JOIN ActivityLines ON PK_ActivityLineID = FK_ActivityLineID
WHERE FK_ActivityID = @ActivityID

--ACTIVITYLINES
DELETE FROM ActivityLines WHERE FK_ActivityID=@ActivityID

--ACTIVITYDELIVERIES
DELETE FROM ActivityDeliveries WHERE FK_ActivityID=@ActivityID

--ACTIVITYSUBSIDER
DELETE FROM ActivitySubsider WHERE FK_ActivityID=@ActivityID

--ACTIVITY
DELETE FROM Activities WHERE PK_ActivityID=@ActivityID


