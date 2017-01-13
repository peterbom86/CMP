CREATE function rdh_fn_ActivityDiscountTPR (@ActivityID int, @OnInvoice int)
Returns float

AS

begin

declare @Discount float

Set @Discount=
  (SELECT 
  CASE WHEN ISNULL(SUM(Supplier*NSV),0)=0 THEN 0 ELSE
  SUM(CASE WHEN FK_valueTypeID=1 THEN Value*NSV*Supplier ELSE Value*Supplier END)/SUM(Supplier*NSV) END
  FROM vwCampaignDiscounts WHERE FK_ActivityID=@ActivityID
  AND OnInvoice=@OnInvoice)

return @Discount
end


