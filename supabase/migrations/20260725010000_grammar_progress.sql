-- Pha 4 — Xây UI Ngữ pháp: thêm nội dung học sâu (lỗi thường gặp/mẹo nhớ/
-- so sánh với ngữ pháp tương tự) và tiến độ học riêng theo người dùng,
-- mirror hệt user_vocab_progress/user_kanji_progress.

alter table grammar_points add column common_mistake text;
alter table grammar_points add column memory_tip text;
alter table grammar_points add column comparison_note text;

create table user_grammar_progress (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  grammar_id uuid not null references grammar_points(id) on delete cascade,
  status     varchar(16),                          -- 'known' | 'unknown' | null (chưa ôn)
  starred    boolean not null default false,
  updated_at timestamptz not null default now(),
  unique (user_id, grammar_id)
);
create index ix_user_grammar_progress_user on user_grammar_progress (user_id);

alter table user_grammar_progress enable row level security;

create policy "user_grammar_progress_select_own" on user_grammar_progress
  for select using (auth.uid() = user_id);

create policy "user_grammar_progress_insert_own" on user_grammar_progress
  for insert with check (auth.uid() = user_id);

create policy "user_grammar_progress_update_own" on user_grammar_progress
  for update using (auth.uid() = user_id);
