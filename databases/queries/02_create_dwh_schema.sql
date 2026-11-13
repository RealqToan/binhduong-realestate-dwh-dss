/* ==========================================================
   02_create_dwh_schema.sql
   Tạo database BDS_DW: 7 bảng chiều, Fact_Listing, Fact_Listing_Detail.
   Chạy sau 01_create_staging.sql.
   ========================================================== */
USE master;
GO

IF DB_ID(N'BDS_DW') IS NULL
    CREATE DATABASE BDS_DW COLLATE Vietnamese_CI_AS;
GO

USE BDS_DW;
GO

/* ---------- Xóa theo thứ tự bảng con trước bảng cha ---------- */
IF OBJECT_ID(N'dbo.Fact_Listing_Detail', N'U') IS NOT NULL DROP TABLE dbo.Fact_Listing_Detail;
IF OBJECT_ID(N'dbo.Fact_Listing',        N'U') IS NOT NULL DROP TABLE dbo.Fact_Listing;
IF OBJECT_ID(N'dbo.Dim_Segment',         N'U') IS NOT NULL DROP TABLE dbo.Dim_Segment;
IF OBJECT_ID(N'dbo.Dim_Direction',       N'U') IS NOT NULL DROP TABLE dbo.Dim_Direction;
IF OBJECT_ID(N'dbo.Dim_Project',         N'U') IS NOT NULL DROP TABLE dbo.Dim_Project;
IF OBJECT_ID(N'dbo.Dim_PropertyType',    N'U') IS NOT NULL DROP TABLE dbo.Dim_PropertyType;
IF OBJECT_ID(N'dbo.Dim_Location',        N'U') IS NOT NULL DROP TABLE dbo.Dim_Location;
IF OBJECT_ID(N'dbo.Dim_Time',            N'U') IS NOT NULL DROP TABLE dbo.Dim_Time;
IF OBJECT_ID(N'dbo.Dim_Date',            N'U') IS NOT NULL DROP TABLE dbo.Dim_Date;
GO

/* ===================== DIM_DATE (Type 0, 366 dòng) ===================== */
CREATE TABLE dbo.Dim_Date (
    date_key      INT          NOT NULL PRIMARY KEY,
    full_date     DATE         NULL,
    day_num       TINYINT      NULL,
    day_of_week   TINYINT      NULL,
    day_name      NVARCHAR(20) NULL,
    week          TINYINT      NULL,
    month_num     TINYINT      NULL,
    month_name    NVARCHAR(20) NULL,
    quarter_num   TINYINT      NULL,
    quarter_name  NVARCHAR(20) NULL,
    year_num      SMALLINT     NULL,
    is_holiday    BIT          NOT NULL DEFAULT 0,
    holiday_name  NVARCHAR(50) NULL
);
GO

-- Lịch đầy đủ năm 2025. day_of_week: 1 = Thứ Hai ... 7 = Chủ Nhật (ISO 8601)
;WITH d AS (
    SELECT CAST('2025-01-01' AS DATE) AS dt
    UNION ALL
    SELECT DATEADD(DAY, 1, dt) FROM d WHERE dt < '2025-12-31'
)
INSERT INTO dbo.Dim_Date (date_key, full_date, day_num, day_of_week, day_name, week,
                          month_num, month_name, quarter_num, quarter_name, year_num,
                          is_holiday, holiday_name)
SELECT
    YEAR(dt) * 10000 + MONTH(dt) * 100 + DAY(dt),
    dt,
    DAY(dt),
    ((DATEDIFF(DAY, '2025-01-06', dt) % 7) + 7) % 7 + 1,
    CHOOSE(((DATEDIFF(DAY, '2025-01-06', dt) % 7) + 7) % 7 + 1,
           N'Thứ Hai', N'Thứ Ba', N'Thứ Tư', N'Thứ Năm', N'Thứ Sáu', N'Thứ Bảy', N'Chủ Nhật'),
    DATEPART(ISO_WEEK, dt),
    MONTH(dt),
    CONCAT(N'Tháng ', MONTH(dt)),
    DATEPART(QUARTER, dt),
    CONCAT(N'Q', DATEPART(QUARTER, dt)),
    YEAR(dt),
    0,
    NULL
FROM d
OPTION (MAXRECURSION 400);
GO

-- Dòng -1: không xác định
INSERT INTO dbo.Dim_Date (date_key, full_date, day_num, day_of_week, day_name, week,
                          month_num, month_name, quarter_num, quarter_name, year_num,
                          is_holiday, holiday_name)
VALUES (-1, NULL, NULL, NULL, N'Không xác định', NULL,
        NULL, N'Không xác định', NULL, N'Không xác định', NULL, 0, NULL);
GO

-- Ngày lễ dương lịch 2025.
-- CHƯA đủ: còn thiếu Tết Âm lịch, Giỗ Tổ Hùng Vương và ngày nghỉ bù.
-- Đối chiếu quyết định nghỉ lễ của Chính phủ rồi bổ sung trước khi chốt báo cáo.
UPDATE dbo.Dim_Date SET is_holiday = 1, holiday_name = N'Tết Dương lịch'      WHERE date_key = 20250101;
UPDATE dbo.Dim_Date SET is_holiday = 1, holiday_name = N'Giải phóng miền Nam' WHERE date_key = 20250430;
UPDATE dbo.Dim_Date SET is_holiday = 1, holiday_name = N'Quốc tế Lao động'    WHERE date_key = 20250501;
UPDATE dbo.Dim_Date SET is_holiday = 1, holiday_name = N'Quốc khánh'          WHERE date_key = 20250902;
GO

/* ===================== DIM_TIME (Type 0, 25 dòng) ===================== */
CREATE TABLE dbo.Dim_Time (
    time_key    INT          NOT NULL PRIMARY KEY,
    day_period  NVARCHAR(30) NOT NULL
);
GO

INSERT INTO dbo.Dim_Time (time_key, day_period)
SELECT h,
       CASE WHEN h BETWEEN 0  AND 5  THEN N'Đêm (0h–6h)'
            WHEN h BETWEEN 6  AND 11 THEN N'Sáng (6h–12h)'
            WHEN h BETWEEN 12 AND 17 THEN N'Chiều (12h–18h)'
            ELSE N'Tối (18h–24h)' END
FROM (SELECT TOP (24) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS h
      FROM sys.all_objects) AS x;
GO
INSERT INTO dbo.Dim_Time (time_key, day_period) VALUES (-1, N'Không xác định');
GO

/* ===================== DIM_LOCATION (Type 1) ===================== */
CREATE TABLE dbo.Dim_Location (
    location_key   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    province_name  NVARCHAR(50)  NOT NULL,
    district_name  NVARCHAR(50)  NOT NULL,
    ward_name      NVARCHAR(50)  NOT NULL,
    street_name    NVARCHAR(100) NOT NULL,
    CONSTRAINT UQ_Dim_Location UNIQUE (province_name, district_name, ward_name, street_name)
);
GO
SET IDENTITY_INSERT dbo.Dim_Location ON;
INSERT INTO dbo.Dim_Location (location_key, province_name, district_name, ward_name, street_name)
VALUES (-1, N'Không xác định', N'Không xác định', N'Không xác định', N'Không xác định');
SET IDENTITY_INSERT dbo.Dim_Location OFF;
GO

/* ===================== DIM_PROPERTYTYPE (Type 1) ===================== */
CREATE TABLE dbo.Dim_PropertyType (
    property_type_key   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    property_type_name  NVARCHAR(50) NOT NULL UNIQUE,
    property_type_group NVARCHAR(50) NOT NULL
);
GO
SET IDENTITY_INSERT dbo.Dim_PropertyType ON;
INSERT INTO dbo.Dim_PropertyType (property_type_key, property_type_name, property_type_group)
VALUES (-1, N'Không xác định', N'Không xác định');
SET IDENTITY_INSERT dbo.Dim_PropertyType OFF;
GO
INSERT INTO dbo.Dim_PropertyType (property_type_name, property_type_group) VALUES
    (N'Căn hộ chung cư',      N'BĐS ở'),
    (N'Nhà',                  N'BĐS ở'),
    (N'Biệt thự/Nhà liền kề', N'BĐS ở'),
    (N'Đất',                  N'BĐS đất'),
    (N'Shophouse',            N'BĐS thương mại');
GO

/* ===================== DIM_PROJECT (Type 1) ===================== */
CREATE TABLE dbo.Dim_Project (
    project_key   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    project_name  NVARCHAR(100) NOT NULL UNIQUE
);
GO
SET IDENTITY_INSERT dbo.Dim_Project ON;
INSERT INTO dbo.Dim_Project (project_key, project_name) VALUES
    (0,  N'Nhà lẻ (không thuộc dự án)'),
    (-1, N'Không xác định');
SET IDENTITY_INSERT dbo.Dim_Project OFF;
GO
-- Dự án thật được nạp bằng SSIS (SQL_Load_Dim_Project).

/* ===================== DIM_DIRECTION (Type 0) ===================== */
CREATE TABLE dbo.Dim_Direction (
    direction_key    INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    house_direction  NVARCHAR(30) NOT NULL UNIQUE,
    direction_group  NVARCHAR(30) NOT NULL
);
GO
SET IDENTITY_INSERT dbo.Dim_Direction ON;
INSERT INTO dbo.Dim_Direction (direction_key, house_direction, direction_group)
VALUES (-1, N'Không xác định', N'Không xác định');
SET IDENTITY_INSERT dbo.Dim_Direction OFF;
GO
INSERT INTO dbo.Dim_Direction (house_direction, direction_group) VALUES
    (N'Bắc',      N'Hướng Bắc'),
    (N'Đông Bắc', N'Hướng Bắc'),
    (N'Tây Bắc',  N'Hướng Bắc'),
    (N'Đông',     N'Hướng Đông'),
    (N'Nam',      N'Hướng Nam'),
    (N'Đông Nam', N'Hướng Nam'),
    (N'Tây Nam',  N'Hướng Nam'),
    (N'Tây',      N'Hướng Tây');
GO

/* ===================== DIM_SEGMENT (Type 0) ===================== */
CREATE TABLE dbo.Dim_Segment (
    segment_key   INT          NOT NULL PRIMARY KEY,
    segment_name  NVARCHAR(30) NOT NULL UNIQUE,
    sort_order    TINYINT      NOT NULL
);
GO
INSERT INTO dbo.Dim_Segment (segment_key, segment_name, sort_order) VALUES
    (-1, N'Không xác định', 0),
    (1,  N'Phân khúc thấp', 1),
    (2,  N'Trung bình',     2),
    (3,  N'Cao cấp',        3),
    (4,  N'Rất cao',        4);
GO

/* ===================== FACT_LISTING (grain: 1 tin đăng) ===================== */
CREATE TABLE dbo.Fact_Listing (
    fact_id            INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    stg_row_id         INT NULL,                       -- khóa truy vết từ Stg_Listing
    date_key           INT NOT NULL REFERENCES dbo.Dim_Date(date_key),
    time_key           INT NOT NULL REFERENCES dbo.Dim_Time(time_key),
    location_key       INT NOT NULL REFERENCES dbo.Dim_Location(location_key),
    property_type_key  INT NOT NULL REFERENCES dbo.Dim_PropertyType(property_type_key),
    project_key        INT NOT NULL REFERENCES dbo.Dim_Project(project_key),
    direction_key      INT NOT NULL REFERENCES dbo.Dim_Direction(direction_key),
    segment_key        INT NOT NULL REFERENCES dbo.Dim_Segment(segment_key),
    price              BIGINT        NOT NULL,
    area               DECIMAL(12,3) NULL,
    frontage_width     DECIMAL(10,2) NULL,
    bedroom_count      TINYINT       NULL,
    bathroom_count     TINYINT       NULL,
    total_listings     TINYINT       NOT NULL DEFAULT 1,
    is_outlier         BIT           NOT NULL
);
GO
CREATE INDEX IX_Fact_stg_row_id ON dbo.Fact_Listing(stg_row_id);
GO

/* ===================== FACT_LISTING_DETAIL ===================== */
CREATE TABLE dbo.Fact_Listing_Detail (
    fact_id          INT           NOT NULL PRIMARY KEY REFERENCES dbo.Fact_Listing(fact_id),
    name             NVARCHAR(300) NULL,
    description_raw  NVARCHAR(MAX) NULL
);
GO