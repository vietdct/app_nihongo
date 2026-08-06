-- Mini Test (docs/JLPT_MINI_TEST_DESIGN.md) dùng 4 giá trị mode riêng biệt
-- theo biến thể — 'mini_quick5' | 'mini_daily' | 'mini_weak_point' | 'mini_ai'
-- (§5: mode chỉ để phân loại thống kê, KHÔNG tra jlpt_exam_blueprints như
-- Full Exam) — thay cho giá trị 'mini_test' chung đã đặt lúc thiết kế Full
-- Exam (Task 4, trước khi có đề xuất 4 biến thể). Đồng thời section_type
-- 'mixed' (1 section gộp nhiều nguồn câu của Mini Test, khác Full Exam luôn
-- tách riêng vocabulary/grammar/reading/listening) cần được cho phép ở
-- jlpt_exam_answers. Chỉ NỚI constraint (thêm giá trị), không xoá giá trị
-- cũ nào đang dùng.
alter table jlpt_exam_sessions drop constraint jlpt_exam_sessions_mode_check;
alter table jlpt_exam_sessions add constraint jlpt_exam_sessions_mode_check
  check (mode in (
    'full_exam', 'mini_test', 'section_practice', 'custom_test',
    'weak_point_test', 'ai_mock_exam',
    'mini_quick5', 'mini_daily', 'mini_weak_point', 'mini_ai'
  ));

alter table jlpt_exam_answers drop constraint jlpt_exam_answers_section_type_check;
alter table jlpt_exam_answers add constraint jlpt_exam_answers_section_type_check
  check (section_type in ('vocabulary', 'grammar', 'reading', 'listening', 'mixed'));
