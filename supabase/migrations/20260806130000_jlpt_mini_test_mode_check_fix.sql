-- Sửa lỗi giá trị mode Mini Test đặt sai ở migration trước
-- (20260806100000_jlpt_mini_test_mode_check.sql): constraint cho phép
-- 'mini_weak_point' (snake_case) nhưng `MiniTestBlueprint.sessionMode`
-- (mini_test_blueprint.dart) thực tế sinh ra 'mini_${variant.name}' —
-- `MiniTestVariant.weakPoint.name` là 'weakPoint' (Dart enum .name giữ
-- nguyên camelCase định danh) => giá trị THẬT là 'mini_weakPoint', không
-- khớp constraint cũ. Nếu không sửa, mọi lượt Weak Point Mini nộp bài
-- (`submitSession`/`createSession`) sẽ bị Postgres từ chối do vi phạm check
-- constraint. Phát hiện khi rà lại migration lúc bỏ biến thể AI Mini Test
-- (2026-08-06) khỏi phạm vi sản phẩm. Giữ nguyên 'mini_ai' trong danh sách
-- dù tính năng đã bỏ — đã có 1 dòng thật dùng giá trị này
-- (jlpt_exam_sessions, status=submitted), theo đúng nguyên tắc "chỉ nới,
-- không xoá giá trị đang dùng" đã ghi ở migration trước.
alter table jlpt_exam_sessions drop constraint jlpt_exam_sessions_mode_check;
alter table jlpt_exam_sessions add constraint jlpt_exam_sessions_mode_check
  check (mode in (
    'full_exam', 'mini_test', 'section_practice', 'custom_test',
    'weak_point_test', 'ai_mock_exam',
    'mini_quick5', 'mini_daily', 'mini_weakPoint', 'mini_ai'
  ));
