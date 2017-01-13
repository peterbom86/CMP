CREATE PROC [dbo].[GenerateRebateAgreements]
AS 
    PRINT '# 0.0 Beginning - ' + CONVERT(nvarchar, GETDATE(), 120)
	
    PRINT '# 0.1 Check if tempNetPrice exists - ' + CONVERT(nvarchar, GETDATE(), 120)
	IF ( EXISTS ( SELECT   *
               FROM     INFORMATION_SCHEMA.TABLES
               WHERE    TABLE_SCHEMA = 'dbo'
                        AND TABLE_NAME = 'tempNetPrice' ) ) 
    BEGIN
		DROP TABLE dbo.tempNetPrice
    END
    
    PRINT '# 0.5 Flagging not sent idocs for deletion - '
        + CONVERT(nvarchar, GETDATE(), 120)
    UPDATE  rai
    SET     StateID = 99
    FROM    dbo.RebateAgreementExport as rae
            INNER JOIN dbo.RebateAgreementIdoc as rai on rae.ExportID = rai.ExportID
            LEFT JOIN ( SELECT  rae.ExportID,
                                CampaignID,
                                SequenceNo,
                                StateID
                        FROM    dbo.RebateAgreementExport as rae
                                INNER JOIN dbo.RebateAgreementIdoc as rai ON rae.ExportID = rai.ExportID
                      ) Sub ON rae.CampaignID = Sub.CampaignID
                               AND rae.SequenceNo < Sub.SequenceNo
                               AND Sub.StateID IN ( 2, 3 )
    WHERE   rai.StateID = 1
            AND Sub.ExportID IS NULL
	
    PRINT '# 0.6 Deleting idocs flagged for deletion - '
        + CONVERT(nvarchar, GETDATE(), 120)
    DELETE  FROM rail
    FROM    dbo.RebateAgreementIdocLine as rail
            INNER JOIN dbo.RebateAgreementIdoc as rai on rail.IdocID = rai.IdocID
    WHERE   StateID = 99

    DELETE  FROM rai
    FROM    dbo.RebateAgreementIdoc as rai
    WHERE   StateID = 99

    DELETE  FROM rae
    FROM    dbo.RebateAgreementExport as rae
    WHERE   ExportID NOT IN ( SELECT    ExportID
                              FROM      dbo.RebateAgreementIdoc as rai )

    DECLARE @sql nvarchar(MAX)	
    DECLARE @FieldList nvarchar(MAX)
    DECLARE @Calculation nvarchar(MAX)
    SET @FieldList = 'ActivityLineID int, ChainID int, PriceTag datetime, ProductID int, Pieces int, Price float'

    PRINT '# 1.0 Creating Fieldlist - ' + CONVERT(nvarchar, GETDATE(), 120)
    SELECT  @FieldList = ISNULL(@FieldList, '') + ', [' + Label
            + '] float DEFAULT(0)',
            @Calculation = ISNULL(@Calculation + ' + ', '') + 'ROUND(CAST('
            + CASE WHEN FK_ValueTypeID = 1 THEN '[Price] * '
                   ELSE ''
              END + '[' + Label + '] as money), 2)'
    FROM    dbo.BaseDiscountTypes as bdt
    WHERE   IsBaseDiscount = 1

    PRINT '# 1.1 Creating tempNetPrice - ' + CONVERT(nvarchar, GETDATE(), 120)

    SET @sql = 'CREATE TABLE tempNetPrice (' + @FieldList
        + ', NetPrice as (([Price] - (' + @Calculation + ')) / [Pieces]))'
    EXEC ( @sql
        )

    PRINT '# 1.2 Insert tempNetPrice - ' + CONVERT(nvarchar, GETDATE(), 120)
    INSERT  INTO tempNetPrice
            (
              ActivityLineID,
              ChainID,
              PriceTag,
              ProductID,
              Pieces,
              Price
            )
            SELECT  PK_ActivityLineID,
                    FK_ChainID,
                    PriceTag,
                    FK_SalesUnitID,
                    ISNULL(ec.Pieces, 1),
                    ISNULL(Value, 0)
            FROM    dbo.Campaigns as c
                    INNER JOIN dbo.Activities as a ON c.PK_CampaignID = a.FK_CampaignID
                    INNER JOIN dbo.ActivityLines as al on a.PK_ActivityID = al.FK_ActivityID
                    LEFT JOIN dbo.Prices as p ON FK_PriceTypeID = 1
                                                 AND al.FK_SalesUnitID = p.FK_ProductID
                                                 AND PriceTag BETWEEN PeriodFrom AND PeriodTo
                    LEFT JOIN dbo.EANCodes as ec ON ProductID = FK_SalesUnitID
                                                    AND FK_EANTypeID = 2
                    INNER JOIN dbo.ActivityStatus as as2 ON PK_ActivityStatusID = FK_ActivityStatusID
                    INNER JOIN dbo.Participators as p2 on PK_ParticipatorID = FK_ChainID
                    INNER JOIN dbo.ParticipatorStatus as ps on p2.FK_ParticipatorStatusID = ps.PK_ParticipatorStatusID
            WHERE   IsHidden = 0
                    AND ValidForSettlement = 1

    DECLARE @BaseDiscountLabel nvarchar(MAX)
    DECLARE FieldListCursor CURSOR
        FOR SELECT  Label
            FROM    dbo.BaseDiscountTypes as bdt
            WHERE   IsBaseDiscount = 1

    OPEN FieldListCursor

    FETCH NEXT FROM FieldListCursor INTO @BaseDiscountLabel

    WHILE @@FETCH_STATUS = 0
        BEGIN
            PRINT '# 1.3 Update tempNetPrice - Field: ' + @BaseDiscountLabel
                + ' - ' + CONVERT(nvarchar, GETDATE(), 120)
            SET @sql = 'UPDATE td
	SET [' + @BaseDiscountLabel
                + '] = Value
	FROM tempNetPrice td
		INNER JOIN dbo.BaseDiscounts as bd ON ChainID = FK_ParticipatorID AND PriceTag BETWEEN PeriodFrom AND PeriodTo AND FK_ProductID = ProductID
		INNER JOIN dbo.BaseDiscountTypes as bdt ON bd.FK_BaseDiscountTypeID = bdt.PK_BaseDiscountTypeID AND Label = '''
                + @BaseDiscountLabel + ''''
            EXEC ( @sql
                )
            FETCH NEXT FROM FieldListCursor INTO @BaseDiscountLabel
        END

    CLOSE FieldListCursor
    DEALLOCATE FieldListCursor

    -- Not necessary anymore, as all weeks should be sent
	--PRINT '# 1.9 Create CampaignList based on selected weeks'
	--EXEC GenerateRebateAgreementsCampaignList

    PRINT '# 2.0 Create #tempRebateAgreements - '
        + CONVERT(nvarchar, GETDATE(), 120)
    CREATE TABLE #tempRebateAgreements
        (
          ID int IDENTITY(1, 1)
                 PRIMARY KEY,
          CampaignID int,
          CampaignLabel nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS,
          IdocType nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
          PricingHierarchyNode nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS,
          EANCode nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS,
          ItemCategory nvarchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS,
          RebateRecipient nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
          CustomerNo nvarchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
          PeriodFrom datetime,
          PeriodTo datetime,
          Rate Money,
          Volume Money,
          ForceExportRebateAgreement bit,
          ExportType nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS
        )


    PRINT '# 2.1 Fill #tempRebateAgreements - Rebate - '
        + CONVERT(nvarchar, GETDATE(), 120)
    INSERT  INTO #tempRebateAgreements
            (
              CampaignID,
              CampaignLabel,
              IdocType,
              PricingHierarchyNode,
              EANCode,
              ItemCategory,
              RebateRecipient,
              CustomerNo,
              PeriodFrom,
              PeriodTo,
              Rate,
              Volume,
              ForceExportRebateAgreement
            )
            SELECT  PK_CampaignID CampaignID,
                    ISNULL(RIGHT(PFrom.Period, 2) + '-'
                           + SUBSTRING(CAST(PFrom.Period as nvarchar), 3, 2),
                           '') + ISNULL(' ' + p3.Label, '') CampaignLabel,
                    'Rebate' IdocType,
                    PH2.Node PricingHierarchyNode,
                    Null EANCode,
                    Null ItemCategory,
                    RR.RebateRecipient,
                    CN.CustomerNo,
                    MinDeliveryDay PeriodFrom,
                    MaxDeliveryDay - 4 PeriodTo,
                    SUM(CASE ISNULL(FK_ValueTypeID, 1)
                          WHEN 2 THEN ISNULL(CampaignDiscounts.Value, 0)
                          ELSE NetPrice -- dbo.rdh_fn_NetPrice(PK_ProductID, FK_ChainID, PriceTag)
                               * ISNULL(CampaignDiscounts.Value, 0)
                        END * EstimatedVolumeWholeseller)
                    / CASE WHEN SUM(EstimatedVolumeWholeseller) = 0 THEN 1
                           ELSE SUM(EstimatedVolumeWholeseller)
                      END * CASE WHEN AVG(ean.Pieces) = 0 THEN 1.0
                                 ELSE AVG(ean.Pieces)
                            END [Rate],
                    SUM(EstimatedVolumeWholeseller)
                    / CASE WHEN AVG(ean.Pieces) = 0 THEN 1.0
                           ELSE AVG(ean.Pieces)
                      END [Volume],
                    ForceExportRebateAgreement
            FROM    Products
                    INNER JOIN ProductHierarchies PH1 ON PH1.FK_ProductID = PK_ProductID
                    INNER JOIN ProductHierarchies PH2 ON PH1.FK_ProductHierarchyParentID = PH2.PK_ProductHierarchyID
                    INNER JOIN ProductHierarchies PH3 ON PH2.FK_ProductHierarchyParentID = PH3.PK_ProductHierarchyID
                    INNER JOIN ProductHierarchies PH4 ON PH3.FK_ProductHierarchyParentID = PH4.PK_ProductHierarchyID
                                                         AND PH4.FK_ProductHierarchyLevelID = 21
                    INNER JOIN ActivityLines AL ON PK_ProductID = AL.FK_ProductID
                    INNER JOIN EANCodes ean ON PK_ProductID = ProductID
                                               AND FK_EANTypeID = 2
                    INNER JOIN CampaignDiscounts ON PK_ActivityLineID = FK_ActivityLineID
                                                    AND OnInvoice = 0
                                                    AND Value > 0
                    INNER JOIN Activities ON PK_ActivityID = FK_ActivityID
                    INNER JOIN Campaigns ON PK_CampaignID = FK_CampaignID
					INNER JOIN dbo.vwRebateRecipients RR ON RR.FK_CategoryID = Campaigns.FK_CategoryId  AND RR.FK_ParticipatorID = Campaigns.FK_ChainID
					INNER JOIN dbo.vwCustomersOffInvoice CN ON CN.FK_CategoryID = Campaigns.FK_CategoryId AND CN.FK_ParticipatorID = Campaigns.FK_ChainID
                    INNER JOIN ( SELECT FK_ActivityID,
                                        Min(p2.Label) MinDeliveryDay
                                 FROM   ActivityDeliveries
                                        INNER JOIN dbo.Periods as p ON DeliveryDate = Label
                                        INNER JOIN dbo.Periods as p2 ON p.Period = p2.Period
                                 GROUP BY FK_ActivityID
                               ) MinDeliveries ON PK_ActivityID = MinDeliveries.FK_ActivityID
                    INNER JOIN ( SELECT FK_ActivityID,
                                        Max(p2.Label) MaxDeliveryDay
                                 FROM   ActivityDeliveries
                                        INNER JOIN dbo.Periods as p ON DeliveryDate = Label
                                        INNER JOIN dbo.Periods as p2 ON p.Period = p2.Period
                                 GROUP BY FK_ActivityID
                               ) MaxDeliveries ON PK_ActivityID = MaxDeliveries.FK_ActivityID
                    INNER JOIN Periods ON CAST(FLOOR(CAST(ActivityTo AS float)) AS datetime) = Periods.Label
                    INNER JOIN Periods PFrom ON CAST(FLOOR(CAST(ActivityFrom AS float)) AS datetime) = PFrom.Label
                    INNER JOIN ( SELECT Period,
                                        Min(Label) AS Monday
                                 FROM   Periods
                                 GROUP BY Period
                               ) P2 ON Periods.Period = P2.Period
                    INNER JOIN tempNetPrice np ON PK_ActivityLineID = np.ActivityLineID
                    INNER JOIN dbo.ActivityStatus as as2 ON PK_ActivityStatusID = FK_ActivityStatusID
                    INNER JOIN dbo.Participators as p3 on PK_ParticipatorID = FK_ChainID
                    INNER JOIN dbo.ParticipatorStatus as ps on p3.FK_ParticipatorStatusID = ps.PK_ParticipatorStatusID
            WHERE   IsHidden = 0
                    AND ValidForSettlement = 1
                    AND p3.ECCExportRebate = 1
                    AND EstimatedVolumeWholeseller <> 0
                    AND CASE WHEN ISNULL(RebateAgreementNoDiscount, '') = '' THEN 'SAP' ELSE RebateAgreementNoDiscount END LIKE 'SAP%'
                    /*AND (EXISTS ( SELECT *
                                 FROM   dbo.RebateAgreementCampaignsToSent as racts
                                 WHERE  PK_CampaignID = CampaignID )
                    OR NOT EXISTS ( SELECT  *
                                    FROM    dbo.RebateAgreementCampaignsToSent ))*/
            GROUP BY PK_CampaignID,
                    dbo.Campaigns.Label,
                    PH2.Node,
                    RR.RebateRecipient,
                    CN.CustomerNo,
                    MinDeliveryDay,
                    MaxDeliveryDay,
                    ForceExportRebateAgreement,
                    PFrom.Period,
                    p3.Label

    PRINT '# 2.2 Fill #tempRebateAgreements - Subsider - '
        + CONVERT(nvarchar, GETDATE(), 120)
    INSERT  INTO #tempRebateAgreements
            (
              CampaignID,
              CampaignLabel,
              IdocType,
              PricingHierarchyNode,
              EANCode,
              ItemCategory,
              RebateRecipient,
              CustomerNo,
              PeriodFrom,
              PeriodTo,
              Rate,
              Volume,
              ForceExportRebateAgreement
            )
            SELECT  PK_CampaignID CampaignID,
                    ISNULL(RIGHT(PFrom.Period, 2) + '-'
                           + SUBSTRING(CAST(PFrom.Period as nvarchar), 3, 2),
                           '') + ISNULL(' ' + p2.Label, '') CampaignLabel,
                    'Subsider' IdocType,
                    PH2.Node PricingHierarchyNode,
                    Null EANCode,
                    Null ItemCategory,
                    RR.RebateRecipient,
                    CN.CustomerNo,
                    MinDeliveryDay PeriodFrom,
                    MaxDeliveryDay - 4 PeriodTo,
                    SUM(ISNULL(CampaignSubsider, 0.0)
                        * CASE WHEN AllocationSumCampaign = 0
                               THEN 1.0
                                    / CAST(AllocationCountCampaign AS float)
                               ELSE NetPrice --dbo.rdh_fn_NetPrice(FK_SalesUnitID, FK_ChainID, PriceTag)
                                    * EstimatedVolumeWholeseller
                                    / AllocationSumCampaign
                          END + ISNULL(ActivitySubsider, 0.0)
                        * CASE WHEN AllocationSumActivity = 0
                               THEN 1.0
                                    / CAST(AllocationCountActivity AS float)
                               ELSE NetPrice --dbo.rdh_fn_NetPrice(FK_SalesUnitID,FK_ChainID, PriceTag)
                                    * EstimatedVolumeWholeseller
                                    / AllocationSumActivity
                          END) [Rate],
                    SUM(ISNULL(CampaignSubsider, 0.0)
                        * CASE WHEN AllocationSumCampaign = 0
                               THEN 1.0
                                    / CAST(AllocationCountCampaign AS float)
                               ELSE NetPrice --dbo.rdh_fn_NetPrice(FK_SalesUnitID,FK_ChainID, PriceTag)
                                    * EstimatedVolumeWholeseller
                                    / AllocationSumCampaign
                          END + ISNULL(ActivitySubsider, 0.0)
                        * CASE WHEN AllocationSumActivity = 0
                               THEN 1.0
                                    / CAST(AllocationCountActivity AS float)
                               ELSE NetPrice --dbo.rdh_fn_NetPrice(FK_SalesUnitID,FK_ChainID, PriceTag)
                                    * EstimatedVolumeWholeseller
                                    / AllocationSumActivity
                          END) [Volume],
                    ForceExportRebateAgreement
            FROM    Campaigns
					INNER JOIN dbo.vwRebateRecipients RR ON RR.FK_CategoryID = Campaigns.FK_CategoryId  AND RR.FK_ParticipatorID = Campaigns.FK_ChainID
					INNER JOIN dbo.vwCustomersOffInvoice CN ON CN.FK_CategoryID = Campaigns.FK_CategoryId AND CN.FK_ParticipatorID = Campaigns.FK_ChainID
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
                    AND p2.ECCExportRebate = 1
                    AND ISNULL(CampaignSubsider, 0) + ISNULL(ActivitySubsider,
                                                             0) <> 0
                    AND CASE WHEN ISNULL(RebateAgreementNoSubsider, '') = '' THEN 'SAP' ELSE RebateAgreementNoSubsider END LIKE 'SAP%'
                    /*AND (EXISTS ( SELECT *
                                 FROM   dbo.RebateAgreementCampaignsToSent as racts
                                 WHERE  PK_CampaignID = CampaignID )
                    OR NOT EXISTS ( SELECT  *
                                    FROM    dbo.RebateAgreementCampaignsToSent ))*/
            GROUP BY PK_CampaignID,
                    dbo.Campaigns.Label,
                    PH2.Node,
                    RR.RebateRecipient,
                    CN.CustomerNo,
                    MinDeliveryDay,
                    MaxDeliveryDay,
                    ForceExportRebateAgreement,
                    PFrom.Period,
                    p2.Label

    PRINT '# 2.3 Fill #tempRebateAgreements - SalesDeal1 - '
        + CONVERT(nvarchar, GETDATE(), 120)
    INSERT  INTO #tempRebateAgreements
            (
              CampaignID,
              CampaignLabel,
              IdocType,
              PricingHierarchyNode,
              EANCode,
              ItemCategory,
              RebateRecipient,
              CustomerNo,
              PeriodFrom,
              PeriodTo,
              Rate,
              Volume,
              ForceExportRebateAgreement
            )
            SELECT DISTINCT
                    PK_CampaignID CampaignID,
                    ISNULL(RIGHT(PFrom.Period, 2) + '-'
                           + SUBSTRING(CAST(PFrom.Period as nvarchar), 3, 2),
                           '') + ISNULL(' ' + dbo.Participators.Label, '') CampaignLabel,
                    'SalesDeal1' as IdocType,
                    Null ProductHierarchyNode,
                    EANCode,
                    ItemCategory,
                    Null RebateRecipient,
                    ecll.Label CustomerNo,
                    MinDeliveryDay PeriodFrom,
                    Monday + 4 PeriodTo,
                    ISNULL(CampaignDiscounts.Value * 100, 0) DiscountOnInvoice,
                    Null Volume,
                    ForceExportRebateAgreement
            FROM    Campaigns
                    INNER JOIN Activities ON PK_CampaignID = FK_CampaignID
                    INNER JOIN ActivityLines ON PK_ActivityID = ActivityLines.FK_ActivityID
                    INNER JOIN ( SELECT FK_ActivityID,
                                        Min(DeliveryDate) MinDeliveryDay
                                 FROM   ActivityDeliveries
                                 GROUP BY FK_ActivityID
                               ) Deliveries ON PK_ActivityID = Deliveries.FK_ActivityID
                    INNER JOIN CampaignDiscounts ON FK_ActivityLineID = PK_ActivityLineID
                                                    AND OnInvoice = 1
                                                    AND FK_ValueTypeID = 1
                                                    AND dbo.CampaignDiscounts.Value > 0
                    INNER JOIN Products ON FK_SalesUnitID = PK_ProductID
                    INNER JOIN ProductHierarchies PH1 ON PK_ProductID = PH1.FK_ProductID
                    INNER JOIN ProductHierarchies PH2 ON PH1.FK_ProductHierarchyParentID = PH2.PK_ProductHierarchyID
                                                         AND PH2.FK_ProductHierarchyLevelID = 4
                    INNER JOIN EANCodes ON PK_ProductID = ProductID
                                           AND FK_EANTypeID = 2
                    INNER JOIN Participators ON FK_ChainID = PK_ParticipatorID
                    INNER JOIN dbo.ExternalCustomerLinkLines as ecll ON PK_ParticipatorID = ecll.FK_ParticipatorID
					INNER JOIN dbo.ExternalCustomerLinks EL ON EL.PK_ExternalCustomerLinkID = ecll.FK_ExternalCustomerLinkID
						AND EL.Label = 'Customer No (On-invoice)'
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
                    AND Participators.ECCExportRebate = 1
                    /*AND (EXISTS ( SELECT *
                                 FROM   dbo.RebateAgreementCampaignsToSent as racts
                                 WHERE  PK_CampaignID = CampaignID )
                    OR NOT EXISTS ( SELECT  *
                                    FROM    dbo.RebateAgreementCampaignsToSent ))*/
                    AND dbo.CampaignDiscounts.Value <> 0
                    AND CASE WHEN ISNULL(SalesDealNo, '') = '' THEN 'SAP' ELSE SalesDealNo END LIKE 'SAP%'

    PRINT '# 2.4 Fill #tempRebateAgreements - SalesDeal2 - '
        + CONVERT(nvarchar, GETDATE(), 120)
    INSERT  INTO #tempRebateAgreements
            (
              CampaignID,
              CampaignLabel,
              IdocType,
              PricingHierarchyNode,
              EANCode,
              ItemCategory,
              RebateRecipient,
              CustomerNo,
              PeriodFrom,
              PeriodTo,
              Rate,
              Volume,
              ForceExportRebateAgreement
            )
            SELECT DISTINCT
                    PK_CampaignID CampaignID,
                    ISNULL(RIGHT(PFrom.Period, 2) + '-'
                           + SUBSTRING(CAST(PFrom.Period as nvarchar), 3, 2),
                           '') + ISNULL(' ' + dbo.Participators.Label, '') CampaignLabel,
                    'SalesDeal1' as IdocType,
                    Null ProductHierarchyNode,
                    EANCode,
                    ItemCategory,
                    Null RebateRecipient,
                    ecll.Label CustomerNo,
                    MinDeliveryDay PeriodFrom,
                    Monday + 4 PeriodTo,
                    ROUND(( ISNULL(CampaignDiscounts.Value * 100, 0)
                            / Prices.Value ) * EANCodes.Pieces / PiecesPerConsumerUnit, 3) DiscountOnInvoice,
                    Null Volume,
                    ForceExportRebateAgreement
            FROM    Campaigns
                    INNER JOIN Activities ON PK_CampaignID = FK_CampaignID
                    INNER JOIN ActivityLines ON PK_ActivityID = ActivityLines.FK_ActivityID
                    INNER JOIN ( SELECT FK_ActivityID,
                                        Min(DeliveryDate) MinDeliveryDay
                                 FROM   ActivityDeliveries
                                 GROUP BY FK_ActivityID
                               ) Deliveries ON PK_ActivityID = Deliveries.FK_ActivityID
                    INNER JOIN CampaignDiscounts ON FK_ActivityLineID = PK_ActivityLineID
                                                    AND OnInvoice = 1
                                                    AND FK_ValueTypeID = 2
                                                    AND dbo.CampaignDiscounts.Value > 0
                    INNER JOIN Products ON FK_SalesUnitID = PK_ProductID
                    INNER JOIN ProductHierarchies PH1 ON PK_ProductID = PH1.FK_ProductID
                    INNER JOIN ProductHierarchies PH2 ON PH1.FK_ProductHierarchyParentID = PH2.PK_ProductHierarchyID
                                                         AND PH2.FK_ProductHierarchyLevelID = 4
                    INNER JOIN EANCodes ON PK_ProductID = ProductID
                                           AND FK_EANTypeID = 2
                    INNER JOIN Participators ON FK_ChainID = PK_ParticipatorID
                    INNER JOIN dbo.ExternalCustomerLinkLines as ecll ON PK_ParticipatorID = ecll.FK_ParticipatorID
					INNER JOIN dbo.ExternalCustomerLinks EL ON EL.PK_ExternalCustomerLinkID = ecll.FK_ExternalCustomerLinkID
						AND EL.Label ='Customer No (On-invoice)'
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
            WHERE IsHidden = 0
                    AND ValidForSettlement = 1
                    AND ExportRebateAgreement = 1
                    AND Participators.ECCExportRebate = 1
                    AND dbo.Prices.Value <> 0
                    /*AND (EXISTS ( SELECT *
                                 FROM   dbo.RebateAgreementCampaignsToSent as racts
                                 WHERE  PK_CampaignID = CampaignID )
                    OR NOT EXISTS ( SELECT  *
                                    FROM    dbo.RebateAgreementCampaignsToSent ))*/
                    AND dbo.CampaignDiscounts.Value <> 0
                    AND CASE WHEN ISNULL(SalesDealNo, '') = '' THEN 'SAP' ELSE SalesDealNo END LIKE 'SAP%'

    PRINT '# 3.0a Find previous sent - ' + CONVERT(nvarchar, GETDATE(), 120)
    SELECT  rae.ExportID,
            rae.CampaignID,
            rae.CampaignLabel,
            IdocType,
            PricingHierarchyNode,
            EANCode,
            ItemCategory,
            RebateRecipient,
            CustomerNo,
            PeriodFrom,
            PeriodTo,
            Rate,
            Volume
    INTO    #tempPrevious
    FROM    dbo.RebateAgreementExport as rae
            INNER JOIN ( SELECT CampaignID,
                                MAX(SequenceNo) MaxSequenceNo
                         FROM   dbo.RebateAgreementExport as rae2
                         GROUP BY CampaignID
                       ) Sub ON rae.CampaignID = Sub.CampaignID
                                AND rae.SequenceNo = MaxSequenceNo
                                AND rae.ExportType <> 'DELETE'
            INNER JOIN dbo.RebateAgreementIdoc as rai ON rae.ExportID = rai.ExportID
            INNER JOIN dbo.RebateAgreementIdocLine as rail ON rai.IdocID = rail.IdocID

    PRINT '# 3.0b Find rows not to update - ' + CONVERT(nvarchar, GETDATE(), 120)
    UPDATE  t
    SET     ExportType = 'Nothing'
    FROM    #tempRebateAgreements t
            INNER JOIN #tempPrevious Sub ON Sub.CampaignID = t.CampaignID
                                            AND Sub.CampaignLabel = t.CampaignLabel
                                            AND Sub.IdocType = t.IdocType
                                            AND ISNULL(Sub.PricingHierarchyNode,
                                                       'CMP-1') = ISNULL(t.PricingHierarchyNode, 'CMP-1')
                                            AND ISNULL(Sub.EANCode, 'CMP-1') = ISNULL(t.EANCode, 'CMP-1')
                                            AND ISNULL(Sub.ItemCategory,
                                                       'CMP-1') = ISNULL(t.ItemCategory, 'CMP-1')
                                            AND ISNULL(Sub.RebateRecipient,
                                                       'CMP-1') = ISNULL(t.RebateRecipient, 'CMP-1')
                                            AND ISNULL(Sub.CustomerNo, 'CMP-1') = ISNULL(t.CustomerNo, 'CMP-1')
                                            AND Sub.PeriodFrom = t.PeriodFrom
                                            AND Sub.PeriodTo = t.PeriodTo
                                            AND Sub.Rate = t.Rate
                                            AND ISNULL(Sub.Volume, -1) = ISNULL(t.Volume, -1)
                                            AND ForceExportRebateAgreement = 0

    PRINT '# 3.0b Find rows to delete - ' + CONVERT(nvarchar, GETDATE(), 120)
    INSERT  INTO #tempRebateAgreements
            (
              CampaignID,
              CampaignLabel,
              IdocType,
              PricingHierarchyNode,
              EANCode,
              ItemCategory,
              RebateRecipient,
              CustomerNo,
              PeriodFrom,
              PeriodTo,
              Rate,
              Volume,
              ExportType
            )
            SELECT  Sub.CampaignID,
                    Sub.CampaignLabel,
                    Sub.IdocType,
                    Sub.PricingHierarchyNode,
                    Sub.EANCode,
                    Sub.ItemCategory,
                    Sub.RebateRecipient,
                    Sub.CustomerNo,
                    Sub.PeriodFrom,
                    Sub.PeriodTo,
                    Sub.Rate,
                    Sub.Volume,
                    'DELETE'
            FROM    #tempRebateAgreements t
                    RIGHT JOIN #tempPrevious Sub ON Sub.CampaignID = t.CampaignID
                                                    AND Sub.IdocType = t.IdocType
                                                    AND ISNULL(Sub.PricingHierarchyNode, 'CMP-1') = ISNULL(t.PricingHierarchyNode, 'CMP-1')
                                                    AND ISNULL(Sub.EANCode, 'CMP-1') = ISNULL(t.EANCode, 'CMP-1')
                                                    AND ISNULL(Sub.ItemCategory, 'CMP-1') = ISNULL(t.ItemCategory, 'CMP-1')
                                                    AND ISNULL(Sub.RebateRecipient, 'CMP-1') = ISNULL(t.RebateRecipient, 'CMP-1')
                                                    AND ISNULL(Sub.CustomerNo, 'CMP-1') = ISNULL(t.CustomerNo, 'CMP-1')
                                                    AND Sub.PeriodFrom = t.PeriodFrom
                                                    AND Sub.PeriodTo = t.PeriodTo
                                                    AND Sub.Rate = t.Rate
                                                    AND ISNULL(Sub.Volume, -1) = ISNULL(t.Volume, -1)
                                                    AND ForceExportRebateAgreement = 0
            WHERE   t.CampaignID IS Null
                    AND Sub.CampaignID NOT IN (
                    SELECT  CampaignID
                    FROM    #tempRebateAgreements t )

    PRINT '# 3.0c Find rows to delete - ' + CONVERT(nvarchar, GETDATE(), 120) -- Uncommented by po 15/3-2012 - seemed to do the right thing anyway after putting in ExportType = 'Nothing' - Commented out by po 21/12-2011 - Seems to do the wrong thing. It looks like it is changing the deletes to change.
    UPDATE t
    SET     ExportType = 'CHANGE'
    FROM    #tempRebateAgreements t
    WHERE CampaignID IN (
    SELECT Sub.CampaignID
    FROM    #tempRebateAgreements t
            RIGHT JOIN #tempPrevious Sub ON Sub.CampaignID = t.CampaignID
                                            AND Sub.IdocType = t.IdocType
                                            AND ISNULL(Sub.PricingHierarchyNode,
                                                       'CMP-1') = ISNULL(t.PricingHierarchyNode, 'CMP-1')
                                            AND ISNULL(Sub.EANCode, 'CMP-1') = ISNULL(t.EANCode, 'CMP-1')
                                            AND ISNULL(Sub.ItemCategory,
                                                       'CMP-1') = ISNULL(t.ItemCategory, 'CMP-1')
                                            AND ISNULL(Sub.RebateRecipient,
                                                       'CMP-1') = ISNULL(t.RebateRecipient, 'CMP-1')
                                            AND ISNULL(Sub.CustomerNo, 'CMP-1') = ISNULL(t.CustomerNo, 'CMP-1')
                                            AND Sub.PeriodFrom = t.PeriodFrom
                                            AND Sub.PeriodTo = t.PeriodTo
                                            AND Sub.Rate = t.Rate
                                            AND ISNULL(Sub.Volume, -1) = ISNULL(t.Volume, -1)
                                            AND ForceExportRebateAgreement = 0
	WHERE t.CampaignID IS Null) AND ExportType = 'Nothing'

    PRINT '# 3.1 Find rows to insert - ' + CONVERT(nvarchar, GETDATE(), 120)
    UPDATE  t
    SET     ExportType = 'INSERT'
    FROM    #tempRebateAgreements t
    WHERE   CampaignID NOT IN (
            SELECT  rae.CampaignID
            FROM    dbo.RebateAgreementExport as rae
                    INNER JOIN ( SELECT CampaignID,
                                        MAX(SequenceNo) MaxSequenceNo
                                 FROM   dbo.RebateAgreementExport as rae2
                                 GROUP BY CampaignID
                               ) Sub ON rae.CampaignID = Sub.CampaignID
                                        AND rae.ExportType <> 'DELETE' )

    PRINT '# 3.2 Find rows to change - ' + CONVERT(nvarchar, GETDATE(), 120)
    UPDATE  t
    SET     ExportType = 'CHANGE'
    FROM    #tempRebateAgreements t
    WHERE   CampaignID IN ( SELECT  CampaignID
                            FROM    #tempRebateAgreements t
                            WHERE   ExportType IS NULL )

    PRINT '# 3.3 Find rows to delete - ' + CONVERT(nvarchar, GETDATE(), 120)
    INSERT  INTO #tempRebateAgreements
            (
              CampaignID,
              CampaignLabel,
              IdocType,
              PricingHierarchyNode,
              EANCode,
              ItemCategory,
              RebateRecipient,
              CustomerNo,
              PeriodFrom,
              PeriodTo,
              Rate,
              Volume,
              ExportType
            )
            SELECT  rae.CampaignID,
                    CampaignLabel,
                    IdocType,
                    PricingHierarchyNode,
                    EANCode,
                    ItemCategory,
                    RebateRecipient,
                    CustomerNo,
                    PeriodFrom,
                    PeriodTo,
                    Rate,
                    Volume,
                    'DELETE'
            FROM    dbo.RebateAgreementExport as rae
                    INNER JOIN ( SELECT CampaignID,
                                        MAX(SequenceNo) MaxSequenceNo
                                 FROM   dbo.RebateAgreementExport as rae2
                                 GROUP BY CampaignID
                               ) Sub ON rae.CampaignID = Sub.CampaignID
                                        AND rae.SequenceNo = MaxSequenceNo
                                        AND rae.ExportType <> 'DELETE'
                    INNER JOIN dbo.RebateAgreementIdoc as rai on rae.ExportID = rai.ExportID
                    INNER JOIN dbo.RebateAgreementIdocLine as rail on rai.IdocID = rail.IdocID
            WHERE   rae.CampaignID NOT IN ( SELECT  CampaignID
                                            FROM    #tempRebateAgreements )
                    OR rae.CampaignID IN ( SELECT   CampaignID
                                           FROM     #tempRebateAgreements
                                           WHERE    ExportType = 'CHANGE' )

    PRINT '# 4.0 Create Idocs for deletion - ' + CONVERT(nvarchar, GETDATE(), 120)
    DECLARE @tempRebateAgreementExport TABLE
        (
          ExportID int,
          CampaignID int,
          ExportType nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
          SequenceNo int
        )

    INSERT  INTO dbo.RebateAgreementExport
            (
              CampaignID,
              CampaignLabel,
              ExportType,
              SequenceNo
            )
    OUTPUT  INSERTED.ExportID,
            INSERTED.CampaignID,
            INSERTED.ExportType,
            INSERTED.SequenceNo
            INTO @tempRebateAgreementExport
            SELECT DISTINCT
                    t.CampaignID,
                    CampaignLabel,
                    ExportType,
                    MaxSequenceNo + 1
            FROM    #tempRebateAgreements t
                    INNER JOIN ( SELECT CampaignID,
                                        MAX(SequenceNo) MaxSequenceNo
                                 FROM   dbo.RebateAgreementExport as rae
                                 GROUP BY CampaignID
                               ) Sub ON Sub.CampaignID = t.CampaignID
            WHERE   ExportType = 'DELETE'

    DECLARE @tempRebateAgreementIdoc TABLE
        (
          IdocID int,
          ExportID int,
          IdocType nvarchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS
        )

    INSERT  INTO dbo.RebateAgreementIdoc
            (
              ExportID,
              IdocType,
              UniqueIdentifier,
              RebateRecipient,
              CustomerNo,
              PeriodFrom,
              PeriodTo
            )
    OUTPUT  INSERTED.IdocID,
            INSERTED.ExportID,
            INSERTED.IdocType
            INTO @tempRebateAgreementIdoc
            SELECT DISTINCT
                    ExportID,
                    IdocType,
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CONVERT(nvarchar, GETDATE(), 120),
                                                            ' ', ''), '-', ''),
                                            'T', ''), ':', '') + REPLICATE('0', 5 - LEN(CAST(ROW_NUMBER() OVER ( ORDER BY ExportID, IdocType ) as nvarchar)))
                            + CAST(ROW_NUMBER() OVER ( ORDER BY ExportID, IdocType ) as nvarchar),
                            '.', ''),
                    RebateRecipient,
                    CustomerNo,
                    PeriodFrom,
                    PeriodTo
            FROM    ( SELECT DISTINCT
                                t.ExportID,
                                t2.IdocType,
                                RebateRecipient,
                                CustomerNo,
                                PeriodFrom,
                                PeriodTo
                      FROM      @tempRebateAgreementExport t
                                INNER JOIN #tempRebateAgreements t2 ON t.CampaignID = t2.CampaignID
                                                                       AND t.ExportType = t2.ExportType
                    ) Sub

    INSERT  INTO dbo.RebateAgreementIdocLine
            (
              IdocID,
              PricingHierarchyNode,
              EANCode,
              ItemCategory,
              Rate,
              Volume
            )
            SELECT  t2.IdocID,
                    PricingHierarchyNode,
                    EANCode,
                    ItemCategory,
                    Rate,
                    Volume
            FROM    @tempRebateAgreementExport t
                    INNER JOIN @tempRebateAgreementIdoc t2 ON t.ExportID = t2.ExportID
                    INNER JOIN #tempRebateAgreements t3 ON t.CampaignID = t3.CampaignID
                                                           AND t2.IdocType = t3.IdocType
                                                           AND t.ExportType = t3.ExportType
                                                       
    DELETE  FROM @tempRebateAgreementExport
    DELETE  FROM @tempRebateAgreementIdoc

    WAITFOR DELAY '00:00:01'
	
    PRINT '# 4.1 Create Idocs for insertion - ' + CONVERT(nvarchar, GETDATE(), 120)
    INSERT  INTO dbo.RebateAgreementExport
            (
              CampaignID,
              CampaignLabel,
              ExportType,
              SequenceNo
            )
    OUTPUT  INSERTED.ExportID,
            INSERTED.CampaignID,
            INSERTED.ExportType,
            INSERTED.SequenceNo
            INTO @tempRebateAgreementExport
            SELECT DISTINCT
                    t.CampaignID,
                    CampaignLabel,
                    'INSERT' ExportType,
                    ISNULL(MaxSequenceNo, 0) + 1
            FROM    #tempRebateAgreements t
                    LEFT JOIN ( SELECT  CampaignID,
                                        MAX(SequenceNo) MaxSequenceNo
                                FROM    dbo.RebateAgreementExport as rae
                                GROUP BY CampaignID
                              ) Sub ON Sub.CampaignID = t.CampaignID
            WHERE   ExportType IN ( 'CHANGE', 'INSERT' )

    INSERT  INTO dbo.RebateAgreementIdoc
            (
              ExportID,
              IdocType,
              UniqueIdentifier,
              RebateRecipient,
              CustomerNo,
              PeriodFrom,
              PeriodTo
            )
    OUTPUT  INSERTED.IdocID,
            INSERTED.ExportID,
            INSERTED.IdocType
            INTO @tempRebateAgreementIdoc
            SELECT DISTINCT
                    ExportID,
                    IdocType,
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CONVERT(nvarchar, GETDATE(), 120),
                                                            ' ', ''), '-', ''),
                                            'T', ''), ':', '') + REPLICATE('0', 5 - LEN(CAST(ROW_NUMBER() OVER ( ORDER BY ExportID, IdocType ) as nvarchar)))
                            + CAST(ROW_NUMBER() OVER ( ORDER BY ExportID, IdocType ) as nvarchar),
                            '.', ''),
                    RebateRecipient,
                    CustomerNo,
                    PeriodFrom,
                    PeriodTo
            FROM    ( SELECT DISTINCT
                                t.ExportID,
                                t2.IdocType,
                                RebateRecipient,
                                CustomerNo,
                                PeriodFrom,
                                PeriodTo
                      FROM      @tempRebateAgreementExport t
                                INNER JOIN #tempRebateAgreements t2 ON t.CampaignID = t2.CampaignID
                                                                       AND t.ExportType = REPLACE(t2.ExportType, 'CHANGE', 'INSERT')
                    ) Sub

    INSERT  INTO dbo.RebateAgreementIdocLine
            (
              IdocID,
              PricingHierarchyNode,
              EANCode,
              ItemCategory,
              Rate,
              Volume
            )
            SELECT  t2.IdocID,
                    PricingHierarchyNode,
                    EANCode,
                    ItemCategory,
                    Rate,
                    Volume
            FROM    @tempRebateAgreementExport t
                    INNER JOIN @tempRebateAgreementIdoc t2 ON t.ExportID = t2.ExportID
                    INNER JOIN #tempRebateAgreements t3 ON t.CampaignID = t3.CampaignID
                                                           AND t2.IdocType = t3.IdocType
                                                           AND t.ExportType = REPLACE(t3.ExportType, 'CHANGE', 'INSERT')

    PRINT '# 5.0 Cleanup - ' + CONVERT(nvarchar, GETDATE(), 120)
    UPDATE  dbo.Campaigns
    SET     ForceExportRebateAgreement = 0
    WHERE   ForceExportRebateAgreement = 1
                                                       
    DROP TABLE #tempRebateAgreements
    DROP TABLE #tempPrevious
    
    DROP TABLE tempNetPrice

    PRINT '# 5.1 Flag changes prior to today for failure - '
        + CONVERT(nvarchar, GETDATE(), 120)
/*    UPDATE  rai
    SET     StateID = 9
    FROM    dbo.RebateAgreementExport as rae
            INNER JOIN dbo.RebateAgreementIdoc as rai on rae.ExportID = rai.ExportID
            INNER JOIN dbo.RebateAgreementExport AS rae2 ON rae.CampaignID = rae2.CampaignID
    WHERE   rai.StateID = 1
            AND rai.PeriodFrom <= GETDATE()*/
--Changed 2013-04-11 by po as both insert and delete should be failed when this happens, 
--or else the rebateagreement is deleted and no new is inserted
    UPDATE  rai2
    SET     StateID = 99 /*StateID = 9*/
	FROM dbo.RebateAgreementIdoc AS rai
		INNER JOIN dbo.RebateAgreementExport AS rae ON rai.ExportID = rae.ExportID
		INNER JOIN dbo.RebateAgreementExport AS rae2 ON rae.CampaignID = rae2.CampaignID
		INNER JOIN dbo.RebateAgreementIdoc AS rai2 ON rae2.ExportID = rai2.ExportID
	WHERE rai.StateID = 1
		AND rai.PeriodFrom <= GETDATE()
		AND rai2.StateID = 1

    PRINT '# 9.9 Finished - ' + CONVERT(nvarchar, GETDATE(), 120)
