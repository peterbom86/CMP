CREATE 
--ALTER 
PROCEDURE [dbo].[rdh_InsertBatchRun]
  (
	@UserID INT,
	@BatchRunType INT 
  )
  AS
  BEGIN
INSERT 
  INTO BatchRun 
  ( 
	  FK_CreatedByUserID,
	  CreatedDate,
	  BatchRunType
  ) 
  VALUES 
  ( 
	  @UserID,
	  getdate(),
	  @BatchRunType
  )

SELECT SCOPE_IDENTITY()

END