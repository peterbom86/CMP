CREATE  procedure rdh_DeleteCampaignSubsider
@CampaignSubsiderID int

AS 

DELETE FROM CampaignSubsider WHERE PK_CampaignSubsiderID=@CampaignSubsiderID





