CREATE FUNCTION dbo.fn_GetCategoryID (@CampaignID int)
returns int

AS

Begin

declare @Res int


	Set @Res = 
		(SELECT SUM(X.BitValue)
		FROM 
		Campaigns INNER JOIN 
		(SELECT DISTINCT FK_CampaignID, BitValue AS BitValue
		FROM 
			Activities A 
            INNER JOIN ActivityLines ON PK_ActivityID = FK_ActivityID
            INNER JOIN Products ON PK_ProductID = FK_SalesUnitID
            INNER JOIN ProductHierarchies PH1 ON PK_ProductID = PH1.FK_ProductID
			INNER JOIN ProductHierarchies PH2 ON PH1.FK_ProductHierarchyParentID = PH2.PK_ProductHierarchyID
			INNER JOIN CategoryGroups ON PH2.FK_CategoryGroupID = PK_CategoryGroupID
		WHERE 
			PH2.FK_ProductHierarchyLevelID = 4 AND FK_CampaignID = @CampaignID
		GROUP BY
			FK_CampaignID,BitValue) X ON X.FK_CampaignID = PK_CampaignID)

Return ISNULL(@Res, 1)
end

