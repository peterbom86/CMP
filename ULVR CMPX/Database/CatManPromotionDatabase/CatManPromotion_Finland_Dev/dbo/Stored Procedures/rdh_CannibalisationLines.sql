CREATE PROCEDURE [dbo].[rdh_CannibalisationLines]

AS

DECLARE @PeriodFrom int
DECLARE @PeriodTo INT
DECLARE @PeriodTo_Icecream int
DECLARE @MaxLogisticForecastID int
DECLARE @Opco as nvarchar(100)
DECLARE @StartDate DATETIME
DECLARE @Dayspan INT
DECLARE @DaySpanIceCream INT
DECLARE @Now DATETIME


SET @Now = CAST(FLOOR(CAST(GETDATE() as float)) as datetime) 

SELECT @Opco = ESL.Value 
FROM 
	ExternalSystems ES
	INNER JOIN ExternalSystemLines ESL ON PK_ExternalSystemID = FK_ExternalSystemID
WHERE
	ES.Label  = 'APO' AND ESL.Label = 'OpCo'

SELECT @DaySpan = Dayspan-7, @StartDate = Startdate,  @DaySpanIceCream = DaySpan_Icecream-7
FROM dbo.APOConfiguration


SELECT  @PeriodFrom = Period
FROM    dbo.Periods as p
WHERE   Label = 
CASE WHEN
	CAST(FLOOR(CAST(GETDATE() as float)) as datetime)<@StartDate THEN @StartDate ELSE @Now
END


SELECT  @PeriodTo = Period
FROM    dbo.Periods as p
WHERE   Label =  @Now  + @Dayspan

SET @MaxLogisticForecastID = ( SELECT   MAX(PK_LogisticForecastID) LogisticForecastID
                               FROM     LogisticForecast
                             )

SELECT  @PeriodTo_Icecream = Period
FROM    dbo.Periods as p
WHERE   Label = @Now + @DaySpanIceCream

SET @MaxLogisticForecastID = ( SELECT   MAX(PK_LogisticForecastID) LogisticForecastID
                               FROM     LogisticForecast
                             )

SELECT  CAST(Details.CommonCode as varchar(20)) [Distribution Unit],
        CH6.Node [Cust Input (NatBan)],
        @Opco [Operating Company],
        CONVERT(NVARCHAR, p2.Label, 112) [Calendar day],
        -CAST(SUM(ISNULL(
		CASE
			WHEN CP.CategoryID = 1 THEN C.Value1
			WHEN CP.CategoryID = 2 THEN C.Value2
			WHEN CP.CategoryID = 3 THEN C.Value3
			WHEN CP.CategoryID = 4 THEN C.Value4
			WHEN CP.CategoryID = 5 THEN C.Value5
			WHEN CP.CategoryID = 6 THEN C.Value6
		ELSE
			0
		END
			, 0)
			
			) AS int) [Promo Cann % AMPS_2]
FROM    dbo.Cannibalisation C
        RIGHT JOIN ( SELECT DISTINCT
                            FK_ChainID,
                            FK_SalesUnitID,
                            Period,
                            CommonCode
                     FROM   LogisticForecastLines
                            INNER JOIN Periods ON Periods.Label = DeliveryDay
                     WHERE  FK_LogisticForecastID = @MaxLogisticForecastID
                            AND ROUND(EstimatedVolumeSupplier * WeeklySplit, 0) > 0
                   ) Details ON FK_ParticipatorID = FK_ChainID
        INNER JOIN CustomerHierarchies CH1 ON Details.FK_ChainID = CH1.FK_ParticipatorID
        INNER JOIN CustomerHierarchies CH2 ON CH1.FK_CustomerHierarchyParentID = CH2.PK_CustomerHierarchyID
        INNER JOIN CustomerHierarchies CH3 ON CH2.FK_CustomerHierarchyParentID = CH3.PK_CustomerHierarchyID
        INNER JOIN CustomerHierarchies CH4 ON CH3.FK_CustomerHierarchyParentID = CH4.PK_CustomerHierarchyID
        INNER JOIN CustomerHierarchies CH5 ON CH4.FK_CustomerHierarchyParentID = CH5.PK_CustomerHierarchyID
        INNER JOIN CustomerHierarchies CH6 ON CH5.FK_CustomerHierarchyParentID = CH6.PK_CustomerHierarchyID
        INNER JOIN dbo.Products as p on PK_ProductID = Details.FK_SalesUnitID
        INNER JOIN dbo.CommonCodes as cc on PK_ProductID = cc.FK_ProductID
                                            AND Active = 1
        --INNER JOIN dbo.Periods as p2 ON Details.Period = p2.Period AND p2.DayNumber = 1 
        --                                AND Details.Period BETWEEN @PeriodFrom AND @PeriodTo
		LEFT JOIN dbo.vwCannibalisationproducts CP ON CP.PK_CommonCodeID = CC.PK_CommonCodeID
		INNER JOIN dbo.Periods as p2 ON Details.Period = p2.Period AND p2.DayNumber = 1 
                                AND Details.Period BETWEEN @PeriodFrom AND 
								CASE WHEN CP.CategoryID = 5 THEN @PeriodTo_Icecream ELSE @PeriodTo END
WHERE   CH6.Node NOT LIKE '%-%'
GROUP BY Details.CommonCode,
        CH6.Node,
        p2.Label