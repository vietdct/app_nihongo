-- Hồ sơ Phase 4 (nhóm Achievement) — thêm cột longest_streak_count để huy
-- hiệu "7 ngày"/"30 ngày" không biến mất khi streak hiện tại bị reset (badge
-- đã đạt phải là vĩnh viễn, không nên phụ thuộc streak_count đang chạy).
-- Khởi tạo bằng streak_count hiện có vì đó là giá trị lớn nhất từng biết
-- được tính đến thời điểm này (không có lịch sử streak trước đó để suy ra
-- mốc cao hơn).

alter table profiles add column longest_streak_count integer not null default 0;
update profiles set longest_streak_count = streak_count;
