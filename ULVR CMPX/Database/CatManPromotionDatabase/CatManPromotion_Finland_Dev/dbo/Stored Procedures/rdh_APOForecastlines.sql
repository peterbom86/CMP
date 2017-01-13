CREATE PROCEDURE [dbo].[rdh_APOForecastlines]

AS

DECLARE @PeriodFrom int
DECLARE @PeriodTo INT
DECLARE @PeriodTo_Icecream int
DECLARE @MaxLogisticForecastID int
DECLARE @Opco as nvarchar(100)
DECLARE @StartDate DATETIME
DECLARE @DaySpan INT
DECLARE @DaySpanIceCream INT
DECLARE @Now DATETIME



SET @Now = CAST(FLOOR(CAST(GETDATE() as float)) as datetime) 

SELECT @Opco = ESL.Value 
FROM 
	ExternalSystems ES
	INNER JOIN ExternalSystemLines ESL ON PK_ExternalSystemID = FK_ExternalSystemID
WHERE
	ES.Label  = 'APO' AND ESL.Label = 'OpCo'


SELECT @DaySpan = Dayspan-7, @StartDate = Startdate, @DaySpanIceCream = DaySpan_Icecream-7
FROM dbo.APOConfiguration

SELECT  @PeriodFrom =Period
FROM    dbo.Periods as p
WHERE   Label = 
CASE WHEN
	CAST(FLOOR(CAST(GETDATE() as float)) as datetime)<@StartDate THEN @StartDate ELSE @Now
END

SELECT  @PeriodTo = Period
FROM    dbo.Periods as p
WHERE   Label = @Now + @DaySpan

SET @MaxLogisticForecastID = ( SELECT   MAX(PK_LogisticForecastID) LogisticForecastID
                               FROM     LogisticForecast
                             )


SELECT  @PeriodTo_Icecream = Period
FROM    dbo.Periods as p
WHERE   Label = @Now + @DaySpanIceCream

SET @MaxLogisticForecastID = ( SELECT   MAX(PK_LogisticForecastID) LogisticForecastID
                               FROM     LogisticForecast
                             )



SELECT  Details.CommonCode ProductCode,
        ch6.Node NBCustomer,
        @Opco OpCo,
        CONVERT(varchar(50), p2.Label, 112) Date,
        'ZUN' Zun,
        CONVERT(decimal(15, 0), Sum(Details.Volume)) Volume
FROM    ( SELECT 
                            FK_ChainID,
                            FK_SalesUnitID,
                            Period,
                            CommonCode,
                            Sum(CAST(EstimatedVolumeSupplier AS float)
                                    * WeeklySplit
                                    / CAST(PiecesPerZUN AS float)) Volume
                     FROM   LogisticForecastLines
                            INNER JOIN Periods ON Periods.Label = DeliveryDay
                     WHERE  FK_LogisticForecastID = @MaxLogisticForecastID
                            AND ROUND(EstimatedVolumeSupplier * WeeklySplit, 0) <> 0
							AND PiecesPerZUN<>0
                     GROUP BY FK_ChainID,
                            FK_SalesUnitID,
                            Period,
                            CommonCode
                   ) Details
        INNER JOIN CustomerHierarchies CH1 ON Details.FK_ChainID = CH1.FK_ParticipatorID
        INNER JOIN CustomerHierarchies CH2 ON CH1.FK_CustomerHierarchyParentID = CH2.PK_CustomerHierarchyID
        INNER JOIN CustomerHierarchies CH3 ON CH2.FK_CustomerHierarchyParentID = CH3.PK_CustomerHierarchyID
        INNER JOIN CustomerHierarchies CH4 ON CH3.FK_CustomerHierarchyParentID = CH4.PK_CustomerHierarchyID
        INNER JOIN CustomerHierarchies CH5 ON CH4.FK_CustomerHierarchyParentID = CH5.PK_CustomerHierarchyID
        INNER JOIN CustomerHierarchies CH6 ON CH5.FK_CustomerHierarchyParentID = CH6.PK_CustomerHierarchyID
		LEFT JOIN dbo.vwCannibalisationproducts CP ON Details.FK_SalesUnitID = CP.FK_ProductID AND CP.CategoryID = 5 /*ICE CREAM*/
        INNER JOIN dbo.Periods as p2 ON Details.Period = p2.Period AND p2.DayNumber = 1 
                                        AND Details.Period BETWEEN @PeriodFrom AND 
										CASE WHEN CP.CategoryID = 5 THEN @PeriodTo_Icecream ELSE @PeriodTo END
WHERE   ch6.node NOT LIKE '%-%'
GROUP BY Details.CommonCode,
        ch6.Node,
        p2.Label,
		CP.CategoryID
