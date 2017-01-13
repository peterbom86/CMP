CREATE FUNCTION dbo.rdh_fn_OFPrice (@ActivityID int, @SalesunitID int, @participator int,@period datetime, @InclSale bit, @InclVat bit)
returns float

AS

BEGIN

Declare @GSV float
Declare @NetPrice float
Declare @OnInvoice_amt float
Declare @OnInvoice_pct float
Declare @InvoicePrice float
Declare @Levy float
Declare @OFT_amt float
Declare @OFT_pct float
Declare @InvoicePrice_Levy float
Declare @OFPrice float
Declare @OnSale_amt float
Declare @OnSale_pct float
Declare @OFPriceInclOnSale float


--GSV
Set @GSV =   
	ISNULL((SELECT [value] FROM Prices WHERE FK_PriceTypeID = 16 AND FK_ProductID = @SalesUnitID 
	AND PeriodTo > @period AND PeriodFrom <= @period)/
	(SELECT Pieces / PiecesPerConsumerUnit FROM EANCodes INNER JOIN dbo.Products ON PK_ProductID = ProductID WHERE ProductID = @SalesUnitID AND FK_EANTypeID = 2),0)


--NETPRICE
Set @NetPrice = dbo.rdh_fn_NetPrice ( @SalesUnitID, @participator, @period )

--TPR_AMT
Set @OnInvoice_amt = 
  ISNULL((SELECT ISNULL([value],0) FROM vwCampaignDiscount WHERE FK_SalesUnitID=@SalesUnitID
  AND FK_ActivityID= @ActivityID AND FK_ValueTypeID=2 AND OnInvoice=1),0)
--TPR %
Set @OnInvoice_pct = 
  ISNULL((SELECT ISNULL([value],0) FROM vwCampaignDiscount WHERE FK_SalesUnitID=@SalesUnitID
  AND FK_ActivityID= @ActivityID AND FK_ValueTypeID=1 AND OnInvoice=1),0)

--INVOICEPRICE
Set @InvoicePrice = @NetPrice - @OnInvoice_amt - ( @GSV * @OnInvoice_pct )

--AFGIFT
Set @Levy = 
  ISNULL((SELECT SUM([value]) FROM Prices p INNER JOIN dbo.PriceTypes pt ON p.FK_PriceTypeID = pt.PK_PriceTypeID WHERE IsTax = 1 AND FK_ProductID = @SalesUnitID 
  AND PeriodTo > @period AND PeriodFrom <= @period)/
  (SELECT Pieces / PiecesPerConsumerUnit FROM EANCodes INNER JOIN dbo.Products ON PK_ProductID = ProductID WHERE ProductID = @SalesUnitID AND FK_EANTypeID = 2),0)

--FA PRICE
Set @InvoicePrice_Levy = @InvoicePrice + @Levy

--OFT_AMT
Set @OFT_amt = dbo.rdh_fn_OFT( @SalesUnitID, @participator, @period, 2 )

--OFT%
Set @OFT_pct = dbo.rdh_fn_OFT( @SalesUnitID, @participator, @period, 1 )

--OFT_PRICE
Set @OFPrice = @InvoicePrice_Levy + @OFT_amt + ( @InvoicePrice_Levy * @OFT_pct )

IF @InclSale = 1
BEGIN
  --ONSALE_AMT
  Set @OnSale_amt = 
    ISNULL((SELECT ISNULL([value],0) FROM vwCampaignDiscount WHERE FK_SalesUnitID = @SalesUnitID
    AND FK_ActivityID= @ActivityID AND FK_ValueTypeID=2 AND OnInvoice=0),0)
  
  --ONSALE %
  Set @OnSale_pct = 
    ISNULL((SELECT ISNULL([value],0) FROM vwCampaignDiscount WHERE FK_SalesUnitID = @SalesUnitID
    AND FK_ActivityID = @ActivityID AND FK_ValueTypeID=1 AND OnInvoice=0),0)

  Set @OFPrice = @OFPrice - @OnSale_amt - ( @InvoicePrice * @OnSale_Pct )
END

IF @InclVAT = 1 

BEGIN
  Set @OFPrice = @OFPrice * 1.25
END

if @OFPrice<0 Set @OFPrice=0

return ISNULL(@OFPrice,0)

END
