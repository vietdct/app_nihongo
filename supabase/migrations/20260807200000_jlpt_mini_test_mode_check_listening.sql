-- Thêm 'mini_listening' vào constraint mode của jlpt_exam_sessions — thiếu
-- giá trị này khi thêm biến thể MiniTestVariant.listening (2026-08-07, xem
-- mini_test_variant.dart) cho tính năng "Nghe hiểu" mới ở tab Ôn tập
-- (review_screen.dart._ListeningReviewRow). `MiniTestBlueprint.sessionMode`
-- sinh ra 'mini_${variant.name}' => 'mini_listening', bị Postgres từ chối
-- (23514) khi tạo session vì check constraint cũ chưa liệt kê giá trị này.
-- Phát hiện khi live-verify trên simulator (PostgrestException tại
-- ExamSessionRepository.createSession).
alter table jlpt_exam_sessions drop constraint jlpt_exam_sessions_mode_check;
alter table jlpt_exam_sessions add constraint jlpt_exam_sessions_mode_check
  check (mode in (
    'full_exam', 'mini_test', 'section_practice', 'custom_test',
    'weak_point_test', 'ai_mock_exam',
    'mini_quick5', 'mini_daily', 'mini_weakPoint', 'mini_ai', 'mini_listening'
  ));
