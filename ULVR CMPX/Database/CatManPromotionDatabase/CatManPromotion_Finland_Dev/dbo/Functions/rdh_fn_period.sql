CREATE function rdh_fn_period (@Year int, @Week int, @Add int)
Returns nvarchar(6)

AS

begin

declare @string nvarchar(6)

If @Week+@Add-1<10 set @string=CAST(@Year AS nvarchar) + '0' + CAST(@Week+@Add-1 as nvarchar)
If @Week+@Add-1>=10 set @string=CAST(@Year AS nvarchar) + CAST(@Week+@Add-1 as nvarchar)

return @string

end


