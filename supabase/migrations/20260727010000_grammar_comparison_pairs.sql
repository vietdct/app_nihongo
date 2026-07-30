-- ─────────────────────────────────────────────────────────────
-- Cặp ngữ pháp dễ nhầm — cấu trúc hoá lại quan hệ đã ngầm tồn tại trong
-- grammar_points.comparison_note (nhiều dòng đã tự nhắc tên 1 điểm ngữ pháp
-- khác bằng câu chữ). Dữ liệu quan hệ nhỏ, gần như tĩnh — không đi qua
-- Drift offline cache như grammar_points, fetch thẳng qua Supabase.
-- ─────────────────────────────────────────────────────────────
create table grammar_comparison_pairs (
  id           uuid primary key default gen_random_uuid(),
  grammar_id_a uuid not null references grammar_points(id) on delete cascade,
  grammar_id_b uuid not null references grammar_points(id) on delete cascade,
  created_at   timestamptz not null default now(),
  check (grammar_id_a <> grammar_id_b),
  unique (grammar_id_a, grammar_id_b)
);
create index ix_grammar_comparison_pairs_a on grammar_comparison_pairs (grammar_id_a);
create index ix_grammar_comparison_pairs_b on grammar_comparison_pairs (grammar_id_b);

alter table grammar_comparison_pairs enable row level security;
create policy "grammar_comparison_pairs_read_all" on grammar_comparison_pairs for select using (true);
