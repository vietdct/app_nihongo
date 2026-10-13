-- Câu hỏi luyện Ngữ pháp dạng trắc nghiệm điền chỗ trống, có đáp án nhiễu và lời giải.
-- Tách riêng khỏi grammar_points vì mỗi mẫu có thể có nhiều câu và cần lưu nhiễu/lời giải/nguồn.
-- Bảng thêm mới (additive): không đụng dữ liệu hiện có. Bài học liên kết bằng lesson_id (nullable
-- để sau này dùng cho cấp N5–N1 theo cấp độ, giống listening_dialogues).
create table grammar_practice_questions (
  id             uuid primary key default gen_random_uuid(),
  level_id       uuid not null references jlpt_levels(id),
  lesson_id      uuid references lessons(id) on delete cascade,
  grammar_point_id uuid references grammar_points(id) on delete set null,
  -- Câu tiếng Nhật, chỗ trống là （　　）.
  prompt_jp      text not null,
  options        jsonb not null,
  correct_index  int not null,
  explanation_vi text,
  -- 'book': câu nguyên văn từ sách; 'ai': câu do AI soạn. Nhiễu/lời giải luôn do người soạn viết.
  source         text not null check (source in ('book', 'ai')),
  source_ref     text,
  created_at     timestamptz not null default now(),
  check (jsonb_typeof(options) = 'array'
         and jsonb_array_length(options) between 2 and 4
         and correct_index >= 0
         and correct_index < jsonb_array_length(options))
);
create index ix_grammar_practice_level on grammar_practice_questions (level_id);
create index ix_grammar_practice_lesson on grammar_practice_questions (lesson_id);
create unique index ux_grammar_practice_lesson_prompt
  on grammar_practice_questions (lesson_id, prompt_jp);

alter table grammar_practice_questions enable row level security;
create policy "grammar_practice_questions_read_all"
  on grammar_practice_questions for select using (true);
