--SELECT dbo.rdh_fn_BaseDiscount(410,4,'2005-12-19')

CREATE Function rdh_fn_BaseDiscount (@product int,@participator int,@period datetime)
Returns float

AS

begin

declare @Base float
declare @Prompt float
declare @Price float

set @Price= (SELECT [Value] FROM Prices WHERE FK_ProductID=@Product AND FK_PriceTypeID=1 AND
PeriodFrom<@period AND PeriodTo>@period)

set @Base=

(SELECT SUM(REBATE) AS REB FROM 

(SELECT ROUND(CASE WHEN FK_VALUETYPEID=1 THEN
[value]* @Price


ELSE [value]END,2) AS REBATE


FROM BaseDiscounts

WHERE 
FK_ProductID=@product AND
FK_BaseDiscountTypeID IN (1,2,3,4) AND
PeriodFrom<@period AND PeriodTo>@period AND
FK_ParticipatorID=@participator) AS X)

set @Prompt=

(SELECT SUM(REBATE) AS REB FROM 

(SELECT ROUND(CASE WHEN FK_VALUETYPEID=1 THEN
[value]* (@Price-@Base)


ELSE [value]END,2) AS REBATE


FROM BaseDiscounts

WHERE 
FK_ProductID=@product AND
FK_BaseDiscountTypeID IN (5) AND
PeriodFrom<@period AND PeriodTo>@period AND
FK_ParticipatorID=@participator) AS X)

return @Price-@Base-@Prompt

end



