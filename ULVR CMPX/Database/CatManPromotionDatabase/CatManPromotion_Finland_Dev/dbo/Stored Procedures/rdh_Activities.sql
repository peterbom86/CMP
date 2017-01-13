CREATE  procedure [dbo].[rdh_Activities]
@bitValue int

AS

SELECT   DISTINCT  ph.PK_ProductHierarchyID, ph.Label
FROM       dbo.CategoryGroups as cg INNER JOIN
  dbo.ProductHierarchies as ph on PK_CategoryGroupID = FK_CategoryGroupID 
INNER JOIN ProductHierarchies ph2 ON ph.PK_ProductHierarchyID = ph2.FK_ProductHierarchyParentID
INNER JOIN ActivityLines al ON ph2.FK_ProductID = al.FK_SalesUnitID
WHERE     (ph.FK_ProductHierarchyLevelID = 4) AND cg.BitValue & @bitValue > 0 
GROUP BY ph.PK_ProductHierarchyID, ph.Label
ORDER BY ph.Label
