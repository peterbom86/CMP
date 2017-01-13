CREATE FUNCTION rdh_fn_GetAllocation (@Participator INT, @Product INT)
RETURNS FLOAT

AS

BEGIN

DECLARE @Allocation FLOAT
 
SELECT  @Allocation  = AL.Allocation 
FROM 
	Allocations A	
	INNER JOIN dbo.AllocationLines AL ON AL.FK_AllocationID = A.PK_AllocationID
WHERE
	A.FK_ParticipatorID = @Participator AND AL.FK_ProductID = @Product

RETURN @Allocation

END