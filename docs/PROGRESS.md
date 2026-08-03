# Current Progress

> Đây là trạng thái hiện tại, không phải nhật ký. Mỗi lần bàn giao hãy viết đè và giữ dưới khoảng 100 dòng.

## Mục tiêu

Triển khai Review Module theo thứ tự đã thống nhất (xem `docs/TASK.md`).

## Trạng thái

- **Đã xong đủ 8/8 task**: Dashboard, Today's Review, Weak Points, Mistake Notebook, Smart Review, AI Review Coach, Review Statistics (biểu đồ), Gamification mở rộng (placeholder UI).
- Task 8 làm theo hướng **chỉ UI giữ chỗ** (người dùng chọn) — Coins/Rương phần thưởng/League hiện "Sắp ra mắt" ở tab Hồ sơ, không có backend/công thức thưởng thật (đúng như `docs/REVIEW_DESIGN.md` §11/§16 đã tự ghi: chưa xác nhận công thức). Achievement thật (5 mốc, tính từ dữ liệu thật) đã có sẵn từ trước ở `ProfileScreen`, không cần làm lại.
- Theo yêu cầu người dùng: **chưa commit gì** trong toàn bộ phiên này (2 commit phiên trước + việc mới task 7/8) — sẽ commit 1 lần khi đủ cả 8 task (đã đủ, chờ xác nhận commit).

## Đã hoàn thành (task 7 — Review Statistics)

- Thêm dependency `fl_chart: ^0.69.0` vào `pubspec.yaml` (đã được người dùng đồng ý trước đó), `flutter pub get` thành công.
- `ReviewStatisticsScreen` (`/review/statistics`) — tầng tổng hợp phía trên theo `docs/REVIEW_DESIGN.md` §15.12, **không** làm Retention Rate/Study Time/JLPT theo cấp vì không có dữ liệu nguồn thật cho các mục này (không có session log, không có provider load nội dung xuyên cấp độ) — tránh bịa số liệu.
  - 4 tile số liệu thật: Đã thuộc, Tổng lượt ôn, Chuỗi ngày, Lỗi đã ghi nhận.
  - Biểu đồ cột "Độ thành thục theo module" (stacked bar, 4 mức Mới/Đang học/Quen/Vững, cùng ngưỡng `intervalDays` với `KanjiStatisticsScreen`).
  - Biểu đồ cột "Lỗi theo module" (từ `review_mistakes` group theo `source_type`).
  - Biểu đồ cột "Lỗi ghi nhận theo ngày" (14 ngày gần nhất, bucket theo `updatedAt`).
  - Trạng thái rỗng riêng cho từng phần khi chưa có dữ liệu.
- Route `/review/statistics` đăng ký trong `app_router.dart`; entry point "Thống kê ôn tập" thêm vào `ReviewScreen`.
- `flutter analyze`: No issues found (đã sửa hết lint `require_trailing_commas`/`curly_braces_in_flow_control_structures`). `flutter test`: 101/101 pass.

## File đã thay đổi (task 7 + 8, chưa commit)

- `pubspec.yaml` (+ `fl_chart`)
- `lib/features/review/review_statistics_screen.dart` (mới)
- `lib/core/router/app_router.dart` (route `/review/statistics`)
- `lib/features/review/review_screen.dart` (entry point Thống kê ôn tập)
- `lib/features/profile/profile_screen.dart` (section "Sắp ra mắt": Coins/Rương phần thưởng/League — task 8)

## Kiểm tra

- `flutter analyze`/`flutter test`: sạch toàn bộ.
- Build debug simulator: thành công (**lưu ý phải thêm `--dart-define-from-file=env.json`**, thiếu cờ này làm app crash ngay khi khởi động vì thiếu `SUPABASE_URL`/`SUPABASE_ANON_KEY` — đã xác nhận qua `xcrun simctl spawn booted log show`).
- **Môi trường simulator: input tap KHÔNG hoạt động hoàn toàn** trong phiên này — không chỉ riêng màn mới, đã thử tap cả tab "Review" và tab "Lesson" ở Home (màn đã render đúng, xác nhận qua screenshot), không tab nào phản hồi. Đây là vấn đề tái hiện lần thứ 2 liên tiếp (đã ghi nhận ở phiên trước), giờ xác nhận là **lỗi toàn cục của input injection trên simulator này**, không phải lỗi code hay riêng của `ReviewStatisticsScreen`. Đã dừng thử lại theo đúng quy tắc "thất bại 2 lần thì dừng và đánh giá lại".
- Vì vậy: `ReviewStatisticsScreen` **chưa được xác nhận bằng mắt/tap** trong phiên này. Cơ sở tin cậy: code tái dùng đúng pattern/màu/bố cục đã chạy ổn ở `KanjiStatisticsScreen`, `flutter analyze`/`test` sạch.

## Vấn đề còn lại

- Simulator input tap không hoạt động (toàn cục, không riêng feature nào) — cần khắc phục ở máy/phiên sau (thử `flutter run` giữ hot-reload, hoặc test tay trên máy thật/simulator khác).
- Chưa commit + chưa push toàn bộ việc từ 2 phiên (Weak Points/Mistake Notebook/Smart Review, AI Review Coach, Review Statistics, Gamification placeholder) — theo đúng yêu cầu người dùng "làm xong đủ 8 task rồi mới commit".
- `ReviewCoachScreen` và `ReviewStatisticsScreen` chưa xác nhận UI bằng mắt/tap thật (vướng lỗi input simulator).

## Bước tiếp theo

1. Commit toàn bộ việc còn lại (đã đủ 8/8 task) — chờ xác nhận từ người dùng.
2. Hỏi có muốn push lên remote không.
3. Khắc phục vấn đề input simulator rồi xác nhận UI `ReviewCoachScreen` + `ReviewStatisticsScreen` bằng mắt/tap thật.
