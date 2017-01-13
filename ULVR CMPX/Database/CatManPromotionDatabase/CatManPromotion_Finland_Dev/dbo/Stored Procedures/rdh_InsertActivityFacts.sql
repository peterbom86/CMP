CREATE Procedure rdh_InsertActivityFacts

AS

Truncate table vwCampaignPricesAndDiscounts;

INSERT INTO vwCampaignPricesAndDiscounts
(PK_ActivityLineID, FK_SalesUnitID, GSV, Cost, Charge, BaseDiscountPct, BaseDiscountAmt, PromptDiscountPct, PromptDiscountAmt, 
                      InvoiceDiscountsPct, InvoiceDiscountsAmt, CampaignDiscountsPct, CampaignDiscountsAmt, PEDiscount)


SELECT     PK_ActivityLineID, FK_SalesUnitID, GSV, Cost, Charge, BaseDiscountPct, BaseDiscountAmt, PromptDiscountPct, PromptDiscountAmt, 
                      InvoiceDiscountsPct, InvoiceDiscountsAmt, CampaignDiscountsPct, CampaignDiscountsAmt, PEDiscount
FROM         dbo.vwCampaignPricesAndDiscounts1





