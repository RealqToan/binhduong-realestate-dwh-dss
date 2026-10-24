import pandas as pd
import numpy as np
import re

# ---------------------------------------------------------
# 1. ĐỌC DỮ LIỆU ĐẦU VÀO
# ---------------------------------------------------------
INPUT_PATH = 'Binhduong_real_estate1.csv'
df = pd.read_csv(INPUT_PATH, encoding='utf-8-sig')

initial_len = len(df)

print("=" * 70)
print(f"{'QUY TRÌNH THỰC THI LÀM SẠCH & CHUẨN HÓA DỮ LIỆU NÂNG CAO - BÌNH DƯƠNG':^70}")
print("=" * 70)
print(f"• Số lượng bản ghi đầu vào                 : {initial_len:>12,}")

# ---------------------------------------------------------
# 2. BƯỚC 1: CHUẨN HÓA ĐỊNH DẠNG VĂN BẢN VÀ XÓA KÝ TỰ RÁC
# ---------------------------------------------------------
def clean_text(text):
    if pd.isna(text):
        return text
    text = str(text)
    # Xóa ký tự xuống dòng, tab
    text = re.sub(r'[\r\n\t]+', ' ', text)
    # Xóa khoảng trắng thừa giữa các từ
    text = re.sub(r'\s+', ' ', text).strip()
    return text.title()

text_cols = ['name', 'title', 'street_name', 'ward_name', 'district_name', 'project_name', 'property_type_name']
for col in text_cols:
    if col in df.columns:
        df[col] = df[col].apply(clean_text)

# ---------------------------------------------------------
# 3. BƯỚC 2: ÉP KIỂU VÀ LỌC GIÁ TRỊ GIÁ & DIỆN TÍCH BẤT THƯỜNG (OUTLIERS)
# ---------------------------------------------------------
df['price_num'] = pd.to_numeric(df['price'], errors='coerce')
df['area_num'] = pd.to_numeric(df['area'], errors='coerce')

# Tính Đơn giá / m2 (đơn vị: triệu VNĐ / m2) để phát hiện nhiễu
# Giả định price_num trong dataset gốc tính theo đơn vị VNĐ hoặc Triệu VNĐ
df['price_per_m2'] = np.where(df['area_num'] > 0, df['price_num'] / df['area_num'], np.nan)

# ĐIỀU KIỆN LỌC SẠCH (BUSINESS RULES R1 & R2):
# - Giá phải dương (> 0) và không quá phi thực tế
# - Diện tích trong khoảng [10m2, 20.000m2] (tránh lỗi gõ thừa số 0)
# - Đơn giá / m2 phải hợp lý: từ 500.000 VNĐ/m2 đến 1 Tỷ VNĐ/m2 (tùy thang đo dataset)
valid_price_cond = (df['price_num'] > 0) & df['price_num'].notna()
valid_area_cond = (df['area_num'] >= 10) & (df['area_num'] <= 20000) & df['area_num'].notna()

df_step1 = df[valid_price_cond & valid_area_cond].copy()

# Lọc bỏ thêm các Outlier về đơn giá vô lý (nếu có)
q_low = df_step1['price_per_m2'].quantile(0.001) # Lọc 0.1% đơn giá đáy cực đoan
q_high = df_step1['price_per_m2'].quantile(0.999) # Lọc 0.1% đơn giá đỉnh cực đoan
df_step1 = df_step1[(df_step1['price_per_m2'] >= q_low) & (df_step1['price_per_m2'] <= q_high)]

dropped_invalid = initial_len - len(df_step1)
print(f"-> Đã loại bỏ {dropped_invalid:,} bản ghi vi phạm (Giá <=0, diện tích <10m2 hoặc >20,000m2, Outlier giá).")

# ---------------------------------------------------------
# 4. BƯỚC 3: XỬ LÝ KHUYẾT THIẾU VÀ ĐỒNG BỘ BẢNG CHIỀU (Quy tắc R3)
# ---------------------------------------------------------
df_step2 = df_step1.copy()

# Xử lý tên dự án
df_step2['project_name'] = df_step2['project_name'].fillna('Đất Dân / Nhà Lẻ Ngoài Dự Án')
df_step2['is_in_project'] = np.where(df_step2['project_name'] == 'Đất Dân / Nhà Lẻ Ngoài Dự Án', 0, 1)

# Xử lý địa danh
df_step2['ward_name'] = df_step2['ward_name'].fillna('Chưa Xác Định')
df_step2['street_name'] = df_step2['street_name'].fillna('Đường Nội Bộ / Không Rõ Tên')

# Xử lý đặc thù Đất nền vs Công trình xây dựng
is_land = df_step2['property_type_name'].str.contains('Đất', case=False, na=False)
df_step2['bedroom_count'] = pd.to_numeric(df_step2['bedroom_count'], errors='coerce').fillna(0)
df_step2['bathroom_count'] = pd.to_numeric(df_step2['bathroom_count'], errors='coerce').fillna(0)

# Nếu là Đất thì bắt buộc số phòng = 0
df_step2.loc[is_land, 'bedroom_count'] = 0
df_step2.loc[is_land, 'bathroom_count'] = 0

# Xử lý thuộc tính tầng
df_step2['floor_count'] = pd.to_numeric(df_step2['floor_count'], errors='coerce').fillna(0)

# ---------------------------------------------------------
# 5. BƯỚC 4: KHỬ TRÙNG LẶP NGHIỆP VỤ ƯU TIÊN TIN MỚI NHẤT (Quy tắc R4)
# ---------------------------------------------------------
# Sắp xếp theo ngày đăng (published_at) giảm dần để giữ tin mới nhất
if 'published_at' in df_step2.columns:
    df_step2['published_at_dt'] = pd.to_datetime(df_step2['published_at'], errors='coerce')
    df_step2 = df_step2.sort_values(by='published_at_dt', ascending=False)

core_cols = ['district_name', 'ward_name', 'street_name', 'price_num', 'area_num', 'property_type_name']
before_dedup = len(df_step2)

# Giữ lại bản ghi xuất hiện đầu tiên (tương ứng tin đăng MỚI NHẤT)
df_cleaned = df_step2.drop_duplicates(subset=core_cols, keep='first').copy()
dropped_duplicates = before_dedup - len(df_cleaned)
print(f"-> Đã khử {dropped_duplicates:,} bản ghi trùng lặp nghiệp vụ (Giữ lại tin đăng MỚI NHẤT).")

# Xóa cột phụ trợ trước khi xuất file
cols_to_drop = [c for c in ['published_at_dt', 'price_per_m2'] if c in df_cleaned.columns]
df_cleaned = df_cleaned.drop(columns=cols_to_drop)
# Loại bỏ các cột bị lặp lại không cần thiết
df_cleaned = df_cleaned.drop(columns=['price_num', 'area_num'], errors='ignore')
# ---------------------------------------------------------
# 6. XUẤT FILE KẾT QUẢ ĐẠT CHUẨN
# ---------------------------------------------------------
print("-" * 70)
print(f"• Số lượng bản ghi tinh sạch hoàn toàn      : {len(df_cleaned):>12,}")
print("=" * 70)

OUTPUT_PATH = 'Binh_duong_cleaned.csv'
df_cleaned.to_csv(OUTPUT_PATH, index=False, encoding='utf-8-sig')
print(f"✅ Đã xuất file dữ liệu sạch tinh tại: {OUTPUT_PATH}")
print("=" * 70)
