CREATE PROCEDURE dbo.GenerateRebateAgreementsCampaignList

AS



SELECT  201211 AS Period
INTO    #Periods
UNION
SELECT  201212
UNION
SELECT  201213
UNION
SELECT  201214
UNION
SELECT  201215
UNION
SELECT  201216
UNION
SELECT  201217
UNION
SELECT  201218
UNION
SELECT  201219
UNION
SELECT  201220
UNION
SELECT  201221
UNION
SELECT  201222
UNION
SELECT  201223
UNION
SELECT  201224
UNION
SELECT  201225
UNION
SELECT  201226
UNION
SELECT  201227
UNION
SELECT  201228
UNION
SELECT  201229
UNION
SELECT  201230
UNION
SELECT  201231
UNION
SELECT  201232
UNION
SELECT  201233
UNION
SELECT  201234
UNION
SELECT  201235
UNION
SELECT  201236
UNION
SELECT  201237
UNION
SELECT  201238
UNION
SELECT  201239
UNION
SELECT  201240
UNION
SELECT  201241
UNION
SELECT  201242
UNION
SELECT  201243
UNION
SELECT  201244
UNION
SELECT  201245
UNION
SELECT  201246
UNION
SELECT  201247
UNION
SELECT  201248
UNION
SELECT  201249
UNION
SELECT  201250
UNION
SELECT  201251
UNION
SELECT  201252

SELECT DISTINCT
        PK_CampaignID
INTO #Campaigns
FROM    Products
        INNER JOIN ActivityLines AL ON PK_ProductID = AL.FK_ProductID
        INNER JOIN EANCodes ean ON PK_ProductID = ProductID
                                   AND FK_EANTypeID = 2
        INNER JOIN CampaignDiscounts ON PK_ActivityLineID = FK_ActivityLineID
                                        AND OnInvoice = 0
        INNER JOIN Activities ON PK_ActivityID = FK_ActivityID
        INNER JOIN Campaigns ON PK_CampaignID = FK_CampaignID
        INNER JOIN ( SELECT FK_ActivityID,
                            Min(p2.Label) MinDeliveryDay
                     FROM   ActivityDeliveries
                            INNER JOIN dbo.Periods as p ON DeliveryDate = Label
                            INNER JOIN dbo.Periods as p2 ON p.Period = p2.Period
                     GROUP BY FK_ActivityID
                   ) MinDeliveries ON PK_ActivityID = MinDeliveries.FK_ActivityID
        INNER JOIN dbo.Periods as MinDeliveryPeriod ON MinDeliveryDay = MinDeliveryPeriod.Label
        INNER JOIN #Periods as PeriodsToSend ON MinDeliveryPeriod.Period = PeriodsToSend.Period
        INNER JOIN dbo.ActivityStatus as as2 ON PK_ActivityStatusID = FK_ActivityStatusID
        INNER JOIN dbo.Participators as p3 on PK_ParticipatorID = FK_ChainID
        INNER JOIN dbo.ParticipatorStatus as ps on p3.FK_ParticipatorStatusID = ps.PK_ParticipatorStatusID
WHERE   IsHidden = 0
        AND ValidForSettlement = 1
        AND EstimatedVolumeWholeseller <> 0
        AND CASE WHEN ISNULL(RebateAgreementNoDiscount, '') = '' THEN 'SAP'
                 ELSE RebateAgreementNoDiscount
            END LIKE 'SAP%'
UNION
SELECT DISTINCT
        PK_CampaignID
FROM    Campaigns
        INNER JOIN dbo.ExternalCustomerLinkLines as ecll ON FK_ChainID = ecll.FK_ParticipatorID
                                                            AND ecll.FK_ExternalCustomerLinkID = 4
        INNER JOIN dbo.ExternalCustomerLinkLines as ecll2 ON FK_ChainID = ecll2.FK_ParticipatorID
                                                             AND ecll2.FK_ExternalCustomerLinkID = 6
        LEFT JOIN ( SELECT  FK_CampaignID,
                            SUM(Value) CampaignSubsider
                    FROM    CampaignSubsider
                    GROUP BY FK_CampaignID
                  ) CS ON PK_CampaignID = CS.FK_CampaignID
        INNER JOIN Activities A ON PK_CampaignID = A.FK_CampaignID
        LEFT JOIN ( SELECT  FK_ActivityID,
                            SUM(Value) ActivitySubsider
                    FROM    ActivitySubsider
                    GROUP BY FK_ActivityID
                  ) AcS ON PK_ActivityID = AcS.FK_ActivityID
        INNER JOIN ActivityLines AL ON PK_ActivityID = AL.FK_ActivityID
        INNER JOIN Periods ON CAST(FLOOR(CAST(ActivityTo AS float)) AS datetime) = Periods.Label
        INNER JOIN Periods PFrom ON CAST(FLOOR(CAST(ActivityFrom AS float)) AS datetime) = PFrom.Label
        INNER JOIN Products ON PK_ProductID = AL.FK_ProductID
        INNER JOIN ProductHierarchies PH1 ON PH1.FK_ProductID = PK_ProductID
        INNER JOIN ProductHierarchies PH2 ON PH1.FK_ProductHierarchyParentID = PH2.PK_ProductHierarchyID
        INNER JOIN ProductHierarchies PH3 ON PH2.FK_ProductHierarchyParentID = PH3.PK_ProductHierarchyID
        INNER JOIN ProductHierarchies PH4 ON PH3.FK_ProductHierarchyParentID = PH4.PK_ProductHierarchyID
                                             AND PH4.FK_ProductHierarchyLevelID = 21
        INNER JOIN ( SELECT PK_CampaignID CampaignID,
                            SUM(NetPrice --dbo.rdh_fn_NetPrice(FK_SalesUnitID, FK_ChainID, PriceTag)
                                * EstimatedVolumeWholeseller) AllocationSumCampaign,
                            COUNT(*) AllocationCountCampaign
                     FROM   Campaigns
                            INNER JOIN Activities A ON PK_CampaignID = A.FK_CampaignID
                            INNER JOIN ActivityLines ON PK_ActivityID = FK_ActivityID
                            INNER JOIN tempNetPrice np ON PK_ActivityLineID = ActivityLineID
                     GROUP BY PK_CampaignID
                   ) AllocationCampaign ON PK_CampaignID = CampaignID
        INNER JOIN ( SELECT PK_ActivityID ActivityID,
                            SUM(NetPrice --dbo.rdh_fn_NetPrice(FK_SalesUnitID, FK_ChainID, PriceTag)
                                * EstimatedVolumeWholeseller) AllocationSumActivity,
                            COUNT(*) AllocationCountActivity
                     FROM   Campaigns
                            INNER JOIN Activities A ON PK_CampaignID = A.FK_CampaignID
                            INNER JOIN ActivityLines ON PK_ActivityID = FK_ActivityID
                            INNER JOIN tempNetPrice np ON PK_ActivityLineID = ActivityLineID
                     GROUP BY PK_ActivityID
                   ) AllocationActivity ON PK_ActivityID = ActivityID
        INNER JOIN ( SELECT FK_ActivityID,
                            Min(p2.Label) MinDeliveryDay
                     FROM   ActivityDeliveries
                            INNER JOIN dbo.Periods as p ON DeliveryDate = Label
                            INNER JOIN dbo.Periods as p2 ON p.Period = p2.Period
                     GROUP BY FK_ActivityID
                   ) MinDeliveries ON PK_ActivityID = MinDeliveries.FK_ActivityID
        INNER JOIN dbo.Periods as MinDeliveryPeriod ON MinDeliveryDay = MinDeliveryPeriod.Label
        INNER JOIN #Periods as PeriodsToSend ON MinDeliveryPeriod.Period = PeriodsToSend.Period
        INNER JOIN ( SELECT FK_ActivityID,
                            Max(p2.Label) MaxDeliveryDay
                     FROM   ActivityDeliveries
                            INNER JOIN dbo.Periods as p ON DeliveryDate = Label
                            INNER JOIN dbo.Periods as p2 ON p.Period = p2.Period
                     GROUP BY FK_ActivityID
                   ) MaxDeliveries ON PK_ActivityID = MaxDeliveries.FK_ActivityID
        INNER JOIN tempNetPrice np ON ActivityLineID = PK_ActivityLineID
        INNER JOIN dbo.ActivityStatus as as2 ON PK_ActivityStatusID = FK_ActivityStatusID
        INNER JOIN dbo.Participators as p2 on PK_ParticipatorID = FK_ChainID
        INNER JOIN dbo.ParticipatorStatus as ps on p2.FK_ParticipatorStatusID = ps.PK_ParticipatorStatusID
WHERE   IsHidden = 0
        AND ValidForSettlement = 1
        AND ISNULL(CampaignSubsider, 0) + ISNULL(ActivitySubsider, 0) <> 0
        AND CASE WHEN ISNULL(RebateAgreementNoSubsider, '') = '' THEN 'SAP'
                 ELSE RebateAgreementNoSubsider
            END LIKE 'SAP%'            
UNION         
SELECT DISTINCT
        PK_CampaignID CampaignID
FROM    Campaigns
        INNER JOIN Activities ON PK_CampaignID = FK_CampaignID
        INNER JOIN ActivityLines ON PK_ActivityID = ActivityLines.FK_ActivityID
        INNER JOIN ( SELECT FK_ActivityID,
                            Min(DeliveryDate) MinDeliveryDay
                     FROM   ActivityDeliveries
                     GROUP BY FK_ActivityID
                   ) Deliveries ON PK_ActivityID = Deliveries.FK_ActivityID
        INNER JOIN dbo.Periods as MinDeliveryPeriod ON MinDeliveryDay = MinDeliveryPeriod.Label
        INNER JOIN #Periods as PeriodsToSend ON MinDeliveryPeriod.Period = PeriodsToSend.Period
        INNER JOIN CampaignDiscounts ON FK_ActivityLineID = PK_ActivityLineID
                                        AND OnInvoice = 1
                                        AND FK_ValueTypeID = 1
        INNER JOIN Products ON FK_SalesUnitID = PK_ProductID
        INNER JOIN ProductHierarchies PH1 ON PK_ProductID = PH1.FK_ProductID
        INNER JOIN ProductHierarchies PH2 ON PH1.FK_ProductHierarchyParentID = PH2.PK_ProductHierarchyID
                                             AND PH2.FK_ProductHierarchyLevelID = 4
        INNER JOIN EANCodes ON PK_ProductID = ProductID
                               AND FK_EANTypeID = 2
        INNER JOIN Participators ON FK_ChainID = PK_ParticipatorID
        INNER JOIN dbo.ExternalCustomerLinkLines as ecll ON PK_ParticipatorID = ecll.FK_ParticipatorID
                                                            AND FK_ExternalCustomerLinkID = 9
        INNER JOIN Periods ON CAST(FLOOR(CAST(ActivityTo AS float)) AS datetime) = Periods.Label
        INNER JOIN Periods PFrom ON CAST(FLOOR(CAST(ActivityFrom AS float)) AS datetime) = PFrom.Label
        INNER JOIN ( SELECT Period,
                            Min(Label) AS Monday
                     FROM   Periods
                     GROUP BY Period
                   ) P2 ON Periods.Period = P2.Period
        INNER JOIN dbo.ActivityStatus as as2 ON PK_ActivityStatusID = FK_ActivityStatusID
        INNER JOIN dbo.ParticipatorStatus as ps on dbo.Participators.FK_ParticipatorStatusID = ps.PK_ParticipatorStatusID
WHERE   IsHidden = 0
        AND ValidForSettlement = 1
        AND ExportRebateAgreement = 1
        AND dbo.CampaignDiscounts.Value <> 0
        AND CASE WHEN ISNULL(SalesDealNo, '') = '' THEN 'SAP'
                 ELSE SalesDealNo
            END LIKE 'SAP%'            
UNION
SELECT DISTINCT
        PK_CampaignID CampaignID
FROM    Campaigns
        INNER JOIN Activities ON PK_CampaignID = FK_CampaignID
        INNER JOIN ActivityLines ON PK_ActivityID = ActivityLines.FK_ActivityID
        INNER JOIN ( SELECT FK_ActivityID,
                            Min(DeliveryDate) MinDeliveryDay
                     FROM   ActivityDeliveries
                     GROUP BY FK_ActivityID
                   ) Deliveries ON PK_ActivityID = Deliveries.FK_ActivityID
        INNER JOIN dbo.Periods as MinDeliveryPeriod ON MinDeliveryDay = MinDeliveryPeriod.Label
        INNER JOIN #Periods as PeriodsToSend ON MinDeliveryPeriod.Period = PeriodsToSend.Period
        INNER JOIN CampaignDiscounts ON FK_ActivityLineID = PK_ActivityLineID
                                        AND OnInvoice = 1
                                        AND FK_ValueTypeID = 2
        INNER JOIN Products ON FK_SalesUnitID = PK_ProductID
        INNER JOIN ProductHierarchies PH1 ON PK_ProductID = PH1.FK_ProductID
        INNER JOIN ProductHierarchies PH2 ON PH1.FK_ProductHierarchyParentID = PH2.PK_ProductHierarchyID
                                             AND PH2.FK_ProductHierarchyLevelID = 4
        INNER JOIN EANCodes ON PK_ProductID = ProductID
                               AND FK_EANTypeID = 2
        INNER JOIN Participators ON FK_ChainID = PK_ParticipatorID
        INNER JOIN dbo.ExternalCustomerLinkLines as ecll ON PK_ParticipatorID = ecll.FK_ParticipatorID
                                                            AND FK_ExternalCustomerLinkID = 9
        INNER JOIN Periods ON CAST(FLOOR(CAST(ActivityTo AS float)) AS datetime) = Periods.Label
        INNER JOIN Periods PFrom ON CAST(FLOOR(CAST(ActivityFrom AS float)) AS datetime) = PFrom.Label
        INNER JOIN Prices ON PK_ProductID = Prices.FK_ProductID
                             AND FK_PriceTypeID = 1
                             AND Prices.PeriodFrom <= PriceTag
                             AND Prices.PeriodTo >= PriceTag
        INNER JOIN ( SELECT Period,
                            Min(Label) AS Monday
                     FROM   Periods
                     GROUP BY Period
                   ) P2 ON Periods.Period = P2.Period
        INNER JOIN dbo.ActivityStatus as as2 ON PK_ActivityStatusID = FK_ActivityStatusID
        INNER JOIN dbo.ParticipatorStatus as ps on dbo.Participators.FK_ParticipatorStatusID = ps.PK_ParticipatorStatusID
WHERE   IsHidden = 0
        AND ValidForSettlement = 1
        AND ExportRebateAgreement = 1
        AND dbo.Prices.Value <> 0
        AND ( EXISTS ( SELECT   *
                       FROM     dbo.RebateAgreementCampaignsToSent as racts
                       WHERE    PK_CampaignID = CampaignID )
              OR NOT EXISTS ( SELECT    *
                              FROM      dbo.RebateAgreementCampaignsToSent )
            )
        AND dbo.CampaignDiscounts.Value <> 0
        AND CASE WHEN ISNULL(SalesDealNo, '') = '' THEN 'SAP'
                 ELSE SalesDealNo
            END LIKE 'SAP%'

INSERT INTO dbo.RebateAgreementCampaignsToSent
        ( CampaignID )
SELECT PK_CampaignID
FROM #Campaigns
WHERE PK_CampaignID NOT IN (SELECT CampaignID FROM dbo.RebateAgreementCampaignsToSent as racts)

DROP TABLE #Periods
DROP TABLE #Campaigns
