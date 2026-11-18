CREATE DATABASE DW_BinhDuong_RealEstate;
GO

-- 2. Su dung Database
USE DW_BinhDuong_RealEstate;
GO

-- 3. Kiem tra Database
SELECT name
FROM sys.databases
WHERE name = 'DW_BinhDuong_RealEstate';
GO

-- Tao staging 
CREATE TABLE Staging_RealEstate (
    StagingID INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(MAX),
    description NVARCHAR(MAX),
    property_type_name NVARCHAR(255),
    province_name NVARCHAR(255),
    district_name NVARCHAR(255),
    ward_name NVARCHAR(255),
    street_name NVARCHAR(255),
    project_name NVARCHAR(255),
    price DECIMAL(19,2),
    area DECIMAL(12,2),
    frontage_width DECIMAL(10,2),
    bedroom_count INT,
    bathroom_count INT,
    house_direction NVARCHAR(255),
    full_date DATE,
    post_hour INT,
    is_outlier TINYINT
);
GO

-- Kiem tra bang
SELECT * FROM Staging_RealEstate;
GO

--  Toongr so dong
SELECT
    COUNT(*) AS TotalRecords,
    COUNT(price) AS TotalPrice,
    COUNT(area) AS TotalArea,
    SUM(CASE WHEN is_outlier = 1 THEN 1 ELSE 0 END)
        AS TotalOutliers
FROM Staging_RealEstate;


-- 1. Kiểm tra tổng số dòng
SELECT COUNT(*) AS TotalRows
FROM Staging_RealEstate;

-- 2. Kiểm tra dữ liệu bị thiếu
SELECT
    SUM(CASE WHEN name IS NULL OR LTRIM(RTRIM(name)) = '' THEN 1 ELSE 0 END) AS MissingName,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS MissingPrice,
    SUM(CASE WHEN area IS NULL THEN 1 ELSE 0 END) AS MissingArea,
    SUM(CASE WHEN full_date IS NULL THEN 1 ELSE 0 END) AS MissingDate,
    SUM(CASE WHEN province_name IS NULL OR LTRIM(RTRIM(province_name)) = '' THEN 1 ELSE 0 END) AS MissingProvince
FROM Staging_RealEstate;

-- 1. Dim_Date
CREATE TABLE dbo.Dim_Date (
    date_key INT PRIMARY KEY,
    full_date DATE NULL,
    day_of_month TINYINT NULL,
    day_of_week TINYINT NULL,
    day_name NVARCHAR(20) NULL,
    week TINYINT NULL,
    month_num TINYINT NULL,
    month_name NVARCHAR(20) NULL,
    quarter_num TINYINT NULL,
    quarter_name NVARCHAR(20) NULL,
    year SMALLINT NULL,
    holiday_name NVARCHAR(50) NULL,
    is_holiday BIT NULL
);
GO

-- 2. Dim_Time
CREATE TABLE dbo.Dim_Time (
    time_key INT PRIMARY KEY,
    day_period NVARCHAR(30) NULL
);
GO

-- 3. Dim_Location
CREATE TABLE dbo.Dim_Location (
    location_key INT IDENTITY(1,1) PRIMARY KEY,
    province_name NVARCHAR(50),
    district_name NVARCHAR(50),
    ward_name NVARCHAR(50),
    street_name NVARCHAR(100)
);
GO

-- 4. Dim_PropertyType
CREATE TABLE dbo.Dim_PropertyType (
    property_type_key INT IDENTITY(1,1) PRIMARY KEY,
    property_type_name NVARCHAR(50),
    property_type_group NVARCHAR(50)
);
GO

-- 5. Dim_Project
CREATE TABLE dbo.Dim_Project (
    project_key INT IDENTITY(1,1) PRIMARY KEY,
    project_name NVARCHAR(100)
);
GO

-- 6. Dim_Direction
CREATE TABLE dbo.Dim_Direction (
    direction_key INT IDENTITY(1,1) PRIMARY KEY,
    house_direction NVARCHAR(30),
    direction_group NVARCHAR(30)
);
GO

-- 7. Dim_Segment
CREATE TABLE dbo.Dim_Segment (
    segment_key INT PRIMARY KEY,
    segment_name NVARCHAR(30),
    sort_order TINYINT
);
GO

-- Tạo bảng Fact_Listing
CREATE TABLE dbo.Fact_Listing (
    fact_id INT IDENTITY(1,1) PRIMARY KEY,

    date_key INT NOT NULL,
    time_key INT NOT NULL,
    location_key INT NOT NULL,
    property_type_key INT NOT NULL,
    project_key INT NOT NULL,
    direction_key INT NOT NULL,
    segment_key INT NOT NULL,

    price BIGINT NOT NULL,
    area DECIMAL(12,3) NULL,
    frontage_width DECIMAL(10,2) NULL,
    bedroom_count TINYINT NULL,
    bathroom_count TINYINT NULL,

    total_listings TINYINT NOT NULL DEFAULT 1,
    is_outlier BIT NOT NULL,

    CONSTRAINT FK_Listing_Date
        FOREIGN KEY (date_key)
        REFERENCES dbo.Dim_Date(date_key),

    CONSTRAINT FK_Listing_Time
        FOREIGN KEY (time_key)
        REFERENCES dbo.Dim_Time(time_key),

    CONSTRAINT FK_Listing_Location
        FOREIGN KEY (location_key)
        REFERENCES dbo.Dim_Location(location_key),

    CONSTRAINT FK_Listing_PropertyType
        FOREIGN KEY (property_type_key)
        REFERENCES dbo.Dim_PropertyType(property_type_key),

    CONSTRAINT FK_Listing_Project
        FOREIGN KEY (project_key)
        REFERENCES dbo.Dim_Project(project_key),

    CONSTRAINT FK_Listing_Direction
        FOREIGN KEY (direction_key)
        REFERENCES dbo.Dim_Direction(direction_key),

    CONSTRAINT FK_Listing_Segment
        FOREIGN KEY (segment_key)
        REFERENCES dbo.Dim_Segment(segment_key)
);
GO

---Tạo bảng Fact_Listing_Detail
CREATE TABLE dbo.Fact_Listing_Detail (
    fact_id INT PRIMARY KEY,
    name NVARCHAR(300) NULL,
    description_raw NVARCHAR(MAX) NULL,

    CONSTRAINT FK_Listing_Detail
        FOREIGN KEY (fact_id)
        REFERENCES dbo.Fact_Listing(fact_id)
);
GO


--3.4. Tạo bảng cấu hình ngưỡng phân khúc 
CREATE TABLE dbo.Cfg_Segment_Threshold (
    version INT NOT NULL,
    effective_date DATE NOT NULL,
    segment_key INT NOT NULL,
    min_price_per_m2 DECIMAL(19,2) NULL,
    max_price_per_m2 DECIMAL(19,2) NULL,

    CONSTRAINT PK_Cfg_Segment_Threshold
        PRIMARY KEY (version, segment_key),

    CONSTRAINT FK_Cfg_Segment
        FOREIGN KEY (segment_key)
        REFERENCES dbo.Dim_Segment(segment_key)
);
GO


-- Dim_Date: thành viên không xác định
INSERT INTO dbo.Dim_Date (date_key)
VALUES (-1);

-- Dim_Time: thành viên không xác định
INSERT INTO dbo.Dim_Time (time_key, day_period)
VALUES (-1, N'Không xác định');

-- Dim_Location: thành viên không xác định
SET IDENTITY_INSERT dbo.Dim_Location ON;

INSERT INTO dbo.Dim_Location
(location_key, province_name, district_name, ward_name, street_name)
VALUES (-1, N'Không xác định', N'Không xác định',
        N'Không xác định', N'Không xác định');

SET IDENTITY_INSERT dbo.Dim_Location OFF;

-- Dim_PropertyType
SET IDENTITY_INSERT dbo.Dim_PropertyType ON;

INSERT INTO dbo.Dim_PropertyType
(property_type_key, property_type_name, property_type_group)
VALUES (-1, N'Không xác định', N'Không xác định');

SET IDENTITY_INSERT dbo.Dim_PropertyType OFF;

-- Dim_Project: -1 và 0
SET IDENTITY_INSERT dbo.Dim_Project ON;

INSERT INTO dbo.Dim_Project (project_key, project_name)
VALUES
(-1, N'Không xác định'),
(0, N'Nhà lẻ (Không thuộc dự án)');

SET IDENTITY_INSERT dbo.Dim_Project OFF;

-- Dim_Direction
SET IDENTITY_INSERT dbo.Dim_Direction ON;

INSERT INTO dbo.Dim_Direction
(direction_key, house_direction, direction_group)
VALUES (-1, N'Không xác định', N'Không xác định');

SET IDENTITY_INSERT dbo.Dim_Direction OFF;

-- Dim_Segment
INSERT INTO dbo.Dim_Segment
(segment_key, segment_name, sort_order)
VALUES
(-1, N'Không xác định', 0),
(1, N'Phân khúc thấp', 1),
(2, N'Trung bình', 2),
(3, N'Cao cấp', 3),
(4, N'Rất cao', 4);
GO

SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;


-- Kiểm tra tên database và số lượng bản ghi các bảng
SELECT
    DB_NAME() AS CurrentDatabase;

SELECT
    s.name AS SchemaName,
    t.name AS TableName,
    SUM(p.rows) AS TotalRows
FROM sys.tables t
JOIN sys.schemas s
    ON t.schema_id = s.schema_id
LEFT JOIN sys.partitions p
    ON t.object_id = p.object_id
    AND p.index_id IN (0, 1)
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

-- Kiểm tra cấu trúc các bảng cũ
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN (
    'Fact_RealEstate',
    'Dim_Date',
    'Dim_Time',
    'Dim_Location',
    'Dim_PropertyType',
    'Dim_Project',
    'Dim_Direction',
    'Dim_Segment',
    'Staging_RealEstate'
)
ORDER BY TABLE_NAME, ORDINAL_POSITION;

--- Kiểm tra các khóa ngoại đang tồn tại
SELECT
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    COL_NAME(
        fkc.parent_object_id,
        fkc.parent_column_id
    ) AS ColumnName,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc
    ON fk.object_id = fkc.constraint_object_id
ORDER BY TableName;

-- Kiểm tra các bảng Fact hiện có
SELECT
    name AS TableName,
    create_date
FROM sys.tables
WHERE name LIKE 'Fact%'
ORDER BY name;

--Kiểm tra số lượng dữ liệu trong từng bảng
SELECT
    t.name AS TableName,
    SUM(p.rows) AS TotalRows
FROM sys.tables t
JOIN sys.partitions p
    ON t.object_id = p.object_id
WHERE p.index_id IN (0, 1)
  AND (
      t.name LIKE 'Fact%'
      OR t.name LIKE 'Dim%'
      OR t.name LIKE 'Staging%'
  )
GROUP BY t.name
ORDER BY t.name;

-- Kiểm tra cấu trúc hai bảng Fact
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME IN (
    'Fact_RealEstate',
    'Fact_Listing',
    'Fact_Listing_Detail'
)
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- Kiểm tra Fact_RealEstate
IF OBJECT_ID('dbo.Fact_RealEstate', 'U') IS NOT NULL
    EXEC('SELECT TOP 5 * FROM dbo.Fact_RealEstate');

-- Kiểm tra Fact_Listing
IF OBJECT_ID('dbo.Fact_Listing', 'U') IS NOT NULL
    EXEC('SELECT TOP 5 * FROM dbo.Fact_Listing');

-- Kiểm tra Fact_Listing_Detail
IF OBJECT_ID('dbo.Fact_Listing_Detail', 'U') IS NOT NULL
    EXEC('SELECT TOP 5 * FROM dbo.Fact_Listing_Detail');

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
ORDER BY TABLE_NAME, ORDINAL_POSITION;

SELECT
    s.name AS SchemaName,
    t.name AS TableName
FROM sys.tables t
JOIN sys.schemas s
    ON t.schema_id = s.schema_id
ORDER BY t.name;

-- sript dim date  
USE DW_BinhDuong_RealEstate;

;WITH DateList AS
(
    SELECT CAST('2025-01-01' AS DATE) AS full_date

    UNION ALL

    SELECT DATEADD(DAY, 1, full_date)
    FROM DateList
    WHERE full_date < '2025-12-31'
)
INSERT INTO dbo.Dim_Date
(
    date_key,
    full_date,
    day_of_month,
    day_of_week,
    day_name,
    week,
    month_num,
    month_name,
    quarter_num,
    quarter_name,
    year,
    holiday_name,
    is_holiday
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), d.full_date, 112)),
    d.full_date,
    DAY(d.full_date),
    (DATEDIFF(DAY, '19000101', d.full_date) % 7) + 1,

    CASE (DATEDIFF(DAY, '19000101', d.full_date) % 7) + 1
        WHEN 1 THEN N'Thứ Hai'
        WHEN 2 THEN N'Thứ Ba'
        WHEN 3 THEN N'Thứ Tư'
        WHEN 4 THEN N'Thứ Năm'
        WHEN 5 THEN N'Thứ Sáu'
        WHEN 6 THEN N'Thứ Bảy'
        WHEN 7 THEN N'Chủ Nhật'
    END,

    DATEPART(ISO_WEEK, d.full_date),
    MONTH(d.full_date),
    N'Tháng ' + CAST(MONTH(d.full_date) AS NVARCHAR(2)),
    DATEPART(QUARTER, d.full_date),
    N'Q' + CAST(DATEPART(QUARTER, d.full_date) AS NVARCHAR(1)),
    YEAR(d.full_date),
    NULL,
    0

FROM DateList d
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Dim_Date x
    WHERE x.date_key =
        CONVERT(INT, CONVERT(CHAR(8), d.full_date, 112))
)
OPTION (MAXRECURSION 400);

SELECT *
FROM dbo.Dim_Segment
ORDER BY sort_order;

--- tính giá/m²:
SELECT
    StagingID,
    price,
    area,
    price / NULLIF(area, 0) AS price_per_m2
FROM dbo.Staging_RealEstate
WHERE price > 0
  AND area > 0;


  -- Tính các phân vị 25%, 50%, 75%
  SELECT DISTINCT
    PERCENTILE_CONT(0.25)
        WITHIN GROUP (ORDER BY price / NULLIF(area, 0))
        OVER () AS P25,

    PERCENTILE_CONT(0.50)
        WITHIN GROUP (ORDER BY price / NULLIF(area, 0))
        OVER () AS P50,

    PERCENTILE_CONT(0.75)
        WITHIN GROUP (ORDER BY price / NULLIF(area, 0))
        OVER () AS P75

FROM dbo.Staging_RealEstate
WHERE price > 0
  AND area > 0;

---Lưu ngưỡng vào Cfg_Segment_Threshold
INSERT INTO dbo.Cfg_Segment_Threshold
(
    version,
    effective_date,
    segment_key,
    min_price_per_m2,
    max_price_per_m2
)
VALUES
(1, '2025-01-01', 1, 0, 24280575.5395683),
(1, '2025-01-01', 2, 24280575.5395683, 36666666.6666667),
(1, '2025-01-01', 3, 36666666.6666667, 47972972.972973),
(1, '2025-01-01', 4, 47972972.972973, NULL);


SELECT *
FROM dbo.Cfg_Segment_Threshold
ORDER BY version, segment_key;

EXEC sp_help 'Dim_Location';

SELECT * FROM dbo.Dim_Direction;

--- Kiểm tra các Dimension đã hoàn thành
SELECT 'Dim_Date' AS TableName, COUNT(*) AS TotalRows FROM Dim_Date
UNION ALL
SELECT 'Dim_Time', COUNT(*) FROM Dim_Time
UNION ALL
SELECT 'Dim_Location', COUNT(*) FROM Dim_Location
UNION ALL
SELECT 'Dim_Direction', COUNT(*) FROM Dim_Direction
UNION ALL
SELECT 'Dim_Project', COUNT(*) FROM Dim_Project
UNION ALL
SELECT 'Dim_PropertyType', COUNT(*) FROM Dim_PropertyType
UNION ALL
SELECT 'Dim_Segment', COUNT(*) FROM Dim_Segment;


SELECT * FROM Dim_Direction;
SELECT * FROM Dim_Project;
SELECT * FROM Dim_PropertyType;

UPDATE dbo.Dim_Direction
SET house_direction =
    CASE
        WHEN REPLACE(REPLACE(house_direction, N' ', N''), N'-', N'') = N'ĐôngBắc'
            THEN N'Đông Bắc'
        WHEN REPLACE(REPLACE(house_direction, N' ', N''), N'-', N'') = N'TâyBắc'
            THEN N'Tây Bắc'
        WHEN REPLACE(REPLACE(house_direction, N' ', N''), N'-', N'') = N'ĐôngNam'
            THEN N'Đông Nam'
        WHEN REPLACE(REPLACE(house_direction, N' ', N''), N'-', N'') = N'TâyNam'
            THEN N'Tây Nam'
        ELSE LTRIM(RTRIM(house_direction))
    END;

SELECT COUNT(*) AS TotalRows
FROM dbo.Staging_RealEstate;

-- 1. Xóa dữ liệu DIM đã nạp Xóa data trc khi nạp
TRUNCATE TABLE dbo.Staging_RealEstate;
GO

DELETE FROM dbo.Dim_Location
WHERE location_key <> -1;

DELETE FROM dbo.Dim_PropertyType
WHERE property_type_key <> -1;

DELETE FROM dbo.Dim_Project
WHERE project_key NOT IN (-1, 0);

DELETE FROM dbo.Dim_Direction
WHERE direction_key <> -1;

DELETE FROM dbo.Dim_Time
WHERE time_key <> -1;

-- 2. Đặt lại IDENTITY
DBCC CHECKIDENT ('dbo.Dim_Location', RESEED, 0);
DBCC CHECKIDENT ('dbo.Dim_PropertyType', RESEED, 0);
DBCC CHECKIDENT ('dbo.Dim_Project', RESEED, 0);
DBCC CHECKIDENT ('dbo.Dim_Direction', RESEED, 0);
GO


-- kiem tra so dong 
SELECT 'Staging_RealEstate' AS TableName, COUNT(*) AS TotalRows
FROM dbo.Staging_RealEstate

UNION ALL
SELECT 'Dim_Date', COUNT(*) FROM dbo.Dim_Date

UNION ALL
SELECT 'Dim_Time', COUNT(*) FROM dbo.Dim_Time

UNION ALL
SELECT 'Dim_Location', COUNT(*) FROM dbo.Dim_Location

UNION ALL
SELECT 'Dim_PropertyType', COUNT(*) FROM dbo.Dim_PropertyType

UNION ALL
SELECT 'Dim_Project', COUNT(*) FROM dbo.Dim_Project

UNION ALL
SELECT 'Dim_Direction', COUNT(*) FROM dbo.Dim_Direction

UNION ALL
SELECT 'Dim_Segment', COUNT(*) FROM dbo.Dim_Segment;

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE,
    COLUMNPROPERTY(
        OBJECT_ID('dbo.Fact_Listing'),
        COLUMN_NAME,
        'IsIdentity'
    ) AS IsIdentity
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Fact_Listing'
ORDER BY ORDINAL_POSITION;

EXEC sp_help 'dbo.Fact_Listing_Detail';

SELECT 'Fact_Listing' AS TableName, COUNT(*) AS TotalRows
FROM dbo.Fact_Listing



SELECT 'Fact_Listing_Detail', COUNT(*)
FROM dbo.Fact_Listing_Detail;

ALTER TABLE dbo.Fact_Listing
ADD source_staging_id INT NULL;

CREATE UNIQUE INDEX UX_Fact_Listing_Source
ON dbo.Fact_Listing(source_staging_id)
WHERE source_staging_id IS NOT NULL;

SELECT TOP 10
    fact_id,
    source_staging_id,
    date_key,
    time_key,
    price,
    area
FROM dbo.Fact_Listing;

SELECT 'Staging_RealEstate' AS TableName, COUNT(*) AS TotalRows
FROM dbo.Staging_RealEstate
UNION ALL
SELECT 'Fact_Listing', COUNT(*) FROM dbo.Fact_Listing
UNION ALL
SELECT 'Fact_Listing_Detail', COUNT(*) FROM dbo.Fact_Listing_Detail;

SELECT * FROM dbo.Dim_Segment
ORDER BY sort_order;

SELECT * FROM dbo.Cfg_Segment_Threshold
ORDER BY version, segment_key;

SELECT
    MIN(post_hour) AS MinHour,
    MAX(post_hour) AS MaxHour,
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN post_hour IS NULL THEN 1 ELSE 0 END) AS NullHours
FROM dbo.Staging_RealEstate;

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Fact_Listing';

SELECT TOP 10
    StagingID,
    name,
    property_type_name,
    province_name,
    district_name,
    house_direction,
    price,
    area,
    post_hour,
    full_date
FROM dbo.Staging_RealEstate;

SELECT post_hour, COUNT(*) AS so_luong
FROM dbo.Staging_RealEstate
GROUP BY post_hour
ORDER BY post_hour;

SELECT
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    MIN(area) AS min_area,
    MAX(area) AS max_area,
    MIN(price / NULLIF(area, 0)) AS min_price_m2,
    MAX(price / NULLIF(area, 0)) AS max_price_m2
FROM dbo.Staging_RealEstate;

--- 

WITH SegmentData AS
(
    SELECT
        CASE
            WHEN price IS NULL
              OR area IS NULL
              OR area <= 0
              OR is_outlier = 1 THEN -1
            WHEN price / NULLIF(area, 0) < 24280575.54 THEN 1
            WHEN price / NULLIF(area, 0) < 36666666.67 THEN 2
            WHEN price / NULLIF(area, 0) < 47972972.97 THEN 3
            ELSE 4
        END AS segment_key
    FROM dbo.Staging_RealEstate
)
SELECT
    segment_key,
    COUNT(*) AS total_listings
FROM SegmentData
GROUP BY segment_key
ORDER BY segment_key;

SELECT *
FROM dbo.Dim_Segment
ORDER BY sort_order;

-- 1. Kiểm tra tổng số dòng
SELECT
    COUNT(*) AS total_fact,
    COUNT(DISTINCT source_staging_id) AS unique_staging
FROM dbo.Fact_Listing;

-- 2. Kiểm tra dữ liệu mẫu
SELECT TOP 10 * FROM dbo.Fact_Listing ORDER BY fact_id;

-- 3. Kiểm tra các dòng bị trùng StagingID
SELECT source_staging_id, COUNT(*) AS so_lan
FROM dbo.Fact_Listing
GROUP BY source_staging_id
HAVING COUNT(*) > 1;

--Nạp dữ liệu vào Fact_Listing_Detail
INSERT INTO dbo.Fact_Listing_Detail
(
    fact_id,
    name,
    description_raw
)
SELECT
    f.fact_id,
    CAST(s.name AS NVARCHAR(300)),
    CAST(s.description AS NVARCHAR(MAX))
FROM dbo.Staging_RealEstate s
INNER JOIN dbo.Fact_Listing f
    ON f.source_staging_id = s.StagingID
WHERE NOT EXISTS
(
    SELECT 1
    FROM dbo.Fact_Listing_Detail d
    WHERE d.fact_id = f.fact_id
);


-- Kiểm tra kết quả
SELECT COUNT(*) AS total_detail
FROM dbo.Fact_Listing_Detail;

SELECT TOP 10 *
FROM dbo.Fact_Listing_Detail
ORDER BY fact_id;


-- 1. Kiểm tra số lượng dữ liệu Fact
SELECT COUNT(*) AS Total_Fact
FROM Fact_Listing;

-- 2. Kiểm tra các bảng Dimension
SELECT 'Dim_Date' AS TableName, COUNT(*) AS TotalRows
FROM Dim_Date
UNION ALL
SELECT 'Dim_Time', COUNT(*) FROM Dim_Time
UNION ALL
SELECT 'Dim_Location', COUNT(*) FROM Dim_Location
UNION ALL
SELECT 'Dim_PropertyType', COUNT(*) FROM Dim_PropertyType
UNION ALL
SELECT 'Dim_Project', COUNT(*) FROM Dim_Project;

SELECT COUNT(*) AS Missing_Location
FROM Fact_Listing f
LEFT JOIN Dim_Location d
    ON f.location_key = d.location_key
WHERE d.location_key IS NULL;

-- Thêm cột Price_Per_M2 vào bảng Fact_Listing
ALTER TABLE dbo.Fact_Listing
ADD Price_Per_M2 DECIMAL(18,2) NULL;

SELECT COLUMN_NAME, DATA_TYPE, NUMERIC_PRECISION, NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Fact_Listing'
  AND COLUMN_NAME = 'Price_Per_M2';

ALTER TABLE dbo.Fact_Listing
ADD
    Supply_Share_Pct DECIMAL(18,4) NULL,
    Price_Growth_MoM DECIMAL(18,4) NULL;

SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Fact_Listing'
AND COLUMN_NAME IN ('Supply_Share_Pct', 'Price_Growth_MoM');