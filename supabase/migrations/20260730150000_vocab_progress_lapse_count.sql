-- Vocab Đợt 6 — bộ lọc "Hay quên nhất": cần đếm lũy kế số lần bị chấm "Quên"
-- qua các lượt ôn SRS, khác với `interval_days <= 1` (chỉ phản ánh lượt gần
-- nhất). Tăng ở app khi `recordReview` được gọi với `SrsGrade.forgot`.
alter table user_vocab_progress
  add column lapse_count integer not null default 0;
