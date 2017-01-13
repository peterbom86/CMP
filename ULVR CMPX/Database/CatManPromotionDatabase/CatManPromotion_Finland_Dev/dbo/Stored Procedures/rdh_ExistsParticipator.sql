CREATE PROCEDURE rdh_ExistsParticipator (
@ParticipatorID INT )
AS
SELECT 
  CASE COUNT( PK_ParticipatorID ) 
    WHEN 0 THEN 0 
    WHEN NULL THEN 0 
    ELSE 1 
  END 
  AS ParticipatorExists 
  FROM Participators 
  WHERE (  PK_ParticipatorID = @ParticipatorID )


