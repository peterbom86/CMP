CREATE function rdh_fn_TotalDiscount(@ActivityLineID int, @ProductID int, @ParticipatorID int, @Period Datetime)
returns float

AS

begin

Declare @OnInvoicePct float
Declare @OnInvoiceAmt float
Declare @OffInvoicePct float
Declare @OffInvoiceAmt float
Declare @NetPrice float
Declare @Discount float

set @OninvoicePct=ISNULL((SELECT SUM([value]) FROM CampaignDiscounts WHERE FK_ActivityLineID=@ActivityLineID AND OnInvoice = 1 AND FK_ValueTypeID=1),0)
set @OninvoiceAmt=ISNULL((SELECT SUM([value]) FROM CampaignDiscounts WHERE FK_ActivityLineID=@ActivityLineID AND OnInvoice = 1 AND FK_ValueTypeID=2),0)
set @OffinvoicePct=ISNULL((SELECT SUM([value]) FROM CampaignDiscounts WHERE FK_ActivityLineID=@ActivityLineID AND OnInvoice = 0 AND FK_ValueTypeID=1),0)
set @OffinvoiceAmt=ISNULL((SELECT SUM([value]) FROM CampaignDiscounts WHERE FK_ActivityLineID=@ActivityLineID AND OnInvoice = 0 AND FK_ValueTypeID=2),0)

set @NetPrice=dbo.rdh_fn_NetPrice(@ProductID,@ParticipatorID,@Period)

if @NetPrice=0
set @Discount=0
else
set @Discount=(@OnInvoicePct*@NetPrice + @OnInvoiceAmt + (@OffInvoicePct*(@NetPrice - @OnInvoiceAmt -@OnInvoicePct*@NetPrice) + @OffInvoiceAmt))/@NetPrice

Return @Discount

end




