-- Hồ sơ Phase 2 (nhóm Personal) — thêm cột country (quốc gia người học tự
-- chọn trong Edit Profile) để hiển thị ở Profile Home. Nullable vì user cũ
-- chưa từng nhập. "Study Since" không cần cột mới, dùng thẳng
-- profiles.created_at đã có sẵn từ Pha 1.

alter table profiles add column country text;
