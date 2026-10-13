-- Một hội thoại nghe có thể thuộc riêng một bài học. Cột nullable để toàn bộ
-- dữ liệu nghe N5 hiện có vẫn tiếp tục là pool theo cấp độ như trước.
alter table listening_dialogues
  add column lesson_id uuid references lessons(id) on delete cascade;

create index ix_listening_dialogues_lesson
  on listening_dialogues (lesson_id);
