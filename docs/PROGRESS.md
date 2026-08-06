# Current Progress

> Đây là trạng thái hiện tại, không phải nhật ký. Mỗi lần bàn giao hãy viết đè và giữ dưới khoảng 100 dòng.

## Mục tiêu

JLPT Mock Exam + Mini Test module (`docs/JLPT_MOCK_EXAM_DESIGN.md`,
`docs/JLPT_MINI_TEST_DESIGN.md`), sau đó dọn dẹp trùng lặp trong tab "Ôn
tập" theo phản hồi người dùng.

## Trạng thái — module chính đã xong, đang ở Task 12 (QA)

- **Task 1-11** (Mini Test: Quick 5/Daily/Weak Point, Đọc hiểu/Nghe hiểu,
  bỏ AI Mini Test): xong, người dùng đã xác nhận trên máy.
- **Dọn "Chọn chế độ thi" JLPT**: rút từ 6 xuống 3 (Full Exam/Mini
  Test/Custom Test) — bỏ Section Practice (gộp vào Custom Test), Weak
  Point Test (trùng Weak Point Mini), AI Mock Exam (cùng lý do bỏ AI Mini
  Test). Người dùng đã xác nhận trên máy.
- **Dọn tab "Ôn tập"**: bỏ "Flashcard Từ vựng" (gộp vào Smart Review — màn
  `VocabularyFlashcardScreen` giờ tự tính tập AI gợi ý bằng `isSmartPick`,
  có toggle "AI gợi ý/Tất cả"), bỏ "AI Kaiwa" (trùng tab Kaiwa ở footer),
  xoá hẳn "AI Review Coach" (`review_coach_screen.dart` +
  `providers/review_coach_service.dart` — không dùng nữa, Edge Function
  `ai-review-coach` vẫn để deployed dormant). Đã xác nhận bằng mắt trên
  simulator.
- **Delay 3s trước khi tự phát audio nghe hiểu** (toàn app, không riêng
  JLPT): `quiz_screen.dart` + `exam_runner_screen.dart`. Code xong,
  `flutter analyze` sạch, **chưa live-verify** (chưa vào được đúng 1 câu
  nghe hiểu trong phiên test này).
- **Task 12 (QA Accessibility + Responsive)**: audit tĩnh xong (thêm 2
  tooltip Bookmark/Flag còn thiếu ở `exam_runner_screen.dart`; các layout
  mới đều đã bọc `Expanded`/`Wrap` nên không thấy nguy cơ tràn chữ). Chưa
  test màn hình nhỏ thật — máy chỉ có simulator iPhone 17 series (không có
  iPhone SE/màn nhỏ) nên chưa verify responsive trên thiết bị nhỏ.

## Kiểm tra

- `flutter analyze` toàn repo: sạch (chỉ còn 4 info deprecation cũ
  `RadioListTile.groupValue`, không liên quan phiên làm việc này).
- Build `flutter run --dart-define-from-file=env.json` trên iPhone 17 Pro
  Max: thành công nhiều lần trong phiên.
- Xác nhận bằng mắt trên simulator: 3 mode JLPT, tab Ôn tập rút gọn, toggle
  AI gợi ý/Tất cả ở Flashcard Từ vựng.

## Vấn đề còn lại

- **Delay 3s audio nghe hiểu**: chưa live-verify.
- **Responsive màn nhỏ**: chưa test (thiếu simulator màn nhỏ).
- Simulator tap bị đứng input định kỳ trong suốt phiên (vấn đề môi
  trường, không phải bug code) — nhiều lần phải retry/detach-attach.

## Bước tiếp theo

1. Vào 1 câu Nghe hiểu thật (Daily/Weak Point Mini có bật nguồn "Nghe
   hiểu", hoặc Full Exam phần Listening) để xác nhận delay 3s hoạt động
   đúng và không tự phát đè khi chuyển câu nhanh.
2. Nếu muốn verify responsive kỹ hơn: boot thêm 1 simulator màn nhỏ (vd.
   `xcrun simctl create` iPhone SE) rồi kiểm tra Settings sheet Weak Point
   Mini (label Đọc hiểu/Nghe hiểu khá dài) + Exam Runner có đoạn văn đọc
   hiểu dài.
3. Hỏi người dùng có muốn gỡ luôn Edge Function `ai-review-coach` (đang để
   dormant) hay giữ.
4. Sau khi xong, hỏi người dùng có muốn `git commit`/`git push` không —
   hiện tại các thay đổi trong phiên này **chưa commit**.
