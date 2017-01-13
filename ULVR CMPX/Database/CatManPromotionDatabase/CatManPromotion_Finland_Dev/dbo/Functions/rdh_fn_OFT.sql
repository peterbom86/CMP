CREATE   Function rdh_fn_OFT(@product int,@participator int,@period datetime, @ValueType int)
returns float

AS


BEGIN

declare @OFT float


Set @OFT=
  ISNULL((SELECT SUM([value]) FROM BaseDiscounts
  WHERE FK_BaseDiscountTypeID=8 AND
  FK_ParticipatorID=@participator AND
  FK_ValueTypeID=@ValueType AND
  FK_ProductID=@product AND
  PeriodFrom<=@period AND
  PeriodTo>=@Period),0)

return @OFT

END



