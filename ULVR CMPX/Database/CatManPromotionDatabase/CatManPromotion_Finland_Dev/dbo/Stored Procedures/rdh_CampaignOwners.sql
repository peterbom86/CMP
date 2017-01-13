CREATE  procedure [dbo].[rdh_CampaignOwners]
AS

SELECT     dbo.Users.PK_UserID AS ID, dbo.Users.Label, dbo.Teams.Label AS Team, dbo.Users.LogonName AS LogonName
FROM         dbo.TeamUsers INNER JOIN
                      dbo.Teams ON dbo.TeamUsers.FK_TeamID = dbo.Teams.PK_TeamID INNER JOIN
                      dbo.Users ON dbo.TeamUsers.FK_UserID = dbo.Users.PK_UserID INNER JOIN
                      dbo.Campaigns ON dbo.Users.PK_UserID = dbo.Campaigns.FK_OwnerUserID
GROUP BY dbo.Users.PK_UserID, dbo.Users.Label, dbo.Teams.Label, dbo.Users.LogonName
ORDER BY dbo.Teams.Label, dbo.Users.Label




