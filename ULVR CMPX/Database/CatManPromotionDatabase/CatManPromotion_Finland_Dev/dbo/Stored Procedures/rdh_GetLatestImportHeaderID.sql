﻿CREATE PROCEDURE rdh_GetLatestImportHeaderID

AS

SELECT MAX(PK_ImportHeaderID) ImportHeaderID
FROM tblImportAPOBaseLine_Foods_Header
