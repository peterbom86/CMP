CREATE PROC dbo.rdh_ExportCMS
AS 
    DECLARE @PeriodFrom DATETIME
    DECLARE @PeriodTo DATETIME

    SET @PeriodFrom = '2013-01-01'
    SET @PeriodTo = CAST(FLOOR(CAST(GETDATE() as float)) as datetime) + 4 * 7

    TRUNCATE TABLE tempExportCMS

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

    SELECT  FK_CampaignID CampaignID,
            SUM(Value) SumValue
    INTO    tempCampaignSubsider
    FROM    CampaignSubsider
    WHERE   IsAdvertising = 0
    GROUP BY FK_CampaignID

    SELECT  FK_ActivityID ActivityID,
            SUM(Value) SumValue
    INTO    tempActivitySubsider
    FROM    ActivitySubsider
    WHERE   IsAdvertising = 0
    GROUP BY FK_ActivityID

    SELECT  FK_CampaignID CampaignID,
            SUM(Value) SumValue
    INTO    tempCampaignAdvertising
    FROM    CampaignSubsider
    WHERE   IsAdvertising = 1
    GROUP BY FK_CampaignID

    SELECT  FK_ActivityID ActivityID,
            SUM(Value) SumValue
    INTO    tempActivityAdvertising
    FROM    ActivitySubsider
    WHERE   IsAdvertising = 1
    GROUP BY FK_ActivityID

    SELECT DISTINCT
            COALESCE([OnInv].[FK_ActivityLineID], [OffInv].[FK_ActivityLineID]) AS [FK_ActivityLineID],
            [OnInv].[Value] AS OnInvoiceDiscount,
            [OffInv].[Value] AS OffInvoiceDiscount,
            [OnInv].[FK_ValueTypeID] AS OnInvoiceValueTypeID,
            [OffInv].[FK_ValueTypeID] AS OffInvoiceValueTypeID
    INTO    tempOnOffDiscount
    FROM    (SELECT * FROM CampaignDiscounts WHERE OnInvoice = 1) OnInv
    FULL JOIN (SELECT * FROM CampaignDiscounts WHERE OnInvoice = 0) OffInv
            ON [OnInv].[FK_ActivityLineID] = [OffInv].[FK_ActivityLineID]

    SELECT  [FK_ParticipatorID],
            [FK_ProductID],
            [Value],
            [PeriodFrom],
            [PeriodTo]
    INTO    tempBaseDiscounts
    FROM    BaseDiscounts
    WHERE   [FK_BaseDiscountTypeID] = 7	

    SELECT  FK_ActivityID,
            COUNT(FK_ActivityID) CountOfLinesInActivity,
            SUM(al.EstimatedVolumeWholeseller * p.Value / (ec.Pieces / PiecesPerConsumerUnit)) SumGSVActivity
    INTO    tempCountOfLinesInActivity
    FROM    dbo.ActivityLines AS al
      INNER JOIN dbo.Activities AS a ON a.PK_ActivityID = al.FK_ActivityID
      INNER JOIN dbo.Prices AS p ON p.FK_ProductID = al.FK_SalesUnitID AND 
        PeriodFrom <= a.PriceTag AND PeriodTo >= a.PriceTag
      INNER JOIN dbo.EANCodes AS ec ON ec.ProductID = p.FK_ProductID AND ec.FK_EANTypeID = 2
      INNER JOIN dbo.Products as p2 ON ec.ProductID = p2.PK_ProductID
    WHERE p.FK_PriceTypeID = 1 
    GROUP BY FK_ActivityID

    SELECT  FK_CampaignID,
            COUNT(*) CountOfLinesInCampaign,
            SUM(al.EstimatedVolumeWholeseller * p.Value / (ec.Pieces / PiecesPerConsumerUnit ) ) SumGSVCampaign
    INTO    tempCountOfLinesInCampaign
    FROM    dbo.ActivityLines AS al
    INNER JOIN dbo.Activities AS a
            ON PK_ActivityID = FK_ActivityID
      INNER JOIN dbo.Prices AS p ON p.FK_ProductID = al.FK_SalesUnitID AND 
        PeriodFrom <= a.PriceTag AND PeriodTo >= a.PriceTag
      INNER JOIN dbo.EANCodes AS ec ON ec.ProductID = p.FK_ProductID AND ec.FK_EANTypeID = 2
      INNER JOIN dbo.Products as p2 ON ec.ProductID = p2.PK_ProductID
    WHERE p.FK_PriceTypeID = 1 
    GROUP BY FK_CampaignID

    INSERT  INTO tempExportCMS
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
                    AcS.Label [Status],
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
                    EstimatedVolumeWholeseller * AD.Value AS Volume,
                    ISNULL(Tax.Value, 0) * EstimatedVolumeWholeseller * AD.Value
                    / (SUEAN.Pieces  / SU.PiecesPerConsumerUnit) AS Tax,
                    ISNULL(Pr.Value, 0) * EstimatedVolumeWholeseller * AD.Value
                    / (SUEAN.Pieces  / SU.PiecesPerConsumerUnit) AS GSV,
                    (ISNULL(Pr.Value, 0) / (SUEAN.Pieces / SU.PiecesPerConsumerUnit)
                     - dbo.rdh_fn_NetPrice(FK_SalesUnitID, FK_ChainID,
                                           PriceTag))
                    * EstimatedVolumeWholeseller * AD.Value AS BaseDiscount,
                    CASE WHEN OnOffDiscount.OnInvoiceValueTypeID = 1
                         THEN ISNULL(Pr.Value, 0) / (SUEAN.Pieces  / SU.PiecesPerConsumerUnit )
                         ELSE 1
                    END * ISNULL(OnOffDiscount.OnInvoiceDiscount, 0)
                    * EstimatedVolumeWholeseller * AD.Value OnInvoiceDiscount,
                    CASE WHEN OnOffDiscount.OffInvoiceValueTypeID = 1
                         THEN ISNULL(Pr.Value, 0) / (SUEAN.Pieces  / SU.PiecesPerConsumerUnit)
                         ELSE 1
                    END * ISNULL(OnOffDiscount.OffInvoiceDiscount, 0)
                    * EstimatedVolumeWholeseller * AD.Value OffInvoiceDiscount,
                    ISNULL(Cost.Value, 0) * EstimatedVolumeWholeseller * AD.Value
                    / (SUEAN.Pieces  / SU.PiecesPerConsumerUnit) AS CostPrice,
                    ISNULL(SupplyCost.Value, 0) * ISNULL(Pr.Value, 0)
                    * EstimatedVolumeWholeseller * AD.Value / (SUEAN.Pieces  / SU.PiecesPerConsumerUnit) SupplyCostPrice,
                    ISNULL(ISNULL(CS.SumValue, 0) * AD.Value * 
                      CASE WHEN SumGSVCampaign = 0 
                        THEN 1 / CountOfLinesInCampaign 
                        ELSE (al.EstimatedVolumeWholeseller * Pr.Value / (SUEAN.Pieces  / SU.PiecesPerConsumerUnit) ) / SumGSVCampaign END, 0) CampaignSubsider,
                    ISNULL(ISNULL(AcSu.SumValue, 0) * AD.Value   * 
                      CASE WHEN SumGSVActivity = 0 
                        THEN 1 / CountOfLinesInActivity 
                        ELSE (al.EstimatedVolumeWholeseller * Pr.Value / (SUEAN.Pieces  / SU.PiecesPerConsumerUnit) ) / SumGSVActivity END, 0) ActivitySubsider,
                    ISNULL(VT.Value, 0) * dbo.rdh_fn_NetPrice(FK_SalesUnitID, FK_ChainID, PriceTag)
                    * EstimatedVolumeWholeseller * AD.Value VariableTrade,
                    ISNULL(ISNULL(CA.SumValue, 0) * AD.Value  * 
                      CASE WHEN SumGSVCampaign = 0 
                        THEN 1 / CountOfLinesInCampaign 
                        ELSE (al.EstimatedVolumeWholeseller * Pr.Value / (SUEAN.Pieces  / SU.PiecesPerConsumerUnit) ) / SumGSVCampaign END, 0) CampaignAdvertising,
                    ISNULL(ISNULL(AcA.SumValue, 0) * AD.Value  * 
                      CASE WHEN SumGSVActivity = 0 
                        THEN 1 / CountOfLinesInActivity 
                        ELSE (al.EstimatedVolumeWholeseller * Pr.Value / (SUEAN.Pieces  / SU.PiecesPerConsumerUnit) ) / SumGSVActivity END, 0) ActivityAdvertising
                
                
                --Null SettlementID, --PK_SettlementID SettlementID, 
                --Null InvoiceDate,
                --Null PostingDate,
                --Null ActualVolume, --Actual.Volume ActualVolume, 
                --Null ActualGSV, --ISNULL(Pr.Value, 0) * Actual.Volume / SUEAN.Pieces AS ActualGSV, 
                --Null ActualBaseDiscount, --(ISNULL(Pr.Value, 0) / SUEAN.Pieces - dbo.rdh_fn_NetPrice(FK_SalesUnitID, FK_ChainID, PriceTag)) * Actual.Volume AS ActualBaseDiscount,
                --Null ActualOnInvoice, --Actual.OnInvoice ActualOnInvoice, 
                --Null ActualOffInvoice, --Actual.OffInvoice ActualOffInvoice, 
                --Null ActualCostPrice, --ISNULL(Cost.Value, 0) * Actual.Volume / SUEAN.Pieces AS ActualCostPrice, 
                --Null ActualSupplyCostPrice, --ISNULL(SupplyCost.Value, 0) * Actual.Volume / SUEAN.Pieces ActualSupplyCostPrice,
                --Null AS ActualCampaignSubsider,
                --Null AS ActualActivitySubsider
                    
--select  [PK_CampaignID]
            FROM    Campaigns
            INNER JOIN Participators Chains
                    ON Chains.PK_ParticipatorID = FK_ChainID
            INNER JOIN Participators Wholesellers
                    ON Wholesellers.PK_ParticipatorID = FK_WholesellerID
            INNER JOIN Activities A
                    ON PK_CampaignID = A.FK_CampaignID
            INNER JOIN ActivityDeliveries AD
                    ON PK_ActivityID = AD.FK_ActivityID
            INNER JOIN Periods PeriodDel
                    ON DeliveryDate = PeriodDel.Label
                       AND PeriodDel.Label BETWEEN @PeriodFrom AND @PeriodTo
            INNER JOIN Periods PeriodActFrom
                    ON PeriodActFrom.Label = ActivityFrom
            INNER JOIN Periods PeriodActTo
                    ON CAST(FLOOR(CAST(ActivityTo AS FLOAT)) AS DATETIME) = PeriodActTo.Label
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
            LEFT JOIN tempCampaignSubsider CS
                    ON PK_CampaignID = CS.CampaignID
            LEFT JOIN tempActivitySubsider AcSu
                    ON PK_ActivityID = AcSu.ActivityID
            LEFT JOIN tempCampaignAdvertising CA
                    ON PK_CampaignID = CA.CampaignID
            LEFT JOIN tempActivityAdvertising AcA
                    ON PK_ActivityID = AcA.ActivityID
            LEFT JOIN Prices Pr
                    ON FK_SalesUnitID = Pr.FK_ProductID
                       AND Pr.PeriodFrom <= [PriceTag]
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
            LEFT JOIN tempOnOffDiscount OnOffDiscount
                    ON PK_ActivityLineID = OnOffDiscount.FK_ActivityLineID
            INNER JOIN tempCountOfLinesInActivity CountOfLinesInActivity
                    ON PK_ActivityID = CountOfLinesInActivity.FK_ActivityID
            INNER JOIN tempCountOfLinesInCampaign CountOfLinesInCampaign
                    ON PK_CampaignID = CountOfLinesInCampaign.FK_CampaignID
            LEFT JOIN tempBaseDiscounts VT
                    ON Chains.PK_ParticipatorID = VT.FK_ParticipatorID
                       AND SU.PK_ProductID = VT.FK_ProductID
                       AND VT.PeriodFrom <= PriceTag
                       AND VT.PeriodTo >= PriceTag

    DROP TABLE tempProductHierarchy
    DROP TABLE tempForecastingUnits
    DROP TABLE tempChainHierarchy
    DROP TABLE tempCampaignSubsider
    DROP TABLE tempActivitySubsider
    DROP TABLE [tempActivityAdvertising]
    DROP TABLE [tempCampaignAdvertising]
    DROP TABLE [tempOnOffDiscount]
    DROP TABLE tempBaseDiscounts
    DROP TABLE tempCountOfLinesInActivity
    DROP TABLE tempCountOfLinesInCampaign

