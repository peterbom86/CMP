
CREATE 
PROCEDURE [dbo].[rdh_InsertBatchRunCampaignDetail]
  (
	@BatchRunCampaignID INT,
	@ActivityID INT,
	@ProductID INT,
	@BatchRunAction INT,
	@ActivityLabel VARCHAR(255),
	@ProductLabel VARCHAR(255),
	@ProductCode VARCHAR(50)
  )
  AS
BEGIN
	INSERT 
	  INTO BatchRunCampaignDetail 
	  ( 
		  FK_BatchRunCampaignID,
		  FK_ActivityID,
		  FK_ProductID,
		  BatchRunAction,
		  ActivityLabel,
		  ProductLabel,
		  ProductCode
	  ) 
	  SELECT 
		  @BatchRunCampaignID,
		  @ActivityID,
		  @ProductID,
		  @BatchRunAction,
		  ISNULL(A.Label, @ActivityLabel),
		  ISNULL(P.Label ,@ProductLabel),
		  ISNULL(P.ProductCode, @ProductCode)
		  FROM Products P
		  LEFT JOIN Activities A ON A.PK_ActivityID = @ActivityID
		  WHERE P.PK_ProductID = @ProductID

	SELECT SCOPE_IDENTITY()

END