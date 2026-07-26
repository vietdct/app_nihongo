-- Nghe hiểu kiểu JLPT (Minna no Nihongo): hội thoại 2 người thật, độ dài
-- ngắn/dài khác nhau, kèm 1 câu hỏi trắc nghiệm về nội dung — khác với kiểu
-- "nghe 1 câu ví dụ đơn lẻ" trước đó (không đủ giống đề nghe thật).
-- turns lưu dạng jsonb: [{"speaker":"A","jp":"..."}, ...] — số lượng turn
-- khác nhau giữa các bản ghi chính là nguồn "ngắn/dài khác nhau" khi random.
create table listening_dialogues (
  id            uuid primary key default gen_random_uuid(),
  level_id      uuid not null references jlpt_levels(id),
  turns         jsonb not null,
  question_vi   text not null,
  options       jsonb not null,
  correct_index int not null,
  created_at    timestamptz not null default now()
);
create index ix_listening_dialogues_level on listening_dialogues (level_id);

alter table listening_dialogues enable row level security;
create policy "listening_dialogues_read_all" on listening_dialogues for select using (true);
