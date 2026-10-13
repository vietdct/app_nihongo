-- Mỗi điểm ngữ pháp cần 2-3 ví dụ khác nhau để dễ hiểu hơn (trước đây chỉ có
-- đúng 1 câu ở example_jp/example_vi). Không đổi example_jp/example_vi hiện
-- có vì nó đang gắn với practice_tokens (bài ghép câu/điền từ soạn thủ công
-- theo đúng câu đó) — thêm 2 cột mảng song song để chứa các ví dụ bổ sung.
alter table grammar_points
  add column extra_examples_jp text[] not null default '{}',
  add column extra_examples_vi text[] not null default '{}';
