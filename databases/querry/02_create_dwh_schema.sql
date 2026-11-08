USE BinhDuong_RealEstate_DWH;
GO

-- Xóa bảng Fact và các bảng Dim cũ nếu tồn tại để tạo lại khung mới
IF OBJECT_ID('dbo.Fact_Listing', 'U') IS NOT NULL DROP TABLE dbo.Fact_Listing;
IF OBJECT_ID('dbo.Dim_Date', 'U') IS NOT NULL DROP TABLE dbo.Dim_Date;
IF OBJECT_ID('dbo.Dim_Time', 'U') IS NOT NULL DROP TABLE dbo.Dim_Time;
IF OBJECT_ID('dbo.Dim_Location', 'U') IS NOT NULL DROP TABLE dbo.Dim_Location;
IF OBJECT_ID('dbo.Dim_PropertyType', 'U') IS NOT NULL DROP TABLE dbo.Dim_PropertyType;
IF OBJECT_ID('dbo.Dim_Project', 'U') IS NOT NULL DROP TABLE dbo.Dim_Project;
IF OBJECT_ID('dbo.Dim_Direction', 'U') IS NOT NULL DROP TABLE dbo.Dim_Direction;
GO

-- ===============================================================================
-- 1. TẠO CÁC BẢNG DIMENSION (DIMENSIONS)
-- ===============================================================================

-- 1.1. Dim_Date (SCD Type 0 - Dữ liệu thời gian tĩnh)
CREATE TABLE dbo.Dim_Date (
    date_key INT PRIMARY KEY,              -- Khóa chính dạng YYYYMMDD (VD: 20261108)
    full_date DATE NOT NULL,
    day_of_month TINYINT NOT NULL,
    day_of_week TINYINT NOT NULL,
    day_name NVARCHAR(20) NOT NULL,
    month_num TINYINT NOT NULL,
    month_name NVARCHAR(20) NOT NULL,
    quarter TINYINT NOT NULL,
    quarter_name VARCHAR(5) NOT NULL,
    year SMALLINT NOT NULL,
    is_weekend BIT NOT NULL
);
GO

-- 1.2. Dim_Time (SCD Type 0 - Khung giờ đăng tin)
CREATE TABLE dbo.Dim_Time (
    time_key TINYINT PRIMARY KEY,          -- Khóa chính 0 đến 23
    post_hour TINYINT NOT NULL,
    day_period NVARCHAR(20) NOT NULL
);
GO

-- 1.3. Dim_Location (SCD Type 1 - Phân cấp địa lý)
CREATE TABLE dbo.Dim_Location (
    location_key INT IDENTITY(1,1) PRIMARY KEY,
    province_name NVARCHAR(50) NOT NULL DEFAULT N'Bình Dương',
    district_name NVARCHAR(50) NOT NULL,
    ward_name NVARCHAR(50) NOT NULL,
    street_name NVARCHAR(100) NOT NULL DEFAULT N'Chưa xác định'
);
GO

-- 1.4. Dim_PropertyType (SCD Type 1 - Loại hình BĐS)
CREATE TABLE dbo.Dim_PropertyType (
    property_type_key INT IDENTITY(1,1) PRIMARY KEY,
    property_type_name NVARCHAR(50) NOT NULL
);
GO

-- 1.5. Dim_Project (SCD Type 1 - Dự án BĐS)
CREATE TABLE dbo.Dim_Project (
    project_key INT IDENTITY(1,1) PRIMARY KEY,
    project_name NVARCHAR(100) NOT NULL
);
GO

-- 1.6. Dim_Direction (SCD Type 0 - Hướng nhà phong thủy)
CREATE TABLE dbo.Dim_Direction (
    direction_key TINYINT PRIMARY KEY,     -- 0 đến 8
    house_direction NVARCHAR(30) NOT NULL
);
GO

-- ===============================================================================
-- 2. TẠO BẢNG FACT TRUNG TÂM (Fact_Listing)
-- ===============================================================================
CREATE TABLE dbo.Fact_Listing (
    fact_id BIGINT IDENTITY(1,1) PRIMARY KEY,
    -- Khóa ngoại nối sang 6 bảng Dimension
    date_key INT NOT NULL,
    time_key TINYINT NOT NULL,
    location_key INT NOT NULL,
    property_type_key INT NOT NULL,
    project_key INT NOT NULL,
    direction_key TINYINT NOT NULL,
    
    -- Base Measures (Độ đo định lượng lưu vật lý)
    total_listings INT NOT NULL DEFAULT 1,
    price DECIMAL(18,2) NULL,
    area DECIMAL(10,2) NULL,
    bedroom_count SMALLINT NULL,
    bathroom_count SMALLINT NULL,
    frontage_width DECIMAL(8,2) NULL,
    
    -- Cờ dị biệt & Thuộc tính mô tả văn bản thô
    is_outlier BIT NOT NULL DEFAULT 0,
    name NVARCHAR(200) NULL,
    description NVARCHAR(MAX) NULL,

    -- Các ràng buộc khóa ngoại (Foreign Keys)
    CONSTRAINT FK_Fact_Date FOREIGN KEY (date_key) REFERENCES dbo.Dim_Date(date_key),
    CONSTRAINT FK_Fact_Time FOREIGN KEY (time_key) REFERENCES dbo.Dim_Time(time_key),
    CONSTRAINT FK_Fact_Location FOREIGN KEY (location_key) REFERENCES dbo.Dim_Location(location_key),
    CONSTRAINT FK_Fact_PropertyType FOREIGN KEY (property_type_key) REFERENCES dbo.Dim_PropertyType(property_type_key),
    CONSTRAINT FK_Fact_Project FOREIGN KEY (project_key) REFERENCES dbo.Dim_Project(project_key),
    CONSTRAINT FK_Fact_Direction FOREIGN KEY (direction_key) REFERENCES dbo.Dim_Direction(direction_key)
);
GO

-- ===============================================================================
-- 3. NẠP DỮ LIỆU TĨNH BAN ĐẦU VÀ BẢN GHI MẶC ĐỊNH (SCD TYPE 0)
-- ===============================================================================

-- 3.1. Populate Dim_Time (24 khung giờ đăng tin)
TRUNCATE TABLE dbo.Dim_Time;
DECLARE @Hour INT = 0;
WHILE @Hour <= 23
BEGIN
    INSERT INTO dbo.Dim_Time (time_key, post_hour, day_period)
    VALUES (
        @Hour, @Hour,
        CASE 
            WHEN @Hour BETWEEN 6 AND 11 THEN N'Sáng (6h-12h)'
            WHEN @Hour BETWEEN 12 AND 17 THEN N'Chiều (12h-18h)'
            WHEN @Hour BETWEEN 18 AND 23 THEN N'Tối (18h-24h)'
            ELSE N'Đêm (0h-6h)'
        END
    );
    SET @Hour = @Hour + 1;
END;
GO

-- 3.2. Populate Dim_Direction (9 hướng nhà phong thủy)
TRUNCATE TABLE dbo.Dim_Direction;
INSERT INTO dbo.Dim_Direction (direction_key, house_direction) VALUES
(0, N'Không xác định'), (1, N'Đông'), (2, N'Tây'), (3, N'Nam'), (4, N'Bắc'),
(5, N'Đông Nam'), (6, N'Tây Nam'), (7, N'Đông Bắc'), (8, N'Tây Bắc');
GO

-- 3.3. Tạo bản ghi mặc định cho Dim_Project (Gán ID = -1 khi BĐS không thuộc dự án nào)
SET IDENTITY_INSERT dbo.Dim_Project ON;
IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Project WHERE project_key = -1)
BEGIN
    INSERT INTO dbo.Dim_Project (project_key, project_name) VALUES (-1, N'Không thuộc dự án');
END;
SET IDENTITY_INSERT dbo.Dim_Project OFF;
GO

-- 3.4. Sinh dữ liệu Dim_Date tự động từ 2020 đến 2030
DECLARE @StartDate DATE = '2020-01-01';
DECLARE @EndDate DATE = '2030-12-31';

WHILE @StartDate <= @EndDate
BEGIN
    DECLARE @DateKey INT = YEAR(@StartDate) * 10000 + MONTH(@StartDate) * 100 + DAY(@StartDate);
    IF NOT EXISTS (SELECT 1 FROM dbo.Dim_Date WHERE date_key = @DateKey)
    BEGIN
        INSERT INTO dbo.Dim_Date (
            date_key, full_date, day_of_month, day_name, day_of_week, 
            month_num, month_name, quarter, quarter_name, year, is_weekend
        )
        VALUES (
            @DateKey, @StartDate, DAY(@StartDate),
            CASE DATEPART(WEEKDAY, @StartDate)
                WHEN 1 THEN N'Chủ Nhật' WHEN 2 THEN N'Thứ Hai' WHEN 3 THEN N'Thứ Ba'
                WHEN 4 THEN N'Thứ Tư' WHEN 5 THEN N'Thứ Năm' WHEN 6 THEN N'Thứ Sáu' ELSE N'Thứ Bảy'
            END,
            DATEPART(WEEKDAY, @StartDate), MONTH(@StartDate),
            N'Tháng ' + CAST(MONTH(@StartDate) AS NVARCHAR(2)),
            DATEPART(QUARTER, @StartDate), 'Q' + CAST(DATEPART(QUARTER, @StartDate) AS VARCHAR(1)),
            YEAR(@StartDate),
            CASE WHEN DATEPART(WEEKDAY, @StartDate) IN (1, 7) THEN 1 ELSE 0 END
        );
    END
    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END;
GO

PRINT N'=== KHỞI TẠO TOÀN BỘ KHUNG STAR SCHEMA VÀ DỮ LIỆU TĨNH THÀNH CÔNG ==='; 


