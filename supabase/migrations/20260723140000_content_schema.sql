-- Pha 2 — Nội dung học liệu: Lessons, Vocabulary, Kanji, Grammar
-- Tham chiếu: Tài liệu thiết kế v2.0, mục 3 (nhóm "Nội dung học liệu").
-- Toàn bộ nội dung học liệu là dữ liệu công khai — RLS chỉ cho phép đọc,
-- ghi chỉ qua service role (seed/admin), không cho client tự ghi.

create extension if not exists "pg_trgm";

-- ─────────────────────────────────────────────────────────────
-- Bài học
-- ─────────────────────────────────────────────────────────────
create table lessons (
  id          uuid primary key default gen_random_uuid(),
  level_id    uuid not null references jlpt_levels(id),
  title       varchar(200) not null,
  description text,
  order_index int not null default 0,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index ix_lessons_level_order on lessons (level_id, order_index);

-- ─────────────────────────────────────────────────────────────
-- Từ vựng
-- ─────────────────────────────────────────────────────────────
create table vocabulary (
  id             uuid primary key default gen_random_uuid(),
  word           varchar(64) not null,
  reading        varchar(128) not null,
  meaning_vi     text not null,
  part_of_speech varchar(32),
  example_jp     text,
  example_vi     text,
  audio_url      text,
  level_id       uuid not null references jlpt_levels(id),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index ix_vocabulary_level on vocabulary (level_id);
create index ix_vocabulary_word_trgm on vocabulary using gin (word gin_trgm_ops);
create index ix_vocabulary_reading_trgm on vocabulary using gin (reading gin_trgm_ops);

-- ─────────────────────────────────────────────────────────────
-- Kanji
-- ─────────────────────────────────────────────────────────────
create table kanji (
  id           uuid primary key default gen_random_uuid(),
  character    varchar(4) not null,
  onyomi       varchar(128),
  kunyomi      varchar(128),
  meaning_vi   text not null,
  stroke_count int,
  example_jp   text,
  example_vi   text,
  level_id     uuid not null references jlpt_levels(id),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create unique index ux_kanji_character on kanji (character);
create index ix_kanji_level on kanji (level_id);
create index ix_kanji_stroke_count on kanji (stroke_count);

-- ─────────────────────────────────────────────────────────────
-- Ngữ pháp (schema tạo sẵn từ Pha 2, UI/seed đầy đủ để dành Pha 4)
-- ─────────────────────────────────────────────────────────────
create table grammar_points (
  id          uuid primary key default gen_random_uuid(),
  title       varchar(200) not null,
  explanation text not null,
  example_jp  text,
  example_vi  text,
  level_id    uuid not null references jlpt_levels(id),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index ix_grammar_points_level on grammar_points (level_id);

-- ─────────────────────────────────────────────────────────────
-- Gắn vocabulary/kanji/grammar vào bài học theo thứ tự
-- (polymorphic — xem lý do ở migration Pha 1: ít bảng lặp hơn quan trọng
--  hơn ràng buộc FK cứng ở tầng DB cho một người maintain)
-- ─────────────────────────────────────────────────────────────
create table lesson_items (
  id          uuid primary key default gen_random_uuid(),
  lesson_id   uuid not null references lessons(id) on delete cascade,
  item_type   varchar(16) not null,   -- 'vocabulary' | 'kanji' | 'grammar'
  item_id     uuid not null,
  order_index int not null default 0,
  created_at  timestamptz not null default now()
);
create index ix_lesson_items_lesson_order on lesson_items (lesson_id, order_index);
create unique index ux_lesson_items_unique on lesson_items (lesson_id, item_type, item_id);

-- ─────────────────────────────────────────────────────────────
-- Row Level Security — nội dung học liệu công khai, chỉ đọc
-- ─────────────────────────────────────────────────────────────
alter table lessons enable row level security;
create policy "lessons_read_all" on lessons for select using (true);

alter table vocabulary enable row level security;
create policy "vocabulary_read_all" on vocabulary for select using (true);

alter table kanji enable row level security;
create policy "kanji_read_all" on kanji for select using (true);

alter table grammar_points enable row level security;
create policy "grammar_points_read_all" on grammar_points for select using (true);

alter table lesson_items enable row level security;
create policy "lesson_items_read_all" on lesson_items for select using (true);
