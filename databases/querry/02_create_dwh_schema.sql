-- ============================================================================
-- FILE: 02_create_dwh_schema.sql (HOÀN CHỈNH DÀNH CHO DWH BĐS BÌNH DƯƠNG)
-- MỤC ĐÍCH: Khởi tạo DWH, 8 Bảng Chiều, 3 Bảng Fact và nạp Dòng khuyết (-1)
-- NƠI THỰC THI: SQL Server Management Studio (SSMS)
-- ============================================================================

USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'BinhDuong_DWH')
BEGIN
    CREATE DATABASE BinhDuong_DWH;
    PRINT N'Đã tạo Database BinhDuong_DWH thành công.';
END
GO

USE BinhDuong_DWH;
GO

-- ============================================================================
-- PHẦN I: KHỞI TẠO 8 BẢNG CHIỀU (DIMENSION TABLES)
-- ============================================================================

-- 1. Dim_Date
IF OBJECT_ID('dbo.Dim_Date', 'U') IS NOT NULL DROP TABLE dbo.Dim_Date;
CREATE TABLE dbo.Dim_Date (
    date_key INT PRIMARY KEY, -- Định dạng YYYYMMDD (Dòng khuyết = -1)
    full_date DATE NOT NULL,
    day_of_month TINYINT NOT NULL,
    day_of_week TINYINT NOT NULL,
    day_name NVARCHAR(50) NULL,
    week_of_year TINYINT NOT NULL,
    month_num TINYINT NOT NULL,
    month_name NVARCHAR(50) NULL,
    quarter TINYINT NOT NULL,
    year_num SMALLINT NOT NULL,
    is_weekend BIT NOT NULL
);

-- 2. Dim_Time
IF OBJECT_ID('dbo.Dim_Time', 'U') IS NOT NULL DROP TABLE dbo.Dim_Time;
CREATE TABLE dbo.Dim_Time (
    time_key INT PRIMARY KEY, -- 0 đến 23 (Dòng khuyết = -1)
    hour TINYINT NOT NULL,
    day_period NVARCHAR(50) NOT NULL
);

-- 3. Dim_PropertyType
IF OBJECT_ID('dbo.Dim_PropertyType', 'U') IS NOT NULL DROP TABLE dbo.Dim_PropertyType;
CREATE TABLE dbo.Dim_PropertyType (
    property_type_key INT IDENTITY(1,1) PRIMARY KEY,
    property_type_name NVARCHAR(100) NOT NULL
);

-- 4. Dim_Location
IF OBJECT_ID('dbo.Dim_Location', 'U') IS NOT NULL DROP TABLE dbo.Dim_Location;
CREATE TABLE dbo.Dim_Location (
    location_key INT IDENTITY(1,1) PRIMARY KEY,
    district_name NVARCHAR(255) NULL,
    ward_name NVARCHAR(255) NULL
);

-- 5. Dim_Street
IF OBJECT_ID('dbo.Dim_Street', 'U') IS NOT NULL DROP TABLE dbo.Dim_Street;
CREATE TABLE dbo.Dim_Street (
    street_key INT IDENTITY(1,1) PRIMARY KEY,
    street_name NVARCHAR(255) NOT NULL
);

-- 6. Dim_Project
IF OBJECT_ID('dbo.Dim_Project', 'U') IS NOT NULL DROP TABLE dbo.Dim_Project;
CREATE TABLE dbo.Dim_Project (
    project_key INT IDENTITY(1,1) PRIMARY KEY,
    project_name NVARCHAR(255) NULL,
    is_in_project BIT NOT NULL
);

-- 7. Dim_Direction
IF OBJECT_ID('dbo.Dim_Direction', 'U') IS NOT NULL DROP TABLE dbo.Dim_Direction;
CREATE TABLE dbo.Dim_Direction (
    direction_key INT IDENTITY(1,1) PRIMARY KEY,
    house_direction NVARCHAR(50) NOT NULL,
    direction_type NVARCHAR(20) NOT NULL
);

-- 8. Dim_Segment
IF OBJECT_ID('dbo.Dim_Segment', 'U') IS NOT NULL DROP TABLE dbo.Dim_Segment;
CREATE TABLE dbo.Dim_Segment (
    segment_key INT IDENTITY(1,1) PRIMARY KEY,
    price_segment NVARCHAR(50) NOT NULL,
    area_segment NVARCHAR(50) NOT NULL,
    frontage_segment NVARCHAR(50) NOT NULL
);
GO

-- ============================================================================
-- PHẦN II: NẠP DÒNG KHUYẾT MẶC ĐỊNH (DUMMY ROWS: KEY = -1)
-- ============================================================================

INSERT INTO dbo.Dim_Date (date_key, full_date, day_of_month, day_of_week, day_name, week_of_year, month_num, month_name, quarter, year_num, is_weekend)
VALUES (-1, '1900-01-01', 0, 0, N'Chưa xác định', 0, 0, N'Chưa xác định', 0, 1900, 0);

INSERT INTO dbo.Dim_Time (time_key, hour, day_period)
VALUES (-1, 0, N'Chưa xác định');

SET IDENTITY_INSERT dbo.Dim_PropertyType ON;
INSERT INTO dbo.Dim_PropertyType (property_type_key, property_type_name) VALUES (-1, N'Không xác định');
SET IDENTITY_INSERT dbo.Dim_PropertyType OFF;

SET IDENTITY_INSERT dbo.Dim_Location ON;
INSERT INTO dbo.Dim_Location (location_key, district_name, ward_name) VALUES (-1, N'Không xác định', N'Chưa xác định');
SET IDENTITY_INSERT dbo.Dim_Location OFF;

SET IDENTITY_INSERT dbo.Dim_Street ON;
INSERT INTO dbo.Dim_Street (street_key, street_name) VALUES (-1, N'Không xác định');
SET IDENTITY_INSERT dbo.Dim_Street OFF;

SET IDENTITY_INSERT dbo.Dim_Project ON;
INSERT INTO dbo.Dim_Project (project_key, project_name, is_in_project) VALUES (-1, N'Không thuộc dự án', 0);
SET IDENTITY_INSERT dbo.Dim_Project OFF;

SET IDENTITY_INSERT dbo.Dim_Direction ON;
INSERT INTO dbo.Dim_Direction (direction_key, house_direction, direction_type) VALUES (-1, N'Chưa xác định', N'Chưa xác định');
SET IDENTITY_INSERT dbo.Dim_Direction OFF;

SET IDENTITY_INSERT dbo.Dim_Segment ON;
INSERT INTO dbo.Dim_Segment (segment_key, price_segment, area_segment, frontage_segment) VALUES (-1, N'Chưa phân loại', N'Chưa phân loại', N'Chưa phân loại');
SET IDENTITY_INSERT dbo.Dim_Segment OFF;
GO

-- ============================================================================
-- PHẦN III: KHỞI TẠO 3 BẢNG SỰ KIỆN (FACT TABLES)
-- ============================================================================

-- 1. Fact_Listing (Transaction Fact)
IF OBJECT_ID('dbo.Fact_Listing', 'U') IS NOT NULL DROP TABLE dbo.Fact_Listing;
CREATE TABLE dbo.Fact_Listing (
    listing_id INT IDENTITY(1,1) PRIMARY KEY,
    
    date_key INT NOT NULL DEFAULT -1,
    time_key INT NULL DEFAULT -1, -- Cho phép NULL nếu bài đăng bị khuyết post_hour
    location_key INT NOT NULL DEFAULT -1,
    street_key INT NOT NULL DEFAULT -1,
    property_type_key INT NOT NULL DEFAULT -1,
    project_key INT NOT NULL DEFAULT -1,
    direction_key INT NOT NULL DEFAULT -1,
    segment_key INT NOT NULL DEFAULT -1,
    
    total_listings INT NOT NULL DEFAULT 1,
    price DECIMAL(18,2) NOT NULL,
    area DECIMAL(10,2) NOT NULL,
    price_per_m2 DECIMAL(18,2) NOT NULL,
    bedroom_count INT NOT NULL DEFAULT 0,
    bathroom_count INT NOT NULL DEFAULT 0,
    frontage_width DECIMAL(10,2) NULL,
    is_outlier BIT NOT NULL DEFAULT 0,
    
    CONSTRAINT FK_FactListing_Date FOREIGN KEY (date_key) REFERENCES dbo.Dim_Date(date_key),
    CONSTRAINT FK_FactListing_Time FOREIGN KEY (time_key) REFERENCES dbo.Dim_Time(time_key),
    CONSTRAINT FK_FactListing_Location FOREIGN KEY (location_key) REFERENCES dbo.Dim_Location(location_key),
    CONSTRAINT FK_FactListing_Street FOREIGN KEY (street_key) REFERENCES dbo.Dim_Street(street_key),
    CONSTRAINT FK_FactListing_PropertyType FOREIGN KEY (property_type_key) REFERENCES dbo.Dim_PropertyType(property_type_key),
    CONSTRAINT FK_FactListing_Project FOREIGN KEY (project_key) REFERENCES dbo.Dim_Project(project_key),
    CONSTRAINT FK_FactListing_Direction FOREIGN KEY (direction_key) REFERENCES dbo.Dim_Direction(direction_key),
    CONSTRAINT FK_FactListing_Segment FOREIGN KEY (segment_key) REFERENCES dbo.Dim_Segment(segment_key)
);

-- 2. Fact_Market_Monthly (Periodic Snapshot theo Tháng x Quận)
IF OBJECT_ID('dbo.Fact_Market_Monthly', 'U') IS NOT NULL DROP TABLE dbo.Fact_Market_Monthly;
CREATE TABLE dbo.Fact_Market_Monthly (
    market_monthly_key INT IDENTITY(1,1) PRIMARY KEY,
    date_key INT NOT NULL,
    location_key INT NOT NULL,
    property_type_key INT NOT NULL,
    
    total_listings INT NOT NULL,
    avg_price DECIMAL(18,2) NOT NULL,
    avg_area DECIMAL(10,2) NOT NULL,
    avg_price_per_m2 DECIMAL(18,2) NOT NULL,
    median_price_per_m2 DECIMAL(18,2) NOT NULL,
    min_price_per_m2 DECIMAL(18,2) NOT NULL,
    max_price_per_m2 DECIMAL(18,2) NOT NULL,
    price_change_mom DECIMAL(5,2) NULL,
    
    CONSTRAINT FK_FactMarket_Date FOREIGN KEY (date_key) REFERENCES dbo.Dim_Date(date_key),
    CONSTRAINT FK_FactMarket_Location FOREIGN KEY (location_key) REFERENCES dbo.Dim_Location(location_key),
    CONSTRAINT FK_FactMarket_PropertyType FOREIGN KEY (property_type_key) REFERENCES dbo.Dim_PropertyType(property_type_key)
);

-- 3. Fact_Project_Monthly (Periodic Snapshot theo Tháng x Dự án)
IF OBJECT_ID('dbo.Fact_Project_Monthly', 'U') IS NOT NULL DROP TABLE dbo.Fact_Project_Monthly;
CREATE TABLE dbo.Fact_Project_Monthly (
    project_monthly_key INT IDENTITY(1,1) PRIMARY KEY,
    date_key INT NOT NULL,
    project_key INT NOT NULL,
    location_key INT NOT NULL,
    property_type_key INT NOT NULL,
    
    total_listings INT NOT NULL,
    total_listed_area DECIMAL(12,2) NOT NULL,
    avg_price DECIMAL(18,2) NOT NULL,
    avg_area DECIMAL(10,2) NOT NULL,
    avg_price_per_m2 DECIMAL(18,2) NOT NULL,
    median_price_per_m2 DECIMAL(18,2) NOT NULL,
    
    CONSTRAINT FK_FactProject_Date FOREIGN KEY (date_key) REFERENCES dbo.Dim_Date(date_key),
    CONSTRAINT FK_FactProject_Project FOREIGN KEY (project_key) REFERENCES dbo.Dim_Project(project_key),
    CONSTRAINT FK_FactProject_Location FOREIGN KEY (location_key) REFERENCES dbo.Dim_Location(location_key),
    CONSTRAINT FK_FactProject_PropertyType FOREIGN KEY (property_type_key) REFERENCES dbo.Dim_PropertyType(property_type_key)
);
GO

PRINT N'Đã khởi tạo Database BinhDuong_DWH và toàn bộ các bảng thành công (Đã tối ưu hóa DDL)!';
GO