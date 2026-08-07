-- Lịch nhiệt (heatmap) ngày học — bảng log riêng vì `profiles.last_study_date`
-- chỉ giữ ngày gần nhất (dùng cho streak), không có lịch sử để vẽ calendar.
-- Ghi 1 dòng/ngày/user khi có hoạt động thật (vocab/kanji/quiz/kaiwa/mini
-- test — cùng tín hiệu "hôm nay đã học" mà dailyMissionStatusProvider và
-- MiniTestXpController đã tính sẵn), upsert idempotent nên gọi nhiều lần
-- trong ngày không tạo trùng dòng.

create table study_days (
  user_id    uuid not null references auth.users(id) on delete cascade,
  study_date date not null,
  created_at timestamptz not null default now(),
  primary key (user_id, study_date)
);

create index ix_study_days_user_date on study_days (user_id, study_date desc);

alter table study_days enable row level security;

create policy "study_days_select_own" on study_days
  for select using (auth.uid() = user_id);

create policy "study_days_insert_own" on study_days
  for insert with check (auth.uid() = user_id);
