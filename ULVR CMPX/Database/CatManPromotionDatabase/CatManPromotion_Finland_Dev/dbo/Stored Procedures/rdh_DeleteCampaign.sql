
CREATE     procedure [dbo].[rdh_DeleteCampaign] 
@CampaignID int

AS

--ACTIVITYDISCOUNTS
DELETE FROM CampaignDiscounts WHERE FK_ActivityLineID IN 
(SELECT PK_ActivityLineID FROM ActivityLines WHERE FK_ActivityID IN (SELECT PK_ActivityID FROM Activities WHERE FK_CampaignID = @CampaignID))

DELETE FROM AL 
FROM ActivityLinesToESAP AL
  INNER JOIN ActivityLines ON PK_ActivityLineID = FK_ActivityLineID
  INNER JOIN Activities A ON PK_ActivityID = FK_ActivityID
WHERE FK_CampaignID = @CampaignID

--ACTIVITYLINES
DELETE FROM ActivityLines WHERE FK_ActivityID IN (SELECT PK_ActivityID FROM Activities WHERE FK_CampaignID = @CampaignID)

--ACTIVITYDELIVERIES
DELETE FROM ActivityDeliveries WHERE FK_ActivityID IN (SELECT PK_ActivityID FROM Activities WHERE FK_CampaignID = @CampaignID)

--ACTIVITYSUBSIDER
DELETE FROM ActivitySubsider WHERE FK_ActivityID IN (SELECT PK_ActivityID FROM Activities WHERE FK_CampaignID = @CampaignID)

--ACTIVITY
DELETE FROM Activities WHERE PK_ActivityID IN (SELECT PK_ActivityID FROM Activities WHERE FK_CampaignID = @CampaignID)

--ACTIVITYSUBSIDER
DELETE FROM CampaignSubsider WHERE FK_CampaignID = @CampaignID

--CAMPAIGN
DELETE FROM Campaigns WHERE PK_CampaignID = @CampaignID





