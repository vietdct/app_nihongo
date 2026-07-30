-- Kaiwa SRS (Đợt 5): ôn tập kiểu SM-2 rút gọn cho các câu người học đã nói
-- và bị AI sửa (`kaiwa_messages.feedback.better_phrasing`) — cùng thuật
-- toán với user_kanji_progress/user_grammar_progress (xem `srs_scheduler.dart`,
-- tái dùng nguyên `computeNextSchedule`). Khác 2 bảng progress kia: Kaiwa
-- không có 1 catalog nội dung cố định để join — mỗi tin nhắn CHÍNH LÀ 1 mục
-- ôn tập, nên cột SRS gắn thẳng lên kaiwa_messages thay vì 1 bảng progress
-- riêng. Mặc định due_at = now() cho cả hàng cũ lẫn hàng mới — chưa có lịch
-- sử ôn thật thì coi như due ngay, không giả định due tương lai.
alter table kaiwa_messages
  add column interval_days double precision not null default 0,
  add column ease_factor double precision not null default 2.5,
  add column due_at timestamptz not null default now(),
  add column review_count integer not null default 0;

-- Trước đây chỉ có select/insert — ôn tập cần ghi lại lịch SRS sau mỗi lượt.
create policy "kaiwa_messages_update_own" on kaiwa_messages for update using (auth.uid() = user_id);
