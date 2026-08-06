-- JLPT Mock Exam — schema nền cho 4 khái niệm đã đặc tả ở
-- docs/JLPT_MOCK_EXAM_DESIGN.md §5. Không đổi bảng nào đã có (jlpt_levels,
-- listening_dialogues, quiz content...). `ExamSectionResult`/`PassFailPrediction`
-- trong đặc tả không tách bảng riêng — gộp vào jlpt_exam_sessions.score/
-- pass_fail_prediction (jsonb, điền 1 lần khi submit), giống cách
-- review_mistakes gộp occurrence_count thay vì log từng attempt.

-- Nội dung tham chiếu, ít đổi, đọc công khai (giống listening_dialogues):
-- cấu trúc 1 đề theo level+mode. Chỉ Full Exam/Mini Test cần blueprint cố
-- định; Section Practice/Custom/Weak Point/AI Mock Exam chọn câu hỏi động,
-- không cần blueprint (xem docs/JLPT_MOCK_EXAM_DESIGN.md §3).
create table jlpt_exam_blueprints (
  id          uuid primary key default gen_random_uuid(),
  level_id    uuid not null references jlpt_levels(id),
  mode        varchar(24) not null check (mode in ('full_exam', 'mini_test')),
  -- [{"type":"vocabulary_grammar","question_count":35,"time_minutes":25}, ...]
  sections    jsonb not null,
  created_at  timestamptz not null default now(),
  unique (level_id, mode)
);
alter table jlpt_exam_blueprints enable row level security;
create policy "jlpt_exam_blueprints_read_all" on jlpt_exam_blueprints
  for select using (true);

-- Đoạn văn đọc hiểu tự soạn (docs/JLPT_MOCK_EXAM_DESIGN.md §8, §20 — quyết
-- định tự soạn passage mẫu, không dùng đề thật để tránh vấn đề bản quyền).
create table reading_passages (
  id         uuid primary key default gen_random_uuid(),
  level_id   uuid not null references jlpt_levels(id),
  title      text not null,
  body_ja    text not null,
  -- [{"question_ja":"...","options":["...","...","...","..."],"correct_index":0}, ...]
  questions  jsonb not null,
  created_at timestamptz not null default now()
);
create index ix_reading_passages_level on reading_passages (level_id);
alter table reading_passages enable row level security;
create policy "reading_passages_read_all" on reading_passages
  for select using (true);

-- Dữ liệu riêng người dùng (RLS theo pattern user_vocab_progress/review_mistakes):
create table jlpt_exam_sessions (
  id                   uuid primary key default gen_random_uuid(),
  user_id              uuid not null references auth.users(id) on delete cascade,
  level_id             uuid not null references jlpt_levels(id),
  mode                 varchar(24) not null check (mode in (
    'full_exam', 'mini_test', 'section_practice', 'custom_test',
    'weak_point_test', 'ai_mock_exam'
  )),
  status               varchar(16) not null default 'in_progress'
    check (status in ('in_progress', 'submitted', 'abandoned')),
  blueprint_id         uuid references jlpt_exam_blueprints(id),
  -- điền khi submit: {"vocabulary_grammar":{"correct":28,"total":35}, "reading":{...}, "listening":{...}}
  score                jsonb,
  -- {"predicted_pass":true,"confidence":"...","note":"ước lượng, không phải kết quả thật"}
  pass_fail_prediction jsonb,
  started_at           timestamptz not null default now(),
  submitted_at         timestamptz,
  created_at           timestamptz not null default now()
);
create index ix_jlpt_exam_sessions_user on jlpt_exam_sessions (user_id, started_at desc);
alter table jlpt_exam_sessions enable row level security;
create policy "jlpt_exam_sessions_select_own" on jlpt_exam_sessions
  for select using (auth.uid() = user_id);
create policy "jlpt_exam_sessions_insert_own" on jlpt_exam_sessions
  for insert with check (auth.uid() = user_id);
create policy "jlpt_exam_sessions_update_own" on jlpt_exam_sessions
  for update using (auth.uid() = user_id);

-- question_snapshot lưu nguyên câu hỏi lúc sinh đề (không chỉ id) vì Vocab/
-- Grammar sinh động từ quiz_generator.dart, không phải content row cố định
-- — đề đã làm không được đổi nội dung nếu ngân hàng câu hỏi thay đổi sau đó.
create table jlpt_exam_answers (
  id                uuid primary key default gen_random_uuid(),
  session_id        uuid not null references jlpt_exam_sessions(id) on delete cascade,
  user_id           uuid not null references auth.users(id) on delete cascade,
  section_type      varchar(16) not null
    check (section_type in ('vocabulary', 'grammar', 'reading', 'listening')),
  question_index    integer not null,
  question_snapshot jsonb not null,
  selected_index    integer,
  is_correct        boolean,
  bookmarked        boolean not null default false,
  flagged           boolean not null default false,
  time_spent_ms     integer,
  answered_at       timestamptz,
  unique (session_id, section_type, question_index)
);
create index ix_jlpt_exam_answers_session on jlpt_exam_answers (session_id);
alter table jlpt_exam_answers enable row level security;
create policy "jlpt_exam_answers_select_own" on jlpt_exam_answers
  for select using (auth.uid() = user_id);
create policy "jlpt_exam_answers_insert_own" on jlpt_exam_answers
  for insert with check (auth.uid() = user_id);
create policy "jlpt_exam_answers_update_own" on jlpt_exam_answers
  for update using (auth.uid() = user_id);
