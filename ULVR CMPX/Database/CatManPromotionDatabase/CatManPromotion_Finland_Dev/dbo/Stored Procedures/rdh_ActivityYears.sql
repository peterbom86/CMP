CREATE Procedure [dbo].[rdh_ActivityYears]

AS

select CAST(yr as varchar) as Year, ordervalue from
(SELECT TOP(20) Year(ActivityFrom) As Yr, 2 as ordervalue
FROM Activities
GROUP BY Year(ActivityFrom)
ORDER BY Year(ActivityFrom)
) as yr
Union
select 'All' as yr, 1 as ordervalue
from Activities
order by ordervalue