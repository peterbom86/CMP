
CREATE PROC [dbo].[rdh_GetDefaultDiscountWithTax]
@CampaignID int 

AS 
SELECT *
FROM dbo.Campaigns c
INNER JOIN dbo.Participators p on c.FK_ChainID = p.PK_ParticipatorID
WHERE c.PK_CamPaignID = @CampaignID
