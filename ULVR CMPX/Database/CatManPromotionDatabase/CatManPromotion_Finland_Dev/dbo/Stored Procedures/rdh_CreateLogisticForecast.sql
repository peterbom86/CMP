CREATE PROC [dbo].[rdh_CreateLogisticForecast]
AS 
    DECLARE @version INT
    DECLARE @PeriodFrom DATETIME
    DECLARE @thisweek INT
    DECLARE @newid INT
	DECLARE @Startdate AS DATETIME
	DECLARE @Dayspan AS INT
	DECLARE @DaySpanIceCream INT
	DECLARE @Now DATETIME

	SET @Now = CAST(FLOOR(CAST(GETDATE() as float)) as datetime) 

	SELECT @DaySpan = Dayspan-7, @DaySpanIceCream = DaySpan_Icecream-7, @StartDate = Startdate
	FROM dbo.APOConfiguration


    SELECT  @thisweek = Period
    FROM    Periods
    WHERE   Label = CAST(CAST(GETDATE() AS INT) AS DATETIME)

    SELECT  @PeriodFrom = CASE WHEN MIN(Label)- 27 <@Startdate THEN @Startdate-7 ELSE MIN(Label) END
    FROM    Periods
    WHERE   Period = @thisweek

    SELECT  @version = ISNULL(MAX(RIGHT(Label, LEN(Label) - 24)), 0) + 1
    FROM    LogisticForecast
    WHERE   Label LIKE '%' + CAST(@thisweek AS VARCHAR(6)) + '%'

    INSERT  INTO LogisticForecast
            ( Label ,
              PeriodFrom ,
              PeriodTo
            )
    VALUES  ( 'Load uge ' + CAST(@thisweek AS VARCHAR(6)) + ' version '
              + CAST(@version AS VARCHAR) ,
              @PeriodFrom + 7 ,
              @PeriodFrom + @Dayspan
            )

    SELECT  @newid = @@identity

    INSERT  INTO LogisticForecastLines
            ( FK_LogisticForecastID ,
              FK_CampaignID ,
              FK_ActivityID ,
              ActivityFrom ,
              ActivityTo ,
              FK_ActivityStatusID ,
              FK_ActivityLineID ,
              FK_SalesUnitID ,
              FK_ProductID ,
              CommonCode ,
              DeliveryDay ,
              FK_ChainID ,
              EstimatedVolumeSupplier ,
              PiecesPerZUN ,
              EstimatedVolumeZUN ,
              WeeklySplit,
			  FK_LogisticForecastTypeID
            )
            SELECT  @newid ,
                    PK_CampaignID ,
                    PK_ActivityID ,
                    ActivityFrom ,
                    ActivityTo ,
                    FK_ActivityStatusID ,
                    PK_ActivityLineID ,
                    PK_ProductID ,
                    ActivityLines.FK_ProductID ,
                    CommonCode ,
                    DeliveryDate ,
                    FK_ChainID ,
                    EstimatedVolumeSupplier ,
                    Pieces / PiecesPerConsumerUnit AS Pieces ,
                    0 ,
                    CASE WHEN SumValue = 0 THEN 0
                         ELSE Value / SumValue
                    END,
					1 /*Promotion Volume*/
            FROM    Campaigns
                    INNER JOIN Activities ON PK_CampaignID = FK_CampaignID
                    INNER JOIN ActivityLines ON PK_ActivityID = FK_ActivityID
                    INNER JOIN ActivityStatus ON PK_ActivityStatusID = FK_ActivityStatusID
                    INNER JOIN Products ON PK_ProductID = FK_SalesUnitID
                    INNER JOIN CommonCodes ON PK_ProductID = CommonCodes.FK_ProductID --AND Active = 1
                    INNER JOIN EANCodes ON PK_ProductID = ProductID
                                           AND FK_EANTypeID = 5
                    INNER JOIN ActivityDeliveries ON PK_ActivityID = ActivityDeliveries.FK_ActivityID
                    INNER JOIN ( SELECT FK_ActivityID ,
                                        SUM(Value) SumValue
                                 FROM   ActivityDeliveries
                                 GROUP BY FK_ActivityID
                               ) SumActivityDeliveries ON PK_ActivityID = SumActivityDeliveries.FK_ActivityID
                    INNER JOIN ActivityPurposes ON PK_ActivityPurposeID = FK_ActivityPurposeID
                    INNER JOIN CommonCodePeriod CCP ON PK_CommonCodeID = FK_CommonCodeID
                                                       AND CCP.PeriodFrom <= DeliveryDate
                                                       AND CCP.PeriodTo >= DeliveryDate
					LEFT JOIN dbo.vwCannibalisationproducts CP ON FK_SalesUnitID = CP.FK_ProductID AND CP.CategoryID = 5 /*ICE CREAM*/
            WHERE   IsValidForForecast = 1
                    AND IsValidForLogisticForecast = 1
                    AND DeliveryDate >= @PeriodFrom-35 /*INCLUDE DELIVERIES 5 WEEKS BACK FOR DIP CALCULATION:*/ 
                    AND DeliveryDate <= @now + CASE WHEN CP.CategoryID = 5 THEN @DaySpanIceCream ELSE @Dayspan END
                    AND EstimatedVolumeSupplier <> 0
                    and ExportAPO =1

    UPDATE  LFL
    SET     ValidForAPO = 1
    FROM    LogisticForecastLines LFL
            INNER JOIN Products ON PK_ProductID = LFL.FK_SalesUnitID
            INNER JOIN ProductHierarchies PH5 ON PH5.FK_ProductID = PK_ProductID
            INNER JOIN ProductHierarchies PH4 ON PH4.PK_ProductHierarchyID = PH5.FK_ProductHierarchyParentID
            INNER JOIN ProductHierarchies PH3 ON PH3.PK_ProductHierarchyID = PH4.FK_ProductHierarchyParentID
            INNER JOIN ProductHierarchies PH2 ON PH2.PK_ProductHierarchyID = PH3.FK_ProductHierarchyParentID
            INNER JOIN ProductHierarchies PH1 ON PH1.PK_ProductHierarchyID = PH2.FK_ProductHierarchyParentID
    WHERE   FK_LogisticForecastID = @newid
            AND PH1.FK_ProductHierarchyLevelID = 20 --AND PH1.Node NOT IN ('6G', '6I') Frisko skal være med igen


/*START OF BASELINE DIP CALCULATION*/

SELECT 1 AS PlusWeeks
INTO #PlusWeeks
UNION ALL SELECT 2
UNION ALL SELECT 3
UNION ALL SELECT 4
UNION ALL SELECT 5

/*FIND LAST DELIVERY */
SELECT 
	L.FK_LogisticForecastID, FK_ActivityID,FK_ActivityLineID, MAX(DeliveryDay) AS LastDelivery, SUM(L.EstimatedVolumeSupplier*L.WeeklySplit) Volume, AVG(L.PiecesPerZUN) PiecesPerZUN
INTO #TEMP
FROM 
	dbo.LogisticForecastLines L
	INNER JOIN dbo.Activities A ON A.PK_ActivityID = L.FK_ActivityID
WHERE
	L.ValidForAPO = 1 AND L.FK_LogisticForecastID = @newid
GROUP BY 
	L.FK_LogisticForecastID, FK_ActivityID,FK_ActivityLineID

/*CALCULATE THE BASELINE DIPS */
SELECT 
	T.FK_LogisticForecastID,
	T.FK_ActivityLineID,
	T.LastDelivery, 
	DATEADD(d,P.PlusWeeks*7, LastDelivery) BaselineDipDate, 
	CASE 
		WHEN P.PlusWeeks = 1 THEN -T.Volume * A.Plus1Week/100 
		WHEN P.PlusWeeks = 2 THEN -T.Volume * A.Plus2Weeks/100 
		WHEN P.PlusWeeks = 3 THEN -T.Volume * A.Plus3Weeks/100 
		WHEN P.PlusWeeks = 4 THEN -T.Volume * A.Plus4Weeks/100 
		WHEN P.PlusWeeks = 5 THEN -T.Volume * A.Plus5Weeks/100 
	END AS BaselineDipVolume,
	T.PiecesPerZUN,
	0 EstimatedVolumeZUN,
	1 WeeklySplit,
	1 ValidForAPO
INTO #BDL
FROM
	#TEMP T 
	INNER JOIN dbo.Activities A ON A.PK_ActivityID = T.FK_ActivityID
	CROSS JOIN #PlusWeeks P
ORDER BY 1,2,3,4,5

/*REMOVE DIPS WITH 0 VOLUME*/
DELETE FROM #BDL WHERE BaselineDipVolume = 0


/*INSERT DIPS IN LOGISTIC FORECAST TABLE*/
INSERT INTO dbo.LogisticForecastLines
        ( FK_LogisticForecastID ,
          FK_CampaignID ,
          FK_ActivityID ,
          ActivityFrom ,
          ActivityTo ,
          FK_ActivityStatusID ,
          FK_ActivityLineID ,
          FK_SalesUnitID ,
          FK_ProductID ,
          CommonCode ,
          DeliveryDay ,
          FK_ChainID ,
          EstimatedVolumeSupplier ,
          PiecesPerZUN ,
          EstimatedVolumeZUN ,
          WeeklySplit ,
		  FK_LogisticForecastTypeID
		 )
SELECT
	LFL.FK_LogisticForecastID,
	LFL.FK_CampaignID,
	LFL.FK_ActivityID,
	LFL.ActivityFrom ,
	LFL.ActivityTo ,
	LFL.FK_ActivityStatusID ,
	LFL.FK_ActivityLineID ,
	LFL.FK_SalesUnitID ,
	LFL.FK_ProductID ,
	LFL.CommonCode ,
	BDL.BaselineDipDate,
	LFL.FK_ChainID ,
	BDL.BaselineDipVolume ,
	BDL.PiecesPerZUN ,
	BDL.EstimatedVolumeZUN ,
	BDL.WeeklySplit ,
	2
FROM
	#BDL BDL
	INNER JOIN dbo.LogisticForecastLines LFL ON BDL.FK_LogisticForecastID = LFL.FK_LogisticForecastID
		AND BDL.FK_ActivityLineID = LFL.FK_ActivityLineID
		AND BDL.LastDelivery = LFL.DeliveryDay


/*VALIDATE*/
    UPDATE  LFL
    SET     ValidForAPO = 1
    FROM    LogisticForecastLines LFL
            INNER JOIN Products ON PK_ProductID = LFL.FK_SalesUnitID
            INNER JOIN ProductHierarchies PH5 ON PH5.FK_ProductID = PK_ProductID
            INNER JOIN ProductHierarchies PH4 ON PH4.PK_ProductHierarchyID = PH5.FK_ProductHierarchyParentID
            INNER JOIN ProductHierarchies PH3 ON PH3.PK_ProductHierarchyID = PH4.FK_ProductHierarchyParentID
            INNER JOIN ProductHierarchies PH2 ON PH2.PK_ProductHierarchyID = PH3.FK_ProductHierarchyParentID
            INNER JOIN ProductHierarchies PH1 ON PH1.PK_ProductHierarchyID = PH2.FK_ProductHierarchyParentID
    WHERE   FK_LogisticForecastID = @newid
            AND PH1.FK_ProductHierarchyLevelID = 20 AND LFL.FK_LogisticForecastTypeID = 2

/*DELETE DELIVERIES AND DIPS PRIOR TO CURRENT WEEK*/
DELETE FROM dbo.LogisticForecastLines WHERE FK_LogisticForecastID  = @newid AND DeliveryDay<@PeriodFrom

/*CLEAN UP*/
DROP TABLE #PlusWeeks
DROP TABLE #TEMP
DROP TABLE #BDL