CREATE PROCEDURE rdh_GetAbacusFile
  @PeriodFrom int,
  @PeriodTo int,
  @AmtType varchar(15)

AS

SELECT PH.Node, CH.Node, UPPER(LEFT(DATENAME(m, '2006-' + RIGHT(PeriodMonth, 2) + '-06'), 3)) + SUBSTRING(CAST(PeriodMonth AS varchar), 3, 2) Period, 
  Sum(VolumeSupplier) VPROMO,
  Sum(GSV) GSV, 
  Sum(BaseDiscounts) ORDQUANT,
  Sum(PromptDiscounts) PromptDiscounts,
  Sum(InvoiceDiscount + CampaignDiscounts) OTHTPRCO,
  Sum(PEDiscount + ActivitySubsider + CampaignSubsider) TCC,
  Sum(NSV - (InvoiceDiscount + CampaignDiscounts) - (PEDiscount + ActivitySubsider + CampaignSubsider)) NPS_CAMP,
  Sum(Cost) SCC,
  Sum(NSV - (InvoiceDiscount + CampaignDiscounts) - (PEDiscount + ActivitySubsider + CampaignSubsider) - Cost) GP
FROM PivotTable
  INNER JOIN Periods ON DeliveryDate = Periods.Label
  INNER JOIN ProductHierarchies PH ON SPF = PH.Label AND FK_ProductHierarchyLevelID = 14
  INNER JOIN CustomerHierarchies CH ON PlanningCustomer = CH.Label AND FK_CustomerHierarchyLevelID = 8
WHERE AmtType = @AmtType AND PeriodMonth >= @PeriodFrom AND PeriodMonth <= @PeriodTo
GROUP BY PH.Node, CH.Node, PeriodMonth
