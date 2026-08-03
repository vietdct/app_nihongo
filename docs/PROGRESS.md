# Current Progress

> Đây là trạng thái hiện tại, không phải nhật ký. Mỗi lần bàn giao hãy viết đè và giữ dưới khoảng 100 dòng.

## Mục tiêu

Triển khai Mixed Quiz theo `docs/MIXED_QUIZ_DESIGN.md` §7 (10 task tuần tự).

## Trạng thái — 10/10 task xong (9 làm, 1 hoãn có căn cứ) — ĐÃ COMMIT

- **Task 1-6**: Quiz Engine + Multiple Choice, Fill Blank, Typing/Translation, Sentence Ordering/Grammar Selection/Particle Selection, Error Correction (Sổ tay lỗi + AI Kaiwa), Conversation Completion.
- **Task 7**: Quiz Tuỳ chỉnh (chọn bớt 9 nhóm câu hỏi + số câu) + Timed Mode (đồng hồ toàn bài) + Survival Mode (dừng khi sai câu đầu) — thêm vào `QuizScreen` dùng chung.
- **Task 8**: "Thử thách điểm yếu" — tái dùng `isSmartPick()` (giờ là hàm dùng chung ở `vocab_review_providers.dart`, trước là closure riêng trong `review_smart_screen.dart`).
- **Task 9**: Result Page nâng cao — Accuracy%, Thời gian, danh sách Câu sai (đáp án đã chọn vs đáp án đúng), Điểm yếu theo nhóm (gộp theo `sourceType` + 1 câu nhận xét rule-based), nút dẫn `/review/mistakes` + `/review/smart`. Không thêm XP/Coin giả (XP hiện có là hệ thống thật đã tồn tại từ trước Mixed Quiz, không phải bịa mới).
- **Task 10**: **Hoãn** — khảo sát `audio_url` trên bảng `vocabulary`: cột tồn tại trong schema nhưng **0% dòng có giá trị thật** (grep toàn bộ `supabase/` không có insert/update nào gán `audio_url`, trong khi seed N5 có ~308 từ vựng). Theo đúng ràng buộc tự đặt ("chỉ audioUrl thật, không TTS giả"), không có gì để làm mà không phải bịa — xem `docs/MIXED_QUIZ_DESIGN.md` §8.4.

## File đã thay đổi — đã commit (xem `git log` để biết chi tiết)

10 nhóm sinh câu hỏi (`lib/domain/services/quiz_generator.dart`), provider trộn câu hỏi + Quiz Tuỳ chỉnh + Thử thách điểm yếu (`lib/features/review/providers/mixed_quiz_providers.dart`), `QuizScreen` mở rộng 3 luồng chấm + Timed/Survival + Result Page nâng cao (`lib/features/quiz/quiz_screen.dart`), màn Quiz Tuỳ chỉnh mới, 2 provider Kaiwa mới, `isSmartPick()` dùng chung, các route mới trong `app_router.dart`, và bộ test tương ứng (139 test tổng, riêng Mixed Quiz ~53 test mới).

## Kiểm tra

- `flutter analyze`: No issues found (toàn repo, xuyên suốt cả phiên).
- `flutter test` (toàn bộ): **139/139 pass**.
- **UI Task 2-9 chưa xác nhận bằng mắt/tap thật**: simulator input tap không hoạt động trong phiên này (lỗi toàn cục môi trường, xác nhận qua tap thử cả icon Home Screen thuần iOS — không liên quan code). Task 7 (Timed/Survival Mode, đụng state machine `QuizScreen` dùng chung mọi lối vào quiz) và Task 9 (Result Page, không có widget-test infra trong repo để bù) là 2 phần rủi ro cao nhất chưa verify bằng mắt.

## Vấn đề còn lại

- UI Task 2-9 cần xác nhận bằng mắt/tap thật ở máy/simulator khác không lỗi input.
- Chưa hỏi người dùng có muốn `git push` lên remote không.

## Bước tiếp theo

1. Xác nhận UI bằng mắt/tap thật khi có môi trường phù hợp — ưu tiên Task 7 (Timed/Survival) và Task 9 (Result Page).
2. Hỏi người dùng có muốn push lên remote không.
3. Nếu sau này có `audio_url` thật cho vocab, mở lại Task 10 (Listening) — xem `docs/MIXED_QUIZ_DESIGN.md` §8.4.
