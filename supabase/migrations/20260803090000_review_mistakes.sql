-- Review Module — Mistake Notebook: lưu lỗi thật khi người học trả lời sai
-- trong màn Review (Từ vựng/Kanji/Ngữ pháp), để xem lại/ghi chú/bookmark.
-- Không log từng lượt attempt riêng — upsert theo (user_id, source_type,
-- source_id), tăng occurrence_count mỗi lần sai lại, tránh phình bảng.
-- source_id polymorphic (trỏ tới vocabulary/kanji/grammar_points tuỳ
-- source_type) nên không đặt foreign key trực tiếp.

create table review_mistakes (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references auth.users(id) on delete cascade,
  source_type      varchar(16) not null check (source_type in ('vocab', 'kanji', 'grammar')),
  source_id        uuid not null,
  original_answer  text,
  correct_answer   text not null,
  explanation      text,
  note             text,
  bookmarked       boolean not null default false,
  occurrence_count integer not null default 1,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  unique (user_id, source_type, source_id)
);
create index ix_review_mistakes_user on review_mistakes (user_id, updated_at desc);

alter table review_mistakes enable row level security;

create policy "review_mistakes_select_own" on review_mistakes
  for select using (auth.uid() = user_id);

create policy "review_mistakes_insert_own" on review_mistakes
  for insert with check (auth.uid() = user_id);

create policy "review_mistakes_update_own" on review_mistakes
  for update using (auth.uid() = user_id);
