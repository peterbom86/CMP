CREATE PROC [dbo].[rdh_ImportMaterials_Sirius]
AS 
    DECLARE @logTime DATETIME

----------------------------------------------------------------------
--                     Update Active Common Code                    --
----------------------------------------------------------------------
    PRINT 'Update Active Common Code'
    UPDATE  CC
    SET     Active = CASE WHEN ISNULL(PK_CommonCodePeriodID, -1) = -1 THEN 0
                          ELSE 1
                     END
    FROM    CommonCodes CC
            LEFT JOIN CommonCodePeriod CCP ON PK_CommonCodeID = FK_CommonCodeID
                                              AND CCP.PeriodFrom <= CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME)
                                              AND CCP.PeriodTo >= CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME)
    WHERE   CASE WHEN ISNULL(PK_CommonCodePeriodID, -1) = -1 THEN 0
                 ELSE 1
            END <> ISNULL(Active, 2)

----------------------------------------------------------------------
--                     Insert new languagecodes                     --
----------------------------------------------------------------------
    PRINT 'Insert new languagecodes'
    CREATE TABLE #tempLanguageCodes
        (
          ID INT IDENTITY(1, 1)
                 PRIMARY KEY ,
          LanguageCode NVARCHAR(50)
        )

    INSERT  INTO #tempLanguageCodes
            ( LanguageCode 
            )
            SELECT DISTINCT
                    LanguageCode
            FROM    SAP_ProductNames_TotalList AS spntl
            WHERE   LanguageCode NOT IN ( SELECT    LanguageCode
                                          FROM      SAP_LanguageCodes )

    INSERT  INTO SAP_LanguageCodes
            ( LanguageCode ,
              SortOrder 
            )
            SELECT  LanguageCode ,
                    ID + ( SELECT   MAX(SortOrder)
                           FROM     SAP_LanguageCodes
                         )
            FROM    #tempLanguageCodes

    DROP TABLE #tempLanguageCodes

----------------------------------------------------------------------
--        Update ProductName - All product from 09/01-2008          --  [Earlier: if productstatus is undefined ]
----------------------------------------------------------------------
    PRINT 'Update ProductName if productstatus is undefined'

    UPDATE  P
    SET     Label = ProductName
    FROM    SAP_ProductNames_TotalList AS spntl
            INNER JOIN ( SELECT Material ,
                                MIN(SortOrder) MinSortOrder
                         FROM   SAP_ProductNames_TotalList AS spntl
                                INNER JOIN SAP_LanguageCodes AS slc ON spntl.LanguageCode = slc.LanguageCode
                         GROUP BY Material
                       ) CL ON spntl.Material = CL.Material
            INNER JOIN SAP_LanguageCodes LC ON CL.MinSortOrder = LC.SortOrder
                                               AND spntl.LanguageCode = lc.LanguageCode
            INNER JOIN CommonCodes CC ON CAST(CAST(spntl.Material AS BIGINT) AS VARCHAR) = CommonCode
                                         AND Active = 1
            INNER JOIN Products P ON PK_ProductID = FK_ProductID
    WHERE   Label <> ProductName -- AND FK_ProductStatusID = 0

----------------------------------------------------------------------
--                Update other Product information                  --
----------------------------------------------------------------------
    PRINT 'Update other Product information'

    UPDATE  P
    SET     Volume = smtl.Volume ,
            Weight = smtl.Weight ,
            ItemCategory = smtl.ItemCategory
    FROM    SAP_MATINFO_TotalList AS smtl
            INNER JOIN CommonCodes CC ON CAST(CAST(Material AS BIGINT) AS VARCHAR) = CommonCode
                                         AND Active = 1
            INNER JOIN Products P ON PK_ProductID = FK_ProductID
    WHERE   ( P.Volume <> smtl.Volume
              OR P.Weight <> smtl.Weight
              OR P.ItemCategory <> smtl.ItemCategory
            )

----------------------------------------------------------------------
--                Insert New SAP Products Status                    --
----------------------------------------------------------------------
    PRINT 'Insert New SAP Products Status'

    INSERT  INTO SAP_ProductStatusLink
            ( STATUS ,
              FK_ProductStatusID 
            )
            SELECT DISTINCT
                    STATUS ,
                    0
            FROM    SAP_MATINFO_TotalList AS smtl
            WHERE   STATUS NOT IN ( SELECT  STATUS
                                    FROM    SAP_ProductStatusLink )

----------------------------------------------------------------------
--                    Update Products Status                        --
----------------------------------------------------------------------
    PRINT 'Update Products Status'

    UPDATE  P
    SET     FK_ProductStatusID = PSL.FK_ProductStatusID
    FROM    SAP_MATINFO_TotalList AS smtl
            INNER JOIN SAP_ProductStatusLink PSL ON smtl.Status = PSL.STATUS
            INNER JOIN CommonCodes CC ON CAST(CAST(Material AS BIGINT) AS VARCHAR) = CommonCode
                                         AND Active = 1
            INNER JOIN Products P ON PK_ProductID = FK_ProductID
			INNER JOIN dbo.ProductStatus PS ON PS.PK_ProductStatusID = P.FK_ProductStatusID
    WHERE   
			(PS.OverrideFromSap = 1 AND P.FK_ProductStatusID <> PSL.FK_ProductStatusID)/*ACTIVATATED PRODUCTS CHANGING STATUS*/
			OR (P.FK_ProductStatusID = 0 AND PSL.FK_ProductStatusID = 6) /*NOT ACTIVATED PRODUCT BECOMING DELISTED*/
----------------------------------------------------------------------
--                     Update IsMixedGoods                          --
----------------------------------------------------------------------
    PRINT 'Update IsMixedGoods'

    UPDATE  P
    SET     IsMixedGoods = CASE ItemCategory
                             WHEN 'Z5BM' THEN 1
                             WHEN 'ZNOR' THEN 0
                             WHEN 'ZPRO' THEN 0
                           END
    FROM    Products P
    WHERE   ItemCategory IN ( 'Z5BM', 'ZNOR', 'ZPRO' )
            AND CASE ItemCategory
                  WHEN 'Z5BM' THEN 1
                  WHEN 'ZNOR' THEN 0
                  WHEN 'ZPRO' THEN 0
                END <> IsMixedGoods 

----------------------------------------------------------------------
--       Only import the latest file of a given BOM            --
----------------------------------------------------------------------
-- ##Not needed anymore - load is done from TotalList
--PRINT 'Only import the latest file of a given BOM'
--UPDATE OuterBOM
--SET IsHandled = 1,
--  HandledDate = GETDATE()
--FROM SAP_BOM OuterBOM
--WHERE IsHandled = 0 AND 
--  EXISTS (
--  SELECT *
--  FROM SAP_BOM InnerBOM
--  WHERE InnerBOM.IsHandled = 0 AND InnerBOM.Type = 'O'
--  GROUP BY InnerBOM.MATERIAL_HEADER
--  HAVING OuterBOM.MATERIAL_HEADER = InnerBOM.MATERIAL_HEADER AND OuterBOM.PK_BOMID < MAX(InnerBOM.PK_BOMID))

----------------------------------------------------------------------
--            Check BOM File for correct decimalseperator           --
----------------------------------------------------------------------
--Not needed anymore
--PRINT 'Check BOM File for correct decimalseperator '
--INSERT INTO SAP_Errors (FK_FileImportID, Caller, Segment, Description, SystemError )
--SELECT DISTINCT PK_FileImportID, 'import_CreateProducts', 'ZUN', 'Incorrect numberformat', 'Incorrect numberformat'
--FROM SAP_FileImport FI 
--  INNER JOIN SAP_BOM BOM ON PK_FileImportID = BOM.FK_FileImportID
--WHERE FI.IsHandled = 0 AND LEFT(RIGHT(ZUN, 4), 1) = ','

--UPDATE FI
--SET IsHandled = 1,
--  HandledDate = GETDATE()
--FROM SAP_FileImport FI 
--  INNER JOIN SAP_BOM BOM ON PK_FileImportID = BOM.FK_FileImportID
--WHERE FI.IsHandled = 0 AND LEFT(RIGHT(ZUN, 4), 1) = ','

----------------------------------------------------------------------
--                    Report ZNOR With Sales BOM                    --
----------------------------------------------------------------------
    PRINT 'Report ZNOR With Sales BOM'
    SET @logTime = GETDATE()

    INSERT  INTO SAP_ImportLog
            ( FK_FileImportID ,
              Caller ,
              Description ,
              CreatedDate 
            )
            SELECT DISTINCT
                    NULL ,
                    'BOM ZNOR With Sales BOM' Caller ,
                    'A BOM is present on a ZNOR product, which migth be a master data error' Description ,
                    @logTime CreatedDate
            FROM    SAP_BOM_TotalList BOM
                    INNER JOIN CommonCodes CCHeader ON CAST(CAST(MATERIAL_HEADER AS INT) AS VARCHAR) = CCHeader.CommonCode
                                                       AND CCHeader.Active = 1
                    INNER JOIN Products PHeader ON PHeader.PK_ProductID = CCHeader.FK_ProductID
                    INNER JOIN CommonCodes CCComp ON CAST(CAST(MATERIAL_COMPONENT AS INT) AS VARCHAR) = CCComp.CommonCode
                    INNER JOIN Products PComp ON PComp.PK_ProductID = CCComp.FK_ProductID
            WHERE   --IsHandled = 0 AND 
                    Type <> 'O'
                    AND PHeader.IsMixedGoods = 0

    INSERT  INTO SAP_ImportLogDetails
            ( FK_ImportLogID ,
              RefTable ,
              RefField ,
              RefValue 
            )
            SELECT DISTINCT
                    PK_ImportLogID ,
                    'Products' RefTable ,
                    'PK_ProductID' RefField ,
                    CAST(PHeader.PK_ProductID AS NVARCHAR) RefValue
            FROM    SAP_BOM_TotalList BOM
                    INNER JOIN CommonCodes CCHeader ON CAST(CAST(MATERIAL_HEADER AS INT) AS VARCHAR) = CCHeader.CommonCode
                                                       AND CCHeader.Active = 1
                    INNER JOIN Products PHeader ON PHeader.PK_ProductID = CCHeader.FK_ProductID
                    INNER JOIN CommonCodes CCComp ON CAST(CAST(MATERIAL_COMPONENT AS INT) AS VARCHAR) = CCComp.CommonCode
                    INNER JOIN Products PComp ON PComp.PK_ProductID = CCComp.FK_ProductID
                    INNER JOIN SAP_ImportLog IL ON Caller = 'BOM ZNOR With Sales BOM'
                                                   AND IL.CreatedDate = @logTime
            WHERE   --IsHandled = 0 AND 
                    Type <> 'O'
                    AND PHeader.IsMixedGoods = 0

----------------------------------------------------------------------
--                Report Z5BM Without Sales BOM                     --
----------------------------------------------------------------------
    PRINT 'Report Z5BM Without Sales BOM'
    SET @logTime = GETDATE()

    INSERT  INTO SAP_ImportLog
            ( FK_FileImportID ,
              Caller ,
              Description ,
              CreatedDate 
            )
            SELECT DISTINCT
                    NULL ,
                    'BOM Z5BM Without Sales BOM' Caller ,
                    'A no BOM is present on a Z5BM product' Description ,
                    @logTime CreatedDate
            FROM    Products PHeader
                    INNER JOIN CommonCodes CCHeader ON PHeader.PK_ProductID = CCHeader.FK_ProductID
                                                       AND CCHeader.Active = 1
                    LEFT JOIN SAP_BOM_TotalList BOM ON CAST(CAST(MATERIAL_HEADER AS INT) AS VARCHAR) = CCHeader.CommonCode --AND IsHandled = 0 
            WHERE   PHeader.IsMixedGoods = 1
                    AND FK_FileImportID IS NULL
                    AND FK_ProductStatusID = 2

    INSERT  INTO SAP_ImportLogDetails
            ( FK_ImportLogID ,
              RefTable ,
              RefField ,
              RefValue 
            )
            SELECT DISTINCT
                    PK_ImportLogID ,
                    'Products' RefTable ,
                    'PK_ProductID' RefField ,
                    CAST(PHeader.PK_ProductID AS NVARCHAR) RefValue
            FROM    Products PHeader
                    INNER JOIN CommonCodes CCHeader ON PHeader.PK_ProductID = CCHeader.FK_ProductID
                                                       AND CCHeader.Active = 1
                    LEFT JOIN SAP_BOM_TotalList BOM ON CAST(CAST(MATERIAL_HEADER AS INT) AS VARCHAR) = CCHeader.CommonCode --AND IsHandled = 0 
                    INNER JOIN SAP_ImportLog IL ON Caller = 'BOM Z5BM Without Sales BOM'
                                                   AND IL.CreatedDate = @logTime
            WHERE   PHeader.IsMixedGoods = 1
                    AND BOM.FK_FileImportID IS NULL
                    AND FK_ProductStatusID = 2

----------------------------------------------------------------------
--               Update Pieces Per ConsumerUnit                     --
----------------------------------------------------------------------
    PRINT 'Update Pieces Per ConsumerUnit'
    SELECT  Material ,
            Label ,
            ItemCategory ,
            AVG(CASE WHEN Unit = 'CS' THEN CAST(Pcs_Ren AS INT)
                     ELSE NULL
                END) CS ,
            MAX(CASE WHEN Unit = 'CS' THEN Ean
                     ELSE NULL
                END) CS_EAN ,
            AVG(CASE WHEN Unit = 'PAL' THEN CAST(Pcs_Ren AS INT)
                     ELSE NULL
                END) PAL ,
            MAX(CASE WHEN Unit = 'PAL' THEN Ean
                     ELSE NULL
                END) PAL_EAN ,
            AVG(CASE WHEN Unit = 'ZLA'
                     THEN CAST(Pcs_Ren AS INT) / CAST(Pcs_Rez AS INT)
                     ELSE NULL
                END) ZLA ,
            MAX(CASE WHEN Unit = 'ZLA' THEN Ean
                     ELSE NULL
                END) ZLA_EAN ,
            AVG(CASE WHEN Unit = 'ZCU' THEN CAST(Pcs_Rez AS INT)
                     ELSE NULL
                END) ZCU ,
            MAX(CASE WHEN Unit = 'ZCU' THEN Ean
                     ELSE NULL
                END) ZCU_EAN
    INTO    #UOMPerProduct
    FROM    dbo.SAP_UOM_TotalList AS sutl
            INNER JOIN dbo.CommonCodes AS cc ON CAST(Material AS BIGINT) = CommonCode
            INNER JOIN dbo.Products AS p ON cc.FK_ProductID = p.PK_ProductID
    GROUP BY Material ,
            Label ,
            ItemCategory

    SELECT  sbtl.MATERIAL_HEADER ,
            CAST(sbtl.ZUN AS MONEY) ZUN_HEADER ,
            sbtl2.MATERIAL_COMPONENT ,
            CAST(sbtl2.ZUN AS MONEY) ZUN_COMPONENT
    INTO    #BOM
    FROM    dbo.SAP_BOM_TotalList AS sbtl
            INNER JOIN dbo.SAP_BOM_TotalList AS sbtl2 ON sbtl.MATERIAL_HEADER = sbtl2.MATERIAL_HEADER
                                                         AND sbtl.TYPE = 'O'
                                                         AND sbtl2.TYPE = 'I'
    GROUP BY sbtl.MATERIAL_HEADER ,
            sbtl.ZUN ,
            sbtl2.MATERIAL_COMPONENT ,
            sbtl2.ZUN 

    SELECT  ProductCode ,
            CAST(CASE WHEN ISNULL(DIVISION, '') = '30'
                           AND t.CS > 1
                      THEN SUM(t2.ZCU * t.CS * ZUN_COMPONENT / ZUN_HEADER)
                           / t.CS
                      ELSE 1
                 END AS INT) PiecesPerConsumerUnit_New
    INTO    #MixedArticles
    FROM    dbo.Products AS p
            INNER JOIN dbo.ProductStatus AS ps ON p.FK_ProductStatusID = ps.PK_ProductStatusID
            INNER JOIN dbo.EANCodes AS ec2 ON p.PK_ProductID = ec2.ProductID
                                              AND ec2.FK_EANTypeID = 2
            INNER JOIN dbo.EANCodes AS ec3 ON p.PK_ProductID = ec3.ProductID
                                              AND ec3.FK_EANTypeID = 2
            INNER JOIN dbo.EANCodes AS ec4 ON p.PK_ProductID = ec4.ProductID
                                              AND ec4.FK_EANTypeID = 2
            INNER JOIN dbo.EANCodes AS ec5 ON p.PK_ProductID = ec5.ProductID
                                              AND ec5.FK_EANTypeID = 2
            INNER JOIN dbo.CommonCodes AS cc ON p.PK_ProductID = cc.FK_ProductID
                                                AND Active = 1
            INNER JOIN #BOM AS tb ON CAST(MATERIAL_HEADER AS BIGINT) = cc.CommonCode
            INNER JOIN #UOMPerProduct AS t ON Material = MATERIAL_HEADER
            INNER JOIN #UOMPerProduct AS t2 ON t2.Material = MATERIAL_COMPONENT
            INNER JOIN dbo.CommonCodes AS cc2 ON CAST(MATERIAL_COMPONENT AS BIGINT) = cc2.CommonCode
            INNER JOIN dbo.SAP_MATINFO_TotalList AS smtl ON MATERIAL_HEADER = smtl.Material
    WHERE   IsMixedGoods = 1
    GROUP BY ProductCode ,
            ps.Label ,
            MATERIAL_HEADER ,
            p.Label ,
            PiecesPerConsumerUnit ,
            ec2.Pieces ,
            t.CS ,
            t.ZCU ,
            DIVISION

    UPDATE  p
    SET     PiecesPerConsumerUnit = PiecesPerConsumerUnit_New
    FROM    #MixedArticles AS tf
            INNER JOIN dbo.Products AS p ON tf.ProductCode = p.ProductCode
    WHERE   PiecesPerConsumerUnit <> PiecesPerConsumerUnit_New
            AND FK_ProductStatusID = 0

----------------------------------------------------------------------
--               Insert UOM on Non Mixed Articles                   --
----------------------------------------------------------------------
    PRINT 'Insert UOM on Non Mixed Articles'

    INSERT  INTO EANCodes
            ( FK_EANTypeID ,
              ProductID ,
              EANCode ,
              Pieces 
            )
            SELECT DISTINCT
                    1 ,
                    PK_ProductID ,
                    ISNULL(EAN, '') ,
                    1
            FROM    SAP_MATINFO_TotalList AS smtl
                    INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                                 AND Active = 1
                    INNER JOIN Products P ON P.PK_ProductID = CC.FK_ProductID
                                             AND P.IsMixedGoods = 0
                    LEFT JOIN SAP_UOM_TotalList AS sutl ON smtl.Material = sutl.Material
                                                           AND Unit = 'ZCU'
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   EANCodes EAN
                                 WHERE  EAN.FK_EANTypeID = 1
                                        AND P.PK_ProductID = EAN.ProductID )

    INSERT  INTO EANCodes
            ( FK_EANTypeID ,
              ProductID ,
              EANCode ,
              Pieces 
            )
            SELECT DISTINCT
                    2 ,
                    PK_ProductID ,
                    ISNULL(CS.EAN, '') ,
                    ISNULL(CAST(CS.PCS_REN AS INT), 1)
                    * ISNULL(CAST(ZCU.PCS_REZ AS INT), 1)
            FROM    SAP_MATINFO_TotalList AS smtl
                    INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                                 AND Active = 1
                    INNER JOIN Products P ON P.PK_ProductID = CC.FK_ProductID
                                             AND P.IsMixedGoods = 0
                    LEFT JOIN SAP_UOM_TotalList CS ON smtl.Material = CS.Material
                                                      AND CS.UNIT = 'CS'
                    LEFT JOIN SAP_UOM_TotalList ZCU ON smtl.Material = ZCU.Material
                                                       AND ZCU.UNIT = 'ZCU'
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   EANCodes EAN
                                 WHERE  EAN.FK_EANTypeID = 2
                                        AND P.PK_ProductID = EAN.ProductID )

    INSERT  INTO EANCodes
            ( FK_EANTypeID ,
              ProductID ,
              EANCode ,
              Pieces 
            )
            SELECT DISTINCT
                    3 ,
                    PK_ProductID ,
                    ISNULL(ZLA.EAN, '') ,
                    ISNULL(CAST(ZCU.PCS_REZ AS INT), 1)
                    * ISNULL(CAST(ZLA.PCS_REN AS INT), 1)
                    / ISNULL(CAST(ZLA.PCS_REZ AS INT), 1)
            FROM    SAP_MATINFO_TotalList AS smtl
                    INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                                 AND Active = 1
                    INNER JOIN Products P ON P.PK_ProductID = CC.FK_ProductID
                                             AND P.IsMixedGoods = 0
                    LEFT JOIN SAP_UOM_TotalList ZCU ON smtl.Material = ZCU.Material
                                                       AND ZCU.UNIT = 'ZCU'
                    LEFT JOIN SAP_UOM_TotalList ZLA ON smtl.Material = ZLA.Material
                                                       AND ZLA.UNIT = 'ZLA'
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   EANCodes EAN
                                 WHERE  EAN.FK_EANTypeID = 3
                                        AND P.PK_ProductID = EAN.ProductID )

    INSERT  INTO EANCodes
            ( FK_EANTypeID ,
              ProductID ,
              EANCode ,
              Pieces 
            )
            SELECT DISTINCT
                    4 ,
                    PK_ProductID ,
                    ISNULL(PAL.EAN, '') ,
                    ISNULL(CAST(ZCU.PCS_REZ AS INT), 1)
                    * ISNULL(CAST(PAL.PCS_REN AS INT), 1)
            FROM    SAP_MATINFO_TotalList AS smtl
                    INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                                 AND Active = 1
                    INNER JOIN Products P ON P.PK_ProductID = CC.FK_ProductID
                                             AND P.IsMixedGoods = 0
                    LEFT JOIN SAP_UOM_TotalList ZCU ON smtl.Material = ZCU.Material
                                                       AND ZCU.UNIT = 'ZCU'
                    LEFT JOIN SAP_UOM_TotalList PAL ON smtl.Material = PAL.Material
                                                       AND PAL.UNIT = 'PAL'
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   EANCodes EAN
                                 WHERE  EAN.FK_EANTypeID = 4
                                        AND P.PK_ProductID = EAN.ProductID )

    INSERT  INTO EANCodes
            ( FK_EANTypeID ,
              ProductID ,
              EANCode ,
              Pieces 
            )
            SELECT DISTINCT
                    5 ,
                    PK_ProductID ,
                    '' ,
                    ISNULL(CAST(ZCU.PCS_REZ AS INT), 1)
            FROM    SAP_MATINFO_TotalList AS smtl
                    INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                                 AND Active = 1
                    INNER JOIN Products P ON P.PK_ProductID = CC.FK_ProductID
                                             AND P.IsMixedGoods = 0
                    LEFT JOIN SAP_UOM_TotalList ZCU ON smtl.Material = ZCU.Material
                                                       AND ZCU.UNIT = 'ZCU'
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   EANCodes EAN
                                 WHERE  EAN.FK_EANTypeID = 5
                                        AND P.PK_ProductID = EAN.ProductID )

----------------------------------------------------------------------
--                    Insert missing EANCodes                       --
----------------------------------------------------------------------
    PRINT 'Insert missing EANCodes'

    INSERT  INTO EANCodes
            ( FK_EANTypeID ,
              ProductID ,
              EANCode ,
              Pieces 
            )
            SELECT  PK_EANTypeID ,
                    PK_ProductID ,
                    '' ,
                    1
            FROM    Products ,
                    EANTypes
            WHERE   IsMixedGoods = 0
                    AND NOT EXISTS ( SELECT *
                                     FROM   EANCodes
                                     WHERE  PK_EANTypeID = FK_EANTypeID
                                            AND PK_ProductID = ProductID )


----------------------------------------------------------------------
--               Update UOM on Non Mixed Articles                   --
----------------------------------------------------------------------
    PRINT 'Update UOM on Non Mixed Articles'

    UPDATE  EAN
    SET     EANCode = ISNULL(ZCU.EAN, '')
    FROM    SAP_MATINFO_TotalList AS smtl
            INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                         AND Active = 1
            INNER JOIN Products P ON P.PK_ProductID = CC.FK_ProductID
                                     AND P.IsMixedGoods = 0
            LEFT JOIN SAP_UOM_TotalList ZCU ON smtl.Material = ZCU.Material
                                               AND ZCU.UNIT = 'ZCU'
            INNER JOIN EANCodes EAN ON EAN.FK_EANTypeID = 1
                                       AND P.PK_ProductID = EAN.ProductID
    WHERE   EAN.EANCode <> ISNULL(EAN, '')

    UPDATE  EAN
    SET     EANCode = ISNULL(CS.EAN, '') ,
            Pieces = ISNULL(CAST(CS.PCS_REN AS INT), 1)
            * ISNULL(CAST(ZCU.PCS_REZ AS INT), 1)
    FROM    SAP_MATINFO_TotalList AS smtl
            INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                         AND Active = 1
            INNER JOIN Products P ON P.PK_ProductID = CC.FK_ProductID
                                     AND P.IsMixedGoods = 0
            LEFT JOIN SAP_UOM_TotalList CS ON smtl.Material = CS.Material
                                              AND CS.UNIT = 'CS'
            LEFT JOIN SAP_UOM_TotalList ZCU ON smtl.Material = ZCU.Material
                                               AND ZCU.UNIT = 'ZCU'
            INNER JOIN EANCodes EAN ON EAN.FK_EANTypeID = 2
                                       AND P.PK_ProductID = EAN.ProductID
    WHERE   ( ISNULL(CS.EAN, '') <> EAN.EANCode
              OR ISNULL(CAST(CS.PCS_REN AS INT), 1)
              * ISNULL(CAST(ZCU.PCS_REZ AS INT), 1) <> EAN.Pieces
            )

    UPDATE  EAN
    SET     EANCode = ISNULL(ZLA.EAN, '') ,
            Pieces = ISNULL(CAST(ZCU.PCS_REZ AS INT), 1)
            * ISNULL(CAST(ZLA.PCS_REN AS INT), 1)
            / ISNULL(CAST(ZLA.PCS_REZ AS INT), 1)
    FROM    SAP_MATINFO_TotalList AS smtl
            INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                         AND Active = 1
            INNER JOIN Products P ON P.PK_ProductID = CC.FK_ProductID
                                     AND P.IsMixedGoods = 0
            LEFT JOIN SAP_UOM_TotalList ZCU ON smtl.Material = ZCU.Material
                                               AND ZCU.UNIT = 'ZCU'
            LEFT JOIN SAP_UOM_TotalList ZLA ON smtl.Material = ZLA.Material
                                               AND ZLA.UNIT = 'ZLA'
            INNER JOIN EANCodes EAN ON EAN.FK_EANTypeID = 3
                                       AND P.PK_ProductID = EAN.ProductID
    WHERE   ( ISNULL(ZLA.EAN, '') <> EAN.EANCode
              OR ISNULL(CAST(ZLA.PCS_REN AS INT), 1)
              * ISNULL(CAST(ZCU.PCS_REZ AS INT), 1)
              / ISNULL(CAST(ZLA.PCS_REZ AS INT), 1) <> ISNULL(EAN.Pieces, -1)
            )

    UPDATE  EAN
    SET     EANCode = ISNULL(PAL.EAN, '') ,
            Pieces = ISNULL(CAST(ZCU.PCS_REZ AS INT), 1)
            * ISNULL(CAST(PAL.PCS_REN AS INT), 1)
    FROM    SAP_MATINFO_TotalList AS smtl
            INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                         AND Active = 1
            INNER JOIN Products P ON P.PK_ProductID = CC.FK_ProductID
                                     AND P.IsMixedGoods = 0
            LEFT JOIN SAP_UOM_TotalList ZCU ON smtl.Material = ZCU.Material
                                               AND ZCU.UNIT = 'ZCU'
            LEFT JOIN SAP_UOM_TotalList PAL ON smtl.Material = PAL.Material
                                               AND PAL.UNIT = 'PAL'
            INNER JOIN EANCodes EAN ON EAN.FK_EANTypeID = 4
                                       AND P.PK_ProductID = EAN.ProductID
    WHERE   ( ISNULL(PAL.EAN, '') <> EAN.EANCode
              OR ISNULL(CAST(PAL.PCS_REN AS INT), 1)
              * ISNULL(CAST(ZCU.PCS_REZ AS INT), 1) <> EAN.Pieces
            )

    UPDATE  EAN
    SET     Pieces = ISNULL(CAST(ZCU.PCS_REZ AS INT), 1)
    FROM    SAP_MATINFO_TotalList AS smtl
            INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                         AND Active = 1
            INNER JOIN Products P ON P.PK_ProductID = CC.FK_ProductID
                                     AND P.IsMixedGoods = 0
            LEFT JOIN SAP_UOM_TotalList ZCU ON smtl.Material = ZCU.Material
                                               AND ZCU.UNIT = 'ZCU'
            INNER JOIN EANCodes EAN ON EAN.FK_EANTypeID = 5
                                       AND P.PK_ProductID = EAN.ProductID
    WHERE   ISNULL(CAST(ZCU.PCS_REZ AS INT), 1) <> EAN.Pieces

----------------------------------------------------------------------
--                       Insert BOM Headers                         --
----------------------------------------------------------------------
    PRINT 'Insert BOM Headers'

    INSERT  INTO BillOfMaterials
            ( FK_HeaderProductID 
            )
            SELECT DISTINCT
                    PHeader.PK_ProductID
            FROM    SAP_BOM_TotalList BOM
                    INNER JOIN CommonCodes CCHeader ON CAST(CAST(MATERIAL_HEADER AS INT) AS VARCHAR) = CCHeader.CommonCode
                                                       AND CCHeader.Active = 1
                    INNER JOIN Products PHeader ON PHeader.PK_ProductID = CCHeader.FK_ProductID
            WHERE   --IsHandled = 0 AND 
                    Type <> 'O'
                    AND NOT EXISTS ( SELECT *
                                     FROM   BillOfMaterials BOMS
                                     WHERE  PHeader.PK_ProductID = BOMS.FK_HeaderProductID )

----------------------------------------------------------------------
--                       Delete BOM Lines                           --
----------------------------------------------------------------------
    PRINT 'Delete BOM Lines'

    DELETE  FROM BOML
    FROM    SAP_BOM_TotalList BOMHeader
            INNER JOIN CommonCodes CCHeader ON CAST(CAST(BOMHeader.MATERIAL_HEADER AS INT) AS VARCHAR) = CCHeader.CommonCode
                                               AND CCHeader.Active = 1
            INNER JOIN Products PHeader ON PHeader.PK_ProductID = CCHeader.FK_ProductID
            INNER JOIN BillOfMaterials BOMS ON PHeader.PK_ProductID = BOMS.FK_HeaderProductID
            INNER JOIN BillOfMaterialLines BOML ON BOMS.PK_BillOfMaterialID = BOML.FK_BillOfMaterialID
            INNER JOIN Products PComp ON PComp.PK_ProductID = BOML.FK_ComponentProductID
    WHERE   --BOMHeader.IsHandled = 0 AND 
            BOMHeader.Type = 'O'
            AND NOT EXISTS ( SELECT *
                             FROM   SAP_BOM_TotalList BOMComp
                                    INNER JOIN CommonCodes CCComp ON CAST(CAST(BOMComp.MATERIAL_COMPONENT AS INT) AS VARCHAR) = CCComp.CommonCode
                             WHERE  --BOMComp.IsHandled = 0 AND 
                                    BOMComp.Type <> 'O'
                                    AND BOMHeader.MATERIAL_HEADER = BOMComp.MATERIAL_HEADER
                                    AND PComp.PK_ProductID = CCComp.FK_ProductID )

----------------------------------------------------------------------
--                       Insert BOM Lines                           --
----------------------------------------------------------------------
    PRINT 'Insert BOM Lines'

    INSERT  INTO BillOfMaterialLines
            ( FK_BillOfMaterialID ,
              FK_ComponentProductID ,
              Pieces 
            )
            SELECT   DISTINCT PK_BillOfMaterialID ,
                    PComp.PK_ProductID ,
                    CAST(CAST(REPLACE(BOM.ZUN, ',', '') AS FLOAT)
                    * CAST(EAN.Pieces AS FLOAT)
                    / CAST(REPLACE(BOMHeader.ZUN, ',', '') AS FLOAT) --/ CAST(PHeader.PiecesPerConsumerUnit as float) 
AS INT)
            FROM    SAP_BOM_TotalList BOM
                    INNER JOIN CommonCodes CCHeader ON CAST(CAST(MATERIAL_HEADER AS INT) AS VARCHAR) = CCHeader.CommonCode
                                                       AND CCHeader.Active = 1
                    INNER JOIN Products PHeader ON PHeader.PK_ProductID = CCHeader.FK_ProductID
                    INNER JOIN CommonCodes CCComp ON CAST(CAST(MATERIAL_COMPONENT AS INT) AS VARCHAR) = CCComp.CommonCode /*DDC ADDED:*/ AND CCComp.Active = 1
                    INNER JOIN Products PComp ON PComp.PK_ProductID = CCComp.FK_ProductID
                    INNER JOIN EANCodes EAN ON PComp.PK_ProductID = EAN.ProductID
                                               AND EAN.FK_EANTypeID = 5
                    INNER JOIN BillOfMaterials BOMS ON PHeader.PK_ProductID = BOMS.FK_HeaderProductID
                    INNER JOIN SAP_BOM_TotalList BOMHeader ON BOM.MATERIAL_HEADER = BOMHeader.MATERIAL_HEADER
                                                              AND BOMHeader.TYPE = 'O'-- AND BOMHeader.IsHandled = 0
            WHERE   --BOM.IsHandled = 0 AND 
                    BOM.Type <> 'O'
                    AND PHeader.IsMixedGoods = 1
                    AND NOT EXISTS ( SELECT *
                                     FROM   BillOfMaterialLines BOML
                                     WHERE  BOMS.PK_BillOfMaterialID = BOML.FK_BillOfMaterialID
                                            AND PComp.PK_ProductID = BOML.FK_ComponentProductID )

----------------------------------------------------------------------
--                       Update BOM Lines                           --
----------------------------------------------------------------------
    PRINT 'Update BOM Lines'

    UPDATE  BOML
    SET     Pieces = CASE WHEN CAST(CAST(REPLACE(BOM.ZUN, ',', '') AS FLOAT)
                               * CAST(EAN.Pieces AS FLOAT)
                               / CAST(REPLACE(BOMHeader.ZUN, ',', '') AS FLOAT)
                               / CAST(PHeader.PiecesPerConsumerUnit AS FLOAT) AS INT) = 0
                          THEN 1
                          ELSE CAST(CAST(REPLACE(BOM.ZUN, ',', '') AS FLOAT)
                               * CAST(EAN.Pieces AS FLOAT)
                               / CAST(REPLACE(BOMHeader.ZUN, ',', '') AS FLOAT) --/ CAST(PHeader.PiecesPerConsumerUnit as float) 
    AS INT)
                     END
    FROM    SAP_BOM_TotalList BOM
            INNER JOIN CommonCodes CCHeader ON CAST(CAST(BOM.MATERIAL_HEADER AS INT) AS VARCHAR) = CCHeader.CommonCode
                                               AND CCHeader.Active = 1
            INNER JOIN Products PHeader ON PHeader.PK_ProductID = CCHeader.FK_ProductID
            INNER JOIN BillOfMaterials BOMS ON PHeader.PK_ProductID = BOMS.FK_HeaderProductID
            INNER JOIN CommonCodes CCComp ON CAST(CAST(BOM.MATERIAL_COMPONENT AS INT) AS VARCHAR) = CCComp.CommonCode
            INNER JOIN Products PComp ON PComp.PK_ProductID = CCComp.FK_ProductID
            INNER JOIN EANCodes EAN ON PComp.PK_ProductID = EAN.ProductID
                                       AND EAN.FK_EANTypeID = 5
            INNER JOIN BillOfMaterialLines BOML ON BOMS.PK_BillOfMaterialID = BOML.FK_BillOfMaterialID
                                                   AND PComp.PK_ProductID = BOML.FK_ComponentProductID
            INNER JOIN SAP_BOM_TotalList BOMHeader ON BOM.MATERIAL_HEADER = BOMHeader.MATERIAL_HEADER --AND BOMHeader.IsHandled = 0 
                                                      AND BOMHeader.TYPE = 'O'
    WHERE   --BOM.IsHandled = 0 AND 
            BOM.Type <> 'O'
            AND CASE WHEN CAST(CAST(REPLACE(BOM.ZUN, ',', '') AS FLOAT)
                          * CAST(EAN.Pieces AS FLOAT)
                          / CAST(REPLACE(BOMHeader.ZUN, ',', '') AS FLOAT)
                          / CAST(PHeader.PiecesPerConsumerUnit AS FLOAT) AS INT) = 0
                     THEN 1
                     ELSE CAST(CAST(REPLACE(BOM.ZUN, ',', '') AS FLOAT)
                          * CAST(EAN.Pieces AS FLOAT)
                          / CAST(REPLACE(BOMHeader.ZUN, ',', '') AS FLOAT) --/ CAST(PHeader.PiecesPerConsumerUnit as float) 
    AS INT)
                END <> BOML.Pieces

----------------------------------------------------------------------
--                Delete Extra Lines on ZNOR BOM                    --
----------------------------------------------------------------------
    DELETE  FROM BOML1
    FROM    Products P1
            INNER JOIN BillOfMaterials BOM1 ON PK_ProductID = FK_HeaderProductID
            INNER JOIN BillOfMaterialLines BOML1 ON PK_BillOfMaterialID = FK_BillOfMaterialID
    WHERE   EXISTS ( SELECT PK_ProductID ,
                            MIN(FK_ComponentProductID) MinComponentProductID
                     FROM   Products P2
                            INNER JOIN BillOfMaterials BOM2 ON PK_ProductID = FK_HeaderProductID
                            INNER JOIN BillOfMaterialLines BOML2 ON PK_BillOfMaterialID = FK_BillOfMaterialID
                     WHERE  P2.IsMixedGoods = 0
                     GROUP BY PK_ProductID
                     HAVING COUNT(*) > 1
                            AND P1.PK_ProductID = P2.PK_ProductID
                            AND BOML1.FK_ComponentProductID <> MIN(BOML2.FK_ComponentProductID) )

----------------------------------------------------------------------
--                    Update Lines on ZNOR BOM                      --
----------------------------------------------------------------------
    UPDATE  BOML
    SET     FK_ComponentProductID = FK_HeaderProductID ,
            Pieces = 1
    FROM    Products P
            INNER JOIN BillOfMaterials BOM ON PK_ProductID = FK_HeaderProductID
            INNER JOIN BillOfMaterialLines BOML ON PK_BillOfMaterialID = FK_BillOfMaterialID
    WHERE   IsMixedGoods = 0
            AND ( FK_HeaderProductID <> FK_ComponentProductID
                  OR Pieces <> 1
                )

----------------------------------------------------------------------
--                       Insert Missing BOM                         --
----------------------------------------------------------------------
    PRINT 'Insert Missing BOM'

    INSERT  INTO BillOfMaterials
            ( FK_HeaderProductID 
            )
            SELECT DISTINCT
                    P.PK_ProductID
            FROM    Products P
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   BillOfMaterials BOM
                                 WHERE  P.PK_ProductID = BOM.FK_HeaderProductID )

    INSERT  INTO BillOfMaterialLines
            ( FK_BillOfMaterialID ,
              FK_ComponentProductID ,
              Pieces 
            )
            SELECT  PK_BillOfMaterialID ,
                    FK_HeaderProductID ,
                    1
            FROM    BillOfMaterials BOM
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   BillOfMaterialLines BOML
                                 WHERE  BOM.PK_BillOfMaterialID = BOML.FK_BillOfMaterialID )

----------------------------------------------------------------------
--        Update IsMixedGoods if product refer to itself            --
----------------------------------------------------------------------
    PRINT 'Update IsMixedGoods if product refer to itself'

    UPDATE  Header
    SET     IsMixedGoods = 0
    FROM    Products Header
            INNER JOIN BillOfMaterials ON Header.PK_ProductID = FK_HeaderProductID
            INNER JOIN BillOfMaterialLines ON PK_BillOfMaterialID = FK_BillOfMaterialID
            INNER JOIN Products Comp ON Comp.PK_ProductID = FK_ComponentProductID
    WHERE   Header.IsMixedGoods = 1
            AND Header.PK_ProductID = Comp.PK_ProductID

    UPDATE  Header
    SET     IsMixedGoods = 1
    FROM    Products Header
            INNER JOIN BillOfMaterials ON Header.PK_ProductID = FK_HeaderProductID
            INNER JOIN BillOfMaterialLines ON PK_BillOfMaterialID = FK_BillOfMaterialID
            INNER JOIN Products Comp ON Comp.PK_ProductID = FK_ComponentProductID
    WHERE   Header.ItemCategory = 'Z5BM'
            AND Header.IsMixedGoods = 0
            AND Header.PK_ProductID <> Comp.PK_ProductID

----------------------------------------------------------------------
--                        Update 0 Pieces                           --
----------------------------------------------------------------------
    PRINT 'Update 0 Pieces'

    UPDATE  BOML
    SET     Pieces = 1
    FROM    BillOfMaterialLines BOML
    WHERE   Pieces = 0

----------------------------------------------------------------------
--                 Insert UOM on Mixed Articles                     --
----------------------------------------------------------------------
    PRINT 'Insert UOM on Mixed Articles'

    INSERT  INTO EANCodes
            ( FK_EANTypeID ,
              ProductID ,
              EANCode ,
              Pieces 
            )
            SELECT DISTINCT
                    1 ,
                    PK_ProductID ,
                    ISNULL(EAN, '') ,
                    1
            FROM    SAP_MATINFO_TotalList AS smtl
                    INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                                 AND Active = 1
                    INNER JOIN Products P ON P.PK_ProductID = CC.FK_ProductID
                                             AND P.IsMixedGoods = 1
                    LEFT JOIN SAP_UOM_TotalList ZCU ON smtl.Material = ZCU.Material
                                                       AND ZCU.UNIT = 'ZCU'
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   EANCodes EAN
                                 WHERE  EAN.FK_EANTypeID = 1
                                        AND P.PK_ProductID = EAN.ProductID )

    INSERT  INTO EANCodes
            ( FK_EANTypeID ,
              ProductID ,
              EANCode ,
              Pieces 
            )
            SELECT DISTINCT
                    2 ,
                    PK_ProductID ,
                    ISNULL(CS.EAN, '') ,
                    SUM(Pieces)
            FROM    SAP_MATINFO_TotalList AS smtl
                    INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                                 AND Active = 1
                    INNER JOIN Products P ON P.PK_ProductID = CC.FK_ProductID
                                             AND P.IsMixedGoods = 1
                    INNER JOIN BillOfMaterials BOM ON P.PK_ProductID = BOM.FK_HeaderProductID
                    INNER JOIN BillOfMaterialLines BOML ON BOM.PK_BillOfMaterialID = BOML.FK_BillOfMaterialID
                    LEFT JOIN SAP_UOM_TotalList CS ON smtl.Material = CS.Material
                                                      AND CS.UNIT = 'CS'
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   EANCodes EAN
                                 WHERE  EAN.FK_EANTypeID = 2
                                        AND P.PK_ProductID = EAN.ProductID )
            GROUP BY PK_ProductID ,
                    ISNULL(CS.EAN, '')

    INSERT  INTO EANCodes
            ( FK_EANTypeID ,
              ProductID ,
              EANCode ,
              Pieces 
            )
            SELECT DISTINCT
                    3 ,
                    PK_ProductID ,
                    ISNULL(ZLA.EAN, '') ,
                    Pieces * ISNULL(CAST(ZLA.PCS_REN AS INT), 1)
                    / ISNULL(CAST(ZLA.PCS_REZ AS INT), 1)
            FROM    SAP_MATINFO_TotalList AS smtl
                    INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                                 AND Active = 1
                    INNER JOIN Products P ON P.PK_ProductID = CC.FK_ProductID
                                             AND P.IsMixedGoods = 1
                    INNER JOIN EANCodes EAN ON P.PK_ProductID = EAN.ProductID
                                               AND EAN.FK_EANTypeID = 2
                    LEFT JOIN SAP_UOM_TotalList ZLA ON smtl.Material = ZLA.Material
                                                       AND ZLA.UNIT = 'ZLA'
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   EANCodes EAN
                                 WHERE  EAN.FK_EANTypeID = 3
                                        AND P.PK_ProductID = EAN.ProductID )

    INSERT  INTO EANCodes
            ( FK_EANTypeID ,
              ProductID ,
              EANCode ,
              Pieces 
            )
            SELECT DISTINCT
                    4 ,
                    PK_ProductID ,
                    ISNULL(PAL.EAN, '') ,
                    Pieces * ISNULL(CAST(PAL.PCS_REN AS INT), 1)
            FROM    SAP_MATINFO_TotalList AS smtl
                    INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                                 AND Active = 1
                    INNER JOIN Products P ON P.PK_ProductID = CC.FK_ProductID
                                             AND P.IsMixedGoods = 1
                    INNER JOIN EANCodes EAN ON P.PK_ProductID = EAN.ProductID
                                               AND EAN.FK_EANTypeID = 2
                    LEFT JOIN SAP_UOM_TotalList PAL ON smtl.Material = PAL.Material
                                                       AND PAL.UNIT = 'PAL'
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   EANCodes EAN
                                 WHERE  EAN.FK_EANTypeID = 4
                                        AND P.PK_ProductID = EAN.ProductID )

    INSERT  INTO EANCodes
            ( FK_EANTypeID ,
              ProductID ,
              EANCode ,
              Pieces 
            )
            SELECT DISTINCT
                    5 ,
                    PK_ProductID ,
                    '' ,
                    Pieces
            FROM    SAP_MATINFO_TotalList AS smtl
                    INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                                 AND Active = 1
                    INNER JOIN Products P ON P.PK_ProductID = CC.FK_ProductID
                                             AND P.IsMixedGoods = 1
                    INNER JOIN EANCodes EAN ON P.PK_ProductID = EAN.ProductID
                                               AND EAN.FK_EANTypeID = 2
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   EANCodes EAN
                                 WHERE  EAN.FK_EANTypeID = 5
                                        AND P.PK_ProductID = EAN.ProductID )

----------------------------------------------------------------------
--                       Import EANCodes                            --
----------------------------------------------------------------------
    EXEC rdh_ImportEANCodes_Sirius

----------------------------------------------------------------------
--                 Update UOM on Mixed Articles                     --
----------------------------------------------------------------------

----------------------------------------------------------------------
--                             Missing                              --
----------------------------------------------------------------------
    PRINT 'Update UOM on Mixed Articles'

----------------------------------------------------------------------
--            Update UOM and BOM on simple repacks                  --
----------------------------------------------------------------------
    UPDATE  EAN
    SET     Pieces = CAST(REPLACE(ComponentZUN, ',', '') AS FLOAT)
            * CAST(ec.Pieces AS FLOAT)
            / CAST(REPLACE(HeaderZUN, ',', '') AS FLOAT)
            * ISNULL(CAST(CS.PCS_REN AS INT), 1) --/ PiecesPerConsumerUnit
    FROM    Products
            INNER JOIN CommonCodes CC ON PK_ProductID = FK_ProductID
            INNER JOIN EANCodes EAN ON PK_ProductID = ProductID
                                       AND FK_EANTypeID = 2
            INNER JOIN SAP_UOM_TotalList CS ON CAST(CAST(CS.MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                               AND CS.UNIT = 'CS'
            INNER JOIN SAP_UOM_TotalList ZCU ON CAST(CAST(ZCU.MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                                AND ZCU.UNIT = 'ZCU'
            INNER JOIN ( SELECT FK_ProductID ,
                                ComponentZUN ,
                                HeaderZUN
                         FROM   CommonCodes
                                INNER JOIN ( SELECT CAST(BOM1.MATERIAL_HEADER AS BIGINT) CommonCode ,
                                                    BOM1.ZUN ComponentZUN ,
                                                    BOM3.ZUN HeaderZUN
                                             FROM   SAP_BOM_TotalList BOM1
                                                    INNER JOIN ( SELECT
                                                              FK_FileImportID ,
                                                              MATERIAL_HEADER
                                                              FROM
                                                              SAP_BOM_TotalList BOM2
--              INNER JOIN (SELECT MAX(FK_FileImportID) MaxFileImportID FROM SAP_BOM) Sub ON BOM2.FK_FileImportID = MaxFileImportID
                                                              WHERE
                                                              TYPE = 'I'
                                                              GROUP BY FK_FileImportID ,
                                                              MATERIAL_HEADER
                                                              HAVING
                                                              COUNT(*) = 1
                                                              ) BOM2 ON BOM1.FK_FileImportID = BOM2.FK_FileImportID
                                                              AND BOM1.MATERIAL_HEADER = BOM2.MATERIAL_HEADER
                                                    INNER JOIN dbo.SAP_BOM_TotalList
                                                    AS BOM3 ON BOM1.FK_FileImportID = BOM3.FK_FileImportID
                                                              AND BOM1.MATERIAL_HEADER = BOM3.MATERIAL_HEADER
                                                              AND BOM3.TYPE = 'O'
                                             WHERE  BOM1.MATERIAL_HEADER <> BOM1.MATERIAL_COMPONENT
                                                    AND BOM1.TYPE = 'I' /*AND BOM1.ZUN = '1,000.000'*/
                                           ) Sub ON dbo.CommonCodes.CommonCode = Sub.CommonCode
                         WHERE  Active = 1
                       ) Sub ON PK_ProductID = Sub.FK_ProductID
            INNER JOIN dbo.BillOfMaterials AS bom ON PK_ProductID = FK_HeaderProductID
            INNER JOIN dbo.BillOfMaterialLines AS boml ON bom.PK_BillOfMaterialID = boml.FK_BillOfMaterialID
            INNER JOIN dbo.EANCodes AS ec ON FK_ComponentProductID = ec.ProductID
                                             AND ec.FK_EANTypeID = 5
    WHERE   Active = 1
            AND IsMixedGoods = 1
            AND EAN.Pieces <> CAST(REPLACE(ComponentZUN, ',', '') AS FLOAT)
            * CAST(ec.Pieces AS FLOAT)
            / CAST(REPLACE(HeaderZUN, ',', '') AS FLOAT)
            * ISNULL(CAST(CS.PCS_REN AS INT), 1) --/ PiecesPerConsumerUnit

    UPDATE  BOML
    SET     Pieces = CAST(REPLACE(ComponentZUN, ',', '') AS FLOAT)
            * CAST(ec.Pieces AS FLOAT)
            / CAST(REPLACE(HeaderZUN, ',', '') AS FLOAT)
            * ISNULL(CAST(CS.PCS_REN AS INT), 1) --/ PiecesPerConsumerUnit
    FROM    Products
            INNER JOIN CommonCodes CC ON PK_ProductID = FK_ProductID
            INNER JOIN BillOfMaterials ON PK_ProductID = FK_HeaderProductID
            INNER JOIN BillOfMaterialLines BOML ON PK_BillOfMaterialID = FK_BillOfMaterialID
            INNER JOIN SAP_UOM_TotalList CS ON CAST(CAST(CS.MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                               AND CS.UNIT = 'CS'
            INNER JOIN SAP_UOM_TotalList ZCU ON CAST(CAST(ZCU.MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                                AND ZCU.UNIT = 'ZCU'
            INNER JOIN ( SELECT FK_ProductID ,
                                ComponentZUN ,
                                HeaderZUN
                         FROM   CommonCodes
                                INNER JOIN ( SELECT CAST(BOM1.MATERIAL_HEADER AS BIGINT) CommonCode ,
                                                    BOM1.ZUN ComponentZUN ,
                                                    BOM3.ZUN HeaderZUN
                                             FROM   SAP_BOM_TotalList BOM1
                                                    INNER JOIN ( SELECT
                                                              FK_FileImportID ,
                                                              MATERIAL_HEADER
                                                              FROM
                                                              SAP_BOM_TotalList BOM2
--              INNER JOIN (SELECT MAX(FK_FileImportID) MaxFileImportID FROM SAP_BOM) Sub ON BOM2.FK_FileImportID = MaxFileImportID
                                                              WHERE
                                                              TYPE = 'I'
                                                              GROUP BY FK_FileImportID ,
                                                              MATERIAL_HEADER
                                                              HAVING
                                                              COUNT(*) = 1
                                                              ) BOM2 ON BOM1.FK_FileImportID = BOM2.FK_FileImportID
                                                              AND BOM1.MATERIAL_HEADER = BOM2.MATERIAL_HEADER
                                                    INNER JOIN dbo.SAP_BOM_TotalList
                                                    AS BOM3 ON BOM1.FK_FileImportID = BOM3.FK_FileImportID
                                                              AND BOM1.MATERIAL_HEADER = BOM3.MATERIAL_HEADER
                                                              AND BOM3.TYPE = 'O'
                                             WHERE  BOM1.MATERIAL_HEADER <> BOM1.MATERIAL_COMPONENT
                                                    AND BOM1.TYPE = 'I' /*AND BOM1.ZUN = '1,000.000'*/
                                           ) Sub ON dbo.CommonCodes.CommonCode = Sub.CommonCode
                         WHERE  Active = 1
                       ) Sub ON PK_ProductID = Sub.FK_ProductID
            INNER JOIN dbo.EANCodes AS ec ON FK_ComponentProductID = ProductID
                                             AND FK_EANTypeID = 5
    WHERE   Active = 1
            AND IsMixedGoods = 1
            AND BOML.Pieces <> CAST(REPLACE(ComponentZUN, ',', '') AS FLOAT)
            * CAST(ec.Pieces AS FLOAT)
            / CAST(REPLACE(HeaderZUN, ',', '') AS FLOAT)
            * ISNULL(CAST(CS.PCS_REN AS INT), 1) --/ PiecesPerConsumerUnit

----------------------------------------------------------------------
--            Update BOM to handle PiecesPerConsumerUnit            --
----------------------------------------------------------------------

    PRINT 'Update BOM to handle PiecesPerConsumerUnit'

    UPDATE  boml
    SET     Pieces = t2.ZCU * t.CS * ZUN_COMPONENT / ZUN_HEADER
    FROM    dbo.Products AS p
            INNER JOIN dbo.ProductStatus AS ps ON p.FK_ProductStatusID = ps.PK_ProductStatusID
            INNER JOIN dbo.CommonCodes AS cc ON p.PK_ProductID = cc.FK_ProductID
                                                AND Active = 1
            INNER JOIN #BOM AS tb ON CAST(MATERIAL_HEADER AS BIGINT) = cc.CommonCode
            INNER JOIN #UOMPerProduct AS t ON Material = MATERIAL_HEADER
            INNER JOIN #UOMPerProduct AS t2 ON t2.Material = MATERIAL_COMPONENT
            INNER JOIN dbo.CommonCodes AS cc2 ON CAST(MATERIAL_COMPONENT AS BIGINT) = cc2.CommonCode
            INNER JOIN dbo.BillOfMaterials AS bom ON p.PK_ProductID = FK_HeaderProductID
            INNER JOIN dbo.BillOfMaterialLines AS boml ON PK_BillOfMaterialID = FK_BillOfMaterialID
                                                          AND cc2.FK_ProductID = FK_ComponentProductID
    WHERE   IsMixedGoods = 1
            AND t2.ZCU * t.CS * ZUN_COMPONENT / ZUN_HEADER <> Pieces


----------------------------------------------------------------------
--            Update EAN to handle PiecesPerConsumerUnit            --
----------------------------------------------------------------------
    PRINT 'Update EAN to handle PiecesPerConsumerUnit'

    UPDATE  ec
    SET     Pieces = PiecesPerCase_New
    FROM    dbo.EANCodes AS ec
            INNER JOIN ( SELECT PK_ProductID ,
                                CAST(SUM(t2.ZCU * t.CS * ZUN_COMPONENT
                                         / ZUN_HEADER) AS INT) PiecesPerCase_New
                         FROM   dbo.Products AS p
                                INNER JOIN dbo.ProductStatus AS ps ON p.FK_ProductStatusID = ps.PK_ProductStatusID
                                INNER JOIN dbo.EANCodes AS ec2 ON p.PK_ProductID = ec2.ProductID
                                                              AND ec2.FK_EANTypeID = 2
                                INNER JOIN dbo.EANCodes AS ec3 ON p.PK_ProductID = ec3.ProductID
                                                              AND ec3.FK_EANTypeID = 2
                                INNER JOIN dbo.EANCodes AS ec4 ON p.PK_ProductID = ec4.ProductID
                                                              AND ec4.FK_EANTypeID = 2
                                INNER JOIN dbo.EANCodes AS ec5 ON p.PK_ProductID = ec5.ProductID
                                                              AND ec5.FK_EANTypeID = 2
                                INNER JOIN dbo.CommonCodes AS cc ON p.PK_ProductID = cc.FK_ProductID
                                                              AND Active = 1
                                INNER JOIN #BOM AS tb ON CAST(MATERIAL_HEADER AS BIGINT) = cc.CommonCode
                                INNER JOIN #UOMPerProduct AS t ON Material = MATERIAL_HEADER
                                INNER JOIN #UOMPerProduct AS t2 ON t2.Material = MATERIAL_COMPONENT
                                INNER JOIN dbo.CommonCodes AS cc2 ON CAST(MATERIAL_COMPONENT AS BIGINT) = cc2.CommonCode
                                INNER JOIN dbo.SAP_MATINFO_TotalList AS smtl ON MATERIAL_HEADER = smtl.Material
                         WHERE  IsMixedGoods = 1 --AND FK_ProductStatusID = 2
                         GROUP BY PK_ProductID
                       ) Sub ON ec.ProductID = Sub.PK_ProductID
                                AND ec.FK_EANTypeID = 2
    WHERE   ec.Pieces <> PiecesPerCase_New

    UPDATE  ec
    SET     Pieces = PiecesPerZUN_New
    FROM    dbo.EANCodes AS ec
            INNER JOIN ( SELECT PK_ProductID ,
                                SUM(t2.ZCU * t.CS * ZUN_COMPONENT / ZUN_HEADER)
                                / ( t.CS * t.ZCU ) PiecesPerZUN_New
                         FROM   dbo.Products AS p
                                INNER JOIN dbo.ProductStatus AS ps ON p.FK_ProductStatusID = ps.PK_ProductStatusID
                                INNER JOIN dbo.EANCodes AS ec2 ON p.PK_ProductID = ec2.ProductID
                                                              AND ec2.FK_EANTypeID = 2
                                INNER JOIN dbo.EANCodes AS ec3 ON p.PK_ProductID = ec3.ProductID
                                                              AND ec3.FK_EANTypeID = 5
                                INNER JOIN dbo.EANCodes AS ec4 ON p.PK_ProductID = ec4.ProductID
                                                              AND ec4.FK_EANTypeID = 2
                                INNER JOIN dbo.EANCodes AS ec5 ON p.PK_ProductID = ec5.ProductID
                                                              AND ec5.FK_EANTypeID = 2
                                INNER JOIN dbo.CommonCodes AS cc ON p.PK_ProductID = cc.FK_ProductID
                                                              AND Active = 1
                                INNER JOIN #BOM AS tb ON CAST(MATERIAL_HEADER AS BIGINT) = cc.CommonCode
                                INNER JOIN #UOMPerProduct AS t ON Material = MATERIAL_HEADER
                                INNER JOIN #UOMPerProduct AS t2 ON t2.Material = MATERIAL_COMPONENT
                                INNER JOIN dbo.CommonCodes AS cc2 ON CAST(MATERIAL_COMPONENT AS BIGINT) = cc2.CommonCode
                                INNER JOIN dbo.SAP_MATINFO_TotalList AS smtl ON MATERIAL_HEADER = smtl.Material
                         WHERE  IsMixedGoods = 1
                                AND ISNULL(DIVISION, '') = '30'
                         GROUP BY PK_ProductID ,
                                t.CS ,
                                t.ZCU
                       ) Sub ON ec.ProductID = Sub.PK_ProductID
                                AND ec.FK_EANTypeID = 5
    WHERE   ec.Pieces <> PiecesPerZUN_New

    PRINT 'Clean up'
    UPDATE  boml
    SET     Pieces = 1
    FROM    dbo.BillOfMaterialLines AS boml
    WHERE   Pieces = 0

    UPDATE  ec
    SET     Pieces = Sub.Pieces
    FROM    dbo.EANCodes AS ec
            INNER JOIN ( SELECT FK_HeaderProductID ProductID ,
                                SUM(Pieces) Pieces
                         FROM   dbo.BillOfMaterialLines AS boml
                                INNER JOIN dbo.BillOfMaterials AS bom ON boml.FK_BillOfMaterialID = bom.PK_BillOfMaterialID
                         GROUP BY FK_HeaderProductID
                       ) Sub ON ec.ProductID = Sub.ProductID
                                AND FK_EANTypeID = 2
            INNER JOIN dbo.Products AS p ON PK_ProductID = ec.ProductID
    WHERE   ec.Pieces <> Sub.Pieces
            AND IsMixedGoods = 1

----------------------------------------------------------------------
--                     Update ProductType                           --
----------------------------------------------------------------------
    PRINT 'Update ProductType'

    UPDATE  P
    SET     FK_ProductTypeID = CASE WHEN CAST(PAL.Pieces AS FLOAT)
                                         / CASE WHEN CS.Pieces <> 0
                                                THEN CAST(CS.Pieces AS FLOAT)
                                                ELSE 1.0
                                           END <= 4.0 THEN 2
                                    WHEN ItemCategory = 'Z5BM' THEN 3
                                    WHEN ItemCategory = 'ZPRO' THEN 6
                                    ELSE 5
                               END
    FROM    Products P
            INNER JOIN EANCodes CS ON PK_ProductID = CS.ProductID
                                      AND CS.FK_EANTypeID = 2
            INNER JOIN EANCodes PAL ON PK_ProductID = PAL.ProductID
                                       AND PAL.FK_EANTypeID = 4
    WHERE   FK_ProductTypeID <> CASE WHEN CAST(PAL.Pieces AS FLOAT)
                                          / CASE WHEN CS.Pieces <> 0
                                                 THEN CAST(CS.Pieces AS FLOAT)
                                                 ELSE 1.0
                                            END <= 4.0 THEN 2
                                     WHEN ItemCategory = 'Z5BM' THEN 3
                                     WHEN ItemCategory = 'ZPRO' THEN 6
                                     ELSE 5
                                END

----------------------------------------------------------------------
--                   Update Pricing Hierarchy                       --
----------------------------------------------------------------------
    PRINT 'Update Pricing Hierarchy'
    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyLevelID ,
              FK_ProductHierarchyParentID ,
              Node ,
              Label 
            )
            SELECT DISTINCT
                    PHParent.FK_ProductHierarchyLevelID + 1 ,
                    PHParent.PK_ProductHierarchyID ,
                    NODEGROUP ,
                    NODEGROUP + '_'
            FROM    SAP_MATINFO_TotalList AS smtl
                    INNER JOIN ProductHierarchies PHParent ON PHParent.FK_ProductHierarchyLevelID = 19
            WHERE   NODEGROUP <> ''
                    AND NOT EXISTS ( SELECT *
                                     FROM   ProductHierarchies PH
                                     WHERE  PH.FK_ProductHierarchyLevelID = PHParent.FK_ProductHierarchyLevelID
                                            + 1
                                            AND smtl.NODEGROUP = PH.Node )

    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyLevelID ,
              FK_ProductHierarchyParentID ,
              Node ,
              Label 
            )
            SELECT DISTINCT
                    PHParent.FK_ProductHierarchyLevelID + 1 ,
                    PHParent.PK_ProductHierarchyID ,
                    KEY1 ,
                    smtl.NODEGROUP + '_' + VALUE1
            FROM    SAP_MATINFO_TotalList AS smtl
                    INNER JOIN SAP_PriceHierarchy_TotalList PH ON smtl.Material = PH.Material
                    INNER JOIN ProductHierarchies PHParent ON PHParent.FK_ProductHierarchyLevelID = 20
                                                              AND smtl.NODEGROUP = PHParent.Node
            WHERE   PH.NAME = 'PROD_HIER'
                    AND KEY1 <> ''
                    AND NOT EXISTS ( SELECT *
                                     FROM   ProductHierarchies PHCurrent
                                     WHERE  PHCurrent.FK_ProductHierarchyLevelID = PHParent.FK_ProductHierarchyLevelID
                                            + 1
                                            AND PHCurrent.Node = PH.KEY1
                                            AND LEFT(PHCurrent.Label, 2) = smtl.NODEGROUP )

    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyLevelID ,
              FK_ProductHierarchyParentID ,
              Node ,
              Label 
            )
            SELECT DISTINCT
                    PHParent.FK_ProductHierarchyLevelID + 1 ,
                    PHParent.PK_ProductHierarchyID ,
                    KEY2 ,
                    MI.NODEGROUP + '_' + VALUE2
            FROM    SAP_MATINFO_TotalList MI
                    INNER JOIN SAP_PriceHierarchy_TotalList PH ON MI.Material = PH.Material
                    INNER JOIN ProductHierarchies PHParent ON PHParent.FK_ProductHierarchyLevelID = 21
                                                              AND PH.KEY1 = PHParent.Node
                                                              AND LEFT(PHParent.Label,
                                                              2) = MI.NODEGROUP
            WHERE   PH.NAME = 'PROD_HIER'
                    AND KEY2 <> ''
                    AND NOT EXISTS ( SELECT *
                                     FROM   ProductHierarchies PHCurrent
                                     WHERE  PHCurrent.FK_ProductHierarchyLevelID = PHParent.FK_ProductHierarchyLevelID
                                            + 1
                                            AND PHCurrent.Node = PH.KEY2
                                            AND LEFT(PHCurrent.Label, 2) = MI.NODEGROUP )

    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyLevelID ,
              FK_ProductHierarchyParentID ,
              Node ,
              Label 
            )
            SELECT DISTINCT
                    PHParent.FK_ProductHierarchyLevelID + 1 ,
                    PHParent.PK_ProductHierarchyID ,
                    KEY3 ,
                    MI.NODEGROUP + '_' + VALUE3
            FROM    SAP_MATINFO_TotalList MI
                    INNER JOIN SAP_PriceHierarchy_TotalList PH ON MI.Material = PH.Material
                    INNER JOIN ProductHierarchies PHParent ON PHParent.FK_ProductHierarchyLevelID = 22
                                                              AND PH.KEY2 = PHParent.Node
                                                              AND LEFT(PHParent.Label,
                                                              2) = MI.NODEGROUP
            WHERE   PH.NAME = 'PROD_HIER'
                    AND KEY3 <> ''
                    AND NOT EXISTS ( SELECT *
                                     FROM   ProductHierarchies PHCurrent
                                     WHERE  PHCurrent.FK_ProductHierarchyLevelID = PHParent.FK_ProductHierarchyLevelID
                                            + 1
                                            AND PHCurrent.Node = PH.KEY3
                                            AND LEFT(PHCurrent.Label, 2) = MI.NODEGROUP )

    UPDATE  PH1
    SET     FK_ProductHierarchyParentID = PHNew.PK_ProductHierarchyID
    FROM    SAP_MATINFO_TotalList MI
            INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                         AND Active = 1
            INNER JOIN Products P ON PK_ProductID = CC.FK_ProductID
            INNER JOIN SAP_PriceHierarchy_TotalList PH ON MI.Material = PH.Material
            INNER JOIN ProductHierarchies PH1 ON PK_ProductID = PH1.FK_ProductID
            INNER JOIN ProductHierarchies PH2 ON PH2.PK_ProductHierarchyID = PH1.FK_ProductHierarchyParentID
            INNER JOIN ProductHierarchies PHNew ON PH.KEY3 = PHNew.Node
                                                   AND LEFT(PHNew.Label, 2) = MI.NodeGroup
    WHERE   PH.NAME = 'PROD_HIER'
            AND PH2.FK_ProductHierarchyLevelID = 23
            AND PH2.PK_ProductHierarchyID <> PHNew.PK_ProductHierarchyID

    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyParentID ,
              FK_ProductID 
            )
            SELECT  PHParent.PK_ProductHierarchyID ,
                    PK_ProductID
            FROM    SAP_MATINFO_TotalList MI
                    INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                                 AND Active = 1
                    INNER JOIN Products P ON PK_ProductID = CC.FK_ProductID
                    INNER JOIN SAP_PriceHierarchy_TotalList PH ON MI.Material = PH.Material
                    INNER JOIN ProductHierarchies PHParent ON PHParent.FK_ProductHierarchyLevelID = 23
                                                              AND PH.KEY3 = PHParent.Node
                                                              AND LEFT(PHParent.Label,
                                                              2) = MI.NODEGROUP
                    INNER JOIN ProductHierarchies PHParent2 ON PHParent2.PK_ProductHierarchyID = PHParent.FK_ProductHierarchyParentID
                    INNER JOIN ProductHierarchies PHParent3 ON PHParent3.PK_ProductHierarchyID = PHParent2.FK_ProductHierarchyParentID
                    INNER JOIN ProductHierarchies PHParent4 ON PHParent4.PK_ProductHierarchyID = PHParent3.FK_ProductHierarchyParentID
                                                              AND NODEGROUP = PHParent4.Node
            WHERE   PH.NAME = 'PROD_HIER'
                    AND NOT EXISTS ( SELECT *
                                     FROM   ProductHierarchies PHCurrent
                                     WHERE  PHCurrent.FK_ProductHierarchyParentID = PHParent.PK_ProductHierarchyID
                                            AND PHCurrent.FK_ProductID = P.PK_ProductID )


----------------------------------------------------------------------
--                  Update Category Hierarchy                       --
----------------------------------------------------------------------
    PRINT 'Update Category Hierarchy'
    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyLevelID ,
              FK_ProductHierarchyParentID ,
              Node ,
              Label 
            )
            SELECT DISTINCT
                    PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2 ,
                    MAX(CName.Value2)
            FROM    SAP_MATINFO_TotalList MI
                    INNER JOIN SAP_Characteristics_TotalList CNode ON MI.Material = CNode.Material
                                                              AND CNode.Name = 'Z1_VNG_PROD_HIER_L1'
                    INNER JOIN SAP_Characteristics_TotalList CName ON MI.Material = CName.Material
                                                              AND CName.Name = 'Z1_VNG_PROD_HIER_DESC_L1'
                    INNER JOIN ProductHierarchyLevels PHL ON PHL.Node = CNode.Value1
                    INNER JOIN ProductHierarchies PH ON PHL.PK_ProductHierarchyLevelID
                                                        - 1 = PH.FK_ProductHierarchyLevelID
                                                        AND PH.Node = 'Category1'
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   ProductHierarchies PHCurrent
                                 WHERE  FK_ProductHierarchyLevelID = PK_ProductHierarchyLevelID
                                        AND PHCurrent.Node = CNode.Value2 )
            GROUP BY PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2

    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyLevelID ,
              FK_ProductHierarchyParentID ,
              Node ,
              Label 
            )
            SELECT DISTINCT
                    PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2 ,
                    MAX(CName.Value2)
            FROM    SAP_MATINFO_TotalList MI
                    INNER JOIN SAP_Characteristics_TotalList CNode ON MI.Material = CNode.Material
                                                              AND CNode.Name = 'Z1_VNG_PROD_HIER_L2'
                    INNER JOIN SAP_Characteristics_TotalList CName ON MI.Material = CName.Material
                                                              AND CName.Name = 'Z1_VNG_PROD_HIER_DESC_L2'
                    INNER JOIN SAP_Characteristics_TotalList CNodeParent ON MI.Material = CNodeParent.Material
                                                              AND CNodeParent.Name = 'Z1_VNG_PROD_HIER_L1'
                    INNER JOIN ProductHierarchyLevels PHL ON PHL.Node = CNode.Value1
                    INNER JOIN ProductHierarchies PH ON PHL.PK_ProductHierarchyLevelID
                                                        - 1 = PH.FK_ProductHierarchyLevelID
                                                        AND CNodeParent.Value2 = PH.Node
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   ProductHierarchies PHCurrent
                                 WHERE  FK_ProductHierarchyLevelID = PK_ProductHierarchyLevelID
                                        AND PHCurrent.Node = CNode.Value2 )
            GROUP BY PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2

    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyLevelID ,
              FK_ProductHierarchyParentID ,
              Node ,
              Label 
            )
            SELECT DISTINCT
                    PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2 ,
                    MAX(CName.Value2)
            FROM    SAP_MATINFO_TotalList MI
                    INNER JOIN SAP_Characteristics_TotalList CNode ON MI.Material = CNode.Material
                                                              AND CNode.Name = 'Z1_VNG_PROD_HIER_L3'
                    INNER JOIN SAP_Characteristics_TotalList CName ON MI.Material = CName.Material
                                                              AND CName.Name = 'Z1_VNG_PROD_HIER_DESC_L3'
                    INNER JOIN SAP_Characteristics_TotalList CNodeParent ON MI.Material = CNodeParent.Material
                                                              AND CNodeParent.Name = 'Z1_VNG_PROD_HIER_L2'
                    INNER JOIN ProductHierarchyLevels PHL ON PHL.Node = CNode.Value1
                    INNER JOIN ProductHierarchies PH ON PHL.PK_ProductHierarchyLevelID
                                                        - 1 = PH.FK_ProductHierarchyLevelID
                                                        AND CNodeParent.Value2 = PH.Node
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   ProductHierarchies PHCurrent
                                 WHERE  FK_ProductHierarchyLevelID = PK_ProductHierarchyLevelID
                                        AND PHCurrent.Node = CNode.Value2 )
            GROUP BY PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2

    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyLevelID ,
              FK_ProductHierarchyParentID ,
              Node ,
              Label 
            )
            SELECT DISTINCT
                    PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2 ,
                    MAX(CName.Value2)
            FROM    SAP_MATINFO_TotalList MI
                    INNER JOIN SAP_Characteristics_TotalList CNode ON MI.Material = CNode.Material
                                                              AND CNode.Name = 'Z1_VNG_PROD_HIER_L4'
                    INNER JOIN SAP_Characteristics_TotalList CName ON MI.Material = CName.Material
                                                              AND CName.Name = 'Z1_VNG_PROD_HIER_DESC_L4'
                    INNER JOIN SAP_Characteristics_TotalList CNodeParent ON MI.Material = CNodeParent.Material
                                                              AND CNodeParent.Name = 'Z1_VNG_PROD_HIER_L3'
                    INNER JOIN ProductHierarchyLevels PHL ON PHL.Node = CNode.Value1
                    INNER JOIN ProductHierarchies PH ON PHL.PK_ProductHierarchyLevelID
                                                        - 1 = PH.FK_ProductHierarchyLevelID
                                                        AND CNodeParent.Value2 = PH.Node
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   ProductHierarchies PHCurrent
                                 WHERE  FK_ProductHierarchyLevelID = PK_ProductHierarchyLevelID
                                        AND PHCurrent.Node = CNode.Value2 )
            GROUP BY PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2

    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyLevelID ,
              FK_ProductHierarchyParentID ,
              Node ,
              Label 
            )
            SELECT DISTINCT
                    PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2 ,
                    MAX(CName.Value2)
            FROM    SAP_MATINFO_TotalList MI
                    INNER JOIN SAP_Characteristics_TotalList CNode ON MI.Material = CNode.Material
                                                              AND CNode.Name = 'Z1_VNG_PROD_HIER_L5'
                    INNER JOIN SAP_Characteristics_TotalList CName ON MI.Material = CName.Material
                                                              AND CName.Name = 'Z1_VNG_PROD_HIER_DESC_L5'
                    INNER JOIN SAP_Characteristics_TotalList CNodeParent ON MI.Material = CNodeParent.Material
                                                              AND CNodeParent.Name = 'Z1_VNG_PROD_HIER_L4'
                    INNER JOIN ProductHierarchyLevels PHL ON PHL.Node = CNode.Value1
                    INNER JOIN ProductHierarchies PH ON PHL.PK_ProductHierarchyLevelID
                                                        - 1 = PH.FK_ProductHierarchyLevelID
                                                        AND CNodeParent.Value2 = PH.Node
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   ProductHierarchies PHCurrent
                                 WHERE  FK_ProductHierarchyLevelID = PK_ProductHierarchyLevelID
                                        AND PHCurrent.Node = CNode.Value2 )
            GROUP BY PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2

    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyLevelID ,
              FK_ProductHierarchyParentID ,
              Node ,
              Label 
            )
            SELECT DISTINCT
                    PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2 ,
                    MAX(CName.Value2)
            FROM    SAP_MATINFO_TotalList MI
                    INNER JOIN SAP_Characteristics_TotalList CNode ON MI.Material = CNode.Material
                                                              AND CNode.Name = 'Z1_VNG_PROD_HIER_L6'
                    INNER JOIN SAP_Characteristics_TotalList CName ON MI.Material = CName.Material
                                                              AND CName.Name = 'Z1_VNG_PROD_HIER_DESC_L6'
                    INNER JOIN SAP_Characteristics_TotalList CNodeParent ON MI.Material = CNodeParent.Material
                                                              AND CNodeParent.Name = 'Z1_VNG_PROD_HIER_L5'
                    INNER JOIN ProductHierarchyLevels PHL ON PHL.Node = CNode.Value1
                    INNER JOIN ProductHierarchies PH ON PHL.PK_ProductHierarchyLevelID
                                                        - 1 = PH.FK_ProductHierarchyLevelID
                                                        AND CNodeParent.Value2 = PH.Node
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   ProductHierarchies PHCurrent
                                 WHERE  FK_ProductHierarchyLevelID = PK_ProductHierarchyLevelID
                                        AND PHCurrent.Node = CNode.Value2 )
            GROUP BY PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2

    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyLevelID ,
              FK_ProductHierarchyParentID ,
              Node ,
              Label 
            )
            SELECT DISTINCT
                    PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2 ,
                    MAX(CName.Value2)
            FROM    SAP_MATINFO_TotalList MI
                    INNER JOIN SAP_Characteristics_TotalList CNode ON MI.Material = CNode.Material
                                                              AND CNode.Name = 'Z1_VNG_PROD_HIER_L7'
                    INNER JOIN SAP_Characteristics_TotalList CName ON MI.Material = CName.Material
                                                              AND CName.Name = 'Z1_VNG_PROD_HIER_DESC_L7'
                    INNER JOIN SAP_Characteristics_TotalList CNodeParent ON MI.Material = CNodeParent.Material
                                                              AND CNodeParent.Name = 'Z1_VNG_PROD_HIER_L6'
                    INNER JOIN ProductHierarchyLevels PHL ON PHL.Node = CNode.Value1
                    INNER JOIN ProductHierarchies PH ON PHL.PK_ProductHierarchyLevelID
                                                        - 1 = PH.FK_ProductHierarchyLevelID
                                                        AND CNodeParent.Value2 = PH.Node
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   ProductHierarchies PHCurrent
                                 WHERE  FK_ProductHierarchyLevelID = PK_ProductHierarchyLevelID
                                        AND PHCurrent.Node = CNode.Value2 )
            GROUP BY PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2

    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyLevelID ,
              FK_ProductHierarchyParentID ,
              Node ,
              Label 
            )
            SELECT DISTINCT
                    PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2 ,
                    MAX(CName.Value2)
            FROM    SAP_MATINFO_TotalList MI
                    INNER JOIN SAP_Characteristics_TotalList CNode ON MI.Material = CNode.Material
                                                              AND CNode.Name = 'Z1_VNG_PROD_HIER_L8'
                    INNER JOIN SAP_Characteristics_TotalList CName ON MI.Material = CName.Material
                                                              AND CName.Name = 'Z1_VNG_PROD_HIER_DESC_L8'
                    INNER JOIN SAP_Characteristics_TotalList CNodeParent ON MI.Material = CNodeParent.Material
                                                              AND CNodeParent.Name = 'Z1_VNG_PROD_HIER_L7'
                    INNER JOIN ProductHierarchyLevels PHL ON PHL.Node = CNode.Value1
                    INNER JOIN ProductHierarchies PH ON PHL.PK_ProductHierarchyLevelID
                                                        - 1 = PH.FK_ProductHierarchyLevelID
                                                        AND CNodeParent.Value2 = PH.Node
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   ProductHierarchies PHCurrent
                                 WHERE  FK_ProductHierarchyLevelID = PK_ProductHierarchyLevelID
                                        AND PHCurrent.Node = CNode.Value2 )
            GROUP BY PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2

    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyLevelID ,
              FK_ProductHierarchyParentID ,
              Node ,
              Label 
            )
            SELECT DISTINCT
                    PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2 ,
                    MAX(CName.Value2)
            FROM    SAP_MATINFO_TotalList MI
                    INNER JOIN SAP_Characteristics_TotalList CNode ON MI.Material = CNode.Material
                                                              AND CNode.Name = 'Z1_VNG_PROD_HIER_L9'
                    INNER JOIN SAP_Characteristics_TotalList CName ON MI.Material = CName.Material
                                                              AND CName.Name = 'Z1_VNG_PROD_HIER_DESC_L9'
                    INNER JOIN SAP_Characteristics_TotalList CNodeParent ON MI.Material = CNodeParent.Material
                                                              AND CNodeParent.Name = 'Z1_VNG_PROD_HIER_L8'
                    INNER JOIN ProductHierarchyLevels PHL ON PHL.Node = CNode.Value1
                    INNER JOIN ProductHierarchies PH ON PHL.PK_ProductHierarchyLevelID
                                                        - 1 = PH.FK_ProductHierarchyLevelID
                                                        AND CNodeParent.Value2 = PH.Node
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   ProductHierarchies PHCurrent
                                 WHERE  FK_ProductHierarchyLevelID = PK_ProductHierarchyLevelID
                                        AND PHCurrent.Node = CNode.Value2 )
            GROUP BY PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2

    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyLevelID ,
              FK_ProductHierarchyParentID ,
              Node ,
              Label 
            )
            SELECT DISTINCT
                    PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2 ,
                    MAX(CName.Value2)
            FROM    SAP_MATINFO_TotalList MI
                    INNER JOIN SAP_Characteristics_TotalList CNode ON MI.Material = CNode.Material
                                                              AND CNode.Name = 'Z1_VNG_PROD_HIER_L10'
                    INNER JOIN SAP_Characteristics_TotalList CName ON MI.Material = CName.Material
                                                              AND CName.Name = 'Z1_VNG_PROD_HIER_DESC_L10'
                    INNER JOIN SAP_Characteristics_TotalList CNodeParent ON MI.Material = CNodeParent.Material
                                                              AND CNodeParent.Name = 'Z1_VNG_PROD_HIER_L9'
                    INNER JOIN ProductHierarchyLevels PHL ON PHL.Node = CNode.Value1
                    INNER JOIN ProductHierarchies PH ON PHL.PK_ProductHierarchyLevelID
                                                        - 1 = PH.FK_ProductHierarchyLevelID
                                                        AND CNodeParent.Value2 = PH.Node
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   ProductHierarchies PHCurrent
                                 WHERE  FK_ProductHierarchyLevelID = PK_ProductHierarchyLevelID
                                        AND PHCurrent.Node = CNode.Value2 )
            GROUP BY PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2

    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyLevelID ,
              FK_ProductHierarchyParentID ,
              Node ,
              Label 
            )
            SELECT DISTINCT
                    PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2 ,
                    MAX(CName.Value2)
            FROM    SAP_MATINFO_TotalList MI
                    INNER JOIN SAP_Characteristics_TotalList CNode ON MI.Material = CNode.Material
                                                              AND CNode.Name = 'Z1_VNG_PROD_HIER_L11'
                    INNER JOIN SAP_Characteristics_TotalList CName ON MI.Material = CName.Material
                                                              AND CName.Name = 'Z1_VNG_PROD_HIER_DESC_L11'
                    INNER JOIN SAP_Characteristics_TotalList CNodeParent ON MI.Material = CNodeParent.Material
                                                              AND CNodeParent.Name = 'Z1_VNG_PROD_HIER_L10'
                    INNER JOIN ProductHierarchyLevels PHL ON PHL.Node = CNode.Value1
                    INNER JOIN ProductHierarchies PH ON PHL.PK_ProductHierarchyLevelID
                                                        - 1 = PH.FK_ProductHierarchyLevelID
                                                        AND CNodeParent.Value2 = PH.Node
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   ProductHierarchies PHCurrent
                                 WHERE  FK_ProductHierarchyLevelID = PK_ProductHierarchyLevelID
                                        AND PHCurrent.Node = CNode.Value2 )
            GROUP BY PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2

    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyLevelID ,
              FK_ProductHierarchyParentID ,
              Node ,
              Label 
            )
            SELECT DISTINCT
                    PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2 ,
                    MAX(CName.Value2)
            FROM    SAP_MATINFO_TotalList MI
                    INNER JOIN SAP_Characteristics_TotalList CNode ON MI.Material = CNode.Material
                                                              AND CNode.Name = 'Z1_VNG_PROD_HIER_L12'
                    INNER JOIN SAP_Characteristics_TotalList CName ON MI.Material = CName.Material
                                                              AND CName.Name = 'Z1_VNG_PROD_HIER_DESC_L12'
                    INNER JOIN SAP_Characteristics_TotalList CNodeParent ON MI.Material = CNodeParent.Material
                                                              AND CNodeParent.Name = 'Z1_VNG_PROD_HIER_L11'
                    INNER JOIN ProductHierarchyLevels PHL ON PHL.Node = CNode.Value1
                    INNER JOIN ProductHierarchies PH ON PHL.PK_ProductHierarchyLevelID
                                                        - 1 = PH.FK_ProductHierarchyLevelID
                                                        AND CNodeParent.Value2 = PH.Node
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   ProductHierarchies PHCurrent
                                 WHERE  FK_ProductHierarchyLevelID = PK_ProductHierarchyLevelID
                                        AND PHCurrent.Node = CNode.Value2 )
            GROUP BY PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2

    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyLevelID ,
              FK_ProductHierarchyParentID ,
              Node ,
              Label 
            )
            SELECT DISTINCT
                    PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2 ,
                    MAX(CName.Value2)
            FROM    SAP_MATINFO_TotalList MI
                    INNER JOIN CommonCodes AS cc ON CommonCode = CAST(MI.Material AS BIGINT)
                    INNER JOIN SAP_Characteristics_TotalList CNode ON MI.Material = CNode.Material
                                                              AND CNode.Name = 'Z1_VNG_PROD_HIER_L13'
                    INNER JOIN SAP_Characteristics_TotalList CName ON MI.Material = CName.Material
                                                              AND CName.Name = 'Z1_VNG_PROD_HIER_DESC_L13'
                    INNER JOIN SAP_Characteristics_TotalList CNodeParent ON MI.Material = CNodeParent.Material
                                                              AND CNodeParent.Name = 'Z1_VNG_PROD_HIER_L12'
                    INNER JOIN ProductHierarchyLevels PHL ON PHL.Node = CNode.Value1
                    INNER JOIN ProductHierarchies PH ON PHL.PK_ProductHierarchyLevelID
                                                        - 1 = PH.FK_ProductHierarchyLevelID
                                                        AND CNodeParent.Value2 = PH.Node
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   ProductHierarchies PHCurrent
                                 WHERE  FK_ProductHierarchyLevelID = PK_ProductHierarchyLevelID
                                        AND PHCurrent.Node = CNode.Value2 )
            GROUP BY PK_ProductHierarchyLevelID ,
                    PK_ProductHierarchyID ,
                    CNode.Value2

    UPDATE  ph
    SET     FK_ProductHierarchyParentID = ph3.PK_ProductHierarchyID
    FROM    SAP_MATINFO_TotalList MI
            INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                         AND Active = 1
            INNER JOIN Products P ON P.PK_ProductID = CC.FK_ProductID
            INNER JOIN SAP_Characteristics_TotalList CNodeParent ON MI.MATERIAL = CNodeParent.Material
                                                              AND CNodeParent.Name = 'Z1_VNG_PROD_HIER_L13'
            INNER JOIN dbo.ProductHierarchies AS ph ON PK_ProductID = ph.FK_ProductID
            INNER JOIN dbo.ProductHierarchies AS ph2 ON ph.FK_ProductHierarchyParentID = ph2.PK_ProductHierarchyID
                                                        AND ph2.FK_ProductHierarchyLevelID = 37
            INNER JOIN dbo.ProductHierarchies AS ph3 ON Value2 = ph3.Node
                                                        AND ph2.FK_ProductHierarchyLevelID = ph3.FK_ProductHierarchyLevelID
    WHERE   ph2.PK_ProductHierarchyID <> ph3.PK_ProductHierarchyID

    INSERT  INTO ProductHierarchies
            ( FK_ProductHierarchyParentID ,
              FK_ProductID 
            )
            SELECT DISTINCT
                    PK_ProductHierarchyID ,
                    PK_ProductID
            FROM    SAP_MATINFO MI
                    INNER JOIN CommonCodes CC ON CAST(CAST(MATERIAL AS BIGINT) AS VARCHAR) = CC.CommonCode
                                                 AND Active = 1
                    INNER JOIN Products P ON P.PK_ProductID = CC.FK_ProductID
                    INNER JOIN SAP_Characteristics_TotalList CNodeParent ON MI.MATERIAL = CNodeParent.Material
                                                              AND CNodeParent.Name = 'Z1_VNG_PROD_HIER_L13'
                    INNER JOIN ProductHierarchyLevels PHL ON PHL.Node = CNodeParent.Value1
                    INNER JOIN ProductHierarchies PH ON PHL.PK_ProductHierarchyLevelID = PH.FK_ProductHierarchyLevelID
                                                        AND CNodeParent.Value2 = PH.Node
            WHERE   NOT EXISTS ( SELECT *
                                 FROM   ProductHierarchies PHCurrent
                                 WHERE  PHCurrent.FK_ProductHierarchyParentID = PH.PK_ProductHierarchyID
                                        AND PHCurrent.FK_ProductID = PK_ProductID )

    UPDATE  SAP_FileImport
    SET     IsHandled = 1 ,
            HandledDate = GETDATE()
    WHERE   IsHandled = 0
            AND FK_FileTypeID IN ( 1, 2 )
