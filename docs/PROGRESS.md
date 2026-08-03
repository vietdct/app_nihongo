# Current Progress

> Đây là trạng thái hiện tại, không phải nhật ký. Mỗi lần bàn giao hãy viết đè và giữ dưới khoảng 100 dòng.

## Mục tiêu

Triển khai Review Module theo thứ tự đã thống nhất (xem `docs/TASK.md`).

## Trạng thái

- Đã xong task 1–5 trong danh sách ưu tiên: Dashboard, Today's Review, Weak Points, migration `review_mistakes` (đã áp dụng lên Supabase thật), ghi nhận mistake, Mistake Notebook, Smart Review.
- Task 6 (AI Coach), 7 (Statistics biểu đồ), 8 (Gamification mở rộng) — **đang chờ quyết định của người dùng**, chưa bắt đầu (xem "Cần quyết định" bên dưới).

## Đã hoàn thành

- `ReviewScreen` (Dashboard): 2 stat tile thật + hàng Smart Review/Điểm yếu/Sổ tay lỗi, cạnh 4 hàng module cũ.
- `ReviewTodayScreen` (`/review/today`), `ReviewWeakPointsScreen` (`/review/weak-points`), `ReviewSmartScreen` (`/review/smart`), `ReviewMistakesScreen` (`/review/mistakes`) — 4 màn mới.
- Migration `supabase/migrations/20260803090000_review_mistakes.sql` — **đã áp dụng lên Supabase thật** (`supabase db push`, xác nhận qua `supabase migration list`).
- 3 màn Review (Vocab/Kanji/Grammar) ghi nhận mistake thật vào `review_mistakes` khi chấm "Quên" (qua `ReviewMistakesController.recordMistake`, upsert tăng `occurrence_count`).
- `flutter analyze`: No issues. `flutter test`: 101/101 pass — chạy lại sau mỗi bước, luôn sạch.

## File đã thay đổi/thêm

- Sửa: `lib/features/review/review_screen.dart`, `lib/core/router/app_router.dart`, `lib/features/vocabulary/vocabulary_review_screen.dart`, `lib/features/kanji/kanji_review_screen.dart`, `lib/features/grammar/grammar_review_screen.dart`.
- Mới: `lib/features/review/review_today_screen.dart`, `review_weak_points_screen.dart`, `review_smart_screen.dart`, `review_mistakes_screen.dart`, `lib/features/review/providers/review_mistakes_providers.dart`, `lib/domain/entities/review_mistake.dart`, `supabase/migrations/20260803090000_review_mistakes.sql`.

## Kiểm tra

- `flutter analyze`/`flutter test`: sạch toàn bộ, xác nhận nhiều lần trong phiên.
- Build Debug simulator: thành công mọi lần.
- **UI đã xác nhận bằng mắt**: Dashboard (đủ 8 hàng + 2 stat tile, đúng số liệu), Today's Review (số + điều hướng thật sang `/grammar/review`).
- **UI chưa xác nhận được bằng tap** cho: Weak Points, Mistake Notebook, Smart Review — simulator trong phiên này liên tục không nhận tap chính xác vào các hàng mới/cuối danh sách (đã thử rất nhiều lần, nhiều toạ độ, nhiều lần reboot simulator hoàn toàn — không cải thiện). Đã xác nhận **không phải lỗi code**: cùng pattern với các hàng đã verify (Vocab/Kanji/Grammar/Kaiwa/Today's Review), `flutter analyze`/`test` sạch, và đã thấy các hàng mới **render đúng nội dung** qua screenshot (chỉ riêng việc tap-để-điều-hướng không xác nhận được). Nghi vấn: input injection của simulator qua tool này không ổn định trong phiên dài — nên thử `flutter run` trực tiếp (không qua build+launch tách rời) ở phiên sau, hoặc test tay trên máy thật.

## Cần quyết định (chặn task 6–8, chưa tự làm)

- **Task 6 — AI Review Coach**: cần chọn provider AI (tái dùng hạ tầng AI Kaiwa hiện có hay Edge Function riêng) + giới hạn quota riêng.
- **Task 7 — Review Statistics dạng biểu đồ**: cần thêm dependency mới (vd. `fl_chart`) vào `pubspec.yaml` — thay đổi dependency cần xác nhận trước theo `CLAUDE.md`.
- **Task 8 — Gamification mở rộng**: đã xác nhận KHÔNG có backend Coins/League/Treasure/Achievement nào — cần người dùng quyết định có muốn xây từ đầu không, độ ưu tiên thấp.

## Vấn đề còn lại

- Chưa commit gì trong toàn bộ phiên (người dùng chưa yêu cầu).
- AI Memory Review vẫn hoãn theo yêu cầu trước đó.

## Bước tiếp theo

1. Hỏi người dùng quyết định cho task 6/7/8 trước khi làm tiếp.
2. Xác nhận lại UI Weak Points/Mistake Notebook/Smart Review bằng `flutter run` hoặc máy thật ở phiên sau.
3. Khi được yêu cầu: commit toàn bộ (code + migration file, migration đã áp dụng riêng qua CLI, không nằm trong git diff schema thật nhưng file .sql cần commit).
