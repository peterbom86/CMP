CREATE PROCEDURE [dbo].[rdh_ExcelForbrugerServiceRapport]
	@CategoryGroupID INT,
	@GrossistID nvarchar(255),
    @ChainID nvarchar(255)
as

DECLARE @date DATETIME
SET @date = GETDATE()

SELECT
	Grossist.Label AS Grossist, Chain.PK_ParticipatorID ChainID, Chain.Label AS Kæde, ProductHierarchies_1.Label AS Aktivitet, PK_ProductID,
	dbo.Products.ProductCode AS Produktkode, dbo.Products.Label AS Produkt, dbo.ListingTypes.Label AS Sortiment, 
	dbo.ListingTypes.ShortLabel AS Sortimentskode, PK_ListingTypeID SortimentsID,
	dbo.ListingTypes.ColorCode
INTO #tempTable
FROM
        dbo.Participators Chain
	INNER JOIN dbo.Listings ON Chain.PK_ParticipatorID = dbo.Listings.FK_ParticipatorID 
	INNER JOIN dbo.ListingTypes ON dbo.Listings.FK_ListingTypeID = dbo.ListingTypes.PK_ListingTypeID 
	INNER JOIN dbo.Products ON dbo.Listings.FK_ProductID = dbo.Products.PK_ProductID 
	INNER JOIN dbo.Participators Grossist ON Chain.FK_ParentID = Grossist.PK_ParticipatorID
	INNER JOIN dbo.ProductStatus ON dbo.ProductStatus.PK_ProductStatusID = dbo.Products.FK_ProductStatusID
	INNER JOIN dbo.ProductHierarchies ON dbo.Products.PK_ProductID = dbo.ProductHierarchies.FK_ProductID 
	INNER JOIN dbo.ProductHierarchies ProductHierarchies_1 ON dbo.ProductHierarchies.FK_ProductHierarchyParentID = ProductHierarchies_1.PK_ProductHierarchyID 
    INNER JOIN dbo.CategoryGroups ON ProductHierarchies_1.FK_CategoryGroupID = dbo.CategoryGroups.PK_CategoryGroupID
    INNER JOIN dbo.Split(@GrossistID, '~' ) as s ON s.String = Grossist.PK_ParticipatorID
    INNER JOIN dbo.Split(@ChainID, '~') as s2 on s2.String = Chain.PK_ParticipatorID OR s2.String = '0'
WHERE
	Chain.FK_ParticipatorTypeID = 3 AND Chain.FK_ParticipatorStatusID = 1 AND dbo.ProductStatus.isHidden = 0 --AND Grossist.PK_ParticipatorID = @GrossistID
	AND dbo.Listings.PeriodFrom <= @date AND dbo.Listings.PeriodTo >= @date AND dbo.CategoryGroups.PK_CategoryGroupID = @CategoryGroupID
    AND ListingTypes.IsHidden = 0

DECLARE @Kæde NVARCHAR(50)
DECLARE @FieldList NVARCHAR(MAX)
DECLARE @JoinList NVARCHAR(MAX)

SELECT ChainID, MAX(Kæde) Kæde, CAST(ROW_NUMBER() OVER (ORDER BY MAX(Kæde)) AS NVARCHAR) RowNumber 
INTO #tempChain
FROM #tempTable AS tt
GROUP BY ChainID

SELECT @FieldList = ISNULL(@FieldList, '') +
  ', tt' + RowNumber + '.Sortimentskode + '' - '' + tt' + RowNumber + '.Sortiment [Col' + RowNumber + '_Chain_' + Kæde + '], tt' + RowNumber + '.ColorCode AS [Col' + RowNumber + '_ColorCode]',
  @JoinList = ISNULL(@JoinList, '') + 
    ' LEFT JOIN #tempTable AS tt' + RowNumber + ' ON tt.PK_ProductID = tt' + RowNumber + '.PK_ProductID AND tt' + RowNumber + '.ChainID = ' + CAST(ChainID AS NVARCHAR)
FROM #tempChain AS tc

DECLARE @SQL NVARCHAR(MAX)

SET @SQL = 'SELECT DISTINCT tt.Aktivitet, tt.PK_ProductID, tt.Produktkode, tt.Produkt' + @FieldList + '
FROM #tempTable AS tt' + @JoinList

PRINT @SQL
EXEC (@SQL)

DROP TABLE #tempTable
DROP TABLE #tempChain


