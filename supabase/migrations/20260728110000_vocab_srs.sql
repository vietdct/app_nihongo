-- Vocab SRS (Lesson Đợt 4 — pha Review): lịch ôn tập thật kiểu SM-2 rút gọn,
-- cùng thuật toán và đúng 4 cột như user_kanji_progress/user_grammar_progress
-- (xem `srs_scheduler.dart` — tái dùng nguyên `computeNextSchedule`). Mặc
-- định due_at = now() cho cả hàng cũ lẫn hàng mới — chưa có lịch sử ôn thật
-- thì coi như due ngay, không giả định due tương lai.
alter table user_vocab_progress
  add column interval_days double precision not null default 0,
  add column ease_factor double precision not null default 2.5,
  add column due_at timestamptz not null default now(),
  add column review_count integer not null default 0;
