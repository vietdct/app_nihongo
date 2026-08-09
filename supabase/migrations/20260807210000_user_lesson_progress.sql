-- Tiến trình học dở của từng bài — trước đây LessonRunnerController reset
-- về bước 0 mỗi lần vào lại bài (autoDispose, không lưu gì). Bảng này lưu
-- bước đang dừng lại + tổng số bước (để tính %) và mốc hoàn thành, phục vụ
-- thẻ "Continue Learning" ở Home biết đúng bài đang học dở thay vì luôn trỏ
-- về bài đầu tiên của cấp độ.

create table user_lesson_progress (
  user_id         uuid not null references auth.users(id) on delete cascade,
  lesson_id       text not null,
  last_step_index int not null default 0,
  total_steps     int not null default 0,
  completed_at    timestamptz,
  updated_at      timestamptz not null default now(),
  primary key (user_id, lesson_id)
);

create index ix_user_lesson_progress_user on user_lesson_progress (user_id);

alter table user_lesson_progress enable row level security;

create policy "user_lesson_progress_select_own" on user_lesson_progress
  for select using (auth.uid() = user_id);

create policy "user_lesson_progress_insert_own" on user_lesson_progress
  for insert with check (auth.uid() = user_id);

create policy "user_lesson_progress_update_own" on user_lesson_progress
  for update using (auth.uid() = user_id);
