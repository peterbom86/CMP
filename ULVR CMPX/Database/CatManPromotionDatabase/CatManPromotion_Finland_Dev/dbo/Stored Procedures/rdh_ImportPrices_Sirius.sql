CREATE PROC [dbo].[rdh_ImportPrices_Sirius]
AS


/*BEREGNER Z501 PRISER. PRISER PÅ MIX VARER BEREGNES UDFRA KOMPONENTER. OVERSKRIVES HVIS DER ER PRIS PÅ SELVE MIXVAREN. BØR DOG LIGGE PÅ KOMPONENT NIVEAU */ 
    CREATE TABLE #tempPriceTable
        (
          PK_TempID INT IDENTITY(1, 1)
                        PRIMARY KEY ,
          FK_PriceTypeID INT ,
          FK_ProductID INT ,
          Value FLOAT ,
          PeriodFrom DATETIME ,
          PeriodTo DATETIME ,
          FK_FileImportID INT
        );


    WITH    BasePeriodFrom
              AS ( SELECT   PK_ProductID ,
                            CommonCode ,
                            ccp.PeriodFrom
                   FROM     dbo.Products AS p
                            INNER JOIN dbo.CommonCodes AS cc ON p.PK_ProductID = cc.FK_ProductID
                            INNER JOIN dbo.CommonCodePeriod AS ccp ON cc.PK_CommonCodeID = ccp.FK_CommonCodeID
                   WHERE    IsMixedGoods = 0
                 ),
            BasePeriodFromWithRowNumber
              AS ( SELECT   ROW_NUMBER() OVER ( ORDER BY PK_ProductID, PeriodFrom ) RowID ,
                            PK_ProductID ,
                            CommonCode ,
                            PeriodFrom
                   FROM     BasePeriodFrom
                 ),
            BasePeriods
              AS ( SELECT   Sub1.PK_ProductID ,
                            Sub1.CommonCode ,
                            Sub1.PeriodFrom ,
                            ISNULL(Sub2.PeriodFrom - 1, '2099-12-31') PeriodTo
                   FROM     BasePeriodFromWithRowNumber Sub1
                            LEFT JOIN BasePeriodFromWithRowNumber Sub2 ON Sub1.PK_ProductID = Sub2.PK_ProductID
                                                              AND Sub1.RowID
                                                              + 1 = Sub2.RowID
                 ),
            BasePrices
              AS ( SELECT   PK_ProductID ,
                            CommonCode ,
                            bp.PeriodFrom CCPeriodFrom ,
                            bp.PeriodTo CCPeriodTo ,
                            scttl.PeriodFrom PricePeriodFrom ,
                            scttl.PeriodTo PricePeriodTo ,
                            Value ,
                            FK_FileImportID ,
                            QTYType
                   FROM     BasePeriods bp
                            INNER JOIN dbo.SAP_ConditionTypes_TotalList AS scttl ON REPLICATE('0',
                                                              18
                                                              - LEN(CommonCode))
                                                              + CommonCode = Material
                                                              AND ConditionType = 'Z501'
                                                              AND SUBSTRING(Hierarchy,
                                                              14, 2) = 'FI'
                                                              AND SUBSTRING(HIERARCHY,
                                                              5, 2) = '50'
                                                              AND scttl.PeriodFrom <= bp.PeriodTo
                                                              AND scttl.PeriodTo >= bp.PeriodFrom
                 ),
            BasePricePeriods
              AS ( SELECT   PK_ProductID ,
                            CommonCode ,
                            CCPeriodFrom PeriodFrom ,
                            CCPeriodTo ,
                            Value ,
                            FK_FileImportID ,
                            QTYType
                   FROM     BasePrices bp
                   WHERE    PricePeriodFrom <= CCPeriodFrom
                   UNION
                   SELECT   PK_ProductID ,
                            CommonCode ,
                            PricePeriodFrom PeriodFrom ,
                            CCPeriodTo ,
                            Value ,
                            FK_FileImportID ,
                            QTYType
                   FROM     BasePrices bp
                   WHERE    PricePeriodFrom BETWEEN CCPeriodFrom
                                            AND     CCPeriodTo
                 ),
            BasePricePeriodsWithRowNumber
              AS ( SELECT   ROW_NUMBER() OVER ( ORDER BY PK_ProductID, PeriodFrom ) RowID ,
                            PK_ProductID ,
                            CommonCode ,
                            PeriodFrom ,
                            CCPeriodTo ,
                            Value ,
                            FK_FileImportID ,
                            QTYType
                   FROM     BasePricePeriods bpp
                 ),
            FinalPrices
              AS ( SELECT   Sub1.PK_ProductID ,
                            Sub1.CommonCode ,
                            Sub1.PeriodFrom ,
                            CASE WHEN Sub2.PeriodFrom IS NULL
                                 THEN Sub1.CCPeriodTo
                                 ELSE Sub2.PeriodFrom - 1
                            END PeriodTo ,
                            Sub1.Value ,
                            Sub1.FK_FileImportID ,
                            Sub1.QTYType
                   FROM     BasePricePeriodsWithRowNumber Sub1
                            LEFT JOIN BasePricePeriodsWithRowNumber Sub2 ON Sub1.PK_ProductID = Sub2.PK_ProductID
                                                              AND Sub1.RowID
                                                              + 1 = Sub2.RowID
                 )
        INSERT  INTO #tempPriceTable
                ( FK_PriceTypeID ,
                  FK_ProductID ,
                  Value ,
                  PeriodFrom ,
                  PeriodTo ,
                  FK_FileImportID 
                )
                SELECT  1 ,
                        PK_ProductID ,
                        CASE WHEN EANQTY.Pieces = 0 THEN 1.0
                             ELSE CAST(EANCS.Pieces AS FLOAT)
                                  / CAST(EANQTY.Pieces AS FLOAT)
                        END * Value ,
                        CASE WHEN PeriodFrom < '2007-11-05' THEN '2007-11-05'
                             ELSE PeriodFrom
                        END PeriodFrom ,
                        PeriodTo ,
                        FK_FileImportID
                FROM    FinalPrices
                        INNER JOIN EANCodes EANCS ON PK_ProductID = EANCS.ProductID
                                                     AND EANCS.FK_EANTypeID = 2
                        INNER JOIN EANCodes EANQTY ON PK_ProductID = EANQTY.ProductID
                                                      AND EANQTY.FK_EANTypeID = CASE QTYTYPE
                                                              WHEN 'CS' THEN 2
                                                              WHEN 'ZUN'
                                                              THEN 5
                                                              END
                WHERE   PeriodTo >= '2007-11-05'

/*INSERT INTO #tempPriceTable ( FK_PriceTypeID, FK_ProductID, Value, PeriodFrom, PeriodTo, FK_FileImportID )
SELECT 1, PK_ProductID, CASE WHEN EANQTY.Pieces = 0 THEN 1.0 ELSE CAST( EANCS.Pieces AS float) / CAST( EANQTY.Pieces AS float) END * Value, 
  CASE WHEN CTL.PeriodFrom < '2007-11-05' THEN '2007-11-05' ELSE CTL.PeriodFrom END, CTL.PeriodTo, FK_FileImportID
FROM SAP_ConditionTypes_TotalList CTL
  INNER JOIN CommonCodes CC ON CAST(CAST(Material as int) as varchar) = Commoncode AND Active = 1
  INNER JOIN Products P ON PK_ProductID = FK_ProductID
  INNER JOIN EANCodes EANCS ON PK_ProductID = EANCS.ProductID AND EANCS.FK_EANTypeID = 2
  INNER JOIN EANCodes EANQTY ON PK_ProductID = EANQTY.ProductID AND EANQTY.FK_EANTypeID = CASE QTYTYPE WHEN 'CS' THEN 2 WHEN 'ZUN' THEN 5 END
WHERE ConditionType = 'Z501' AND SUBSTRING(Hierarchy, 14, 2) = 'DK' AND SUBSTRING(HIERARCHY,5,2) = '50' AND IsMixedGoods = 0 AND CTL.PeriodTo >= '2007-11-05'
*/

    INSERT  INTO #tempPriceTable
            ( FK_PriceTypeID ,
              FK_ProductID ,
              Value ,
              PeriodFrom ,
              PeriodTo 
            )
            SELECT  1 ,
                    Header.PK_ProductID ,
                    NULL ,
                    TPT.PeriodFrom ,
                    NULL
            FROM    Products Header
                    INNER JOIN BillOfMaterials ON Header.PK_ProductID = FK_HeaderProductID
                    INNER JOIN BillOfMaterialLines ON PK_BillOfMaterialID = FK_BillOfMaterialID
                    INNER JOIN Products Comp ON Comp.PK_ProductID = FK_ComponentProductID
                    INNER JOIN #tempPriceTable TPT ON Comp.PK_ProductID = TPT.FK_ProductID
            WHERE   Header.IsMixedGoods = 1
            UNION
            SELECT  1 ,
                    Header.PK_ProductID ,
                    NULL ,
                    TPT.PeriodTo + 1 ,
                    NULL
            FROM    Products Header
                    INNER JOIN BillOfMaterials ON Header.PK_ProductID = FK_HeaderProductID
                    INNER JOIN BillOfMaterialLines ON PK_BillOfMaterialID = FK_BillOfMaterialID
                    INNER JOIN Products Comp ON Comp.PK_ProductID = FK_ComponentProductID
                    INNER JOIN #tempPriceTable TPT ON Comp.PK_ProductID = TPT.FK_ProductID
            WHERE   Header.IsMixedGoods = 1
                    AND TPT.PeriodTo + 1 < '2100-01-01'
            ORDER BY 2 ,
                    4

    UPDATE  TPT1
    SET     PeriodTo = ISNULL(TPT2.PeriodFrom - 1, '2099-12-31')
    FROM    #tempPriceTable TPT1
            LEFT JOIN #tempPriceTable TPT2 ON TPT1.FK_ProductID = TPT2.FK_ProductID
                                              AND TPT1.PK_TempID = TPT2.PK_TempID
                                              - 1
    WHERE   TPT1.Value IS NULL

    UPDATE  TPT
    SET     Value = SubPrices.Value
    FROM    #tempPriceTable TPT
            INNER JOIN ( SELECT TPT.PK_TempID ,
                                SUM(ISNULL(TPTComp.Value / EAN.Pieces, 0)
                                    * BOML.Pieces-- * Header.PiecesPerConsumerUnit
    ) Value
                         FROM   #tempPriceTable TPT
                                INNER JOIN Products Header ON TPT.FK_ProductID = Header.PK_ProductID
                                INNER JOIN BillOfMaterials ON Header.PK_ProductID = FK_HeaderProductID
                                INNER JOIN BillOfMaterialLines BOML ON PK_BillOfMaterialID = FK_BillOfMaterialID
                                INNER JOIN Products Comp ON Comp.PK_ProductID = FK_ComponentProductID
                                INNER JOIN EANCodes EAN ON Comp.PK_ProductID = ProductID
                                                           AND FK_EANTypeID = 2
                                LEFT JOIN #tempPriceTable TPTComp ON Comp.PK_ProductID = TPTComp.FK_ProductID
                                                              AND TPT.PeriodFrom >= TPTComp.PeriodFrom
                                                              AND TPT.PeriodFrom <= TPTComp.PeriodTo
                         WHERE  TPT.Value IS NULL
                         GROUP BY TPT.PK_TempID
                       ) SubPrices ON TPT.PK_TempID = SubPrices.PK_TempID

    CREATE TABLE #tempPriceTable_MixedGoods
        (
          PK_TempID INT IDENTITY(1, 1)
                        PRIMARY KEY ,
          FK_PriceTypeID INT ,
          FK_ProductID INT ,
          Value FLOAT ,
          PeriodFrom DATETIME ,
          PeriodTo DATETIME
        )

    INSERT  INTO #tempPriceTable_MixedGoods
            ( FK_PriceTypeID ,
              FK_ProductID ,
              Value ,
              PeriodFrom ,
              PeriodTo 
            )
            SELECT  1 ,
                    PK_ProductID ,
                    CASE WHEN EANQTY.Pieces = 0 THEN 1.0
                         ELSE CAST(EANCS.Pieces AS FLOAT)
                              / CAST(EANQTY.Pieces AS FLOAT)
                    END * Value ,
                    CASE WHEN CTL.PeriodFrom < '2007-11-05' THEN '2007-11-05'
                         ELSE CTL.PeriodFrom
                    END ,
                    CTL.PeriodTo
            FROM    SAP_ConditionTypes_TotalList CTL
                    INNER JOIN CommonCodes CC ON CAST(CAST(Material AS INT) AS VARCHAR) = Commoncode
                                                 AND Active = 1
                    INNER JOIN Products P ON PK_ProductID = FK_ProductID
                    INNER JOIN EANCodes EANCS ON PK_ProductID = EANCS.ProductID
                                                 AND EANCS.FK_EANTypeID = 2
                    INNER JOIN EANCodes EANQTY ON PK_ProductID = EANQTY.ProductID
                                                  AND EANQTY.FK_EANTypeID = CASE QTYTYPE
                                                              WHEN 'CS' THEN 2
                                                              WHEN 'ZUN'
                                                              THEN 5
                                                              END
            WHERE   ConditionType = 'Z501'
                    AND SUBSTRING(Hierarchy, 14, 2) = 'FI'
                    AND SUBSTRING(HIERARCHY, 5, 2) = '50'
                    AND IsMixedGoods = 1
                    AND CTL.PeriodTo >= '2007-11-05'

    DELETE  FROM TPT
    FROM    #tempPriceTable TPT
            INNER JOIN #tempPriceTable_MixedGoods TPTM ON TPT.FK_PriceTypeID = TPTM.FK_PriceTypeID
                                                          AND TPT.FK_ProductID = TPTM.FK_ProductID
    WHERE   TPT.PeriodFrom >= TPTM.PeriodFrom
            AND TPT.PeriodTo <= TPTM.PeriodTo

    INSERT  INTO #tempPriceTable
            ( FK_PriceTypeID ,
              FK_ProductID ,
              Value ,
              PeriodFrom ,
              PeriodTo ,
              FK_FileImportID 
            )
            SELECT  TPT.FK_PriceTypeID ,
                    TPT.FK_ProductID ,
                    TPT.Value ,
                    TPTM.PeriodTo + 1 ,
                    TPT.PeriodTo ,
                    TPT.FK_FileImportID
            FROM    #tempPriceTable TPT
                    INNER JOIN #tempPriceTable_MixedGoods TPTM ON TPT.FK_PriceTypeID = TPTM.FK_PriceTypeID
                                                              AND TPT.FK_ProductID = TPTM.FK_ProductID
            WHERE   TPT.PeriodFrom < TPTM.PeriodFrom
                    AND TPT.PeriodTo > TPTM.PeriodTo
  
    UPDATE  TPT
    SET     PeriodTo = TPTM.PeriodFrom - 1
    FROM    #tempPriceTable TPT
            INNER JOIN #tempPriceTable_MixedGoods TPTM ON TPT.FK_PriceTypeID = TPTM.FK_PriceTypeID
                                                          AND TPT.FK_ProductID = TPTM.FK_ProductID
    WHERE   TPT.PeriodFrom < TPTM.PeriodFrom
            AND TPT.PeriodTo >= TPTM.PeriodFrom
  
    UPDATE  TPT
    SET     PeriodFrom = TPTM.PeriodTo + 1
    FROM    #tempPriceTable TPT
            INNER JOIN #tempPriceTable_MixedGoods TPTM ON TPT.FK_PriceTypeID = TPTM.FK_PriceTypeID
                                                          AND TPT.FK_ProductID = TPTM.FK_ProductID
    WHERE   TPT.PeriodFrom >= TPTM.PeriodFrom
            AND TPT.PeriodFrom <= TPTM.PeriodTo

    INSERT  INTO #tempPriceTable
            ( FK_PriceTypeID ,
              FK_ProductID ,
              Value ,
              PeriodFrom ,
              PeriodTo 
            )
            SELECT  FK_PriceTypeID ,
                    FK_ProductID ,
                    Value ,
                    PeriodFrom ,
                    PeriodTo
            FROM    #tempPriceTable_MixedGoods TPTM

    DROP TABLE #tempPriceTable_MixedGoods


/* DER FYLDES 0 PRISER I FOR PRODUKTER HVOR DER IKKER ER MODTAGET PRIS, DA ALLE PRODUKTER SKAL HAVE EN PRIS*/
    INSERT  INTO #tempPriceTable
            SELECT  1 ,
                    PK_ProductID ,
                    0 ,
                    '2007-11-05' ,
                    '2099-12-31' ,
                    NULL
            FROM    Products
            WHERE   PK_ProductID NOT IN ( SELECT    FK_ProductID
                                          FROM      #tempPriceTable )
  /* Z514 ER EN GENEREL PRISREDUKTION UANSET HVILKEN KUNDENODE DEN LIGGES PÅ. BØR DERFOR KUN LIGGE PÅ TOTAL CUSTOMER NODEN. ULVR BØR HVIS DET ER PÅ KUNDENIVEAU BRUGE Z500 ISTEDET !!!*/
    SELECT  PK_ProductID ,
            bde.PeriodFrom PeriodChange
    INTO    #tempProductsWithZ514
    FROM    dbo.BaseDiscountsEdit AS bde
            INNER JOIN dbo.BaseDiscountTypes AS bdt ON bde.FK_BaseDiscountTypeID = bdt.PK_BaseDiscountTypeID
            INNER JOIN dbo.Products AS p ON PK_ProductID = FK_ProductID
    WHERE   PK_BaseDiscountTypeID IN ( 41, 42 )
            AND bde.PeriodFrom <= bde.PeriodTo
    UNION
    SELECT  PK_ProductID ,
            bde.PeriodTo + 1 PeriodChange
    FROM    dbo.BaseDiscountsEdit AS bde
            INNER JOIN dbo.BaseDiscountTypes AS bdt ON bde.FK_BaseDiscountTypeID = bdt.PK_BaseDiscountTypeID
            INNER JOIN dbo.Products AS p ON PK_ProductID = FK_ProductID
    WHERE   PK_BaseDiscountTypeID IN ( 41, 42 )
            AND bde.PeriodFrom <= bde.PeriodTo
            AND bde.PeriodTo < '2099-12-31'
    UNION
    SELECT  FK_ProductID ,
            PeriodFrom PeriodChange
    FROM    #tempPriceTable tpt
    WHERE   FK_ProductID IN ( SELECT DISTINCT
                                        FK_ProductID
                              FROM      dbo.BaseDiscountsEdit AS bde
                              WHERE     FK_BaseDiscountTypeID IN ( 41, 42 )
                                        AND FK_ProductID IS NOT NULL )
            AND FK_PriceTypeID = 1
    UNION
    SELECT  FK_ProductID ,
            PeriodTo + 1 PeriodChange
    FROM    #tempPriceTable tpt
    WHERE   FK_ProductID IN ( SELECT DISTINCT
                                        FK_ProductID
                              FROM      dbo.BaseDiscountsEdit AS bde
                              WHERE     FK_BaseDiscountTypeID IN ( 41, 42 )
                                        AND FK_ProductID IS NOT NULL )
            AND PeriodTo < '2099-12-31'
            AND FK_PriceTypeID = 1

    SELECT  FK_PriceTypeID ,
            Sub1.PK_ProductID ,
            ( Sub3.Value - ISNULL(Sub4.Value, 0) ) * ( ISNULL(1 - Sub5.Value, 1) ) Value ,
            Sub1.PeriodChange PeriodFrom ,
            ISNULL(Sub2.PeriodChange - 1, '2099-12-31') PeriodTo ,
            FK_FileImportID
    INTO    #tempProductsWithZ514_2
    FROM    ( SELECT    PK_ProductID ,
                        PeriodChange ,
                        ROW_NUMBER() OVER ( ORDER BY PK_ProductID, PeriodChange ) RowNumber
              FROM      #tempProductsWithZ514 AS tpwz
            ) Sub1
            LEFT JOIN ( SELECT  PK_ProductID ,
                                PeriodChange ,
                                ROW_NUMBER() OVER ( ORDER BY PK_ProductID, PeriodChange ) RowNumber
                        FROM    #tempProductsWithZ514 AS tpwz
                      ) Sub2 ON Sub1.PK_ProductID = Sub2.PK_ProductID
                                AND Sub1.RowNumber = Sub2.RowNumber - 1
            INNER JOIN ( SELECT FK_PriceTypeID ,
                                FK_ProductID ,
                                Value ,
                                PeriodFrom ,
                                PeriodTo ,
                                FK_FileImportID
                         FROM   #tempPriceTable tpt
                         WHERE  FK_ProductID IN (
                                SELECT DISTINCT
                                        FK_ProductID
                                FROM    dbo.BaseDiscountsEdit AS bde
                                WHERE   FK_BaseDiscountTypeID IN ( 41, 42 )
                                        AND FK_ProductID IS NOT NULL )
                                AND FK_PriceTypeID = 1
                       ) Sub3 ON Sub1.PK_ProductID = FK_ProductID
                                 AND PeriodFrom <= Sub1.PeriodChange
                                 AND PeriodTo >= Sub1.PeriodChange
            LEFT JOIN ( SELECT DISTINCT
                                PK_ProductID ,
                                bde.PeriodFrom ,
                                bde.PeriodTo ,
                                Value
                        FROM    dbo.BaseDiscountsEdit AS bde
                                INNER JOIN dbo.BaseDiscountTypes AS bdt ON bde.FK_BaseDiscountTypeID = bdt.PK_BaseDiscountTypeID
                                INNER JOIN dbo.Products AS p ON PK_ProductID = FK_ProductID
                        WHERE   PK_BaseDiscountTypeID = 42
                                AND bde.PeriodFrom <= bde.PeriodTo
                      ) Sub4 ON Sub1.PK_ProductID = Sub4.PK_ProductID
                                AND Sub1.PeriodChange >= Sub4.PeriodFrom
                                AND Sub1.PeriodChange <= Sub4.PeriodTo
            LEFT JOIN ( SELECT DISTINCT
                                PK_ProductID ,
                                bde.PeriodFrom ,
                                bde.PeriodTo ,
                                Value
                        FROM    dbo.BaseDiscountsEdit AS bde
                                INNER JOIN dbo.BaseDiscountTypes AS bdt ON bde.FK_BaseDiscountTypeID = bdt.PK_BaseDiscountTypeID
                                INNER JOIN dbo.Products AS p ON PK_ProductID = FK_ProductID
                        WHERE   PK_BaseDiscountTypeID = 41
                                AND bde.PeriodFrom <= bde.PeriodTo
                      ) Sub5 ON Sub1.PK_ProductID = Sub5.PK_ProductID
                                AND Sub1.PeriodChange >= Sub5.PeriodFrom
                                AND Sub1.PeriodChange <= Sub5.PeriodTo
    ORDER BY 2 ,
            4 ,
            5

    DELETE  FROM tpt
    FROM    #tempPriceTable tpt
    WHERE   FK_ProductID IN ( SELECT    PK_ProductID
                              FROM      #tempProductsWithZ514_2 AS tpwz )

    INSERT  INTO #tempPriceTable
            ( FK_PriceTypeID ,
              FK_ProductID ,
              Value ,
              PeriodFrom ,
              PeriodTo ,
              FK_FileImportID
            )
            SELECT  FK_PriceTypeID ,
                    PK_ProductID ,
                    Value ,
                    PeriodFrom ,
                    PeriodTo ,
                    FK_FileImportID
            FROM    #tempProductsWithZ514_2

    DROP TABLE #tempProductsWithZ514
    DROP TABLE #tempProductsWithZ514_2

    DELETE  FROM Prices
    WHERE   PeriodFrom >= '2007-11-05'
            AND FK_PriceTypeID = 1

    UPDATE  Pr
    SET     PeriodTo = '2007-11-04'
    FROM    Prices Pr
    WHERE   PeriodTo >= '2007-11-05'
            AND FK_PriceTypeID = 1

    INSERT  INTO Prices
            ( FK_PriceTypeID ,
              FK_ProductID ,
              Value ,
              PeriodFrom ,
              PeriodTo 
            )
            SELECT  FK_PriceTypeID ,
                    FK_ProductID ,
                    Value ,
                    PeriodFrom ,
                    PeriodTo
            FROM    #tempPriceTable

    DROP TABLE #tempPriceTable
