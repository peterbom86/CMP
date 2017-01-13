
CREATE PROCEDURE [dbo].[rdh_InsertAllocation]
    @AllocationLineID int,
  @ListingID int,
  @Allocation float,
  @ListingTypeID int,
  @WholesellerProductNo varchar(50),
  @PeriodFrom datetime,
  @PeriodTo datetime,  
  @WholerSalerFrom datetime,
  @WholerSalerTo datetime,
  @PrimeComment varchar(15) = '',
  @MaterialGroup varchar(14) = '',
  @ConsumerPrice float
  
  
AS

UPDATE AllocationLines
SET Allocation = @Allocation, PrimeComment = @PrimeComment
WHERE PK_AllocationLineID = @AllocationLineID

UPDATE Listings
SET FK_ListingTypeID = @ListingTypeID,
  WholesellerProductNo = @WholesellerProductNo,
  PeriodFrom = @PeriodFrom,
  PeriodTo = @PeriodTo,
  MaterialGroup =@MaterialGroup,
  ConsumerPrice =@ConsumerPrice
  
WHERE PK_ListingID = @ListingID


--Update Wholeseller
UPDATE L2
SET WholesellerProductNo = @WholesellerProductNo,
MaterialGroup =@MaterialGroup,
  PeriodFrom = @WholerSalerFrom,
  PeriodTo = @WholerSalerTo
FROM Listings L1
  INNER JOIN Participators Chain ON L1.FK_ParticipatorID = Chain.PK_ParticipatorID 
  INNER JOIN Participators parent ON Chain.FK_ParentID = parent.PK_ParticipatorID
  INNER JOIN Listings L2 ON parent.PK_ParticipatorID = L2.FK_ParticipatorID AND L1.FK_ProductID = L2.FK_ProductID
 WHERE 
	L1.PK_ListingID = @ListingID
	
	
--Update all Wholesellers Chain
UPDATE L3
SET WholesellerProductNo = @WholesellerProductNo,
MaterialGroup =@MaterialGroup
  
FROM Listings L1
  INNER JOIN Participators Chain ON L1.FK_ParticipatorID = Chain.PK_ParticipatorID 
  INNER JOIN Participators parent ON Chain.FK_ParentID = parent.PK_ParticipatorID
  INNER JOIN Participators AllChain ON AllChain.FK_ParentID = parent.PK_ParticipatorID
  INNER JOIN Listings L3 ON AllChain.PK_ParticipatorID = L3.FK_ParticipatorID AND L1.FK_ProductID = L3.FK_ProductID
WHERE 
	L1.PK_ListingID = @ListingID


