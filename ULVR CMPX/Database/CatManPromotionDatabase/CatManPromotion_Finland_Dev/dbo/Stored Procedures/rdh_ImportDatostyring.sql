CREATE PROCEDURE rdh_ImportDatostyring

AS

BEGIN TRAN

BEGIN TRY

--Get alle the DateControl from PriceHierarchy
    SELECT  sph.FK_FileImportID,
            sph.MATERIAL,
            cc.FK_ProductID,
            sph.KEY1,
            sph.KEY2,
            sph.KEY3,
            sph.VALUE1 [DUforTU],
            sph2.VALUE1 [Current],
            SAP_FileDate,
            ROW_NUMBER() OVER ( PARTITION BY cc.FK_ProductID ORDER BY SAP_FileDate ) RowNumber
    INTO    #tempPriceHierarchy
    FROm    dbo.SAP_PriceHierarchy as sph
            INNER JOIN dbo.SAP_FileImport as sfi ON PK_FileImportID = sph.FK_FileImportID
            INNER JOIN dbo.SAP_Files as sf on PK_SAP_FileID = FK_SAP_FileID
            INNER JOIN dbo.SAP_PriceHierarchy as sph2 ON sph.FK_FileImportID = sph2.FK_FileImportID
            INNER JOIN dbo.CommonCodes as cc ON CommonCode = CAST(sph.MATERIAL as bigint)
            INNER JOIN ( SELECT PK_CommonCodeID
                         FROM   dbo.CommonCodes as cc
                                INNER JOIN ( SELECT FK_ProductID
                                             FROM   dbo.CommonCodes as cc
                                             GROUP BY FK_ProductID
                                             HAVING COUNT(*) > 1
                                           ) Sub ON cc.FK_ProductID = Sub.FK_ProductID
                       ) Sub ON cc.PK_CommonCodeID = Sub.PK_CommonCodeID
            INNER JOIN dbo.CommonCodes as cc2 ON cc2.CommonCode = CAST(sph2.VALUE1 as bigint)
    WHERE   sph.NAME = 'DUs_for_TUs'
            AND sph2.NAME = 'CURRENT_DU_FOR_TU'
            AND cc.FK_ProductID = cc2.FK_ProductID
    ORDER BY cc.FK_ProductID,
            SAP_FileDate

--Delete lines where there is no actual change
    DELETE  FROM t2
    FROM    #tempPriceHierarchy as t
            INNER JOIN #tempPriceHierarchy as t2 ON t.FK_ProductID = t2.FK_ProductID
                                                    AND t.RowNumber = t2.RowNumber
                                                    - 1
                                                    AND t.KEY1 = t2.KEY1
                                                    AND t.KEY2 = t2.KEY2
                                                    AND t.KEY3 = t2.KEY3
                                                    AND t.DUforTU = t2.DUforTU
                                                    AND t.[Current] = t2.[Current]

--Create a list of all the dates with possible datecontrol
    SELECT  FK_ProductID,
            CASE WHEN CONVERT(datetime, KEY2, 112) <= '2012-01-01'
                 THEN '2012-01-01'
                 ELSE CONVERT(datetime, KEY2, 112)
            END Period
    INTO    #tempPeriods
    FROM    #tempPriceHierarchy as t
    UNION
    SELECT  FK_ProductID,
            CONVERT(datetime, KEY3, 112) + 1 Period
    FROM    #tempPriceHierarchy as t
    WHERE   CONVERT(datetime, KEY3, 112) BETWEEN '2012-01-01'
                                         AND     '2012-12-31'
    UNION
    SELECT  FK_ProductID,
            CASE WHEN CAST(FLOOR(CAST(SAP_FileDate as float)) as datetime) <= '2012-01-01'
                 THEN '2012-01-01'
                 ELSE CAST(FLOOR(CAST(SAP_FileDate as float)) as datetime)
            END Period
    FROM    #tempPriceHierarchy as t

--Create a list of all the possible combinations of products and periods.
--The list will be ordered so a new file will overrule an old file - and CURRENT_DU_FOR_TU will overrule DUs_for_TUs
    SELECT  FK_ProductID,
            CASE WHEN CAST(FLOOR(CAST(SAP_FileDate as float)) as datetime) <= '2012-01-01'
                 THEN '2012-01-01'
                 ELSE CAST(FLOOR(CAST(SAP_FileDate as float)) as datetime)
            END PeriodFrom,
            CASE WHEN CAST(FLOOR(CAST(SAP_FileDate as float)) as datetime) < CONVERT(datetime, KEY2, 112)
                 THEN CONVERT(datetime, KEY2, 112) - 1
                 WHEN CAST(FLOOR(CAST(SAP_FileDate as float)) as datetime) >= CONVERT(datetime, KEY3, 112)
                 THEN '2099-12-31'
                 ELSE CAST(FLOOR(CAST(SAP_FileDate as float)) as datetime)
            END PeriodTo,
            [Current] CommonCode,
            REPLICATE('0', 10 - LEN(CAST(RowNumber as nvarchar(10))))
            + CAST(RowNumber as nvarchar(10)) + '1' SortOrder
    INTO    #tempProducts
    FROM    #tempPriceHierarchy as t
    UNION
    SELECT  FK_ProductID,
            CASE WHEN CONVERT(datetime, KEY2, 112) <= '2012-01-01'
                 THEN '2012-01-01'
                 ELSE CONVERT(datetime, KEY2, 112)
            END PeriodFrom,
            CASE WHEN CONVERT(datetime, KEY3, 112) >= '2099-12-31'
                 THEN '2099-12-31'
                 ELSE CONVERT(datetime, KEY3, 112)
            END PeriodTo,
            DUforTU CommonCode,
            REPLICATE('0', 10 - LEN(CAST(RowNumber as nvarchar(10))))
            + CAST(RowNumber as nvarchar(10)) + '2' SortOrder
    FROM    #tempPriceHierarchy as t

--Create a list of the most valid Code (according to the sortorder above) in a given date
    SELECT  ROW_NUMBER() OVER ( PARTITION BY Sub.FK_ProductID ORDER BY Sub.Period ) RowNumber,
            Sub.FK_ProductID,
            CommonCode,
            Sub.Period PeriodFrom,
            CAST(Null as datetime) PeriodTo
    INTO    #tempDateControl
    FROM    #tempProducts as tp
            INNER JOIN ( SELECT tp.FK_ProductID,
                                Period,
                                MAX(SortOrder) SortOrder
                         FROM   #tempPeriods as tp
                                INNER JOIN #tempProducts as tp2 ON tp.FK_ProductID = tp2.FK_ProductID
                                                                   AND Period BETWEEN PeriodFrom AND PeriodTo
                         GROUP BY tp.FK_ProductID,
                                Period
                       ) Sub ON tp.FK_ProductID = Sub.FK_ProductID
                                AND Sub.SortOrder = tp.SortOrder

--Delete codes from the list which does not belong to the same product
    DELETE  FROM tdc
    FROM    #tempDateControl as tdc
            INNER JOIN dbo.CommonCodes as cc ON cc.CommonCode = CAST(tdc.CommonCode as bigint)
    WHERE   cc.FK_ProductID <> tdc.FK_ProductID

--Because the rownumber is important in order to know the next line the column is updated after the delete
    UPDATE  tdc2
    SET     RowNumber = NewRowNumber
    FROM    ( SELECT    ROW_NUMBER() OVER ( PARTITION BY FK_ProductID ORDER BY RowNumber ) NewRowNumber,
                        RowNumber,
                        FK_ProductID
              FROM      #tempDateControl as tdc
            ) Sub
            INNER JOIN #tempDateControl as tdc2 ON Sub.FK_ProductID = tdc2.FK_ProductID
                                                   AND Sub.RowNumber = tdc2.RowNumber
    WHERE   tdc2.RowNumber <> NewRowNumber

--Delete dates where the is no actual change of 
    DELETE  FROM tdc2
    FROM    #tempDateControl as tdc
            INNER JOIN #tempDateControl as tdc2 ON tdc.FK_ProductID = tdc2.FK_ProductID
                                                   AND tdc.RowNumber = tdc2.RowNumber
                                                   - 1
                                                   AND tdc.CommonCode = tdc2.CommonCode

--Because the rownumber is important in order to know the next line the column is updated after the delete
    UPDATE  tdc2
    SET     RowNumber = NewRowNumber
    FROM    ( SELECT    ROW_NUMBER() OVER ( PARTITION BY FK_ProductID ORDER BY RowNumber ) NewRowNumber,
                        RowNumber,
                        FK_ProductID
              FROM      #tempDateControl as tdc
            ) Sub
            INNER JOIN #tempDateControl as tdc2 ON Sub.FK_ProductID = tdc2.FK_ProductID
                                                   AND Sub.RowNumber = tdc2.RowNumber
    WHERE   tdc2.RowNumber <> NewRowNumber

    UPDATE  tdc
    SET     PeriodTo = ISNULL(tdc2.PeriodFrom - 1, '2099-12-31')
    FROM    #tempDateControl as tdc
            LEFT JOIN #tempDateControl as tdc2 ON tdc.FK_ProductID = tdc2.FK_ProductID
                                                  AND tdc.RowNumber = tdc2.RowNumber
                                                  - 1

--577
    DELETE  FROM ccp
    FROM    dbo.CommonCodes as cc
            INNER JOIN dbo.CommonCodePeriod as ccp ON cc.PK_CommonCodeID = ccp.FK_CommonCodeID
            INNER JOIN ( SELECT FK_ProductID,
                                MIN(PeriodFrom) PeriodFrom
                         FROM   #tempDateControl as tdc
                         GROUP BY FK_ProductID
                       ) Sub ON cc.FK_ProductID = Sub.FK_ProductID
                                AND ccp.PeriodFrom >= Sub.PeriodFrom

    UPDATE  ccp
    SET     PeriodTo = Sub.PeriodFrom - 1
    FROM    dbo.CommonCodes as cc
            INNER JOIN dbo.CommonCodePeriod as ccp ON cc.PK_CommonCodeID = ccp.FK_CommonCodeID
            INNER JOIN ( SELECT FK_ProductID,
                                MIN(PeriodFrom) PeriodFrom
                         FROM   #tempDateControl as tdc
                         GROUP BY FK_ProductID
                       ) Sub ON cc.FK_ProductID = Sub.FK_ProductID
                                AND ccp.PeriodTo >= Sub.PeriodFrom

    INSERT  INTO dbo.CommonCodePeriod
            (
              FK_CommonCodeID,
              PeriodFrom,
              PeriodTo
            )
            SELECT  PK_CommonCodeID,
                    tdc.PeriodFrom,
                    tdc.PeriodTo
            FROM    #tempDateControl as tdc
                    INNER JOIN dbo.CommonCodes as cc ON cc.CommonCode = CAST(tdc.CommonCode as bigint)
	
    DROP TABLE #tempDateControl
    DROP TABLE #tempPeriods
    DROP TABLE #tempPriceHierarchy
    DROP TABLE #tempProducts

END TRY
BEGIN CATCH
		
    print 'catch'

    DECLARE @ErrorMessage NVARCHAR(4000) ;
    DECLARE @ErrorSeverity INT ;
    DECLARE @ErrorState INT ;

    SELECT  @ErrorMessage = 'Error in trigger: ' + object_name(@@procid)
            + ', Action canceld due to error: ' + ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE() ;

		-- Use RAISERROR inside the CATCH block to return error
		-- information about the original error that caused
		-- execution to jump to the CATCH block.
    RAISERROR ( @ErrorMessage, -- Message text.
        @ErrorSeverity, -- Severity.
        @ErrorState -- State.
				   ) ;


    ROLLBACK TRAN

END CATCH

COMMIT TRAN
