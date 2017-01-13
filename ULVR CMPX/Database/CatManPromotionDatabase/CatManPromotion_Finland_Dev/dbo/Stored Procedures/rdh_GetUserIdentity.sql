CREATE PROCEDURE rdh_GetUserIdentity( @Username nvarchar(50), @Password nvarchar(50) ) AS
SELECT     PK_UserID, Label, UserName, LogonName, [Password], UserRole
FROM         Users
WHERE LogonName = @Username AND [Password] = @Password


