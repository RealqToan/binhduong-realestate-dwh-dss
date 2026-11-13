/* ==========================================================
   01_create_staging.sql
   Tạo database BinhDuong_Staging và bảng Stg_Listing.
   Chạy trong SSMS, server: . (instance mặc định)
   ========================================================== */
USE master;
GO

-- Xóa database cũ đặt tên trước khi đổi (nếu còn)
IF DB_ID(N'BinhDuong_RealEstate_DWH') IS NOT NULL
BEGIN
    ALTER DATABASE BinhDuong_RealEstate_DWH SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BinhDuong_RealEstate_DWH;
END
GO

IF DB_ID(N'BinhDuong_Staging') IS NULL
    CREATE DATABASE BinhDuong_Staging COLLATE Vietnamese_CI_AS;
GO

USE BinhDuong_Staging;
GO

IF OBJECT_ID(N'dbo.Stg_Listing', N'U') IS NOT NULL
    DROP TABLE dbo.Stg_Listing;
GO

CREATE TABLE dbo.Stg_Listing (
    stg_row_id          INT IDENTITY(1,1) NOT NULL,
    name                NVARCHAR(300)  NULL,
    description         NVARCHAR(MAX)  NULL,
    property_type_name  NVARCHAR(50)   NULL,
    province_name       NVARCHAR(50)   NULL,
    district_name       NVARCHAR(50)   NULL,
    ward_name           NVARCHAR(50)   NULL,
    street_name         NVARCHAR(100)  NULL,
    project_name        NVARCHAR(100)  NULL,
    price               BIGINT         NULL,
    area                DECIMAL(12,3)  NULL,
    frontage_width      DECIMAL(10,2)  NULL,
    bedroom_count       SMALLINT       NULL,
    bathroom_count      SMALLINT       NULL,
    house_direction     NVARCHAR(30)   NULL,
    full_date           DATE           NULL,
    post_hour           TINYINT        NULL,
    is_outlier          BIT            NULL,
    segment_key         INT            NULL,
    CONSTRAINT PK_Stg_Listing PRIMARY KEY (stg_row_id)
);
GO