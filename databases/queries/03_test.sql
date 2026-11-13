USE BDS_DW;
GO
SELECT 'Dim_Date'         AS bang, COUNT(*) AS so_dong FROM BDS_DW.dbo.Dim_Date
UNION ALL SELECT 'Dim_Time',         COUNT(*) FROM BDS_DW.dbo.Dim_Time
UNION ALL SELECT 'Dim_Location',     COUNT(*) FROM BDS_DW.dbo.Dim_Location
UNION ALL SELECT 'Dim_PropertyType', COUNT(*) FROM BDS_DW.dbo.Dim_PropertyType
UNION ALL SELECT 'Dim_Project',      COUNT(*) FROM BDS_DW.dbo.Dim_Project
UNION ALL SELECT 'Dim_Direction',    COUNT(*) FROM BDS_DW.dbo.Dim_Direction
UNION ALL SELECT 'Dim_Segment',      COUNT(*) FROM BDS_DW.dbo.Dim_Segment
UNION ALL SELECT 'Fact_Listing',     COUNT(*) FROM BDS_DW.dbo.Fact_Listing
UNION ALL SELECT 'Fact_Listing_Detail', COUNT(*) FROM BDS_DW.dbo.Fact_Listing_Detail
UNION ALL SELECT 'Stg_Listing',      COUNT(*) FROM BinhDuong_Staging.dbo.Stg_Listing;

USE BinhDuong_Staging;
GO
SELECT 'Stg_Listing' AS bang, COUNT(*) AS so_dong FROM dbo.Stg_Listing;



USE BinhDuong_Staging;
GO
SELECT
    COUNT(*)                                             AS so_dong,          -- 36303
    SUM(CAST(price AS DECIMAL(20,0)))                    AS tong_price,       -- 190180227524490
    SUM(area)                                            AS tong_area,        -- ~51101521.69
    SUM(CASE WHEN is_outlier = 1 THEN 1 ELSE 0 END)      AS so_outlier,       -- 360
    SUM(CASE WHEN project_name = N'Không thuộc dự án' THEN 1 ELSE 0 END) AS nha_le,         -- 18084
    SUM(CASE WHEN project_name = N'Không xác định'    THEN 1 ELSE 0 END) AS du_an_khong_xd, -- 759
    MIN(stg_row_id)                                      AS id_min,           -- 1
    MAX(stg_row_id)                                      AS id_max            -- 36303
FROM dbo.Stg_Listing;


SELECT COUNT(*) AS dim_project FROM BDS_DW.dbo.Dim_Project;

SELECT COUNT(DISTINCT project_name) AS du_an_that
FROM BinhDuong_Staging.dbo.Stg_Listing
WHERE project_name NOT IN (N'Không thuộc dự án', N'Không xác định');



SELECT COUNT(*) AS dim_location FROM BDS_DW.dbo.Dim_Location;

SELECT COUNT(*) AS to_hop_dia_chi
FROM (
    SELECT DISTINCT province_name, district_name, ward_name, street_name
    FROM BinhDuong_Staging.dbo.Stg_Listing
) AS t;


USE BDS_DW;
GO
SELECT
    COUNT(*)                                              AS fact_rows,        -- 36303
    SUM(price)                                            AS tong_price,       -- 190180227524490
    SUM(CAST(is_outlier AS INT))                          AS so_outlier,       -- 360
    SUM(CASE WHEN project_key = 0  THEN 1 ELSE 0 END)     AS nha_le,           -- 18084
    SUM(CASE WHEN project_key = -1 THEN 1 ELSE 0 END)     AS du_an_khong_xd,   -- 759
    SUM(CASE WHEN date_key = -1    THEN 1 ELSE 0 END)     AS khoa_date_am1,    -- 0
    SUM(CASE WHEN time_key = -1    THEN 1 ELSE 0 END)     AS khoa_time_am1,    -- 0
    SUM(CASE WHEN location_key = -1 THEN 1 ELSE 0 END)    AS khoa_loc_am1,     -- 0
    SUM(CASE WHEN property_type_key = -1 THEN 1 ELSE 0 END) AS khoa_type_am1,  -- 0
    SUM(CASE WHEN direction_key = -1 THEN 1 ELSE 0 END)   AS khoa_dir_am1,     -- số tin hướng "Không xác định"
    SUM(CASE WHEN segment_key = -1 THEN 1 ELSE 0 END)     AS khoa_seg_am1      -- 0
FROM dbo.Fact_Listing;

SELECT DB_NAME() AS database_hien_tai, COUNT(*) AS fact_rows
FROM dbo.Fact_Listing;


SELECT
    (SELECT COUNT(*) FROM BDS_DW.dbo.Fact_Listing_Detail)  AS detail_rows,   -- 36303
    (SELECT COUNT(*) FROM BDS_DW.dbo.Fact_Listing f
       WHERE NOT EXISTS (SELECT 1 FROM BDS_DW.dbo.Fact_Listing_Detail d
                         WHERE d.fact_id = f.fact_id)) AS fact_thieu_detail;  -- 0


                         USE BDS_DW;
SELECT
    (SELECT COUNT(*) FROM dbo.Dim_Date)            AS dim_date,         -- 366
    (SELECT COUNT(*) FROM dbo.Dim_Time)            AS dim_time,         -- 25
    (SELECT COUNT(*) FROM dbo.Dim_Location)        AS dim_location,     -- 2047
    (SELECT COUNT(*) FROM dbo.Dim_PropertyType)    AS dim_type,         -- 6
    (SELECT COUNT(*) FROM dbo.Dim_Project)         AS dim_project,      -- 299
    (SELECT COUNT(*) FROM dbo.Dim_Direction)       AS dim_direction,    -- 9
    (SELECT COUNT(*) FROM dbo.Dim_Segment)         AS dim_segment,      -- 5
    (SELECT COUNT(*) FROM dbo.Fact_Listing)        AS fact_rows,        -- 36303
    (SELECT COUNT(*) FROM dbo.Fact_Listing_Detail) AS detail_rows;      -- 36303



USE BDS_DW;
SELECT SUM(price) * 1.0 / SUM(area) AS don_gia_m2_sql
FROM dbo.Fact_Listing
WHERE is_outlier = 0 AND area IS NOT NULL;

SELECT name, price, area, is_outlier
FROM BinhDuong_Staging.dbo.Stg_Listing
WHERE area > 10000
ORDER BY area DESC;

USE BDS_DW;
SELECT d.month_num, d.month_name, COUNT(*) AS so_tin
FROM dbo.Fact_Listing AS f
JOIN dbo.Dim_Date AS d ON d.date_key = f.date_key
GROUP BY d.month_num, d.month_name
ORDER BY d.month_num;

USE BDS_DW;
SELECT COUNT(*) AS tong,
       SUM(CASE WHEN area IS NULL THEN 1 ELSE 0 END) AS thieu_dien_tich
FROM dbo.Fact_Listing;