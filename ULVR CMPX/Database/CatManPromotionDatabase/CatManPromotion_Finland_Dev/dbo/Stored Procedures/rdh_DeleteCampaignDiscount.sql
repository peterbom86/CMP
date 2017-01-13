CREATE  PROCEDURE rdh_DeleteCampaignDiscount( @CampaignDiscountID INT ) AS
DELETE FROM CampaignDiscounts WHERE ( PK_CampaignDiscountID = @CampaignDiscountID )





