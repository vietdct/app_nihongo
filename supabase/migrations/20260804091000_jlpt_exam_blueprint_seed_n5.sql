-- Seed 1 blueprint N5 Full Exam để có dữ liệu test cho exam engine (Task 4+
-- trong docs/JLPT_MOCK_EXAM_DESIGN.md). Số câu/số phút dưới đây là TẠM,
-- chưa phải Official Timing chính thức JLPT (việc tra số liệu công khai
-- chính xác để làm Result/Pass-Fail thật nằm ở Task 7 — §7, §20 quyết định
-- 2026-08-04). Chưa có Reading vì passage chưa soạn (Task 6) — sẽ update
-- thêm section reading vào đây khi soạn xong, không tạo blueprint mới.
insert into jlpt_exam_blueprints (level_id, mode, sections)
select id, 'full_exam', '[
  {"type": "vocabulary", "question_count": 20, "time_minutes": 15},
  {"type": "grammar", "question_count": 15, "time_minutes": 15},
  {"type": "listening", "question_count": 10, "time_minutes": 15}
]'::jsonb
from jlpt_levels where code = 'N5';
