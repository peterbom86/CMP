/* DDC: 13.09.2006 */

CREATE   PROCEDURE rdh_InsertActivitySubsider( @Value FLOAT, @Description VARCHAR(255), @ActivityID INT ) AS

INSERT INTO ActivitySubsider 
  (
  Value,
  [Description],
  FK_ActivityID
  )
  VALUES
  (
  @Value,
  @Description,
  @ActivityID
  )

SELECT SCOPE_IDENTITY()


