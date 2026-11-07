-- ============================================================================
-- FILE: 01_create_staging_db.sql (HOÀN CHỈNH DÀNH CHO DWH BĐS BÌNH DƯƠNG)
-- MỤC ĐÍCH: Khởi tạo Database Staging và bảng Staging_Listings chứa dữ liệu Pre-ETL
-- ============================================================================

USE master;
GO

-- 1. Khởi tạo Database Staging (nếu chưa tồn tại)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'BinhDuong_Staging')
BEGIN
    CREATE DATABASE BinhDuong_Staging;
    PRINT N'Đã tạo Database BinhDuong_Staging thành công.';
END
GO

USE BinhDuong_Staging;
GO

-- 2. Tái tạo bảng Staging_Listings với schema chuẩn đét
IF OBJECT_ID('dbo.Staging_Listings', 'U') IS NOT NULL
    DROP TABLE dbo.Staging_Listings;
GO

CREATE TABLE dbo.Staging_Listings (
    staging_id INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Thuộc tính định danh & văn bản (Đã nâng độ dài tối đa chống lỗi Truncation SSIS)
    name NVARCHAR(1000) NULL,
    description NVARCHAR(MAX) NULL,
    district_name NVARCHAR(255) NULL,
    ward_name NVARCHAR(255) NULL,
    street_name NVARCHAR(255) NULL,
    project_name NVARCHAR(255) NULL,
    property_type_name NVARCHAR(100) NULL,
    house_direction NVARCHAR(50) NULL,
    
    -- Biến đo lường & kỹ thuật
    price DECIMAL(18,2) NULL,
    area DECIMAL(10,2) NULL,
    price_per_m2 DECIMAL(18,2) NULL,
    bedroom_count INT NULL,
    bathroom_count INT NULL,
    frontage_width DECIMAL(10,2) NULL,
    
    -- Thuộc tính thời gian hạt nhân (Dùng làm Lookup Dim_Date và Dim_Time)
    full_date DATE NULL,
    post_hour TINYINT NULL,
    
    -- Cờ phân loại Outlier (R10)
    is_outlier BIT NULL
);
GO

PRINT N'Đã khởi tạo bảng Staging_Listings thành công với độ dài cột tối ưu!';
GO

-- 3. Kiểm tra lại thông tin Metadata các cột vừa tạo
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Staging_Listings'
ORDER BY ORDINAL_POSITION;
GO