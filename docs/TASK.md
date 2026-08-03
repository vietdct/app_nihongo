# Current Task — Review Module

## Trạng thái

- Giai đoạn hiện tại: đặc tả sản phẩm và thiết kế UX/UI cho Review Module.
- Đã xác nhận tạo tài liệu `docs/REVIEW_DESIGN.md` và thiết kế đầy đủ 12 khu vực trước khi sửa source code.
- Chưa được phép sửa source code, test, dependency, cấu hình hoặc database.
- Đối tượng: người học JLPT N5–N1.
- `docs/REVIEW_DESIGN.md` đã được soạn lại đầy đủ 2026-08-03 (căn cứ theo prompt thiết kế gốc + code hiện có: `srs_scheduler.dart`, `app_theme.dart`, route review đã tồn tại). Còn 9 câu hỏi chưa trả lời ở mục "Câu hỏi cần xác nhận" của `REVIEW_DESIGN.md` §17 (6 câu cũ + 3 câu phát sinh).
- 2026-08-03 (cùng ngày): người dùng yêu cầu tiếp tục ("hãy tiếp tục ... nếu không tự tin thì hỏi"). Đã mở rộng phạm vi sang 1 increment code rủi ro thấp, không cần chờ 9 câu hỏi trên: `lib/features/review/review_screen.dart` — thêm 2 stat tile "Đến hạn hôm nay" và "Chuỗi ngày", dùng dữ liệu SRS/streak **đã có thật** trong `user_vocab_progress`/`user_kanji_progress`/`user_grammar_progress`/`profiles` (không thêm bảng, không thêm dependency). Xem `docs/PROGRESS.md` để biết chi tiết và việc còn dang dở (chưa xác nhận UI bằng mắt do simulator không nhận input trong phiên này).
- **Lưu ý mâu thuẫn phạm vi:** working tree hiện có thay đổi code chưa commit ở `vocabulary`, `kanji`, `grammar`, `kaiwa` (xem `docs/PROGRESS.md`) — đây là thay đổi có trước, không thuộc phạm vi được duyệt của task này. Không mở rộng phạm vi task hiện tại sang các thay đổi đó; nếu cần tiếp tục sửa các module này, hãy mở task riêng.

## Kết quả cần đạt

- Thiết kế một Review Module nguyên bản, sẵn sàng chuyển sang triển khai Flutter.
- Bao phủ 12 khu vực: Dashboard, Today's Review, Vocabulary, Grammar, Kanji, Listening, Speaking, AI Review Coach, Weak Points, Mistake Notebook, Smart Review và Statistics.
- Mô tả Information Architecture, user flow, wireframe, UI layout, component library, design tokens, Flutter widget tree, Riverpod state flow, animation, responsive layout, dark mode, accessibility và UX rationale.
- Định nghĩa trải nghiệm AI Memory Review kết hợp lỗi từ vựng, ngữ pháp, Kanji, nghe, nói và Kaiwa vào một tình huống ôn tập tích hợp.
- Mô tả nguyên tắc SRS/adaptive review dựa trên accuracy, response time, confidence, difficulty, recent mistakes và các tín hiệu học tập đã nêu; công thức hoặc thuật toán cụ thể: `[NEEDS_CONFIRMATION]`.

## Phạm vi được sửa

- Hiện tại: `docs/TASK.md` và `docs/REVIEW_DESIGN.md`.
- Tài liệu thiết kế Review Module: `docs/REVIEW_DESIGN.md`.
- Giai đoạn triển khai sau khi được duyệt: các file trực tiếp thuộc Review Module và test liên quan `[NEEDS_CONFIRMATION]`.

## Phạm vi không được sửa

- Mọi source code trong giai đoạn hiện tại.
- Dependency, lockfile, cấu hình build/CI, schema/migration Supabase và dữ liệu seed.
- Auth, lesson, vocabulary, grammar, kanji, kaiwa, quiz, premium hoặc module khác ngoài điểm tích hợp được phê duyệt.
- API/AI provider, quota, monetization và gamification backend khi chưa có requirement xác nhận.
- Không sao chép giao diện hoặc luồng độc quyền của ứng dụng khác.

## Acceptance criteria

- [x] Có kiến trúc thông tin và user flow rõ ràng cho 12 khu vực Review. (`REVIEW_DESIGN.md` §2, §15)
- [x] Có wireframe/layout đủ trạng thái chính: loading, empty, active, success, error và offline `[NEEDS_CONFIRMATION: offline scope]`. (§15.1, §15.2, §13; offline scope vẫn để ngỏ — câu hỏi #8)
- [x] Có component và token tương thích Material 3, light/dark mode và phong cách Nihongo. (§5, §6; giá trị màu dark cụ thể vẫn `[NEEDS_CONFIRMATION]`)
- [x] Có widget tree và Riverpod state flow ở mức đủ để triển khai feature-first. (§7)
- [x] Có quy tắc tạo Today's Review, Smart Review và AI Memory Review, không biến giả định thuật toán thành requirement. (§4, §13, §14 — số liệu cụ thể đánh dấu `[NEEDS_CONFIRMATION]` thay vì bịa)
- [x] Có mô hình dữ liệu khái niệm cho review item, attempt, mistake, schedule, weakness và statistics; chưa thay đổi database. (§3)
- [x] Có quy tắc responsive cho mobile, tablet và landscape. (§9)
- [x] Có yêu cầu accessibility cho Dynamic Type, VoiceOver, contrast và thao tác không phụ thuộc animation. (§10)
- [x] Có animation specification nhưng tôn trọng reduced motion. (§8)
- [x] Phân biệt rõ MVP, tính năng mở rộng và mục cần xác nhận. (§16)
- [x] Không sửa source code trong bước đặc tả này. (chỉ sửa `docs/TASK.md`, `docs/REVIEW_DESIGN.md`)

## File hoặc module có khả năng liên quan

- `lib/features/review/`: màn hình và provider Review hiện có.
- `lib/domain/services/srs_scheduler.dart`: logic lập lịch SRS hiện có.
- `lib/features/vocabulary/`, `lib/features/grammar/`, `lib/features/kanji/`, `lib/features/kaiwa/`: nguồn tín hiệu và điểm vào ôn tập `[NEEDS_CONFIRMATION]`.
- `lib/core/router/`: route của Review Module `[NEEDS_CONFIRMATION]`.
- `lib/core/theme/` và `lib/shared/`: token và component dùng chung `[NEEDS_CONFIRMATION]`.
- `test/domain/srs_scheduler_test.dart` và test Review mới `[NEEDS_CONFIRMATION]`.
- Supabase schema/functions cho mistake history, statistics và AI coach: `[NEEDS_CONFIRMATION]`; không khảo sát hoặc thay đổi trong giai đoạn hiện tại.

## Cách kiểm tra hoàn thành

- Review tài liệu theo checklist Acceptance criteria.
- Đối chiếu đủ 12 khu vực, các question type, SRS signals, statistics, gamification, responsive và accessibility trong yêu cầu.
- Kiểm tra mọi quyết định chưa có căn cứ đều được đánh dấu `[NEEDS_CONFIRMATION]`.
- Xác nhận thiết kế có thể ánh xạ sang Material 3, Riverpod, GoRouter và feature-first architecture.
- Không chạy test, analyze hoặc build vì giai đoạn hiện tại chỉ cập nhật tài liệu task.

## Câu hỏi cần xác nhận

1. Review Module phải dùng dữ liệu/schema hiện có hay được phép đề xuất schema và API mới khi bước sang implementation?
2. Thuật toán SRS cần giữ logic hiện tại, mở rộng logic hiện tại hay thiết kế thuật toán mới?
3. AI Memory Review là phần bắt buộc của MVP hay giai đoạn sau?
4. Gamification nào đã có backend thực tế: XP, coins, streak, league, achievement, treasure box và challenge?
5. Nền tảng ưu tiên để bắt đầu implementation là iPhone, Android hay cả hai?
6. Có mascot hoặc brand asset chính thức bắt buộc phải tái sử dụng không?
