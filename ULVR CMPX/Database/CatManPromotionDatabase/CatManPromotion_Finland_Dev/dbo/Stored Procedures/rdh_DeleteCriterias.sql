CREATE procedure rdh_DeleteCriterias
@UserID int,
@StoredProcedure nvarchar(50)

AS

DELETE FROM ReportCriterias WHERE UserID=@UserID AND ReportObjectName=@StoredProcedure


