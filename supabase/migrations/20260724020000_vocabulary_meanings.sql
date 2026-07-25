-- Pha 3c — Hỗ trợ nhiều nghĩa cho 1 từ vựng, mỗi nghĩa có ví dụ riêng.
-- Trước đây vocabulary chỉ có 1 meaning_vi/example_jp/example_vi — không đủ
-- cho các từ đa nghĩa (VD: 高い = "đắt" khi nói giá, "cao" khi nói chiều cao).

create table vocabulary_meanings (
  id            uuid primary key default gen_random_uuid(),
  vocabulary_id uuid not null references vocabulary(id) on delete cascade,
  order_index   int not null default 0,
  meaning_vi    text not null,
  example_jp    text,
  example_vi    text,
  created_at    timestamptz not null default now()
);
create unique index ux_vocabulary_meanings_order on vocabulary_meanings (vocabulary_id, order_index);

-- Chuyển dữ liệu nghĩa đơn hiện có (nếu có) sang bảng mới làm nghĩa #0,
-- trước khi bỏ các cột cũ trên vocabulary.
insert into vocabulary_meanings (vocabulary_id, order_index, meaning_vi, example_jp, example_vi)
select id, 0, meaning_vi, example_jp, example_vi from vocabulary
on conflict (vocabulary_id, order_index) do nothing;

alter table vocabulary drop column meaning_vi;
alter table vocabulary drop column example_jp;
alter table vocabulary drop column example_vi;

alter table vocabulary_meanings enable row level security;
create policy "vocabulary_meanings_read_all" on vocabulary_meanings for select using (true);
