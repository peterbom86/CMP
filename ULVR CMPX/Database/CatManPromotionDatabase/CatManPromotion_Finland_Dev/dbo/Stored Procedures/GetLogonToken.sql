CREATE PROCEDURE [dbo].[GetLogonToken]
  @Username NVARCHAR(255)
  
AS

DECLARE @Success bit
DECLARE @LogonToken NVARCHAR(36)
DECLARE @LogonTokenExpires DATETIME
DECLARE @Message NVARCHAR(255)

DECLARE @userCount int
SELECT @userCount = COUNT(*) FROM dbo.Users WHERE LogonName = @Username


IF @userCount = 1
BEGIN
	UPDATE dbo.Users
	SET LogonToken = NEWID(),
		LogonTokenExpires = GETDATE() + 1
	WHERE LogonName = @Username
	
	SELECT @Success = 1, @LogonToken = LogonToken, @LogonTokenExpires = LogonTokenExpires
	FROM dbo.Users AS u
	WHERE LogonName = @Username
END
ELSE
BEGIN
	IF @userCount = 0
	BEGIN
		RAISERROR('Username does not exist in CatMan®Promotion',11,1)
		RETURN -1
	END
	IF @userCount > 1
	BEGIN
		RAISERROR('Username exists multiple times in CatMan®Promotion',11,1)
		RETURN -1
	END
END

SELECT @Success AS Success, @LogonToken AS LogonToken, @LogonTokenExpires AS LogonTokenExpires, @Message AS Message
