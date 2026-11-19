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

-- 2. Kiểm tra dữ liệu bị thiếu
SELECT
    SUM(CASE WHEN name IS NULL OR LTRIM(RTRIM(name)) = '' THEN 1 ELSE 0 END) AS MissingName,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS MissingPrice,
    SUM(CASE WHEN area IS NULL THEN 1 ELSE 0 END) AS MissingArea,
    SUM(CASE WHEN full_date IS NULL THEN 1 ELSE 0 END) AS MissingDate,
    SUM(CASE WHEN province_name IS NULL OR LTRIM(RTRIM(province_name)) = '' THEN 1 ELSE 0 END) AS MissingProvince
FROM Staging_RealEstate;

-- Kiem tra ten bang
SELECT TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- Kiểm tra tên database 
SELECT DB_NAME() AS CurrentDatabase;

-- Số lượng bản ghi các bảng
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


-- sript dim date  
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

-- Kiểm tra các bảng Dimension
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

-- 2. XEM CHI TIẾT DỮ LIỆU TỪNG BẢNG DIM
SELECT * FROM dbo.Dim_Time         ORDER BY time_key;
SELECT * FROM dbo.Dim_PropertyType ORDER BY property_type_key;
SELECT * FROM dbo.Dim_Direction    ORDER BY direction_key;
SELECT * FROM dbo.Dim_Segment      ORDER BY sort_order;
SELECT * FROM dbo.Cfg_Segment_Threshold ORDER BY version, segment_key;

-- Dim_Date: Xem dòng -1, các ngày lễ và 10 ngày đầu kỳ dữ liệu
SELECT * FROM dbo.Dim_Date
WHERE date_key = -1 OR is_holiday = 1 OR full_date BETWEEN '2025-06-01' AND '2025-06-05'
ORDER BY date_key;


SELECT * FROM dbo.Dim_Project ORDER BY project_key;
SELECT * FROM dbo.Dim_Location ORDER BY location_key;
GO

-- 3. KIỂM TRA LỖI TRƯỚC KHI ĐẨY SANG SSAS (TRÙNG KHÓA / THIẾU DÒNG -1)

-- Kiểm tra các dòng mặc định (-1 và 0) đã tồn tại đủ chưa
SELECT 'Dim_Date (-1)'      AS Kiem_Tra, COUNT(*) AS So_Luong FROM dbo.Dim_Date         WHERE date_key = -1
UNION ALL
SELECT 'Dim_Time (-1)',                     COUNT(*) FROM dbo.Dim_Time         WHERE time_key = -1
UNION ALL
SELECT 'Dim_Location (-1)',                 COUNT(*) FROM dbo.Dim_Location     WHERE location_key = -1
UNION ALL
SELECT 'Dim_PropertyType (-1)',             COUNT(*) FROM dbo.Dim_PropertyType WHERE property_type_key = -1
UNION ALL
SELECT 'Dim_Project (-1 và 0)',             COUNT(*) FROM dbo.Dim_Project      WHERE project_key IN (-1, 0)
UNION ALL
SELECT 'Dim_Direction (-1)',                COUNT(*) FROM dbo.Dim_Direction    WHERE direction_key = -1
UNION ALL
SELECT 'Dim_Segment (-1)',                  COUNT(*) FROM dbo.Dim_Segment      WHERE segment_key = -1;

-- Kiểm tra trùng lặp khóa tự nhiên trong Dim_Location (nếu trả về 0 dòng là chuẩn)
SELECT province_name, district_name, ward_name, street_name, COUNT(*) AS So_Lan_Trung
FROM dbo.Dim_Location
GROUP BY province_name, district_name, ward_name, street_name
HAVING COUNT(*) > 1;

-- Kiểm tra trùng lặp tên dự án trong Dim_Project (nếu trả về 0 dòng là chuẩn)
SELECT project_name, COUNT(*) AS So_Lan_Trung
FROM dbo.Dim_Project
GROUP BY project_name
HAVING COUNT(*) > 1;
GO