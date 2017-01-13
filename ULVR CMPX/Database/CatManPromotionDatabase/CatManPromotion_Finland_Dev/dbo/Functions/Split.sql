create function [dbo].[Split] ( 
	@StringToSplit varchar(2048),
	@Separator varchar(128))
returns table as return
with indices as
( 
select 0 S, 1 E
union all
select E, charindex(@Separator, @StringToSplit, E) + len(@Separator) 
from indices
where E > S 
)
select substring(@StringToSplit,S, 
case when E > len(@Separator) then e-s-len(@Separator) else len(@StringToSplit) - s + 1 end) String
,S StartIndex        
from indices where S >0
