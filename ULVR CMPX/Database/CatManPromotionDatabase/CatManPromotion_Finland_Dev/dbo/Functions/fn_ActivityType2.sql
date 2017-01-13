CREATE FUNCTION [dbo].[fn_ActivityType2] (@TypeID int)
RETURNS varchar(100)

AS

BEGIN

DECLARE @output nvarchar(max)

SELECT @output = ISNULL(@output + '|', '') + Label FROM ActivityTypes
WHERE ( Value & @TypeID ) <> 0

RETURN ISNULL(@output, '')

END 
