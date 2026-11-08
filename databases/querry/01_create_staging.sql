USE BinhDuong_RealEstate_DWH;
GO

IF OBJECT_ID('dbo.BinhDuong_Staging', 'U') IS NOT NULL 
    DROP TABLE dbo.BinhDuong_Staging;
GO

CREATE TABLE dbo.BinhDuong_Staging (
    name NVARCHAR(200) NULL,               -- Max len 119 -> cấp 200
    description NVARCHAR(MAX) NULL,        -- Max len 2996 -> cấp MAX (hoặc NVARCHAR(4000))
    property_type_name NVARCHAR(50) NULL,  -- Max len 20 -> cấp 50
    province_name NVARCHAR(50) NULL,       -- Max len 10 -> cấp 50
    district_name NVARCHAR(50) NULL,       -- Max len 12 -> cấp 50
    ward_name NVARCHAR(50) NULL,           -- Max len 15 -> cấp 50
    street_name NVARCHAR(100) NULL,        -- Max len 20 -> cấp 100
    project_name NVARCHAR(100) NULL,       -- Max len 50 -> cấp 100
    house_direction NVARCHAR(30) NULL,     -- Max len 13 -> cấp 30
    price DECIMAL(18,2) NULL,
    area DECIMAL(10,2) NULL,
    frontage_width DECIMAL(8,2) NULL,
    bedroom_count SMALLINT NULL,
    bathroom_count SMALLINT NULL,
    post_date DATE NULL,
    post_hour TINYINT NULL,
    is_outlier BIT NULL DEFAULT 0
);
GO

PRINT N'=== ĐÃ CẬP NHẬT BẢNG BinhDuong_Staging THEO KÍCH THƯỚC OPTIMAL ===';