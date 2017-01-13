CREATE PROC dbo.rdh_ExportCMS_Actual 
AS 
    DECLARE @PeriodFrom DATETIME
    DECLARE @PeriodTo DATETIME

    SET @PeriodFrom = '2013-01-01'
    SET @PeriodTo = GETDATE()--'2010-05-20'

    TRUNCATE TABLE tempExportCMS_Actual

    SELECT  PK_ProductID ProductID,
            MAX(PH10.Node) Level4Node,
            MAX(PH10.Label) Level4Name,
            MAX(PH8.Node) Level7Node,
            MAX(PH8.Label) Level7Name,
            MAX(PH4.Node) Level11Node,
            MAX(PH4.Label) Level11Name,
            MAX(PH3.Node) Level12Node,
            MAX(PH3.Label) Level12Name
    INTO    tempProductHierarchy
    FROM    Products P
    INNER JOIN ProductHierarchies PH1
            ON P.PK_ProductID = PH1.FK_ProductID
    INNER JOIN ProductHierarchies PH2
            ON PH2.PK_ProductHierarchyID = PH1.FK_ProductHierarchyParentID
               AND PH2.FK_ProductHierarchyLevelID = 37 --13
    INNER JOIN ProductHierarchies PH3
            ON PH3.PK_ProductHierarchyID = PH2.FK_ProductHierarchyParentID
    INNER JOIN ProductHierarchies PH4
            ON PH4.PK_ProductHierarchyID = PH3.FK_ProductHierarchyParentID
    INNER JOIN ProductHierarchies PH5
            ON PH5.PK_ProductHierarchyID = PH4.FK_ProductHierarchyParentID
    INNER JOIN ProductHierarchies PH6
            ON PH6.PK_ProductHierarchyID = PH5.FK_ProductHierarchyParentID
    INNER JOIN ProductHierarchies PH7
            ON PH7.PK_ProductHierarchyID = PH6.FK_ProductHierarchyParentID
    INNER JOIN ProductHierarchies PH8
            ON PH8.PK_ProductHierarchyID = PH7.FK_ProductHierarchyParentID
    INNER JOIN ProductHierarchies PH9
            ON PH9.PK_ProductHierarchyID = PH8.FK_ProductHierarchyParentID
    INNER JOIN ProductHierarchies PH10
            ON PH10.PK_ProductHierarchyID = PH9.FK_ProductHierarchyParentID
    INNER JOIN ProductHierarchies PH11
            ON PH11.PK_ProductHierarchyID = PH10.FK_ProductHierarchyParentID
    GROUP BY PK_ProductID

    SELECT  PK_ProductID SalesUnitID,
            FU2.PK_ProductHierarchyID ForecastingUnitID,
            FU2.Label ForecastingUnit
    INTO    tempForecastingUnits
    FROM    Products P
    INNER JOIN ProductHierarchies FU1
            ON P.PK_ProductID = FU1.FK_ProductID
    INNER JOIN ProductHierarchies FU2
            ON FU1.FK_ProductHierarchyParentID = FU2.PK_ProductHierarchyID
               AND FU2.FK_ProductHierarchyLevelID = 4

    INSERT  INTO CustomerHierarchies
            (
             FK_CustomerHierarchyParentID,
             FK_ParticipatorID 
            )
            SELECT  1215,
                    PK_PArticipatorID
            FROM    Participators
            WHERE   PK_ParticipatorID NOT IN (
                    SELECT  FK_ParticipatorID
                    FROM    CustomerHierarchies
                    WHERE   FK_ParticipatorID IS NOT NULL)
                    AND FK_ParticipatorTypeID = 3

    SELECT  Chains.PK_ParticipatorID ChainID,
            CH2.Node Sub3ReportingNode,
            CH2.Label Sub3ReportingLabel,
            CH3.Node Sub2ReportingNode,
            CH3.Label Sub2ReportingLabel,
            CH4.Node SubReportingNode,
            CH4.Label SubReportingLabel,
            CH5.Node ReportingNode,
            CH5.Label ReportingLabel,
            CH6.Node PlanningNode,
            CH6.Label PlanningLabel,
            CH7.Node EuroNode,
            CH7.Label EuroLabel
    INTO    tempChainHierarchy
    FROM    Participators Chains
    INNER JOIN CustomerHierarchies CH1
            ON Chains.PK_ParticipatorID = CH1.FK_ParticipatorID
    INNER JOIN CustomerHierarchies CH2
            ON CH1.FK_CustomerHierarchyParentID = CH2.PK_CustomerHierarchyID
    INNER JOIN CustomerHierarchies CH3
            ON CH2.FK_CustomerHierarchyParentID = CH3.PK_CustomerHierarchyID
    INNER JOIN CustomerHierarchies CH4
            ON CH3.FK_CustomerHierarchyParentID = CH4.PK_CustomerHierarchyID
    INNER JOIN CustomerHierarchies CH5
            ON CH4.FK_CustomerHierarchyParentID = CH5.PK_CustomerHierarchyID
    INNER JOIN CustomerHierarchies CH6
            ON CH5.FK_CustomerHierarchyParentID = CH6.PK_CustomerHierarchyID
    INNER JOIN CustomerHierarchies CH7
            ON CH6.FK_CustomerHierarchyParentID = CH7.PK_CustomerHierarchyID

    SELECT  PK_SettlementSubsiderID,
            COUNT(*) CountOfLines
    INTO    tempSettlementSubsiderLines
    FROM    SettlementSubsider SS
    INNER JOIN ActivitySubsider
            ON PK_ActivitySubsiderID = FK_ActivitySubsiderID
    INNER JOIN Activities
            ON PK_ActivityID = FK_ActivityID
    INNER JOIN ActivityLines AL
            ON PK_ActivityID = AL.FK_ActivityID
    GROUP BY PK_SettlementSubsiderID

    SELECT  FK_SettlementID,
            PK_ActivityLineID,
            SUM(SS.Value / CountOfLines) SettlementSubsider
    INTO    tempSettlementSubsider
    FROM    SettlementSubsider SS
    INNER JOIN ActivitySubsider
            ON PK_ActivitySubsiderID = FK_ActivitySubsiderID
    INNER JOIN Activities
            ON PK_ActivityID = FK_ActivityID
    INNER JOIN ActivityLines AL
            ON PK_ActivityID = AL.FK_ActivityID
    INNER JOIN tempSettlementSubsiderLines TS
            ON SS.PK_SettlementSubsiderID = TS.PK_SettlementSubsiderID
    GROUP BY FK_SettlementID,
            PK_ActivityLineID

    SELECT  PK_SettlementSubsiderCampaignID,
            COUNT(*) CountOfLines
    INTO    tempSettlementSubsiderCampaignLines
    FROM    SettlementSubsiderCampaign SS
    INNER JOIN CampaignSubsider
            ON PK_CampaignSubsiderID = FK_CampaignSubsiderID
    INNER JOIN Campaigns
            ON PK_CampaignID = FK_CampaignID
    INNER JOIN Activities A
            ON PK_CampaignID = A.FK_CampaignID
    INNER JOIN ActivityLines AL
            ON PK_ActivityID = AL.FK_ActivityID
    GROUP BY PK_SettlementSubsiderCampaignID

    SELECT  FK_SettlementID,
            PK_ActivityLineID,
            SUM(SS.Value / CountOfLines) SettlementSubsiderCampaign
    INTO    tempSettlementSubsiderCampaign
    FROM    SettlementSubsiderCampaign SS
    INNER JOIN CampaignSubsider
            ON PK_CampaignSubsiderID = FK_CampaignSubsiderID
    INNER JOIN Campaigns
            ON PK_CampaignID = FK_CampaignID
    INNER JOIN Activities A
            ON PK_CampaignID = A.FK_CampaignID
    INNER JOIN ActivityLines AL
            ON PK_ActivityID = AL.FK_ActivityID
    INNER JOIN tempSettlementSubsiderCampaignLines TS
            ON SS.PK_SettlementSubsiderCampaignID = TS.PK_SettlementSubsiderCampaignID
    GROUP BY FK_SettlementID,
            PK_ActivityLineID

    SELECT  PK_SettlementID,
            PostingDate,
            InvoiceDate,
            FK_ActivityLineID,
            SUM(Volume) Volume,
            SUM(OnInvoice) OnInvoice,
            SUM(OffInvoice) OffInvoice,
            SUM(SettlementSubsider) SettlementSubsider,
            SUM(SettlementSubsiderCampaign) SettlementSubsiderCampaign
    INTO    tempSettlements
    FROM    (SELECT PK_SettlementID,
                    PostingDate,
                    InvoiceDate,
                    FK_ActivityLineID,
                    SUM(ActualVolumeWholeseller) Volume,
                    SUM(ActualVolumeSupplier) * AVG(ISNULL(OnInvoice.Value, 0)) OnInvoice,
                    SUM(ActualVolumeWholeseller) * AVG(ISNULL(OffInvoice.Value, 0)) OffInvoice,
                    0 SettlementSubsider,
                    0 SettlementSubsiderCampaign
             FROM   Settlements
             INNER JOIN SettlementLines
                    ON PK_SettlementID = FK_SettlementID
             LEFT JOIN SettlementDiscounts OnInvoice
                    ON PK_SettlementLineID = OnInvoice.FK_SettlementLineID
                       AND OnInvoice.OnInvoice = 1
             LEFT JOIN SettlementDiscounts OffInvoice
                    ON PK_SettlementLineID = OffInvoice.FK_SettlementLineID
                       AND OffInvoice.OnInvoice = 0
             GROUP BY PK_SettlementID,
                    PostingDate,
                    InvoiceDate,
                    FK_ActivityLineID
             UNION ALL
             SELECT PK_SettlementID,
                    PostingDate,
                    InvoiceDate,
                    PK_ActivityLineID,
                    0 Volume,
                    0 OnInvoice,
                    0 OffInvoice,
                    SUM(SettlementSubsider) SettlementSubsider,
                    0 SettlementSubsiderCampaign
             FROM   Settlements S
             INNER JOIN tempSettlementSubsider TS
                    ON S.PK_SettlementID = TS.FK_SettlementID
             GROUP BY PK_SettlementID,
                    PostingDate,
                    InvoiceDate,
                    PK_ActivityLineID
             UNION ALL
             SELECT PK_SettlementID,
                    PostingDate,
                    InvoiceDate,
                    PK_ActivityLineID,
                    0 Volume,
                    0 OnInvoice,
                    0 OffInvoice,
                    0 SettlementSubsider,
                    SUM(SettlementSubsiderCampaign) SettlementSubsiderCampaign
             FROM   Settlements S
             INNER JOIN tempSettlementSubsiderCampaign TS
                    ON S.PK_SettlementID = TS.FK_SettlementID
             GROUP BY PK_SettlementID,
                    PostingDate,
                    InvoiceDate,
                    PK_ActivityLineID) Sub
    GROUP BY PK_SettlementID,
            PostingDate,
            InvoiceDate,
            FK_ActivityLineID

    INSERT  INTO tempExportCMS_Actual
            SELECT  PK_CampaignID CampaignID,
                    Campaigns.Label Campaign,
                    Chains.PK_ParticipatorID ChainID,
                    Chains.Label Chain,
                    Wholesellers.PK_ParticipatorID WholesellerID,
                    Wholesellers.Label Wholeseller,
                    PeriodDel.PeriodYear DeliveryYear,
                    PeriodDel.PeriodWeek DeliveryWeek,
                    PeriodActFrom.PeriodYear ActivityFromYear,
                    PeriodActFrom.PeriodWeek ActivityFromWeek,
                    PeriodActTo.PeriodYear ActivityToYear,
                    PeriodActTo.PeriodWeek ActivityToWeek,
                    PK_ActivityID ActivityID,
                    A.Label Activity,
                    PK_ActivityLineID ActivityLineID,
                    SU.ProductCode SalesUnitCode,
                    SUEAN.EANCode SalesUnitEANCode,
                    SU.Label SalesUnit,
                    P.ProductCode ProductCode,
                    PEAN.EANCode ProductEANCode,
                    P.Label Product,
                    AcS.Label Status,
                    AP.Label Purpose,
                    [dbo].[fn_ActivityType](ActivityTypes) ActivityTypes,
                    EstimatedSalesPricePieces,
                    EstimatedSalesPrice,
                    ForecastingUnitID,
                    ForecastingUnit,
                    Level4Node,
                    Level4Name,
                    Level7Node,
                    Level7Name,
                    Level11Node,
                    Level11Name,
                    Level12Node,
                    Level12Name,
                    Sub3ReportingNode,
                    Sub3ReportingLabel,
                    Sub2ReportingNode,
                    Sub2ReportingLabel,
                    SubReportingNode,
                    SubReportingLabel,
                    ReportingNode,
                    ReportingLabel,
                    PlanningNode,
                    PlanningLabel,
                    EuroNode,
                    EuroLabel,
                    SUEAN.Pieces / SU.PiecesPerConsumerUnit PiecesPerSalesUnit,
                    PK_SettlementID SettlementID,
                    InvoiceDate,
                    PostingDate,
                    Actual.Volume * AD.Value ActualVolume,
                    ISNULL(Pr.Value, 0) * Actual.Volume * AD.Value
                    / (SUEAN.Pieces  / SU.PiecesPerConsumerUnit ) AS ActualGSV,
                    (ISNULL(Pr.Value, 0) / (SUEAN.Pieces  / SU.PiecesPerConsumerUnit)
                     - dbo.rdh_fn_NetPrice(FK_SalesUnitID, FK_ChainID,
                                           PriceTag)) * Actual.Volume
                    * AD.Value AS ActualBaseDiscount,
                    Actual.OnInvoice * AD.Value ActualOnInvoice,
                    Actual.OffInvoice * AD.Value ActualOffInvoice,
                    ISNULL(Cost.Value, 0) * Actual.Volume * AD.Value
                    / (SUEAN.Pieces  / SU.PiecesPerConsumerUnit) AS ActualCostPrice,
                    ISNULL(SupplyCost.Value, 0) * Actual.Volume * AD.Value
                    / (SUEAN.Pieces  / SU.PiecesPerConsumerUnit) ActualSupplyCostPrice,
                    SettlementSubsiderCampaign * AD.Value ActualCampaignSubsider,
                    SettlementSubsider * AD.Value ActualActivitySubsider
            FROM    Campaigns
            INNER JOIN Participators Chains
                    ON Chains.PK_ParticipatorID = FK_ChainID
            INNER JOIN Participators Wholesellers
                    ON Wholesellers.PK_ParticipatorID = FK_WholesellerID
            INNER JOIN Activities A
                    ON PK_CampaignID = A.FK_CampaignID
            INNER JOIN Periods PeriodActFrom
                    ON PeriodActFrom.Label = ActivityFrom
            INNER JOIN Periods PeriodActTo
                    ON CAST(FLOOR(CAST(ActivityTo AS FLOAT)) AS DATETIME) = PeriodActTo.Label
            INNER JOIN ActivityDeliveries AD
                    ON PK_ActivityID = AD.FK_ActivityID
            INNER JOIN Periods PeriodDel
                    ON DeliveryDate = PeriodDel.Label
                       AND PeriodDel.Label BETWEEN @PeriodFrom AND @PeriodTo
            INNER JOIN ActivityLines AL
                    ON PK_ActivityID = AL.FK_ActivityID
            INNER JOIN Products SU
                    ON SU.PK_ProductID = FK_SalesUnitID
            INNER JOIN Products P
                    ON P.PK_ProductID = FK_ProductID
            INNER JOIN EANCodes SUEAN
                    ON SU.PK_ProductID = SUEAN.ProductID
                       AND SUEAN.FK_EANTypeID = 2
            INNER JOIN EANCodes PEAN
                    ON P.PK_ProductID = PEAN.ProductID
                       AND PEAN.FK_EANTypeID = 1
            INNER JOIN ActivityStatus AcS
                    ON PK_ActivityStatusID = FK_ActivityStatusID
            INNER JOIN ActivityPurposes AP
                    ON PK_ActivityPurposeID = FK_ActivityPurposeID
            INNER JOIN tempProductHierarchy PH
                    ON P.PK_ProductID = PH.ProductID
            INNER JOIN tempForecastingUnits FU
                    ON P.PK_ProductID = FU.SalesUnitID -- SU.PK_ProductID = FU.SalesUnitID - ændret pga tilknytning via salesunit gav problemer i relation til POS data.
            INNER JOIN tempChainHierarchy CH
                    ON Chains.PK_ParticipatorID = CH.ChainID
            LEFT JOIN Prices Pr
                    ON FK_SalesUnitID = Pr.FK_ProductID
                       AND Pr.PeriodFrom <= PriceTag
                       AND Pr.PeriodTo >= PriceTag
                       AND Pr.FK_PriceTypeID = 1
            LEFT JOIN Prices Tax
                    ON FK_SalesUnitID = Tax.FK_ProductID
                       AND Tax.PeriodFrom <= PriceTag
                       AND Tax.PeriodTo >= PriceTag
                       AND Tax.FK_PriceTypeID = 6
            LEFT JOIN Prices Cost
                    ON FK_SalesUnitID = Cost.FK_ProductID
                       AND Cost.PeriodFrom <= PriceTag
                       AND Cost.PeriodTo >= PriceTag
                       AND Cost.FK_PriceTypeID = 3
            LEFT JOIN Prices SupplyCost
                    ON FK_SalesUnitID = SupplyCost.FK_ProductID
                       AND SupplyCost.PeriodFrom <= PriceTag
                       AND SupplyCost.PeriodTo >= PriceTag
                       AND SupplyCost.FK_PriceTypeID = 7
            LEFT JOIN BaseDiscounts VT
                    ON Chains.PK_ParticipatorID = VT.FK_ParticipatorID
                       AND SU.PK_ProductID = VT.FK_ProductID
                       AND VT.PeriodFrom <= PriceTag
                       AND VT.PeriodTo >= PriceTag
                       AND FK_BaseDiscountTypeID = 7
            INNER JOIN tempSettlements Actual
                    ON AL.PK_ActivityLineID = Actual.FK_ActivityLineID

    DROP TABLE tempProductHierarchy
    DROP TABLE tempForecastingUnits
    DROP TABLE tempChainHierarchy

    DROP TABLE tempSettlementSubsiderLines
    DROP TABLE tempSettlementSubsider
    DROP TABLE tempSettlementSubsiderCampaignLines
    DROP TABLE tempSettlementSubsiderCampaign
    DROP TABLE tempSettlements



