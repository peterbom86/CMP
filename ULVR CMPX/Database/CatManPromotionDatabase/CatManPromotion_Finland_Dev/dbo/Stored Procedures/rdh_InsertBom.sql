CREATE PROC [dbo].[rdh_InsertBom]
@ManualBOMID int,
@MaterialHeader text,
@Type text, 
@MaterialComponent text,
@Zun text

AS

IF (SELECT Count(*) FROM SAP_BOM_ManualLoadCorrections WHERE ManualBOMID = @ManualBOMID) > 0
BEGIN

UPDATE SAP_BOM_ManualLoadCorrections
SET
   MATERIAL_HEADER = @MaterialHeader,
   TYPE = @Type,
   MATERIAL_COMPONENT = @MaterialComponent,
   ZUN = @Zun
WHERE
   ManualBOMID = @ManualBOMID
END

ELSE
BEGIN

  INSERT INTO dbo.SAP_BOM_ManualLoadCorrections( MATERIAL_HEADER, TYPE, MATERIAL_COMPONENT, ZUN )
  VALUES ( @MaterialHeader, @Type, @MaterialComponent, @Zun )

END
