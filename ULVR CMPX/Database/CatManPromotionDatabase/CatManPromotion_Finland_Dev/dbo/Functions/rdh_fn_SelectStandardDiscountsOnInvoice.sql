CREATE   FUNCTION  rdh_fn_SelectStandardDiscountsOnInvoice
(@ParticipatorID int, 
@UnitID int, 
@Date datetime)

RETURNS float

AS

BEGIN
DECLARE @Discount float

SELECT @Discount = CD.[Value]
FROM         
  
  CustomerHierarchies CustomerHierarchies_2 INNER JOIN
  CustomerHierarchies CustomerHierarchies_1 INNER JOIN
  Activities AC INNER JOIN
  ActivityLines AL ON AC.PK_ActivityID = AL.FK_ActivityID INNER JOIN
  CampaignDiscounts CD ON AL.PK_ActivityLineID = CD.FK_ActivityLineID INNER JOIN
  Campaigns CA ON AC.FK_CampaignID = CA.PK_CampaignID INNER JOIN
  PriceBases ON CD.FK_PriceBaseID = PriceBases.PK_PriceBaseID INNER JOIN
  ValueTypes ON CD.FK_ValueTypeID = ValueTypes.PK_ValueTypeID INNER JOIN
  VolumeBases ON CD.FK_VolumeBaseID = VolumeBases.PK_VolumeBaseID INNER JOIN
  CustomerHierarchies ON CA.FK_ChainID = CustomerHierarchies.FK_ParticipatorID ON 
  CustomerHierarchies_1.PK_CustomerHierarchyID = CustomerHierarchies.FK_CustomerHierarchyParentID ON 
  CustomerHierarchies_2.FK_CustomerHierarchyParentID = CustomerHierarchies_1.PK_CustomerHierarchyID


WHERE     
  CustomerHierarchies_2.FK_ParticipatorID = @ParticipatorID AND 
  AL.FK_SalesUnitID = @UnitID AND 
  AC.FK_ActivityPurposeID = 7 AND 
  CD.OnInvoice=1 AND
  AC.ActivityFrom <= @Date AND AC.ActivityTo >= @Date

GROUP BY 
PriceBases.Label, CD.FK_PriceBaseID, CD.[Value], VolumeBases.Label, 
VolumeBases.PK_VolumeBaseID, ValueTypes.PK_ValueTypeID, ValueTypes.Label, AC.ActivityFrom, AC.ActivityTo, 
AL.FK_SalesUnitID, CustomerHierarchies_2.FK_ParticipatorID, AC.FK_ActivityPurposeID,CD.OnInvoice

RETURN ISNULL(@Discount, 0)
END




