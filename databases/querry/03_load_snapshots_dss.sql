-- ============================================================================
-- FILE: 03_load_snapshots_dss.sql (HOÀN CHỈNH DÀNH CHO DWH BĐS BÌNH DƯƠNG)
-- MỤC ĐÍCH: Nạp tự động dữ liệu tổng hợp cho Fact_Market_Monthly & Fact_Project_Monthly
-- NƠI THỰC THI: SQL Server Management Studio (SSMS) / SSIS Execute SQL Task
-- ============================================================================

USE BinhDuong_DWH;
GO

-- 1. Stored Procedure nạp Fact_Market_Monthly
CREATE OR ALTER PROCEDURE dbo.sp_Build_Fact_Market_Monthly
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE dbo.Fact_Market_Monthly;

    -- BƯỚC 1: Tính toán các chỉ số hạt nhân (bao gồm Median qua CTE)
    WITH RawMetrics AS (
        SELECT 
            f.date_key,
            f.location_key,
            f.property_type_key,
            f.price,
            f.area,
            f.price_per_m2,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY f.price_per_m2) 
                OVER (PARTITION BY f.date_key, f.location_key, f.property_type_key) AS median_price_per_m2
        FROM dbo.Fact_Listing f
        WHERE f.is_outlier = 0 -- Loại bỏ Outlier theo R10
    ),
    AggregatedMonthly AS (
        SELECT 
            date_key,
            location_key,
            property_type_key,
            COUNT(*) AS total_listings,
            AVG(price) AS avg_price,
            AVG(area) AS avg_area,
            AVG(price_per_m2) AS avg_price_per_m2,
            MAX(median_price_per_m2) AS median_price_per_m2, -- Lấy giá trị Median đã tính
            MIN(price_per_m2) AS min_price_per_m2,
            MAX(price_per_m2) AS max_price_per_m2
        FROM RawMetrics
        GROUP BY date_key, location_key, property_type_key
    )
    -- BƯỚC 2: Nạp vào bảng và tính % tăng trưởng giá MoM (Month over Month)
    INSERT INTO dbo.Fact_Market_Monthly (
        date_key, location_key, property_type_key, total_listings,
        avg_price, avg_area, avg_price_per_m2, median_price_per_m2,
        min_price_per_m2, max_price_per_m2, price_change_mom
    )
    SELECT 
        cur.date_key,
        cur.location_key,
        cur.property_type_key,
        cur.total_listings,
        cur.avg_price,
        cur.avg_area,
        cur.avg_price_per_m2,
        cur.median_price_per_m2,
        cur.min_price_per_m2,
        cur.max_price_per_m2,
        CASE 
            WHEN prev.avg_price_per_m2 IS NULL OR prev.avg_price_per_m2 = 0 THEN NULL
            ELSE CAST(((cur.avg_price_per_m2 - prev.avg_price_per_m2) / prev.avg_price_per_m2) * 100 AS DECIMAL(5,2))
        END AS price_change_mom
    FROM AggregatedMonthly cur
    LEFT JOIN AggregatedMonthly prev 
        ON cur.location_key = prev.location_key 
       AND cur.property_type_key = prev.property_type_key
       -- So sánh với tháng liền trước (Dựa trên date_key kiểu YYYYMMDD)
       AND prev.date_key = (
           SELECT MAX(d.date_key) 
           FROM AggregatedMonthly d 
           WHERE d.location_key = cur.location_key 
             AND d.property_type_key = cur.property_type_key 
             AND d.date_key < cur.date_key
       );

    PRINT N'Đã tổng hợp thành công bảng Fact_Market_Monthly (Đã bao gồm MoM & Median)!';
END;
GO

-- 2. Stored Procedure nạp Fact_Project_Monthly
CREATE OR ALTER PROCEDURE dbo.sp_Build_Fact_Project_Monthly
AS
BEGIN
    SET NOCOUNT ON;

    TRUNCATE TABLE dbo.Fact_Project_Monthly;

    -- BƯỚC 1: Tính toán chỉ số có chứa Median bằng CTE
    WITH ProjectRawMetrics AS (
        SELECT 
            f.date_key,
            f.project_key,
            f.location_key,
            f.property_type_key,
            f.price,
            f.area,
            f.price_per_m2,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY f.price_per_m2) 
                OVER (PARTITION BY f.date_key, f.project_key, f.property_type_key) AS median_price_per_m2
        FROM dbo.Fact_Listing f
        WHERE f.is_outlier = 0 AND f.project_key <> -1 -- Chỉ lấy tin bài thuộc dự án rõ ràng
    )
    -- BƯỚC 2: Gom nhóm nạp vào Fact_Project_Monthly
    INSERT INTO dbo.Fact_Project_Monthly (
        date_key, project_key, location_key, property_type_key,
        total_listings, total_listed_area, avg_price, avg_area,
        avg_price_per_m2, median_price_per_m2
    )
    SELECT 
        date_key,
        project_key,
        location_key,
        property_type_key,
        COUNT(*) AS total_listings,
        SUM(area) AS total_listed_area,
        AVG(price) AS avg_price,
        AVG(area) AS avg_area,
        AVG(price_per_m2) AS avg_price_per_m2,
        MAX(median_price_per_m2) AS median_price_per_m2
    FROM ProjectRawMetrics
    GROUP BY date_key, project_key, location_key, property_type_key;

    PRINT N'Đã tổng hợp thành công bảng Fact_Project_Monthly!';
END;
GO

-- ============================================================================
-- THỰC THI THỬ NGHIỆM TẠI SSMS
-- ============================================================================
EXEC dbo.sp_Build_Fact_Market_Monthly;
EXEC dbo.sp_Build_Fact_Project_Monthly;
GO