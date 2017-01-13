
CREATE  PROCEDURE rdh_ExportRebateAgreement 
  @CampaignID int

AS 

DECLARE @SalesOrg varchar(4)
DECLARE @DistributionChannel varchar(2)
DECLARE @Division varchar(2)
DECLARE @CurrencyKey varchar(3)

SET @SalesOrg = '5210'
SET @DistributionChannel = '20'
SET @Division = '10'
SET @CurrencyKey = 'DKK'


DECLARE @AgreementType varchar(4)
DECLARE @ConditionType varchar(4)
DECLARE @CalculationType varchar(1)
DECLARE @TaxIndicator varchar(1)
SET @AgreementType = 'Z508'
SET @ConditionType = 'Z4N0'
SET @CalculationType = 'B'
SET @TaxIndicator = '3'

SELECT 
  -- Z1AGSD
  @SalesOrg SalesOrg, @DistributionChannel DistributionChannel, @Division Division,
  @AgreementType AgreementType, ECLL.Label RebateRecipient, @CurrencyKey CurrencyKey,
  PK_CampaignID CampaignID, '' Status, AgreementFrom, AgreementTo, '' CustomerPromotionID, 
  --E1KOMG
  @ConditionType ConditionType, @SalesOrg SalesOrg, @DistributionChannel DistributionChannel, @Division Division,
  ECLL2.Label HierarchyCustomer, @SalesOrg + @DistributionChannel + @Division + REPLICATE('0', 7 - LEN(ISNULL(ECLL2.Label, ''))) + ISNULL(ECLL2.Label, '') +
  REPLICATE(' ', 17 - LEN(ISNULL(EANHeader.EANCode, ''))) + ISNULL(EANHeader.EANCode, '') + 
  CASE WHEN AL.FK_SalesUnitID <> AL.FK_ProductID THEN 
    REPLICATE(' ', 17 - LEN(ISNULL(EANHeader.EANCode, ''))) + ISNULL(EANHeader.EANCode, '') + REPLICATE(' ', 17 - LEN(ISNULL(EANComp.EANCode, ''))) + ISNULL(EANComp.EANCode, '') ELSE '' END VariableKey,
  --E1KONH
  AgreementFrom ValidFrom, AgreementTo ValidTo, 
  --E1KONP
  @ConditionType ConditionType2, @CalculationType CalculationType, EstimatedVolumeChain * 
  (CASE WHEN CDoff.FK_ValueTypeID = 2 THEN CDoff.Value ELSE 0 END +
    (dbo.rdh_fn_NetPrice( FK_SalesUnitID, FK_ChainID, PriceTag) * ( 1 - 
      CASE WHEN CDon.FK_ValueTypeID = 1 THEN CDon.Value ELSE 0 END ) -
      CASE WHEN CDon.FK_ValueTypeID = 2 THEN CDon.Value ELSE 0 END ) * CASE WHEN CDoff.FK_ValueTypeID = 1 THEN CDoff.Value ELSE 0 END ) Rate,
  @CurrencyKey RateCurrencyKey, '' DeletionIndicator, @TaxIndicator TaxIndicator, '' Rate2
FROM Campaigns
  INNER JOIN Participators ON PK_ParticipatorID = FK_ChainID
  INNER JOIN ExternalCustomerLinkLines ECLL ON PK_ParticipatorID = ECLL.FK_ParticipatorID AND ECLL.FK_ExternalCustomerLinkID = 4
  INNER JOIN ExternalCustomerLinkLines ECLL2 ON PK_ParticipatorID = ECLL2.FK_ParticipatorID AND ECLL2.FK_ExternalCustomerLinkID = 6
  INNER JOIN (SELECT FK_CampaignID, MIN(Firstday.Label) AgreementFrom, MAX(Lastday.Label) AgreementTo
              FROM Activities INNER JOIN ActivityDeliveries ON PK_ActivityID = FK_ActivityID
                INNER JOIN Periods ON DeliveryDate = Periods.Label
                INNER JOIN Periods Firstday ON Periods.Period = Firstday.Period AND Firstday.DayNumber = 1
                INNER JOIN Periods Lastday ON Periods.Period = Lastday.Period AND Lastday.DayNumber = 6
              GROUP BY FK_CampaignID) Period ON PK_CampaignID = Period.FK_CampaignID
  INNER JOIN Activities A ON PK_CampaignID = A.FK_CampaignID
  INNER JOIN ActivityLines AL ON PK_ActivityID = AL.FK_ActivityID
  INNER JOIN Products Header ON Header.PK_ProductID = AL.FK_SalesUnitID
  INNER JOIN EANCodes EANHeader ON Header.PK_ProductID = EANHeader.ProductID AND EANHeader.FK_EANTypeID = 2
  INNER JOIN Products Comp ON Comp.PK_ProductID = AL.FK_ProductID
  INNER JOIN EANCodes EANComp ON Comp.PK_ProductID = EANComp.ProductID AND EANComp.FK_EANTypeID = 2
  LEFT JOIN CampaignDiscounts CDon ON PK_ActivityLineID = CDon.FK_ActivityLineID AND CDon.OnInvoice = 1
  LEFT JOIN CampaignDiscounts CDoff ON PK_ActivityLineID = CDoff.FK_ActivityLineID AND CDoff.OnInvoice = 0
WHERE PK_CampaignID = @CampaignID


