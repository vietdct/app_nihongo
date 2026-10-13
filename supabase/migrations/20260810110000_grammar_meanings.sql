-- Hỗ trợ nhiều nghĩa cho 1 điểm ngữ pháp, mỗi nghĩa có tối đa 2 ví dụ riêng
-- (VD: 〜とともに có nghĩa A "cùng với", B "đồng thời", C "thay đổi kéo theo
-- thay đổi" — trước đây gộp chung 1 đoạn explanation dài, khó đọc).
-- Giống cách vocabulary_meanings đã làm cho từ vựng đa nghĩa. Không đổi gì ở
-- grammar_points hiện có — điểm ngữ pháp chưa có dòng trong bảng này (N4/N5)
-- vẫn hiển thị theo explanation/example_jp/example_vi cũ như trước.

create table grammar_meanings (
  id               uuid primary key default gen_random_uuid(),
  grammar_point_id uuid not null references grammar_points(id) on delete cascade,
  order_index      int not null default 0,
  meaning_vi       text not null,
  examples_jp      text[] not null default '{}',
  examples_vi      text[] not null default '{}',
  created_at       timestamptz not null default now()
);
create unique index ux_grammar_meanings_order on grammar_meanings (grammar_point_id, order_index);

alter table grammar_meanings enable row level security;
create policy "grammar_meanings_read_all" on grammar_meanings for select using (true);
