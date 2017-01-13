
CREATE PROCEDURE [dbo].[rdh_DeleteObsoleteParticipators]

AS


--FIND PARTICIPATORS
SELECT *
INTO #Participators 
FROM dbo.Participators 
WHERE FK_ParticipatorStatusID = 3
SELECT * FROM #Participators

--FIND CAMPAIGNS FOR PARTICIPATORS
SELECT DISTINCT C.PK_CampaignID
INTO #Campaigns
FROM
dbo.Campaigns C
INNER JOIN dbo.Activities A ON A.FK_CampaignID = C.PK_CampaignID
INNER JOIN #Participators P ON P.PK_ParticipatorID = C.FK_ChainID

SELECT * FROM #Campaigns

BEGIN TRAN

--CAMPAIGNDISCOUNTS
DELETE FROM CC
FROM
	CampaignDiscounts CC
	INNER JOIN ActivityLines AL ON AL.PK_ActivityLineID = CC.FK_ActivityLineID
 	INNER JOIN Activities A ON A.PK_ActivityID = AL.FK_ActivityID
	INNER JOIN #Campaigns C ON C.PK_CampaignID = A.FK_CampaignID

DELETE FROM CC
FROM
	dbo.auditCampaignDiscounts CC
	INNER JOIN ActivityLines AL ON AL.PK_ActivityLineID = CC.FK_ActivityLineID
 	INNER JOIN Activities A ON A.PK_ActivityID = AL.FK_ActivityID
	INNER JOIN #Campaigns C ON C.PK_CampaignID = A.FK_CampaignID

DELETE FROM AL 
FROM ActivityLinesToESAP AL
  INNER JOIN ActivityLines ON PK_ActivityLineID = FK_ActivityLineID
  INNER JOIN Activities A ON PK_ActivityID = FK_ActivityID
  INNER JOIN #Campaigns C ON C.PK_CampaignID = A.FK_CampaignID


--SETTLEMENT
DELETE FROM SS 
FROM
dbo.SettlementSubsider SS
INNER JOIN dbo.ActivitySubsider ASU ON ASU.PK_ActivitySubsiderID = SS.FK_ActivitySubsiderID
INNER JOIN dbo.Activities A ON A.PK_ActivityID = ASU.FK_ActivityID
INNER JOIN #Campaigns C ON C.PK_CampaignID = A.FK_CampaignID

DELETE FROM SSCS
FROM
	dbo.SettlementSubsiderCampaignSplit SSCS
	INNER JOIN dbo.SettlementSubsiderCampaign SSC ON SSC.PK_SettlementSubsiderCampaignID = SSCS.FK_SettlementSubsiderCampaignID
	INNER JOIN dbo.CampaignSubsider CS ON CS.PK_CampaignSubsiderID = SSC.FK_CampaignSubsiderID
	INNER JOIN #Campaigns C ON C.PK_CampaignID = CS.FK_CampaignID

DELETE FROM SSC
FROM
	dbo.SettlementSubsiderCampaign SSC 
	INNER JOIN dbo.CampaignSubsider CS ON CS.PK_CampaignSubsiderID = SSC.FK_CampaignSubsiderID
	INNER JOIN #Campaigns C ON C.PK_CampaignID = CS.FK_CampaignID

DELETE FROM SD
FROM
dbo.SettlementDiscounts SD
INNER JOIN dbo.SettlementLines SL ON SL.PK_SettlementLineID =  SD.FK_SettlementLineID
INNER JOIN dbo.ActivityLines AL ON AL.PK_ActivityLineID = SL.FK_ActivityLineID
INNER JOIN dbo.Activities A ON A.PK_ActivityID = AL.FK_ActivityID
INNER JOIN #Campaigns C ON C.PK_CampaignID = A.FK_CampaignID


DELETE FROM SL 
FROM 
dbo.SettlementLines SL
INNER JOIN dbo.ActivityLines AL ON AL.PK_ActivityLineID = SL.FK_ActivityLineID
INNER JOIN dbo.Activities A ON A.PK_ActivityID = AL.FK_ActivityID
INNER JOIN #Campaigns C ON C.PK_CampaignID = A.FK_CampaignID

DELETE FROM S
FROM 
	dbo.Settlements S
	LEFT JOIN dbo.SettlementLines SL  ON SL.FK_SettlementID = S.PK_SettlementID
	LEFT JOIN dbo.SettlementSubsider SSU ON SSU.FK_SettlementID = S.PK_SettlementID
	LEFT JOIN dbo.SettlementSubsiderCampaign SSC ON SSC.FK_SettlementID = S.PK_SettlementID
WHERE
	SL.FK_SettlementID IS NULL
	AND SSU.FK_SettlementID IS NULL
	AND SSC.FK_SettlementID IS NULL

--ACTIVITYLINES
DELETE FROM AL 
FROM 
	ActivityLines AL 
	INNER JOIN dbo.Activities A ON A.PK_ActivityID = AL.FK_ActivityID
	INNER JOIN #Campaigns C ON C.PK_CampaignID = A.FK_CampaignID

DELETE FROM AL 
FROM 
	dbo.auditActivityLines AL 
	INNER JOIN dbo.Activities A ON A.PK_ActivityID = AL.FK_ActivityID
	INNER JOIN #Campaigns C ON C.PK_CampaignID = A.FK_CampaignID

--ACTIVITYDELIVERIES
DELETE FROM AD 
FROM
	ActivityDeliveries AD 
	INNER JOIN dbo.Activities A ON A.PK_ActivityID = AD.FK_ActivityID
	INNER JOIN #Campaigns C ON C.PK_CampaignID = A.FK_CampaignID

DELETE FROM AD 
FROM
	auditActivityDeliveries AD 
	INNER JOIN dbo.Activities A ON A.PK_ActivityID = AD.FK_ActivityID
	INNER JOIN #Campaigns C ON C.PK_CampaignID = A.FK_CampaignID

--ACTIVITYSUBSIDER
DELETE FROM ASU 
FROM 
	ActivitySubsider ASU 
	INNER JOIN dbo.Activities A ON A.PK_ActivityID = ASU.FK_ActivityID
	INNER JOIN #Campaigns C ON C.PK_CampaignID = A.FK_CampaignID

DELETE FROM ASU 
FROM 
	auditActivitySubsider ASU 
	INNER JOIN dbo.Activities A ON A.PK_ActivityID = ASU.FK_ActivityID
	INNER JOIN #Campaigns C ON C.PK_CampaignID = A.FK_CampaignID

--ACTIVITY
DELETE FROM A
FROM 
	Activities A
	INNER JOIN #Campaigns C ON C.PK_CampaignID = A.FK_CampaignID
	
DELETE FROM A
FROM 
	auditActivities A
	INNER JOIN #Campaigns C ON C.PK_CampaignID = A.FK_CampaignID

--CAMPAIGNSUBSIDER
DELETE FROM CS
FROM
	CampaignSubsider CS
	INNER JOIN #Campaigns C ON C.PK_CampaignID = CS.FK_CampaignID 

DELETE FROM CS
FROM
	auditCampaignSubsider CS
	INNER JOIN #Campaigns C ON C.PK_CampaignID = CS.FK_CampaignID


--REBATE AGREEMENT EXPORT
DELETE FROM RAIL
FROM
	dbo.RebateAgreementExport RAE
	INNER JOIN dbo.RebateAgreementIdoc RAI ON RAI.ExportID = RAE.ExportID
	INNER JOIN dbo.RebateAgreementIdocLine RAIL ON RAIL.IdocID = RAI.IdocID
	INNER JOIN #Campaigns C ON C.PK_CampaignID = RAE.CampaignID

DELETE FROM RAIL
FROM
	dbo.RebateAgreementExport RAE
	INNER JOIN dbo.RebateAgreementIdoc RAI ON RAI.ExportID = RAE.ExportID
	INNER JOIN dbo.RebateAgreementAuditIdocLine RAIL ON RAIL.IdocID = RAI.IdocID
	INNER JOIN #Campaigns C ON C.PK_CampaignID = RAE.CampaignID

DELETE FROM RAI
FROM
	dbo.RebateAgreementExport RAE
	INNER JOIN dbo.RebateAgreementIdoc RAI ON RAI.ExportID = RAE.ExportID
	INNER JOIN #Campaigns C ON C.PK_CampaignID = RAE.CampaignID

DELETE FROM RAI
FROM
	dbo.RebateAgreementExport RAE
	INNER JOIN dbo.RebateAgreementAuditIdoc RAI ON RAI.ExportID = RAE.ExportID
	INNER JOIN #Campaigns C ON C.PK_CampaignID = RAE.CampaignID

DELETE FROM RAE
FROM
	dbo.RebateAgreementExport RAE
	INNER JOIN #Campaigns C ON C.PK_CampaignID = RAE.CampaignID

DELETE FROM RAE
FROM
	dbo.RebateAgreementAuditExport RAE
	INNER JOIN #Campaigns C ON C.PK_CampaignID = RAE.CampaignID

--LOGISTIC FORECAST
SELECT LF.PK_LogisticForecastID
INTO #LogisticForecast
FROM
	dbo.LogisticForecast LF
	INNER JOIN dbo.LogisticForecastLines LFL ON LFL.FK_LogisticForecastID = LF.PK_LogisticForecastID
	INNER JOIN #Campaigns C ON C.PK_CampaignID = LFL.FK_CampaignID

DELETE FROM LFL
FROM
	dbo.LogisticForecastLines LFL
	INNER JOIN #LogisticForecast LFO ON LFO.PK_LogisticForecastID= LFL.FK_LogisticForecastID

DELETE FROM LF
FROM
	dbo.LogisticForecast LF
	INNER JOIN #LogisticForecast LFO ON LFO.PK_LogisticForecastID= LF.PK_LogisticForecastID

--CAMPAIGN
DELETE FROM CA
FROM
Campaigns CA
INNER JOIN #Campaigns C ON C.PK_CampaignID = CA.PK_CampaignID

DELETE FROM CA
FROM
dbo.auditCampaigns CA
INNER JOIN #Campaigns C ON C.PK_CampaignID = CA.FK_CampaignID

DROP TABLE #Campaigns
DROP TABLE #LogisticForecast

--DELIVERY PROFILE
DELETE FROM DI
FROM 
	dbo.DeliveryItems DI
	INNER JOIN DeliveryProfiles DP ON DP.PK_DeliveryProfileID = DI.FK_DeliveryProfileID
	INNER JOIN #Participators P ON DP.FK_ParticipatorID = P.PK_ParticipatorID

DELETE FROM DP
FROM 
	dbo.DeliveryProfiles DP
	INNER JOIN #Participators P ON DP.FK_ParticipatorID = P.PK_ParticipatorID

--ALLOCATIONS
DELETE FROM AL
FROM 
	dbo.AllocationLines AL
	INNER JOIN dbo.Allocations A ON A.PK_AllocationID = AL.FK_AllocationID
	INNER JOIN #Participators P ON A.FK_ParticipatorID = P.PK_ParticipatorID

DELETE FROM AL
FROM 
	dbo.auditAllocationLines AL
	INNER JOIN dbo.Allocations A ON A.PK_AllocationID = AL.FK_AllocationID
	INNER JOIN #Participators P ON A.FK_ParticipatorID = P.PK_ParticipatorID

DELETE FROM A
FROM 
	dbo.Allocations A 
	INNER JOIN #Participators P ON A.FK_ParticipatorID = P.PK_ParticipatorID

DELETE FROM A
FROM 
	dbo.auditAllocations A 
	INNER JOIN #Participators P ON A.FK_ParticipatorID = P.PK_ParticipatorID

--LISTINGS
DELETE FROM L
FROM
	dbo.Listings L
	INNER JOIN #Participators P ON L.FK_ParticipatorID = P.PK_ParticipatorID

DELETE FROM L
FROM
	dbo.auditListings L
	INNER JOIN #Participators P ON L.FK_ParticipatorID = P.PK_ParticipatorID

--EXTERNAL LINKS
DELETE FROM ECL
FROM
	dbo.ExternalCustomerLinkLines ECL
	INNER JOIN #Participators P ON ECL.FK_ParticipatorID = P.PK_ParticipatorID

--DISCOUNTS
DELETE FROM BDE
FROM
	dbo.BaseDiscountsEdit BDE
	INNER JOIN #Participators P ON BDE.FK_ParticipatorID = P.PK_ParticipatorID

DELETE FROM BD
FROM
	dbo.BaseDiscounts BD
	INNER JOIN #Participators P ON BD.FK_ParticipatorID = P.PK_ParticipatorID

--CUSTOMER HIERARCHY AND CANNIBALISATION
DELETE FROM CH
FROM
	dbo.CustomerHierarchies CH
	INNER JOIN #Participators P ON CH.FK_ParticipatorID = P.PK_ParticipatorID
		
DELETE FROM C
FROM
	dbo.Cannibalisation C
	INNER JOIN #Participators P ON C.FK_ParticipatorID = P.PK_ParticipatorID

DELETE FROM PCP
FROM
	dbo.ParticipatorContactPerson PCP
	INNER JOIN #Participators P ON PCP.FK_ParticipatorID = P.PK_ParticipatorID

DELETE FROM BDP
FROM
	dbo.BaselineDipProfiles BDP
	INNER JOIN #Participators P ON BDP.FK_ParticipantId = P.PK_ParticipatorID

--PARTICIPATOR
DELETE FROM PA
FROM
	dbo.Participators PA
	INNER JOIN #Participators P ON PA.PK_ParticipatorID = P.PK_ParticipatorID

DROP TABLE #Participators

--ROLLBACK
--COMMIT

