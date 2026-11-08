# Đồ án: Xây dựng Kho dữ liệu & DSS Đầu tư Bất động sản Bình Dương

## 📌 Quy trình vận hành hệ thống (Pipeline workflow)

1. **Bước 1: Pre-ETL (Python)**
   - Chạy `preprocessings/data_cleaning.ipynb` để làm sạch dữ liệu thô trong `datas/raw/`.
   - Kết quả xuất ra file sạch nằm trong `datas/processed/`.

2. **Bước 2: Khởi tạo Database (SQL Server)**
   - Mở SSMS, thực thi lần lượt `databases/querry/01_create_staging.sql` và `02_create_dwh_schema.sql` để tạo DB và cấu trúc Star Schema.

3. **Bước 3: Chạy SSIS Packages (Visual Studio)**
   - Mở Solution `ssis_pakages/BinhDuong_DWH_ETL/BinhDuong_DWH_ETL.slnx` trong Visual Studio.
   - Bấm Run `Master_Package.dtsx` để tự động nạp dữ liệu từ Staging vào bảng `Fact_Listing` và các bảng `Dim`.

4. **Bước 4: Báo cáo (Power BI)**
   - Kết nối Power BI với Database `BinhDuong_RealEstate_DWH` để xem Dashboard.