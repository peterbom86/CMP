CREATE PROCEDURE rdh_GetBaseDiscountType
  @BaseDiscountTypeID int

AS

SELECT PK_BaseDiscountTypeID BaseDiscountTypeID, Label, FK_PriceBaseID PriceBaseID, FK_ValueTypeID ValueTypeID, 
  FK_VolumeBaseID VolumeBaseID, OnInvoice
FROM BaseDiscountTypes
WHERE PK_BaseDiscountTypeID = @BaseDiscountTypeID
