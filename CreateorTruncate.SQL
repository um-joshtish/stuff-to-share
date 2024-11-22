DECLARE @DynamicSQL NVARCHAR(MAX);
DECLARE @RecordExists BIT = 0;

-- Validate the database name, schema, and table name to prevent SQL injection
IF EXISTS (
    SELECT * 
    FROM sys.tables t
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    INNER JOIN sys.databases d ON d.database_id = DB_ID(@DatabaseName)
    WHERE t.name = @TableName AND s.name = @SchemaName
)
BEGIN
    -- Construct dynamic SQL to check for record existence
    SET @DynamicSQL = N'SELECT TOP 1 @RecordExistsOut = 1 FROM [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + ']'
    EXEC sp_executesql @DynamicSQL, N'@RecordExistsOut BIT OUTPUT', @RecordExists OUTPUT

    IF @Action = 'CHECK'
    BEGIN
        IF @RecordExists = 1
            SELECT 'Record exists in the table.' AS Message
        ELSE
            SELECT 'No records found in the table.' AS Message
    END
    ELSE IF @Action = 'TRUNCATE'
    BEGIN
        -- If a record exists, truncate the table
        IF @RecordExists = 1
        BEGIN
            SET @DynamicSQL = N'TRUNCATE TABLE [' + @DatabaseName + '].[' + @SchemaName + '].[' + @TableName + ']'
            EXEC sp_executesql @DynamicSQL
            SELECT 'Table truncated successfully.' AS Message
        ELSE
            SELECT 'No records found to truncate.' AS Message
        END
    END
    ELSE
    BEGIN
        SELECT 'Invalid action specified. Use ''CHECK'' or ''TRUNCATE''.' AS Message
    END
END
ELSE
BEGIN
    -- Handle invalid input
    RAISERROR('The specified database, schema, or table does not exist or the names are invalid.', 16, 1)
END
