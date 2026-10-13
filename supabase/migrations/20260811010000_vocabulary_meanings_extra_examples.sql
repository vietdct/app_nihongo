-- 1 nghĩa của từ vựng có thể cần nhiều hơn 1 câu ví dụ (trước đây chỉ có
-- đúng 1 cặp example_jp/example_vi) — cùng mẫu với
-- grammar_points.extra_examples_jp/vi (20260810100000_grammar_extra_examples.sql).
-- Không đổi example_jp/example_vi hiện có.
alter table vocabulary_meanings
  add column extra_examples_jp text[] not null default '{}',
  add column extra_examples_vi text[] not null default '{}';
