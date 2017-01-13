--EXEC rdh_BaseDiscount 410,4,'2005-12-19'

CREATE procedure rdh_BaseDiscount
@product int,
@participator int,
@period datetime

AS



SELECT SUM(REBATE) AS REB FROM 

(SELECT ROUND(CASE WHEN FK_VALUETYPEID=1 THEN
[value]*

(SELECT [Value] FROM Prices WHERE FK_ProductID=@Product AND FK_PriceTypeID=1 AND
PeriodFrom<@period AND PeriodTo>@period)

ELSE [value]END,2) AS REBATE


FROM BaseDiscounts

WHERE 
FK_ProductID=@product AND
FK_BaseDiscountTypeID IN (1,2,3,4) AND
PeriodFrom<@period AND PeriodTo>@period AND
FK_ParticipatorID=@participator) AS X




