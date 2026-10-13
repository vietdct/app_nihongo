-- Điền/đồng bộ stroke_count theo số nét trong stroke_data (KanjiVG). Chạy lại an toàn.
update kanji
set stroke_count = jsonb_array_length(stroke_data->'strokes')
where stroke_data is not null
  and stroke_count is distinct from jsonb_array_length(stroke_data->'strokes');
