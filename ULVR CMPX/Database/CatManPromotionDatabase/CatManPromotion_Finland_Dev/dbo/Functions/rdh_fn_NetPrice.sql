CREATE FUNCTION dbo.rdh_fn_NetPrice
    (
      @product int,
      @participator int,
      @period datetime
    )
RETURNS FLOAT
AS
BEGIN
    DECLARE @Base FLOAT
    DECLARE @Prompt FLOAT
    DECLARE @Price FLOAT
    DECLARE @Reduction FLOAT
    DECLARE @Pieces INT

    SET @Pieces = ( SELECT  ISNULL(Pieces, 0)
                    FROM    EANCodes
                    WHERE   ProductID = @Product
                            AND FK_EANTypeID = 2
                  )
                  
	SELECT @Pieces = @Pieces / PiecesPerConsumerUnit FROM dbo.Products as p WHERE PK_ProductID = @product

    SET @Price = ( SELECT   ISNULL([Value], 0)
                   FROM     Prices
                   WHERE    FK_ProductID = @Product
                            AND FK_PriceTypeID = 1
                            AND PeriodFrom <= @period
                            AND PeriodTo >= @period
                 )

	SELECT @Reduction = Value FROM dbo.BaseDiscounts as bd WHERE FK_ProductID = @product
		AND FK_BaseDiscountTypeID = 40 AND FK_ParticipatorID = @participator AND PeriodFrom <= @period AND PeriodTo >= @period
		
	SET @Reduction = CASE WHEN ISNULL(@Reduction, 0) = 0 THEN 0 ELSE @Price + @Reduction END

    SET @Base = ( SELECT    SUM(REBATE) AS REB
                  FROM      ( SELECT    ROUND(CAST(CASE WHEN BT.FK_VALUETYPEID = 1
                                                   THEN ISNULL(BD.value, 0)
                                                        * (@Price - @Reduction)
                                                   ELSE ISNULL(BD.value, 0)
                                              END as money), 2) AS REBATE
                              FROM      BaseDiscounts BD
                                        INNER JOIN BaseDiscountTypes BT ON BT.PK_BaseDiscountTypeID = BD.FK_BaseDiscountTypeID
                              WHERE     BD.FK_ProductID = @product
                                        AND BD.FK_PriceBaseID = 1
                                        AND BT.IsBaseDiscount = 1
                                        AND BD.PeriodFrom <= @period
                                        AND BD.PeriodTo >= @period
                                        AND BD.FK_ParticipatorID = @participator
                            ) AS X
                )
    RETURN ( ISNULL(@Price, 0) - ISNULL(@Base, 0) - @Reduction ) / @Pieces
END
