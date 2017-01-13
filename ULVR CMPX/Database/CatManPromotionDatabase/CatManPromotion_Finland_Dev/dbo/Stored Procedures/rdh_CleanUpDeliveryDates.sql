Create procedure rdh_CleanUpDeliveryDates

as

UPDATE ActivityDeliveries
Set DeliveryDate=CAST(Floor(CAST(DeliveryDate as float)) as datetime)
WHERE
DeliveryDate<>CAST(Floor(CAST(DeliveryDate as float)) as datetime)



