CREATE PROCEDURE [dbo].[rdh_CreateBaseLineDips]

AS


DELETE FROM dbo.BaselineDipLines
DELETE FROM dbo.LogisticForecastLines WHERE FK_LogisticForecastTypeID = 2

SELECT 1 AS PlusWeeks
INTO #PlusWeeks
UNION ALL SELECT 2
UNION ALL SELECT 3
UNION ALL SELECT 4
UNION ALL SELECT 5

SELECT 
	L.FK_LogisticForecastID, FK_ActivityID,FK_ActivityLineID, MAX(DeliveryDay) AS LastDelivery, SUM(L.EstimatedVolumeSupplier*L.WeeklySplit) Volume, AVG(L.PiecesPerZUN) PiecesPerZUN
INTO #TEMP
FROM 
	dbo.LogisticForecastLines L
	INNER JOIN dbo.Activities A ON A.PK_ActivityID = L.FK_ActivityID
WHERE
	L.ValidForAPO = 1
GROUP BY 
	L.FK_LogisticForecastID, FK_ActivityID,FK_ActivityLineID


INSERT INTO dbo.BaselineDipLines
        ( FK_LogisticForecastID ,
		  FK_ActivitylineID,
		  LastDeliveryDay,
          BaselineDipDay,
          EstimatedDipVolume ,
          PiecesPerZUN ,
          EstimatedVolumeZUN ,
          WeeklySplit ,
          ValidForAPO
        )
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
FROM
	#TEMP T 
	INNER JOIN dbo.Activities A ON A.PK_ActivityID = T.FK_ActivityID
	CROSS JOIN #PlusWeeks P
ORDER BY 1,2,3,4,5

DELETE FROM dbo.BaselineDipLines WHERE EstimatedDipVolume = 0
--SELECT * FROM dbo.BaselineDipLines

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
	BDL.BaselineDipDay,
	LFL.FK_ChainID ,
	BDL.EstimatedDipVolume ,
	BDL.PiecesPerZUN ,
	BDL.EstimatedVolumeZUN ,
	BDL.WeeklySplit ,
	2
FROM
	dbo.BaselineDipLines BDL
	INNER JOIN dbo.LogisticForecastLines LFL ON BDL.FK_LogisticForecastID = LFL.FK_LogisticForecastID
		AND BDL.FK_ActivityLineID = LFL.FK_ActivityLineID
		AND BDL.LastDeliveryDay = LFL.DeliveryDay

DROP TABLE #PlusWeeks
DROP TABLE #TEMP




