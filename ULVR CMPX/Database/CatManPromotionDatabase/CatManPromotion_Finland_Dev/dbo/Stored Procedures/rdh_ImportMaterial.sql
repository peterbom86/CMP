CREATE   PROCEDURE rdh_ImportMaterial

AS

BEGIN TRANSACTION
DECLARE @tcode varchar(7), @common varchar(18), @text varchar(40), @itemcategory varchar(4), @salesorg varchar(4),
  @salesunit varchar(3), @salesstatus varchar(2), @plant varchar(4), @materialdetermination varchar(18), 
  @netweight varchar(17), @materialgroup varchar(9), @materialgrouptext varchar(20), @itf varchar(18),
  @ean varchar(18), @totalcompany varchar(8), @totalcompanytext varchar(40), @market varchar(8),
  @markettext varchar(40), @localbrand varchar(8), @localbrandtext varchar(40), @spfv varchar(8), @spfvtext varchar(40), 
  @ebf varchar(8), @ebftext varchar(40), @spf varchar(8), @spftext varchar(40), @ishandled bit


DECLARE UploadMaterialCursor CURSOR FOR
SELECT TCode, Common, Text, ItemCategory, SalesOrg, SalesUnit, SalesStatus, Plant, MaterialDetermination, 
  NetWeight, MaterialGroup, MaterialGroupText, ITF, EAN, TotalCompany, TotalCompanyText, Market,
  MarketText, LocalBrand, LocalBrandText, SPFV, SPFVText, EBF, EBFText, SPF, SPFText, IsHandled 
FROM tblUploadMaterial
WHERE IsHandled = 0
ORDER BY UploadID
FOR UPDATE OF IsHandled

OPEN UploadMaterialCursor

FETCH NEXT FROM UploadMaterialCursor INTO @tcode, @common, @text, @itemcategory, @salesorg, @salesunit, @salesstatus, 
  @plant, @materialdetermination, @netweight, @materialgroup, @materialgrouptext, @itf, @ean, @totalcompany, 
  @totalcompanytext, @market, @markettext, @localbrand, @localbrandtext, @spfv, @spfvtext, @ebf, @ebftext, @spf, @spftext, @ishandled

WHILE @@FETCH_STATUS = 0
BEGIN
  IF @materialdetermination <> ''
  BEGIN
    UPDATE tblBaseMaterial
    SET MaterialDetermination = ''
    WHERE TCode = @tcode
  END
  IF (SELECT Count(*) FROM tblBaseMaterial WHERE Common = @common) > 0
  BEGIN
    UPDATE tblBaseMaterial
    SET TCode = @tcode, Text = @text, ItemCategory = @itemcategory, SalesOrg = @salesorg, SalesUnit = @salesunit, 
      SalesStatus = @salesstatus, Plant = @plant, MaterialDetermination = @materialdetermination, 
      NetWeight = @netweight, MaterialGroup = @materialgroup, MaterialGroupText = @materialgrouptext, 
      ITF = @itf, EAN = @ean, TotalCompany = @totalcompany, TotalCompanyText = @totalcompanytext, Market = @market,
      MarketText = @markettext, LocalBrand = @localbrand, LocalBrandText = @localbrandtext, SPFV = @spfv, 
      SPFVText = @spfvtext, EBF = @ebf, EBFText = @ebftext, SPF = @spf, SPFText = @spftext
    WHERE Common = @common
  END
  ELSE
  BEGIN
    INSERT INTO tblBaseMaterial (TCode, Common, Text, ItemCategory, SalesOrg, SalesUnit, SalesStatus, Plant, MaterialDetermination,
      NetWeight, MaterialGroup, MaterialGroupText, ITF, EAN, TotalCompany, TotalCompanyText, Market, MarketText,
      LocalBrand, LocalBrandText, SPFV, SPFVText, EBF, EBFText, SPF, SPFText)
    VALUES (@tcode, @common, @text, @itemcategory, @salesorg, @salesunit, @salesstatus, @plant, @materialdetermination, 
      @netweight, @materialgroup, @materialgrouptext, @itf, @ean, @totalcompany, @totalcompanytext, @market, @markettext, 
      @localbrand, @localbrandtext, @spfv, @spfvtext, @ebf, @ebftext, @spf, @spftext)
  END

  UPDATE tblBaseMaterial
  SET SPFVText = @spfvtext,
    SPF = @spf,
    SPFText = @spftext
  WHERE
    SPFV = @spfv

  UPDATE tblBaseMaterial
  SET SPFText = @spftext,
    EBF = @ebf,
    EBFText = @ebftext
  WHERE
    SPF = @spf

  UPDATE tblBaseMaterial
  SET EBFText = @ebftext,
    Market = @market,
    MarketText = @markettext
  WHERE
    EBF = @ebf

  UPDATE tblBaseMaterial
  SET MarketText = @MarketText,
    TotalCompany = @totalcompany,
    TotalCompanyText = @totalcompanytext
  WHERE
    Market = @market

  UPDATE tblBaseMaterial
  SET LocalBrand = @localbrand,
    LocalBrandText = @localbrandtext
  WHERE
    EBF = @ebf

  UPDATE tblBaseMaterial
  SET LocalBrandText = @localbrandtext
  WHERE
    LocalBrand = @localbrand

  UPDATE tblUploadMaterial
  SET IsHandled = 1
  WHERE CURRENT OF UploadMaterialCursor

  FETCH NEXT FROM UploadMaterialCursor INTO @tcode, @common, @text, @itemcategory, @salesorg, @salesunit, @salesstatus, 
    @plant, @materialdetermination, @netweight, @materialgroup, @materialgrouptext, @itf, @ean, @totalcompany, 
    @totalcompanytext, @market, @markettext, @localbrand, @localbrandtext, @spfv, @spfvtext, @ebf, @ebftext, @spf, @spftext, @ishandled
END

CLOSE UploadMaterialCursor
DEALLOCATE UploadMaterialCursor

COMMIT TRANSACTION



