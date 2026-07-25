-- Pha 3b — Tiến độ học từ vựng theo người dùng: thuộc/chưa thuộc (vuốt
-- flashcard) + đánh dấu sao để xem lại sau. Mỗi người dùng có 1 dòng tiến độ
-- riêng cho mỗi từ vựng; RLS chỉ cho đọc/ghi dữ liệu của chính mình.

create table user_vocab_progress (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  vocab_id   uuid not null references vocabulary(id) on delete cascade,
  status     varchar(16),                          -- 'known' | 'unknown' | null (chưa ôn)
  starred    boolean not null default false,
  updated_at timestamptz not null default now(),
  unique (user_id, vocab_id)
);
create index ix_user_vocab_progress_user on user_vocab_progress (user_id);

alter table user_vocab_progress enable row level security;

create policy "user_vocab_progress_select_own" on user_vocab_progress
  for select using (auth.uid() = user_id);

create policy "user_vocab_progress_insert_own" on user_vocab_progress
  for insert with check (auth.uid() = user_id);

create policy "user_vocab_progress_update_own" on user_vocab_progress
  for update using (auth.uid() = user_id);
