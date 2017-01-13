CREATE   PROCEDURE rdh_CreateProvision
  @ProvisionID int,
  @ProvisionName varchar(255),
  @PeriodFrom datetime,
  @PeriodTo datetime,
  @UserID int,
  @CreatedDate datetime,
  @StatusID int

AS

IF (SELECT Count(*) FROM Provision WHERE PK_ProvisionID = @ProvisionID) > 0
BEGIN
DELETE FROM ProvisionLines WHERE FK_ProvisionID = @ProvisionID
END
ELSE
BEGIN
INSERT INTO Provision (Label, PeriodFrom, PeriodTo, FK_CreatedByUserID, CreatedDate, FK_ProvisionStatusID)
VALUES (@ProvisionName, @PeriodFrom, @PeriodTo, @UserID, @CreatedDate, @StatusID)

SET @ProvisionID = @@IDENTITY
END

SELECT @PeriodFrom = PeriodFrom, @PeriodTo = PeriodTo FROM Provision WHERE PK_ProvisionID = @ProvisionID

INSERT INTO ProvisionLines (FK_ProvisionID, FK_CampaignID, FK_ChainID, FK_ActivityID, ActivityLabel, ActivityFrom, ActivityTo, FK_ActivityStatus,
  FK_ActivityLineID, FK_SalesUnitID, FK_ProductID, FK_ProvisionDiscountTypeID, Value, DeliveryDate)
SELECT @ProvisionID AS ProvisionID, PK_CampaignID, FK_ChainID, PK_ActivityID, A.Label, ActivityFrom, ActivityTo, PK_ActivityStatusID, PK_ActivityLineID, 
  FK_SalesUnitID, AL.FK_ProductID, 
  CASE CD.FK_ValueTypeID
    WHEN 1 THEN 1
    ELSE 2
  END AS FK_ProvisionDiscountTypeID, 
  CASE CD.FK_ValueTypeID
    WHEN 1 THEN dbo.rdh_fn_NetPrice( FK_SalesUnitID, FK_ChainID, PriceTag ) * (1 - ISNULL(CD2.Value, ISNULL(BD.Value, 0))) * CD.Value
    ELSE CD.Value
  END * EstimatedVolumeWholeseller * AD.Value / SumValue, DeliveryDate
FROM Campaigns
  INNER JOIN Activities A ON PK_CampaignID = A.FK_CampaignID
  INNER JOIN ActivityLines AL ON PK_ActivityID = AL.FK_ActivityID
  INNER JOIN Products ON PK_ProductID = FK_SalesUnitID
  INNER JOIN CommonCodes CC ON PK_ProductID = CC.FK_ProductID AND Active = 1
  INNER JOIN (SELECT FK_ActivityID, Sum(Value) AS SumValue FROM ActivityDeliveries GROUP BY FK_ActivityID) Deliveries ON PK_ActivityID = Deliveries.FK_ActivityID
  INNER JOIN ActivityDeliveries AD ON PK_ActivityID = AD.FK_ActivityID
  INNER JOIN ActivityStatus ON PK_ActivityStatusID = FK_ActivityStatusID
  INNER JOIN CampaignDiscounts CD ON PK_ActivityLineID = CD.FK_ActivityLineID AND CD.OnInvoice = 0
  LEFT JOIN CampaignDiscounts CD2 ON PK_ActivityLineID = CD2.FK_ActivityLineID AND CD2.OnInvoice = 1
  LEFT JOIN BaseDiscounts BD ON FK_ChainID = FK_ParticipatorID AND FK_SalesUnitID = BD.FK_ProductID AND 
    BD.PeriodFrom <= PriceTag AND BD.PeriodTo >= PriceTag AND FK_BaseDiscountTypeID = 9
WHERE
  DeliveryDate >= @PeriodFrom AND
  DeliveryDate <= @PeriodTo AND
  IsValidForProvision = 1 AND 
  EstimatedVolumeWholeseller <> 0


INSERT INTO ProvisionLines (FK_ProvisionID, FK_CampaignID, FK_ChainID, FK_ActivityID, ActivityLabel, ActivityFrom, ActivityTo, FK_ActivityStatus,
  FK_ActivityLineID, FK_SalesUnitID, FK_ProductID, FK_ProvisionDiscountTypeID, Value, DeliveryDate)
SELECT @ProvisionID, PK_CampaignID, FK_ChainID, PK_ActivityID, A.Label, ActivityFrom, ActivityTo, FK_CampaignSubsiderStatusID, 
  PK_ActivityLineID, FK_SalesUnitID, FK_ProductID, 3,
  CASE SumRevenue
    WHEN 0 THEN CS.Value / CAST(CountLines AS float)
    ELSE CS.Value * dbo.rdh_fn_NetPrice( FK_SalesUnitID, FK_ChainID, PriceTag ) * EstimatedVolumeSupplier / SumRevenue
  END * AD.Value / SumValue
  , DeliveryDate
FROM CampaignSubsider CS
  INNER JOIN ActivitySubsiderStatus ON PK_ActivitySubsiderStatusID = FK_CampaignSubsiderStatusID
  INNER JOIN Campaigns ON PK_CampaignID = CS.FK_CampaignID
  INNER JOIN Activities A ON PK_CampaignID = A.FK_CampaignID
  INNER JOIN ActivityStatus ON PK_ActivityStatusID = FK_ActivityStatusID
  INNER JOIN ActivityLines AL ON PK_ActivityID = AL.FK_ActivityID
  INNER JOIN ActivityDeliveries AD ON PK_ActivityID = AD.FK_ActivityID
  INNER JOIN (SELECT FK_ActivityID, Sum(Value) SumValue FROM ActivityDeliveries GROUP BY FK_ActivityID) Deliveries ON PK_ActivityID = Deliveries.FK_ActivityID
  INNER JOIN (SELECT PK_CampaignID CampaignID, Sum(dbo.rdh_fn_NetPrice( FK_SalesUnitID, FK_ChainID, PriceTag ) * EstimatedVolumeSupplier) SumRevenue, Count(*) CountLines
              FROM Campaigns
                INNER JOIN Activities A ON PK_CampaignID = A.FK_CampaignID
                INNER JOIN ActivityLines AL ON PK_ActivityID = AL.FK_ActivityID
              WHERE PK_CampaignID IN (SELECT FK_CampaignID FROM CampaignSubsider
                                        INNER JOIN ActivitySubsiderStatus ON PK_ActivitySubsiderStatusID = FK_CampaignSubsiderStatusID
                                      WHERE IsValidForProvision = 1)
              GROUP BY PK_CampaignID) Allocation ON PK_CampaignID = Allocation.CampaignID
WHERE
  DeliveryDate >= @PeriodFrom AND
  DeliveryDate <= @PeriodTo AND
  ActivitySubsiderStatus.IsValidForProvision = 1 AND
  ActivityStatus.IsValidForProvision = 1 AND
  CS.Value <> 0

SELECT @ProvisionID AS ProvisionID


