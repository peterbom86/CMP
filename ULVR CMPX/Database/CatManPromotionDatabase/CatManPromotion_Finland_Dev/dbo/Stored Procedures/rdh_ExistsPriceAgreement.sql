CREATE   procedure rdh_ExistsPriceAgreement
@ParticipatorID int,
@SalesUnitID int,
@PeriodFrom datetime,
@PeriodTo datetime

AS


SELECT PK_CampaignID FROM vwPriceAgreementCampaigns WHERE
FK_ParticipatorID = @ParticipatorID AND 
FK_ProductID = @SalesUnitID AND PeriodFrom <= @PeriodTo AND PeriodTo >= @PeriodFrom
AND [value]<>0






