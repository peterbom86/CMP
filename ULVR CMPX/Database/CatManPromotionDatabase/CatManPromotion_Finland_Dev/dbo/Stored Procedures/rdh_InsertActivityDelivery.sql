/* DDC: 13.09.2006 */

CREATE     PROCEDURE rdh_InsertActivityDelivery( @ActivityID INT, @Value FLOAT, @Date DATETIME ) AS

INSERT INTO ActivityDeliveries 
( DeliveryDate, Value, FK_ActivityID ) 
VALUES
( CAST(Floor(CAST(@Date as float)) as datetime), @Value, @ActivityID )

SELECT SCOPE_IDENTITY()





