CREATE PROCEDURE [dbo].[rdh_CreateMenu]
@MenuID INT,
@Lang VARCHAR(2) = 'da'
AS

SELECT 
	mi.PK_MenuItemID,
	mi.FK_MenuItemID,
	mi.Label,
	mi.[Target],
	mi.[Namespace],
	mi.Tooltip,
	mi.Shortkey,
	mi.Image,
	ISNULL(mtmi.FK_MenuItemID, 0) AS [Active]
FROM dbo.MenuItems mi
  LEFT JOIN MenuToMenuItems mtmi ON mtmi.FK_MenuItemID = mi.PK_MenuItemID 
  AND mtmi.FK_MenuID = @MenuID
WHERE mi.Lang = @Lang AND mi.Visible = 1
