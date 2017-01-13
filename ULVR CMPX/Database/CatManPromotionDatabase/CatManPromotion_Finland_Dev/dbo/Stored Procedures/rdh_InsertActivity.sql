/* DDC: 13.09.2006 */

CREATE          PROCEDURE [dbo].[rdh_InsertActivity](
  @CampaignID INT,
  @Label VARCHAR(255), 
  @Description VARCHAR(255), 
  @StatusID INT, 
  @From VARCHAR(10), 
  @To VARCHAR(10),
  @PriceTag VARCHAR(10), 
  @PurposeID INT, 
  @Type INT, 
  @UserID INT,
  @OffSetFrom INT,
  @offsetTo INT,
  @Plus1Week float,
  @Plus2Weeks float,
  @Plus3Weeks float,
  @Plus4Weeks float,
  @Plus5Weeks float
  ) AS
DECLARE @ActivityFrom AS DATETIME
DECLARE @ActivityTo AS DATETIME
DECLARE @PriceDate AS DATETIME
DECLARE @CreatedDate  AS DATETIME

SET @CreatedDate = (getdate())
SET @ActivityFrom = CONVERT(DATETIME, @From, 102)
SET @ActivityTo = CONVERT(DATETIME, @To, 102) + ' 23:59:59'
SET @PriceDate = CONVERT(DATETIME, @PriceTag, 102)

INSERT 
  INTO 
  Activities 
  ( 
  FK_CampaignID, Label,
  [Description],
  FK_ActivityStatusID,
  ActivityFrom,
  ActivityTo, 
  PriceTag, 
  FK_ActivityPurposeID, 
  ActivityTypes, 
  CreatedDate, 
  FK_CreatedByUserID,
  OffSetFrom,
  OffsetTo,
  Plus1Week,
  Plus2Weeks,
  Plus3Weeks,
  Plus4Weeks,
  Plus5Weeks
  ) 
  VALUES 
  ( @CampaignID, @Label, @Description, @StatusID, @ActivityFrom, @ActivityTo, @PriceDate, @PurposeID, @Type, @CreatedDate, @UserID,@OffSetFrom,@offsetTo, @Plus1Week, @Plus2Weeks, @Plus3Weeks, @Plus4Weeks, @Plus5Weeks )

SELECT SCOPE_IDENTITY() AS Result





