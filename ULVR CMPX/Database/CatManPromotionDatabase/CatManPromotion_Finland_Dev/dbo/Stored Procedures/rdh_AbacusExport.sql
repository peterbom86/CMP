CREATE         procedure rdh_AbacusExport
-- rdh_AbacusExport '2006-01-01', '2006-03-31','MRF','Estimat'
@From datetime,
@To datetime,
@Scenario nvarchar (3),
@AmountType nvarchar(10)

AS


SELECT 
  PH.Node AS PRODUCT, 
  CH.Node AS ORG2, 
  @Scenario AS SCENARIO,  
  LEFT(UPPER(DATENAME(mm, '2000-' + RIGHT(PeriodMonth,2) + '-01')),3) + RIGHT(PeriodYear,2) AS [TIME], 
  '00058686' AS ORG1,
  'M_LU' AS [MONEY],
  CAST(SUM (VolumeSupplier)as char(17)) AS VPROMO, 
  CAST(SUM (0.001 * VolumeSupplier*GSV) as char(17)) AS GSV, 
  CAST(SUM (0.001 * VolumeSupplier*(BaseDiscounts + PromptDiscounts)) as char (17)) AS ORDQUANT,
  CAST(SUM (0.001 * VolumeSupplier * (InvoiceDiscount + CampaignDiscounts)) as char(17)) AS OTHTPROCO,
  CAST(SUM (0.001 * VolumeSupplier * (CampaignPrice-ActivitySubsider-CampaignSubsider-PEDiscount)) as char(17)) AS NPS_CAMP,
  CAST(SUM (0.001 * VolumeSupplier * Cost) as char(17)) AS SCC,
  CAST(SUM (0.001 * VolumeSupplier * (CampaignPrice - Cost)) as char(17)) AS GP,
  CAST(SUM (0.001 * VolumeSupplier * (ActivitySubsider + CampaignSubsider)) as char(17)) AS PE
FROM 
  PivotTable PT INNER JOIN 
  ProductHierarchies PH ON PT.SPF = PH.LABEL AND PH.FK_ProductHierarchyLevelID = 9 INNER JOIN 
  CustomerHierarchies CH ON PT.PlanningCustomer = CH.Label AND CH.FK_CustomerHierarchyLevelID = 8 INNER JOIN
  Periods P ON PT.DeliveryDate = P.Label
WHERE 
  DeliveryDate Between @From AND @To AND
  AmtType=@AmountType AND Status<>'Annulleret'
GROUP BY
  PH.Node, CH.Node, P.PeriodMonth, p.PeriodYear









