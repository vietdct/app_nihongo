-- Pha 3f — Tiến độ học kanji theo người dùng, giống hệt user_vocab_progress:
-- thuộc/chưa thuộc (vuốt flashcard) + đánh dấu sao để xem lại sau.

create table user_kanji_progress (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  kanji_id   uuid not null references kanji(id) on delete cascade,
  status     varchar(16),                          -- 'known' | 'unknown' | null (chưa ôn)
  starred    boolean not null default false,
  updated_at timestamptz not null default now(),
  unique (user_id, kanji_id)
);
create index ix_user_kanji_progress_user on user_kanji_progress (user_id);

alter table user_kanji_progress enable row level security;

create policy "user_kanji_progress_select_own" on user_kanji_progress
  for select using (auth.uid() = user_id);

create policy "user_kanji_progress_insert_own" on user_kanji_progress
  for insert with check (auth.uid() = user_id);

create policy "user_kanji_progress_update_own" on user_kanji_progress
  for update using (auth.uid() = user_id);
