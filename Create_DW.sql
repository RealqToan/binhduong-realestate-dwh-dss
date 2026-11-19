--01_DDL_Create_DW.sql
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

--Tạo bảng cấu hình ngưỡng phân khúc 
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


DELETE FROM dbo.Cfg_Segment_Threshold WHERE version = 1;

;WITH Quantiles AS (
    SELECT DISTINCT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price / NULLIF(area, 0)) OVER () AS P25,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY price / NULLIF(area, 0)) OVER () AS P50,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price / NULLIF(area, 0)) OVER () AS P75
    FROM dbo.Staging_RealEstate
    WHERE price > 0 AND area > 0 AND is_outlier = 0
)
INSERT INTO dbo.Cfg_Segment_Threshold (version, effective_date, segment_key, min_price_per_m2, max_price_per_m2)
SELECT 1, '2025-01-01', 1, 0, P25 FROM Quantiles
UNION ALL
SELECT 1, '2025-01-01', 2, P25, P50 FROM Quantiles
UNION ALL
SELECT 1, '2025-01-01', 3, P50, P75 FROM Quantiles
UNION ALL
SELECT 1, '2025-01-01', 4, P75, NULL FROM Quantiles;
GO

