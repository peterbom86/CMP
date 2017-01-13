









--SELECT dbo.rdh_fn_NetPrice(410,4,'2005-12-19')

CREATE       Function rdh_fn_CampaignPrice (@product int,@participator int,@period datetime, @rebatepct float, @rebatekr float)
Returns float

AS

begin

declare @Base float
declare @Prompt float
declare @Price float
declare @Pieces int
declare @tpr float


set @Pieces= 
	(SELECT ISNULL(Pieces,0) FROM EANCodes
         WHERE ProductID = @Product AND FK_EANTypeID = 2)


set @Price= 
	(SELECT ISNULL([Value],0) FROM Prices WHERE FK_ProductID=@Product AND FK_PriceTypeID=1 AND
	PeriodFrom<=@period AND PeriodTo>=@period)

set @tpr = (@price/@pieces * @rebatepct)-@rebatekr


set @Base=
	(SELECT SUM(REBATE) AS REB FROM 
	
		(SELECT ROUND(CASE WHEN FK_VALUETYPEID=1 THEN
		ISNULL([value],0)* @Price
		ELSE ISNULL([value],0) END,2) AS REBATE
		
		FROM BaseDiscounts
		
		WHERE 
			FK_ProductID=@product AND
			FK_PriceBaseID=1 AND
			FK_BaseDiscountTypeID IN (1,2,3,4,10,11,12,13,14,15,16,17,18,19,20,22) AND
			PeriodFrom<=@period AND PeriodTo>=@period AND
			FK_ParticipatorID=@participator) AS X)



return (ISNULL(@Price,0)-ISNULL(@Base,0)/@Pieces)- @tpr

end











