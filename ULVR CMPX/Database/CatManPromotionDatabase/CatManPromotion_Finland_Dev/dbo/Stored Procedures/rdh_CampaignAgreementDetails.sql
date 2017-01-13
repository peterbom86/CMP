CREATE PROC dbo.rdh_CampaignAgreementDetails
@CampaignID int

AS

SELECT 
	--Stamoplysninger
        MIN(dbo.ActivityDeliveries.DeliveryDate) AS DeliveryDate,
        dbo.Activities.PriceTag,
	-- dbo.Activities.PK_ActivityID, dbo.Campaigns.PK_CampaignID, 
	--dbo.ActivityLines.FK_SalesUnitID, 
        dbo.Campaigns.FK_WholesellerID,
        dbo.Campaigns.FK_ChainID,
        dbo.Activities.PK_ActivityID,
	
	--Rapportoplysninger
        dbo.Products.ProductCode,
        FK_SalesUnitID,
        dbo.Products.Label AS ProductName,
        CASE WHEN ISNULL(RTRIM(E1.EANCode), '') = '' THEN '-'
             ELSE E1.EANCode
        END AS EAN,
        CASE WHEN ISNULL(RTRIM(E2.EANCode), '') = '' THEN '-'
             ELSE E2.EANCode
        END AS ITF,
        E2.Pieces / dbo.Products.PiecesPerConsumerUnit AS Pieces,
        ( SELECT    [Value]
          FROM      Prices
          WHERE     FK_PriceTypeID = 1
                    AND FK_ProductID = FK_SalesUnitID
                    AND PeriodTo >= dbo.Activities.PriceTag
                    AND PeriodFrom <= dbo.Activities.PriceTag
        )
        / ( SELECT  Pieces / PiecesPerConsumerUnit
            FROM    EANCodes
                    INNER JOIN dbo.Products ON dbo.EANCodes.ProductID = dbo.Products.PK_ProductID
            WHERE   ProductID = dbo.ActivityLines.FK_SalesUnitID
                    AND FK_EANTypeID = 2
          ) AS GSV,
        ISNULL(( SELECT SUM([Value])
                 FROM   Prices
					INNER JOIN dbo.PriceTypes as pt ON PK_PriceTypeID = FK_PriceTypeID
                 WHERE  IsTax = 1
                        AND FK_ProductID = FK_SalesUnitID
                        AND PeriodTo > dbo.Activities.PriceTag
                        AND PeriodFrom <= dbo.Activities.PriceTag
               )
               / ( SELECT   Pieces / PiecesPerConsumerUnit
                   FROM     EANCodes
                            INNER JOIN dbo.Products ON PK_ProductID = ProductID
                   WHERE    ProductID = dbo.ActivityLines.FK_SalesUnitID
                            AND FK_EANTypeID = 2
                 ), 0) AS AFG,
        dbo.vwSortHierarchy.Node,
        dbo.rdh_fn_NetPrice(dbo.ActivityLines.FK_SalesUnitID, FK_ChainID,
                            dbo.Activities.PriceTag) AS NSV,
        CASE WHEN ( SELECT  WholesellerProductNo
                    FROM    Listings
                    WHERE   FK_ProductID = Fk_SalesUnitID
                            AND FK_ParticipatorID = FK_ChainId
                  ) = '-1' THEN ''
             ELSE ( SELECT  WholesellerProductNo
                    FROM    Listings
                    WHERE   FK_ProductID = Fk_SalesUnitID
                            AND FK_ParticipatorID = FK_ChainId
                  )
        END AS WholesellerNo,
        ISNULL(( SELECT ISNULL([value], 0)
                 FROM   vwCampaignDiscount
                 WHERE  FK_SalesUnitID = dbo.ActivityLines.FK_SalesUnitID
                        AND FK_ActivityID = dbo.Activities.PK_ActivityID
                        AND FK_ValueTypeID = 1
                        AND OnInvoice = 1
               ), 0) AS TPR_PCT,
        ISNULL(( SELECT ISNULL([value], 0)
                 FROM   vwCampaignDiscount
                 WHERE  FK_SalesUnitID = dbo.ActivityLines.FK_SalesUnitID
                        AND FK_ActivityID = dbo.Activities.PK_ActivityID
                        AND FK_ValueTypeID = 2
                        AND OnInvoice = 1
               ), 0) AS TPR_KR,
        ISNULL(( SELECT ISNULL([value], 0)
                 FROM   vwCampaignDiscount
                 WHERE  FK_SalesUnitID = dbo.ActivityLines.FK_SalesUnitID
                        AND FK_ActivityID = dbo.Activities.PK_ActivityID
                        AND FK_ValueTypeID = 1
                        AND OnInvoice = 0
               ), 0) AS OFF_PCT,
        ISNULL(( SELECT ISNULL([value], 0)
                 FROM   vwCampaignDiscount
                 WHERE  FK_SalesUnitID = dbo.ActivityLines.FK_SalesUnitID
                        AND FK_ActivityID = dbo.Activities.PK_ActivityID
                        AND FK_ValueTypeID = 2
                        AND OnInvoice = 0
               ), 0) AS OFF_KR,
        dbo.rdh_fn_OFT(dbo.ActivityLines.FK_SalesUnitID, FK_ChainID,
                       dbo.Activities.PriceTag, 1) AS OFT,
        dbo.rdh_fn_OFT(dbo.ActivityLines.FK_SalesUnitID, FK_ChainID,
                       dbo.Activities.PriceTag, 2) AS OFT_AMT,
        CASE WHEN ActivityLines.EstimatedSalesPricePieces = 0
             THEN CASE WHEN ISNULL(ActivityLines.EstimatedSalesPrice, 0) = 0
                       THEN ''
                       ELSE '1 for '
                            + REPLACE(CAST(ActivityLines.EstimatedSalesPrice as nvarchar),
                                      '.', ',')
                  END
             ELSE CAST(ActivityLines.EstimatedSalesPricePieces as nvarchar)
                  + ' for '
                  + REPLACE(CAST(CAST(ActivityLines.EstimatedSalesPrice as decimal(6, 2)) as nvarchar),
                            '.', ',')
        END AS PricePoint,
        ISNULL(dbo.ListingTypes.ShortLabel, '') AS Sortiment,
        dbo.Products.ProductChange AS Change
FROM    dbo.Activities
        INNER JOIN dbo.ActivityLines ON dbo.Activities.PK_ActivityID = dbo.ActivityLines.FK_ActivityID
        INNER JOIN dbo.ActivityDeliveries ON dbo.Activities.PK_ActivityID = dbo.ActivityDeliveries.FK_ActivityID
        INNER JOIN dbo.Campaigns ON dbo.Activities.FK_CampaignID = dbo.Campaigns.PK_CampaignID
        INNER JOIN dbo.vwSortHierarchy ON dbo.ActivityLines.FK_SalesUnitID = dbo.vwSortHierarchy.FK_ProductID
        INNER JOIN dbo.Products ON dbo.ActivityLines.FK_SalesUnitID = dbo.Products.PK_ProductID
        INNER JOIN dbo.Listings ON dbo.Products.PK_ProductID = dbo.Listings.FK_ProductID
                                   AND dbo.Campaigns.FK_ChainID = dbo.Listings.FK_ParticipatorID
        INNER JOIN dbo.ListingTypes ON dbo.ListingTypes.PK_ListingTypeID = dbo.Listings.FK_ListingTypeID
        INNER JOIN EANCodes E1 ON E1.ProductID = dbo.Products.PK_ProductID
                                  AND E1.FK_EANTypeID = 1
        INNER JOIN EANCodes E2 ON E2.ProductID = dbo.Products.PK_ProductID
                                  AND E2.FK_EANTypeID = 2
WHERE   ( dbo.Campaigns.PK_CampaignID = @CampaignID )
GROUP BY dbo.Products.ProductCode,
        dbo.Products.Label,
        dbo.ActivityLines.FK_SalesUnitID,
        dbo.vwSortHierarchy.Node,
        dbo.Activities.PriceTag,
        dbo.Campaigns.FK_WholesellerID,
        dbo.Campaigns.FK_ChainID,
        dbo.Activities.PK_ActivityID,/*dbo.ActivityDeliveries.DeliveryDate,*/
        ActivityLines.EstimatedSalesPricePieces,
        ActivityLines.EstimatedSalesPrice,
        ListingTypes.ShortLabel,
        dbo.Products.ProductChange,
        E1.EANCode,
        E2.EANCode,
        E2.Pieces / dbo.Products.PiecesPerConsumerUnit
ORDER BY dbo.vwSortHierarchy.Node,
        E2.Pieces / dbo.Products.PiecesPerConsumerUnit,
        dbo.Products.Label
