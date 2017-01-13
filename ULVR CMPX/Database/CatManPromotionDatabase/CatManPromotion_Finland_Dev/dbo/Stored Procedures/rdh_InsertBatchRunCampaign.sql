CREATE 
PROCEDURE [dbo].[rdh_InsertBatchRunCampaign]
  (
	@BatchRunID INT,
	@CampaignID INT,
	@CopyOfCampaignID INT,
	@BatchRunAction INT,
	@BatchRunReason INT,
	@CampaignLabel VARCHAR(255)
  )
  AS
BEGIN
	INSERT 
	  INTO BatchRunCampaign 
	  ( 
		  FK_BatchRunID,
		  FK_CampaignID,
		  FK_CopyOfCampaignID,
		  BatchRunAction,
		  BatchRunReason,
		  CampaignLabel
	  ) 
	  SELECT 
		  @BatchRunID,
		  @CampaignID,
		  CASE @CopyOfCampaignID WHEN -1 THEN NULL ELSE @CopyOfCampaignID END,
		  @BatchRunAction,
		  @BatchRunReason,
		  ISNULL(C.Label, @CampaignLabel)
	  FROM Campaigns C
	 WHERE C.PK_CampaignID = @CampaignID

	SELECT SCOPE_IDENTITY()

END