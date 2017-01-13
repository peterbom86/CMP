CREATE PROCEDURE rdh_EditConditionTypes_TotalList
  @UploadID int,
  @PeriodFrom datetime,
  @PeriodTo datetime,
  @Value float,
  @ChangeType nvarchar(10)

AS

IF @ChangeType = 'DELETE'
BEGIN
  INSERT INTO SAP_ConditionTypes_TotalList_Edits ( UploadID, ConditionType, Material, Hierarchy, PeriodFrom, PeriodTo, Value, FK_FileImportID, 
      QTYType, ChangeType )
  SELECT UploadID, ConditionType, Material, Hierarchy, PeriodFrom, PeriodTo, Value, FK_FileImportID, 
      QTYType, 'DELETED'
  FROM SAP_ConditionTypes_TotalList
  WHERE UploadID = @UploadID

  DELETE FROM SAP_ConditionTypes_TotalList
  WHERE UploadID = @UploadID
END
ELSE
BEGIN
  IF (SELECT COUNT(*) FROM SAP_ConditionTypes_TotalList WHERE UploadID = @UploadID AND (PeriodFrom > @PeriodFrom OR PeriodTo < @PeriodTo)) = 0
  BEGIN
    INSERT INTO SAP_ConditionTypes_TotalList_Edits ( UploadID, ConditionType, Material, Hierarchy, PeriodFrom, PeriodTo, Value, FK_FileImportID, 
        QTYType, ChangeType )
    SELECT UploadID, ConditionType, Material, Hierarchy, PeriodFrom, PeriodTo, Value, FK_FileImportID, 
        QTYType, 'CHANGED'
    FROM SAP_ConditionTypes_TotalList
    WHERE UploadID = @UploadID

    UPDATE SAP_ConditionTypes_TotalList
    SET PeriodFrom = @PeriodFrom,
      PeriodTo = @PeriodTo,
      Value = @Value
    WHERE UploadID = @UploadID
  END
END
