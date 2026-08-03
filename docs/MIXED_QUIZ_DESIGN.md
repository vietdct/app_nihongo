# Mixed Quiz — Design

> Thay thế placeholder "Quiz tổng hợp — Sắp ra mắt" ở `review_screen.dart:171`.
> Căn cứ theo prompt thiết kế gốc của người dùng (2026-08-03), thu hẹp lại theo
> dữ liệu thật app đang có — không bịa số liệu/tính năng chưa có hạ tầng.

## 0. Cân cứ từ codebase hiện có

Nguồn dữ liệu thật có thể dùng ngay (không cần migration mới):

| Nguồn | Field thật dùng được | File |
|---|---|---|
| Từ vựng | `meanings` (nghĩa+ví dụ), `audioUrl` (có thể null), `reading`, `word` | `vocabulary.dart` |
| Kanji | `onyomi`, `kunyomi`, `hanViet`, `meaningVi`, `exampleJp/Vi` | `kanji.dart` |
| Ngữ pháp | `practiceTokens` + `practiceBlankIndex` (điền từ **có sẵn**), `exampleJp/Vi`, `commonMistake` | `grammar_point.dart` |
| Sổ tay lỗi | `sourceType` (vocab/kanji/grammar), `originalAnswer`, `correctAnswer`, `explanation` | `review_mistake.dart` |
| AI Kaiwa History | `KaiwaMessage.isReviewable` (feedback thật có `betterPhrasing` khác câu gốc) | `kaiwa_message.dart` |
| Weak-point logic | `isSmartPick()` (easeFactor thấp hoặc đến hạn) — logic **đã có**, tái dùng nguyên | `review_smart_screen.dart:32` |

Không có sẵn (không tự bịa để lấp): ảnh minh hoạ cho vocab/kanji, audio TTS cho từ chưa có `audioUrl`, pipeline nhận diện giọng nói/chấm phát âm, bảng leaderboard đa người dùng, backend XP/Coin thật (Task 8 Review Module đã xác nhận: chỉ placeholder UI).

## 1. Nguyên tắc thiết kế

- Không hiển thị số liệu giả (XP/Coin/điểm phát âm) khi chưa có hệ thống tính thật đứng sau.
- Không gọi AI thật cho cá nhân hoá đề — dùng lại `isSmartPick()` (local, tức thời, không tốn quota AI).
- Thứ tự câu hỏi luôn xáo trộn mỗi lần chạy (`List.shuffle()`), không cache thứ tự cũ.
- Chia nhỏ theo từng loại câu hỏi/mode thành các task độc lập, mỗi task tự test được (`flutter analyze` + `flutter test` + xác nhận UI) trước khi sang task sau — theo đúng yêu cầu tránh dồn 1 lượt khó debug.
- Tái dùng route/màn hình chấm điểm đã có khi hợp lý (VD: điền từ ngữ pháp dùng lại đúng cơ chế `practiceTokens` mà `GrammarReviewScreen` đã dùng), không viết lại engine chấm từ đầu.

## 2. Kiến trúc tổng quan

- Route mới: `/review/mixed-quiz` (session config) → `/review/mixed-quiz/play` (đang làm bài) → `/review/mixed-quiz/result` (kết quả).
- 1 provider `MixedQuizSessionNotifier` (Riverpod) giữ: danh sách câu hỏi đã sinh, index hiện tại, đáp án đã chọn, thời gian bắt đầu, danh sách lỗi.
- 1 "Question Engine" thuần Dart (`lib/domain/services/mixed_quiz_generator.dart`) nhận vào: danh sách nguồn đã bật, số lượng câu, mode → trả về `List<MixedQuizQuestion>` (model chung có `type`, `prompt`, `choices`, `correctAnswer`, `sourceType`, `sourceId`). Test được độc lập bằng unit test, không phụ thuộc widget.
- UI mỗi loại câu hỏi là 1 widget con nhỏ (`_MultipleChoiceCard`, `_FillBlankCard`, ...) nhận `MixedQuizQuestion` — dễ thêm loại mới không đụng loại cũ.

## 3. Loại câu hỏi — khả thi hoá theo dữ liệu thật

| # | Loại | Nguồn dùng | Cơ sở dữ liệu thật | Trạng thái |
|---|---|---|---|---|
| 1 | Multiple Choice | Vocab/Kanji/Grammar | nghĩa đúng + 3 nhiễu random cùng level | Phase 1 |
| 2 | Kanji Reading | Kanji | onyomi/kunyomi thật | Phase 1 |
| 3 | Kanji Meaning | Kanji | meaningVi thật | Phase 1 |
| 4 | Fill Blank | Grammar | `practiceTokens`+`practiceBlankIndex` có sẵn | Phase 1 |
| 5 | Typing | Vocab/Kanji | so khớp `reading`/`word` | Phase 2 |
| 6 | Translation | Vocab/Grammar | `meaningVi`/`exampleVi` thật | Phase 2 |
| 7 | Sentence Ordering | Grammar | xáo `practiceTokens` (không cần blankIndex) | Phase 2 |
| 8 | Grammar Selection | Grammar | chọn đúng mẫu ngữ pháp cho câu ví dụ | Phase 2 |
| 9 | Particle Selection | Grammar | trợ từ tách từ `practiceTokens` khi có | Phase 2 |
| 10 | Error Correction | Sổ tay lỗi + AI Kaiwa | `originalAnswer→correctAnswer`, `contentJp→betterPhrasing` | Phase 3 |
| 11 | Conversation Completion | AI Kaiwa History | câu AI thật kế tiếp trong hội thoại đã lưu vs. nhiễu | Phase 3 |
| 12 | Mixed JLPT Questions | Tất cả trên | chính là bản thân module này | Xuyên suốt |
| 13 | Listening | Vocab | **chỉ** vocab có `audioUrl != null` thật, không TTS giả | **Hoãn** — 0% vocab có `audioUrl` thật, xem mục 8.4 |
| 14 | Picture Description | — | chưa có field ảnh | **Ngoài phạm vi** (2026-08-03: người dùng xác nhận bỏ) |
| 15 | Speaking | — | cần STT, phát sinh chi phí cloud | **Ngoài phạm vi** |
| 16 | Shadowing | — | cần STT + audio chuẩn | **Ngoài phạm vi** |
| 17 | Role Play | — | trùng chức năng AI Kaiwa | **Ngoài phạm vi** |

## 4. Quiz modes

- **Quick Quiz** (5/10/20/50 câu), **Custom** (chọn nguồn + số lượng), **Random Mode**: khả thi ngay, thuần local — Phase 1.
- **Timed Quiz**: đếm ngược mỗi câu hoặc toàn bài — Phase 4.
- **Survival Mode**: dừng ngay khi sai 1 câu — Phase 4.
- **AI Challenge**: đổi tên hiển thị thành "Thử thách điểm yếu" (tránh hiểu nhầm gọi AI thật) — dùng `isSmartPick()` để chọn câu hỏi toàn từ mục yếu/đến hạn — Phase 5, tái dùng logic Smart Review.

## 5. Result page

Chỉ số thật hiển thị: Score, Accuracy (%), Time, danh sách Mistakes (câu sai + đáp án đúng), Weak Areas (nhóm theo `sourceType`), gợi ý ôn tiếp (link `/review/mistakes` hoặc `/review/smart`).

**Không hiển thị**: XP/Coins (chưa có backend thật — theo đúng quyết định Task 8 Review Module), "AI Feedback" dạng văn bản AI sinh (đổi thành nhận xét rule-based từ số liệu thật, VD: "Bạn sai nhiều nhất ở Ngữ pháp — 4/6 câu").

## 6. Gamification hooks

- Combo/Perfect Bonus: hiển thị được vì tính trực tiếp từ chuỗi đúng liên tiếp trong phiên (dữ liệu thật, không cần backend).
- Achievements, Leaderboard, Daily Challenge, XP/Coin thật: **ngoài phạm vi MVP** (2026-08-03: người dùng xác nhận bỏ hẳn — không sửa schema, không thêm dependency STT, không tự chốt công thức thưởng lúc này).

## 7. Task breakdown (thực hiện tuần tự, mỗi task tự test riêng)

1. **Quiz Engine + Multiple Choice**: model `MixedQuizQuestion`, generator, route `/review/mixed-quiz`, Multiple Choice cho Vocab/Kanji/Grammar, mode Quick (5/10/20/50) + Random.
2. **Kanji Reading/Meaning + Fill Blank**: dùng lại `practiceTokens`/`practiceBlankIndex` ngữ pháp có sẵn.
3. **Typing + Translation**.
4. **Sentence Ordering + Grammar/Particle Selection**.
5. **Error Correction** (Sổ tay lỗi + AI Kaiwa reviewable messages).
6. **Conversation Completion** (AI Kaiwa History).
7. **Custom Quiz + Timed Quiz + Survival Mode**.
8. **"Thử thách điểm yếu"** (weak-point local logic, tái dùng `isSmartPick`).
9. **Result Page** (Score/Accuracy/Time/Mistakes/Weak Areas + combo, không XP/Coin giả).
10. **Listening** — khảo sát tỉ lệ vocab có `audioUrl` thật trước khi quyết định làm hay hoãn. **Đã khảo sát (2026-08-04): hoãn** — xem mục 8.4.
~~11. Picture Description, Speaking/Shadowing/Role Play, Leaderboard, Achievements mở rộng, XP/Coin thật~~ — **bỏ hẳn khỏi phạm vi Mixed Quiz** (xem mục 8).

## 8. Quyết định đã xác nhận (2026-08-03)

1. Route/entry point: **có** — thay thẳng placeholder "Quiz tổng hợp" ở `review_screen.dart:171` bằng `/review/mixed-quiz`.
2. Task 11 (Picture/Speaking/Shadowing/Role Play/Leaderboard/XP thật): **bỏ hẳn khỏi phạm vi**, không để treo chờ — lý do: kéo theo sửa schema, thêm dependency STT, phát sinh chi phí vận hành cloud, và một số phần buộc phải tự bịa dữ liệu/công thức (ảnh không khớp nghĩa, chấm phát âm thô, công thức XP tự đặt). Nếu sau này cần, mở task riêng khảo sát lại từ đầu.
3. Distractor cho Multiple Choice: **cùng level đang học** (không trộn lẫn level khác).

### 8.4. Task 10 — Listening: hoãn (khảo sát 2026-08-04)

Khảo sát `audio_url` trên bảng `vocabulary`: cột tồn tại trong schema
(`supabase/migrations/20260723140000_content_schema.sql:33`) nhưng **không
có câu `insert`/`update` nào trong toàn bộ `supabase/` (seed lẫn migration)
từng gán giá trị thật cho cột này** — grep `audio_url` trong mọi câu lệnh
ghi dữ liệu ra 0 kết quả, trong khi seed N5 riêng đã có ~308 dòng từ vựng.
Tỉ lệ vocab có `audioUrl` thật: **0%**.

Theo đúng ràng buộc đã đặt ra ở mục 3 (bảng loại câu hỏi, dòng 13): "chỉ
vocab có `audioUrl != null` thật, không TTS giả". Với 0% dữ liệu thật, Task
10 **không có gì để làm mà không phải bịa** (viết Listening bằng TTS giả sẽ
vi phạm chính ràng buộc đã đặt ra, và dựng UI cho 1 nguồn dữ liệu rỗng là vô
nghĩa). Quyết định: **hoãn Listening**, không tự chuyển sang TTS giả để có
việc làm. Nếu sau này có `audio_url` thật (thu âm hoặc mua nguồn audio), mở
lại task này — không cần thiết kế lại từ đầu, cơ chế lọc `audioUrl != null`
đã ghi sẵn ở mục 3.
