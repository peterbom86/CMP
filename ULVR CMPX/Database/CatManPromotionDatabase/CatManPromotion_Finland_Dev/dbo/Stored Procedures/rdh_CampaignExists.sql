CREATE PROCEDURE rdh_CampaignExists ( @CampaignID INT ) AS
SELECT 
  CASE COUNT( PK_CampaignID ) 
    WHEN 0 THEN 0 
    WHEN NULL THEN 0 
    ELSE 1 
  END 
  AS CampaignExists 
  FROM Campaigns 
  WHERE (  PK_CampaignID = @CampaignID )


