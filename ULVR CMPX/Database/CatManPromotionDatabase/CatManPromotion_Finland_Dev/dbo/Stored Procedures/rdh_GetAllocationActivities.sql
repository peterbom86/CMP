CREATE  PROCEDURE rdh_GetAllocationActivities
  @WholesellerID int

AS

SELECT  PK_ProductHierarchyID ActivityID, ProductHierarchies.Label ActivityName, PK_ProductID ProductID, ProductCode, Products.Label ProductName, 
  WholesellerProductNo, '2001-01-01' PeriodFrom, '2099-12-31' PeriodTo, 
  PK_ParticipatorID ChainID, Participators.Label ChainName, PK_AllocationLineID, PK_ListingID, FK_ListingTypeID, Allocation
FROM Participators
  INNER JOIN Allocations ON PK_ParticipatorID = FK_ParticipatorID
  INNER JOIN (SELECT PK_ProductHierarchyID, Label FROM ProductHierarchies WHERE FK_ProductHierarchyLevelID = 4) ProductHierarchies ON PK_ProductHierarchyID = FK_ProductHierarchyID
  INNER JOIN AllocationLines ON PK_AllocationID = FK_AllocationID
  INNER JOIN (SELECT PK_ProductID, ProductCode, Products.Label FROM Products INNER JOIN ProductStatus ON PK_ProductStatusID = FK_ProductStatusID AND IsHidden = 0) Products ON PK_ProductID = AllocationLines.FK_ProductID
  INNER JOIN (
    SELECT PK_ListingID, FK_ParticipatorID, FK_ProductID, FK_ListingTypeID, WholesellerProductNo FROM Listings
    WHERE FK_ParticipatorID IN (SELECT PK_ParticipatorID FROM Participators WHERE FK_ParentID = @WholesellerID)) Listings ON 
      PK_ParticipatorID = Listings.FK_ParticipatorID AND PK_ProductID = Listings.FK_ProductID
ORDER BY PK_ProductHierarchyID, Products.Label, Participators.Label



