CREATE PROCEDURE [dbo].[CreateAudits]

AS

DECLARE @name NVARCHAR(255)
DECLARE @sql NVARCHAR(4000)
DECLARE @PrimaryKey NVARCHAR(255)
DECLARE @ForeignKey NVARCHAR(255)
DECLARE @FieldList NVARCHAR(1000)
DECLARE @FieldListDeleted NVARCHAR(1000)
DECLARE @FieldListInserted NVARCHAR(1000)
DECLARE @FieldListCompare NVARCHAR(1000)

DECLARE AuditCursor CURSOR FOR
SELECT o.name
FROM sysobjects AS o
  INNER JOIN sysproperties AS p ON o.id = p.id AND p.smallid = 0 AND p.name = 'MakeAudit' AND p.value = 'True'
  
OPEN AuditCursor

FETCH NEXT FROM AuditCursor INTO @name

WHILE @@FETCH_STATUS = 0
BEGIN

  EXEC CreateAuditTable @name
  
  SELECT @PrimaryKey = KCU.COLUMN_NAME, @ForeignKey = 'FK_' + KCU.COLUMN_NAME
  FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS TC
    INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU ON TC.TABLE_SCHEMA = KCU.TABLE_SCHEMA AND
      TC.CONSTRAINT_NAME = KCU.CONSTRAINT_NAME
  WHERE TC.CONSTRAINT_TYPE = 'PRIMARY KEY' AND TC.TABLE_SCHEMA = 'dbo' AND TC.TABLE_NAME = @name
  ORDER BY KCU.ORDINAL_POSITION

  SELECT @FieldList = ISNULL(@FieldList + ', ', '') + COLUMN_NAME,
    @FieldListInserted = ISNULL(@FieldListInserted + ', ', '') + 'i.' + COLUMN_NAME,
    @FieldListDeleted = ISNULL(@FieldListDeleted + ', ', '') + 'd.' + COLUMN_NAME,
    @FieldListCompare = ISNULL(@FieldListCompare + ' OR 
        ', '') + 'ISNULL(i.' + COLUMN_NAME + ', ''-1'') <> ISNULL(d.' + COLUMN_NAME + ', ''-1'')'
  FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_NAME = @name AND COLUMN_NAME <> @PrimaryKey

  SET @sql = 'IF EXISTS ( SELECT name FROM sysobjects WHERE name = ''' + @name + '_Events'' AND Type = ''TR'')
    DROP TRIGGER ' + @name + '_Events'

  EXEC ( @sql )
  
  SET @sql = 'CREATE TRIGGER [dbo].[' + @name + '_Events]
   ON  [' + @name + ']
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
  SET NOCOUNT ON;

  IF ( SELECT COUNT(*) FROM Inserted ) = 0
  BEGIN
  -- DELETED
    INSERT INTO ' + @name + '_Audit ( ' + @ForeignKey + ', ' + @FieldList + ', AuditType )
    SELECT d.' + @PrimaryKey + ', ' + @FieldListDeleted + ', ''DELETED'' AuditType
    FROM Deleted AS d
  END
  ELSE
  BEGIN
    IF ( SELECT COUNT(*) FROM Deleted ) = 0
    BEGIN
    -- INSERTED
    INSERT INTO ' + @name + '_Audit ( ' + @ForeignKey + ', ' + @FieldList + ', AuditType )
    SELECT i.' + @PrimaryKey + ', ' + @FieldListInserted + ', ''INSERTED'' AuditType
      FROM Inserted AS i
    END
    ELSE
    BEGIN
    -- UPDATED
    INSERT INTO ' + @name + '_Audit ( ' + @ForeignKey + ', ' + @FieldList + ', AuditType )
    SELECT i.' + @PrimaryKey + ', ' + @FieldListDeleted + ', ''UPDATED'' AuditType
      FROM Inserted AS i
        INNER JOIN Deleted AS d ON d.' + @PrimaryKey + ' = i.' + @PrimaryKey + '
      WHERE ' + @FieldListCompare + '
    END
  END
END '

  EXEC ( @sql )
  SET @FieldList = NULL
  SET @FieldListInserted = NULL
  SET @FieldListDeleted = NULL
  SET @FieldListCompare = NULL
  
  FETCH NEXT FROM AuditCursor INTO @name
END

CLOSE AuditCursor
DEALLOCATE AuditCursor


