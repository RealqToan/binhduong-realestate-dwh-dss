import pandas as pd
import numpy as np


# Đọc file với encoding utf-8-sig dành cho UTF-8 with BOM
INPUT_PATH = 'Binhduong_real_estate1.csv'
df = pd.read_csv(INPUT_PATH, encoding='utf-8-sig')

initial_len = len(df)

# In tiêu đề báo cáo log chuyên nghiệp
print("=" * 65)
print(f"{'QUY TRÌNH THỰC THI LÀM SẠCH & CHUẨN HÓA DỮ LIỆU - BÌNH DƯƠNG':^65}")
print("=" * 65)
print(f"• Số lượng bản ghi đầu vào (từ bạn Toàn) : {initial_len:>12,}")

# BƯỚC 1: XỬ LÝ LỖI GIÁ VÀ DIỆN TÍCH BẤT THƯỜNG (Quy tắc R1 & R2)
df['price_num'] = pd.to_numeric(df['price'], errors='coerce')
df['area_num'] = pd.to_numeric(df['area'], errors='coerce')

df_cleaned = df[(df['price_num'] > 0) & (df['area_num'] >= 10)].copy()
dropped_invalid = initial_len - len(df_cleaned)
print(f"-> Đã loại bỏ {dropped_invalid:,} bản ghi vi phạm điều kiện giá và diện tích.")

# BƯỚC 2: XỬ LÝ DỮ LIỆU KHUYẾT THIẾU VÀ GÁN NHÃN NGHIỆP VỤ (Quy tắc R3)
df_cleaned['project_name'] = df_cleaned['project_name'].fillna('Đất dân / Nhà lẻ ngoài dự án')
df_cleaned['bedroom_count'] = df_cleaned['bedroom_count'].fillna(0)
df_cleaned['bathroom_count'] = df_cleaned['bathroom_count'].fillna(0)
df_cleaned['ward_name'] = df_cleaned['ward_name'].fillna('Chưa xác định')
df_cleaned['street_name'] = df_cleaned['street_name'].fillna('Đường nội bộ / Không rõ tên')

# BƯỚC 3: KHỬ TRÙNG LẶP NGHIỆP VỤ (Quy tắc R4)
core_cols = ['district_name', 'ward_name', 'street_name', 'price_num', 'area_num']
before_dedup = len(df_cleaned)
df_cleaned = df_cleaned.drop_duplicates(subset=core_cols, keep='first')
dropped_duplicates = before_dedup - len(df_cleaned)
print(f"-> Đã khử {dropped_duplicates:,} bản ghi trùng lặp nghiệp vụ (giữ bản ghi đầu tiên).")

# BƯỚC 4: CHUẨN HÓA ĐỊNH DẠNG VĂN BẢN (Text Standardization)
text_cols = ['title', 'street_name', 'ward_name', 'district_name']
for col in text_cols:
    if col in df_cleaned.columns:
        df_cleaned[col] = df_cleaned[col].astype(str).str.strip().str.title()

print("-" * 65)
print(f"• Số lượng bản ghi sau khi hoàn tất làm sạch  : {len(df_cleaned):>12,}")
print("=" * 65)

# BƯỚC 5: XUẤT FILE KẾT QUẢ SẠCH ĐỂ PHỤC VỤ CHO MỤC 2.3 (THIẾT KẾ MÔ HÌNH DWH)
OUTPUT_PATH = 'Binh_duong_cleaned.csv'
df_cleaned.to_csv(OUTPUT_PATH, index=False, encoding='utf-8-sig')
print(f"✅ Đã xuất file dữ liệu sạch thành công tại: {OUTPUT_PATH}")
print("=" * 65)