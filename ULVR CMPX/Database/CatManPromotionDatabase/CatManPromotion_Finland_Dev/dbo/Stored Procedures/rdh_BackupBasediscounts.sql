
CREATE PROCEDURE [dbo].[rdh_BackupBasediscounts]

AS

DECLARE @BatchID AS INT

SET @BatchID = (SELECT MAX(BatchID)+1 FROM dbo.Log_PricesAndDiscounts)
INSERT INTO dbo.Log_PricesAndDiscounts (BatchID, LogDescription) VALUES (@BatchID, 'Priskørsel: Start')
INSERT INTO dbo.Log_PricesAndDiscounts (BatchID, LogDescription) VALUES (@BatchID, 'Backup: Backup af Basediscounts')

TRUNCATE TABLE [CatManPromotion_Sirius_Staging].[dbo].[BaseDiscounts_Backup_FI]

INSERT INTO [CatManPromotion_Sirius_Staging].[dbo].[BaseDiscounts_Backup_FI]
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
	dbo.BaseDiscounts

