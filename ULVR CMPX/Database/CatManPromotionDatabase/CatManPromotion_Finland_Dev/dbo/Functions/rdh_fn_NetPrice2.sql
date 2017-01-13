CREATE FUNCTION dbo.rdh_fn_NetPrice2 (@product int,@participator int,@period datetime)
Returns float

AS

begin

declare @Base float
declare @Prompt float
declare @Price float
declare @Pieces int


set @Pieces= 
  (SELECT ISNULL(Pieces,0) FROM EANCodes
         WHERE ProductID = @Product AND FK_EANTypeID = 2)

SELECT @Pieces = @Pieces / PiecesPerConsumerUnit FROM dbo.Products as p WHERE PK_ProductID = @product

set @Price= 
  (SELECT ISNULL([Value],0) FROM Prices WHERE FK_ProductID=@Product AND FK_PriceTypeID=1 AND
  PeriodFrom<=@period AND PeriodTo>=@period)


set @Base=
  (SELECT SUM(REBATE) AS REB FROM 
  
    (SELECT ROUND(CASE WHEN FK_VALUETYPEID=1 THEN
    ISNULL([value],0)* @Price
    ELSE ISNULL([value],0) END,2) AS REBATE
    
    FROM BaseDiscounts
    
    WHERE 
      FK_ProductID=@product AND
      FK_PriceBaseID=1 AND
      FK_BaseDiscountTypeID IN (1,2,3,4,10,11,12,13,14,15,16,17,18,19,20) AND
      PeriodFrom<=@period AND PeriodTo>=@period AND
      FK_ParticipatorID=@participator) AS X)

set @Prompt=
  (SELECT ISNULL(SUM(REBATE),0) AS REB FROM 
  
    (SELECT ROUND(CASE WHEN FK_VALUETYPEID=1 THEN
    ISNULL([value],0)* (@Price-@Base)  
    ELSE ISNULL([value],0) END,2) AS REBATE
    
    FROM BaseDiscounts
    
    WHERE 
      FK_ProductID=@product AND
      FK_PriceBaseID=2 AND
      FK_BaseDiscountTypeID IN (5) AND
      PeriodFrom<=@period AND PeriodTo>=@period AND
      FK_ParticipatorID=@participator) AS X)

return (ISNULL(@Price,0)-ISNULL(@Base,0)-ISNULL(@Prompt,0))/@Pieces

end
