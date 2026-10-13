-- Nội dung "mini từ điển" mở rộng cho từ vựng (cách dùng thường gặp, sắc
-- thái, từ gần nghĩa, so sánh, lỗi thường gặp) — theo mockup thiết kế
-- "Vocabulary Detail v2". Chỉ 1 số từ được biên soạn thủ công; cột null/mảng
-- rỗng nghĩa là chưa có nội dung, app ẩn cả section thay vì hiện chỗ trống.
alter table vocabulary
  add column common_usage_pattern text,
  add column common_usage_desc text,
  add column common_usage_examples_jp text[] not null default '{}',
  add column common_usage_examples_vi text[] not null default '{}',
  add column nuance_points text[] not null default '{}',
  add column similar_words text[] not null default '{}',
  add column similar_words_meaning_vi text[] not null default '{}',
  add column comparison_words text[] not null default '{}',
  add column comparison_main_descs text[] not null default '{}',
  add column comparison_other_descs text[] not null default '{}',
  add column common_mistake_note text,
  add column common_mistake_suggestions text[] not null default '{}';
