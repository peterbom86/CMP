CREATE PROCEDURE rdh_DeleteCommonCodePeriod
  @CommonCodePeriodID int

AS

DELETE FROM CommonCodePeriod
WHERE PK_CommonCodePeriodID = @CommonCodePeriodID
