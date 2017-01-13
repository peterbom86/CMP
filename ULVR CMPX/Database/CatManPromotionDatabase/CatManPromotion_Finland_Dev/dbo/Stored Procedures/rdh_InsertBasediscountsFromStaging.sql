
CREATE PROCEDURE [dbo].[rdh_InsertBasediscountsFromStaging]

AS

DECLARE @CountBefore AS INT
DECLARE @CountBefore_Uplift AS INT
DECLARE @CountAfter AS INT
DECLARE @CountAfter_Uplift AS INT
DECLARE @CountMatch AS INT
DECLARE @CountMatch_Uplift AS INT

DECLARE @BatchID AS INT

SET @BatchID = (SELECT MAX(BatchID) FROM dbo.Log_PricesAndDiscounts)

/*FINDER RECORDCOUNTS I STAGING OG I BASEDISCOUNTS*/
SELECT 	@CountBefore=COUNT(*) FROM dbo.BaseDiscounts
SELECT @CountBefore_Uplift=COUNT(*) FROM dbo.BaseDiscounts WHERE FK_BaseDiscountTypeID = 8

SELECT @CountAfter=COUNT(*) FROM CatManPromotion_Sirius_Staging.dbo.BaseDiscounts_FI
SELECT @CountAfter_Uplift=COUNT(*) FROM	CatManPromotion_Sirius_Staging.dbo.BaseDiscounts_FI WHERE FK_BaseDiscountTypeID = 8

/*FINDER RECORDCOUNTS DER MATCHER I STAGING OG I BASEDISCOUNTS*/
SELECT @CountMatch = COUNT(*)
FROM
	CatManPromotion_Sirius_Staging.dbo.BaseDiscounts_FI ST
	INNER JOIN dbo.BaseDiscounts BD
	 ON BD.FK_BaseDiscountTypeID = ST.FK_BaseDiscountTypeID 
	 AND BD.FK_ParticipatorID = ST.FK_ParticipatorID
	 AND BD.FK_PriceBaseID = ST.FK_PriceBaseID
	 AND BD.FK_ProductID = ST.FK_ProductID
	 AND ISNULL(BD.FK_ValueTypeID,0) = ISNULL(ST.FK_ValueTypeID,0)
	 AND ISNULL(BD.FK_VolumeBaseID,0) = ISNULL(ST.FK_VolumeBaseID,0)
	 AND ISNULL(BD.OnInvoice,0) = ISNULL(ST.OnInvoice,0)
	 AND BD.PeriodFrom = ST.PeriodFrom
	 AND BD.PeriodTo = ST.PeriodTo
	 AND BD.Value = ST.Value

SELECT 
	@CountMatch_Uplift = COUNT(*)
FROM
	dbo.BaseDiscounts ST
	INNER JOIN CatManPromotion_Sirius_Staging.dbo.BaseDiscounts_Backup_FI BD
	 ON BD.FK_BaseDiscountTypeID = ST.FK_BaseDiscountTypeID 
	 AND BD.FK_ParticipatorID = ST.FK_ParticipatorID
	 AND BD.FK_PriceBaseID = ST.FK_PriceBaseID
	 AND BD.FK_ProductID = ST.FK_ProductID
	 AND ISNULL(BD.FK_ValueTypeID,0) = ISNULL(ST.FK_ValueTypeID,0)
	 AND ISNULL(BD.FK_VolumeBaseID,0) = ISNULL(ST.FK_VolumeBaseID,0)
	 AND ISNULL(BD.OnInvoice,0) = ISNULL(ST.OnInvoice,0)
	 AND BD.PeriodFrom = ST.PeriodFrom
	 AND BD.PeriodTo = ST.PeriodTo
	 AND BD.Value = ST.Value
WHERE
	BD.FK_BaseDiscountTypeID = 8

/*SKRIVER TIL LOG*/
INSERT INTO dbo.Log_PricesAndDiscounts (BatchID, LogDescription, RecordCount) VALUES (@BatchID, 'Afstemning: Total Basediscounts Før',@CountBefore)
INSERT INTO dbo.Log_PricesAndDiscounts (BatchID, LogDescription, RecordCount) VALUES (@BatchID, 'Afstemning: Total Basediscounts Staging',@CountAfter)
INSERT INTO dbo.Log_PricesAndDiscounts (BatchID, LogDescription, RecordCount) VALUES (@BatchID, 'Afstemning: Total Basediscounts Match',@CountMatch)

INSERT INTO dbo.Log_PricesAndDiscounts (BatchID, LogDescription, RecordCount) VALUES (@BatchID, 'Afstemning: Total Basediscounts Før (Uplift)',@CountBefore_Uplift)
INSERT INTO dbo.Log_PricesAndDiscounts (BatchID, LogDescription, RecordCount) VALUES (@BatchID, 'Afstemning: Total Basediscounts Staging (Uplift)',@CountAfter_Uplift)
INSERT INTO dbo.Log_PricesAndDiscounts (BatchID, LogDescription, RecordCount) VALUES (@BatchID, 'Afstemning: Total Basediscounts Match (Uplift)',@CountMatch_Uplift)

/*SANITY CHECK 1: MAX 1 % NYE/SLETTEDE RECORS */
IF ABS(CAST(@CountAfter-@CountBefore AS FLOAT)/CAST(@CountBefore AS FLOAT))<0.01
BEGIN
	/*SANITY CHECK 2: MINDST 99 % MATCHENDE RECORDS*/
	IF CAST(@CountMatch AS FLOAT)/CAST(@CountAfter AS FLOAT)>0.98
	BEGIN
		INSERT INTO dbo.Log_PricesAndDiscounts (BatchID, LogDescription) VALUES (@BatchID, 'Basediscounts: Indsætter i Basediscounts (Live)')
		
		TRUNCATE TABLE [dbo].[BaseDiscounts]
		/*INDSÆTTER FRA STAGING TIL BASEDISCOUNTS*/
		INSERT INTO [dbo].[BaseDiscounts]
			([FK_ParticipatorID]
			,[FK_ProductID]
			,[FK_PriceBaseID]
			,[FK_BaseDiscountTypeID]
			,[Value]
			,[FK_ValueTypeID]
			,[FK_VolumeBaseID]
			,[OnInvoice]
			,[PeriodFrom]
			,[PeriodTo]
			,[FK_CampaignID]
			,[OldValue]
			,[DeleteFlag]
			,[InsertDate]
			,[FK_FileImportID])
		SELECT 
			FK_ParticipatorID ,
			FK_ProductID ,
			FK_PriceBaseID ,
			FK_BaseDiscountTypeID ,
			Value ,
			FK_ValueTypeID ,
			FK_VolumeBaseID ,
			OnInvoice ,
			PeriodFrom ,
			PeriodTo ,
			FK_CampaignID ,
			OldValue ,
			DeleteFlag ,
			InsertDate ,
			FK_FileImportID
		FROM 
			CatManPromotion_Sirius_Staging.dbo.BaseDiscounts_FI


		/*CHECK 100% MATCH*/
		SELECT 
			@CountMatch = COUNT(*)
		FROM
			CatManPromotion_Sirius_Staging.dbo.BaseDiscounts_FI ST
			INNER JOIN dbo.BaseDiscounts BD
			 ON BD.FK_BaseDiscountTypeID = ST.FK_BaseDiscountTypeID 
			 AND BD.FK_ParticipatorID = ST.FK_ParticipatorID
			 AND BD.FK_PriceBaseID = ST.FK_PriceBaseID
			 AND BD.FK_ProductID = ST.FK_ProductID
			 AND ISNULL(BD.FK_ValueTypeID,0) = ISNULL(ST.FK_ValueTypeID,0)
			 AND ISNULL(BD.FK_VolumeBaseID,0) = ISNULL(ST.FK_VolumeBaseID,0)
			 AND ISNULL(BD.OnInvoice,0) = ISNULL(ST.OnInvoice,0)
			 AND BD.PeriodFrom = ST.PeriodFrom
			 AND BD.PeriodTo = ST.PeriodTo
			 AND BD.Value = ST.Value 
		
		SELECT @CountAfter=COUNT(*)	FROM dbo.BaseDiscounts

		INSERT INTO dbo.Log_PricesAndDiscounts (BatchID, LogDescription, RecordCount) VALUES (@BatchID, 'Afstemning: Total Basediscounts (Live)',@CountAfter)
		
		/*OPDATERER LISTEPRISER*/
		INSERT INTO dbo.Log_PricesAndDiscounts (BatchID, LogDescription) VALUES (@BatchID, 'Listepriser: Opdaterer listepriser')
		--EXEC [dbo].[rdh_UpdateListingPrices]
		
		/*HVIS IKKE 100 % MATCH MELLEM STAGING OG BASEDISCOUNTS->FEJL*/
		IF @CountMatch<>@CountAfter
		BEGIN
			INSERT INTO dbo.Log_PricesAndDiscounts (BatchID, LogDescription, RecordCount) VALUES (@BatchID, 'Afstemning: FEJL Staging<>Livetabe)',@CountAfter-@CountMatch)
			--EXEC dbo.rdh_RestoreBasediscountsFromBackup
		END
		INSERT INTO dbo.Log_PricesAndDiscounts (BatchID, LogDescription) VALUES (@BatchID, 'Priskørsel: Slut')
	END
END








