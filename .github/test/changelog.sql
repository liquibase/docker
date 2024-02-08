USE master;

-- Create a sample table in the dbo schema
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'SampleTable')
BEGIN
    CREATE TABLE dbo.SampleTable (
        id INT PRIMARY KEY NOT NULL,
        name VARCHAR(255)
        -- Add more columns as needed
    );

    -- Example: Add an index on the 'name' column
    -- CREATE INDEX idx_name ON dbo.SampleTable (name);
END;
