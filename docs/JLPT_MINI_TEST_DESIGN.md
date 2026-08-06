# JLPT Mini Test — Design

> Đào sâu mục "Mini Test" đã nêu ở `docs/JLPT_MOCK_EXAM_DESIGN.md` §3 (1 dòng) thành đặc tả riêng, theo prompt "Principal Product Designer / JLPT Examination Specialist / Flutter Architect" người dùng cung cấp 2026-08-06, gồm đề xuất **4 biến thể Mini Test** (Quick 5 / Daily / Weak Point / AI) thay cho 1 nút Mini Test đơn. Giai đoạn này **chỉ đặc tả, không sửa source code** — đúng cách làm đã dùng ở `REVIEW_DESIGN.md` và `JLPT_MOCK_EXAM_DESIGN.md`. Mục đánh dấu `[NEEDS_CONFIRMATION]` là chưa có căn cứ từ code/backend hiện có.
>
> **Cập nhật 2026-08-06 — 4 quyết định đã chốt** (người dùng trả lời qua form câu hỏi, xem §22): (1) **Không có Coin** — chỉ dùng XP, tái dùng nguyên `profiles.xp`; (2) **Streak dùng chung streak toàn app** (`profiles.streak_count`/`last_study_date`), không tạo bảng streak riêng; (3) **Ngưỡng Weak Point Mini = 5 mục** thoả `isSmartPick()`, dưới ngưỡng fallback random kèm thông báo; (4) **AI Mini Test dùng quota riêng**, không dùng chung quota AI Kaiwa/Coach. Toàn bộ nội dung bên dưới đã cập nhật theo 4 quyết định này — không còn là bản nháp ban đầu.

## 0. Căn cứ từ codebase hiện có

- **Điểm vào hiện tại**: `JlptExamModeScreen` (`lib/features/review/jlpt_exam/jlpt_exam_mode_screen.dart:64`) đã có `_ModeCard` "Mini Test" nhưng `onTap` chỉ gọi `notifyInDevelopment('Mini Test')` — chưa có route/screen thật, đây là **điểm nối duy nhất** tài liệu này thay thế.
- **Exam engine đã có, tái dùng được gần như toàn bộ**: `ExamRunnerScreen`/`_ExamBody`/`_ExamHeader`/`_ExamBottomBar`/`_QuestionPaletteSheet` (`lib/features/review/jlpt_exam/exam_runner_screen.dart`) đã xử lý section timer, Question Palette, bookmark/flag, TTS cho Listening, Reading passage card — cơ chế **giống hệt** những gì Mini Test cần, khác chỉ là quy mô (ít câu hơn) và nguồn chọn câu (§2). **Không viết lại engine**, chỉ đổi cách tạo `ExamSession`/`ExamBlueprint` đưa vào.
- **`ExamBlueprint`** (`lib/features/review/jlpt_exam/models/exam_blueprint.dart`) hiện chỉ seed `mode = 'full_exam'` cho N5 (`supabase/migrations/20260804091000_jlpt_exam_blueprint_seed_n5.sql`: vocabulary 20 câu/grammar 15 câu/listening 10 câu). **Chưa có blueprint nào cho Mini Test** — cần seed mới hoặc sinh động (khác Full Exam, xem §5).
- **`jlpt_scoring.dart`** (`JlptScoringRule`, thang điểm 3 nhóm N1-N3 / 2 nhóm N4-N5, tối đa 180/180) được thiết kế cho **Full Exam đầy đủ 4 section** — Mini Test chỉ vài câu, **không đủ căn cứ** để chấm theo thang JLPT thật hay đưa ra Pass/Fail Prediction (quyết định §1). Mini Test dùng lối chấm khác, giống Review Module (accuracy % + XP), không tái dùng `JlptScoringRule`.
- **Reading**: `ReadingPassage`/`ReadingPassageQuestion` (`lib/domain/entities/reading_passage.dart`) + `ReadingQuestionGenerator` (`lib/domain/services/reading_question_generator.dart`) đã có 1 đoạn N5 mẫu, seed ở `supabase/migrations/20260804092000_jlpt_exam_reading_seed_n5.sql` — Mini Test **tái dùng đúng nguồn này** khi bật Reading, không soạn nội dung mới.
- **Weak Point**: `isSmartPick()` đã tổng quát hoá, dùng ở nhiều nơi (`lib/features/vocabulary/providers/vocab_review_providers.dart`, `review_mixed_quiz_screen.dart`, `review_smart_screen.dart`, `mixed_quiz_providers.dart`) — **tái dùng trực tiếp** cho biến thể Weak Point Mini, không viết lại rule chọn điểm yếu.
- **Vocab/Grammar generator**: `quiz_generator.dart` (884 dòng) — tái dùng như Full Exam đã làm (§6 `JLPT_MOCK_EXAM_DESIGN.md`).
- **AI infra**: pattern quota/context giới hạn đã có ở AI Kaiwa + `review_coach_service.dart` — AI Mini Test tái dùng pattern này (§11 `JLPT_MOCK_EXAM_DESIGN.md`), không thiết kế provider AI mới.
- Không có bảng `mini_test_*` nào trong Supabase hiện tại → mọi entity ở §5 dưới đây là khái niệm, cần schema khi triển khai.

## 1. Nguyên tắc thiết kế

- Mini Test **không phải** bản thu nhỏ máy móc của Full Exam mà là **công cụ luyện hằng ngày trong vài phút rảnh** — đúng tinh thần đề xuất gốc của người dùng. Vì vậy thay 1 nút "Mini Test" bằng **4 biến thể có mục tiêu riêng** (§2), mỗi biến thể trả lời câu hỏi khác nhau: "khởi động nhanh" / "luyện đều mỗi ngày" / "sửa đúng chỗ yếu" / "AI tự soạn theo lỗi".
- **Không đưa ra Pass/Fail Prediction hay Estimated JLPT Level** cho Mini Test (khác Full Exam) — 5-20 câu không đủ đại diện 1 đề JLPT thật, hiển thị kiểu đó dễ gây hiểu lầm nghiêm trọng ("trượt N3" từ 5 câu). Result Screen Mini Test chỉ có Accuracy %, breakdown theo dimension, XP — giống triết lý Review Module hơn là Exam Module.
- **Mỗi đề luôn khác nhau** (yêu cầu gốc "Every Mini Test should be unique") — không cache 1 bộ câu cố định theo blueprint tĩnh như Full Exam; nguồn câu random có trọng số + loại trừ câu vừa gặp gần đây trong ngân hàng hiện có, theo đúng cơ chế `quiz_generator.dart` đã dùng ở Mixed Quiz.
- Tái dùng tối đa hạ tầng đã có (engine, generator, weak-point rule, reading/listening content, AI pattern) — chỉ xây mới: Home Screen riêng, luồng chọn biến thể, cách build `ExamBlueprint` rút gọn/động, Result Screen rút gọn.
- Mọi animation tôn trọng `MediaQuery.disableAnimations`, giống quy tắc đã áp dụng toàn bộ Review/Mock Exam Module.

## 2. 4 biến thể Mini Test (đề xuất người dùng — đã chốt là hướng thiết kế chính)

| Biến thể | Thời gian | Mục tiêu | Nguồn câu | Settings |
|---|---|---|---|---|
| ⚡ **Quick 5** | 2–3 phút, cố định 5 câu | Khởi động nhanh, không cần nghĩ | Random đều Vocab/Grammar/Kanji đã học (không ưu tiên điểm yếu, không hỏi cấu hình) | **Không có** — bấm là chạy ngay, đúng tinh thần "5 câu ngẫu nhiên" |
| 📚 **Daily Mini Test** | 5–10 phút | Đề luyện hằng ngày bám lộ trình học hiện tại | Theo `ReviewSchedule`/lộ trình bài học gần nhất (item due hôm nay + item mới học tuần này) — tái dùng nguồn dữ liệu đã có ở `reviewTodayProvider`-style (Review Module) | Có, rút gọn: số câu (5/10/15), nguồn (mặc định Mixed) |
| 🎯 **Weak Point Mini** | 5–10 phút | Chỉ ra đúng câu thuộc điểm yếu | `isSmartPick()` lọc theo `WeaknessSignal`/accuracy thấp — nếu chưa đủ dữ liệu điểm yếu (user mới), fallback về random như Quick 5 kèm thông báo rõ | Có: số câu, giới hạn theo dimension (Vocab/Grammar/Kanji) nếu muốn |
| 🤖 **AI Mini Test** | 5–15 phút | AI soạn đề riêng theo lỗi + lịch sử + mục tiêu JLPT | AI sinh dựa trên N mistake/weakness gần nhất (pattern AI Kaiwa/Coach), fallback random nếu chưa đủ dữ liệu lỗi | Có: số câu, level mục tiêu (mặc định level đang chọn) |

- 4 biến thể **dùng chung 1 Exam Screen engine** (`ExamRunnerScreen`, §1) và **chung 1 Result Screen rút gọn** (§10) — khác nhau ở bước "chọn nguồn câu hỏi" trước khi tạo `ExamSession`, không phải 4 màn hình thi khác nhau.
- Quan hệ với `JLPT_MOCK_EXAM_DESIGN.md` §3 "Mini Test" (1 dòng cũ: *"Bản rút gọn ~25–30% số câu mỗi section, cùng tỉ lệ"*): dòng đó mô tả 1 phiên bản rút gọn **theo blueprint tĩnh** — tài liệu này **thay thế** cách hiểu đó bằng 4 biến thể động, phù hợp hơn với mục tiêu "luyện vài phút mỗi ngày" thay vì "đề JLPT thu nhỏ".
- Quan hệ với 🔥 AI Challenge Mode (`JLPT_MOCK_EXAM_DESIGN.md` Addendum B): AI Mini Test ở đây là **tập con giữ đúng format JLPT** (chỉ Vocab/Grammar/Kanji/Reading/Listening, chấm accuracy) — AI Challenge Mode vẫn giữ vị trí "mở rộng sau", thêm Speaking/Kaiwa mà AI Mini Test không có. Không trùng phạm vi.

## 3. Home Screen (Mini Test)

Màn **mới**, mở từ `_ModeCard` "Mini Test" ở `JlptExamModeScreen` — route `/review/jlpt-exam/:levelId/mini`.

```
┌─────────────────────────────────────────┐
│ ‹  Mini Test — N5                        │
├─────────────────────────────────────────┤
│   🎴  [minh hoạ Mini Test — tái dùng     │
│        phong cách hero card đã có]       │
│                                           │
│   Đề hôm nay: 📚 Daily Mini Test         │  ← đề xuất nổi bật, đổi mỗi ngày
│   10 câu · ~7 phút                       │
│                                           │
│   ┌─────────┐ ┌─────────┐               │
│   │ Streak  │ │ Accuracy│               │  ← ReviewStatTile tái dùng
│   │  🔥 5   │ │  82%    │               │    (đã có ở REVIEW_DESIGN.md §6)
│   └─────────┘ └─────────┘               │
│   Điểm gần nhất: 8/10 (2 giờ trước)      │
│                                           │
│   [ Bắt đầu ngay → Đề hôm nay ]          │  ← Quick Start, dẫn thẳng vào biến
│                                           │     thể đang được đề xuất ở trên
├─────────────────────────────────────────┤
│  ⚡ Quick 5        2-3 phút        ›     │
│  📚 Daily Mini Test 5-10 phút      ›     │
│  🎯 Weak Point Mini 5-10 phút      ›     │
│  🤖 AI Mini Test    5-15 phút      ›     │
├─────────────────────────────────────────┤
│  [ Tiếp tục đề dang dở ]  (chỉ hiện khi  │  ← Continue Previous Test,
│    có ExamSession status=inProgress)     │     ẩn nếu không có phiên dở
│  [ Xem lịch sử ]                          │  ← History → JLPT Statistics
│                                           │     (lát cắt Mini Test, §12)
└─────────────────────────────────────────┘
```

- "Đề hôm nay" chọn theo thứ tự ưu tiên: có `ExamSession` dở (Continue) → có Daily Mini Test chưa làm hôm nay → Quick 5 mặc định. Không tự bịa logic phức tạp hơn khi chưa cần.
- 4 hàng biến thể dùng lại đúng pattern `_ModeCard` đã có ở `jlpt_exam_mode_screen.dart` (icon + title + subtitle + chevron), không tạo component thẻ mới.

## 4. Test Settings (bottom sheet, dùng chung Daily/Weak Point/AI — Quick 5 bỏ qua bước này)

```
┌─────────────────────────────┐
│  Cấu hình Daily Mini Test    │
├───────────────────────────────┤
│ Số câu     ○5  ●10  ○15  ○20 │
│ Độ khó     ○Easy ●Normal      │
│            ○Hard ○Adaptive    │
│ Nguồn câu  ☑Vocab ☑Grammar     │
│            ☑Kanji ☐Reading    │
│            ☐Listening         │
│ Đồng hồ    ●Không giới hạn    │
│            ○Theo giờ JLPT     │
├───────────────────────────────┤
│         [ Bắt đầu ]           │
└───────────────────────────────┘
```

- **Difficulty = Adaptive** chỉ hợp lệ khi biến thể là Daily/AI (không hợp lệ cho Weak Point Mini vì bản thân nó đã là 1 kiểu lọc theo độ khó điểm yếu — 2 cơ chế không nên chồng nhau); áp dụng đúng rule đã có ở `REVIEW_DESIGN.md` §4 ("3 đúng nhanh liên tiếp → tăng khó, 2 sai liên tiếp → hạ khó").
- **Timer = "Theo giờ JLPT"** dùng lại `officialTimingMinutesBySectionType` (`jlpt_scoring.dart`) chia tỉ lệ theo số câu đã chọn — không tính riêng bảng thời gian mới cho Mini Test.
- Reading/Listening trong "Nguồn câu" chỉ bật được nếu ngân hàng đủ nội dung cho level đó (hiện N5 mới có 1 passage) — nếu chưa đủ, checkbox disable kèm tooltip "Chưa có đủ nội dung cho N5", không cho chọn rồi lỗi giữa chừng.

## 5. Mô hình dữ liệu khái niệm

Không đổi schema Supabase trong giai đoạn này.

| Entity | Trường chính | Ghi chú |
|---|---|---|
| `MiniTestVariant` (enum) | `quick5 / daily / weakPoint / ai` | Không phải bảng DB — chỉ là tham số truyền vào lúc tạo session, lưu ở `ExamSession.mode` dạng string (`'mini_quick5'`, `'mini_daily'`, `'mini_weak_point'`, `'mini_ai'`) để tương thích cột `mode` sẵn có của `jlpt_exam_blueprints`/`ExamSession`, không thêm cột mới |
| `MiniTestBlueprint` | levelId, variant, questionCount, sources[], timerMode | **Không seed tĩnh như Full Exam** — sinh động lúc runtime theo settings người dùng chọn (§4), không lưu bảng `jlpt_exam_blueprints` như Full Exam vì mỗi lần khác nhau (đúng nguyên tắc §1 "luôn khác nhau") |
| `MiniTestResult` | sessionId, variant, correctCount, totalCount, accuracyPct, xpEarned, weakDimensions[], strongDimensions[] | Tách khỏi `ExamSectionResult` (Full Exam) vì **không** có `scaledScore`/`passThreshold` kiểu JLPT thật (§1). **Không có `coinEarned`** — quyết định 2026-08-06: bỏ Coin, chỉ dùng XP (tái dùng nguyên `profiles.xp`, không thêm cột/bảng mới) |

**Streak — quyết định 2026-08-06**: bỏ hẳn `MiniTestStreak` riêng ở bản nháp đầu. Mini Test **dùng chung streak toàn app đã có** (`profiles.streak_count`/`profiles.last_study_date`, bảng `profiles` — `supabase/migrations/20260723090000_core_schema.sql:34-35`) — hoàn thành 1 Mini Test (bất kỳ biến thể nào) cập nhật `last_study_date` giống cách Vocab/Kanji/Quiz đang được tính vào `computeDailyMissionStatus` (`lib/features/home/providers/mission_providers.dart`), không tạo bảng/entity streak mới, không có 2 con số streak khác nhau gây rối người dùng.

Quan hệ: `ExamSession`/`ExamAnswer` (đã định nghĩa ở `JLPT_MOCK_EXAM_DESIGN.md` §5) **dùng lại nguyên bảng**, chỉ khác giá trị `mode`; `MiniTestResult` là 1 view/tính toán từ `ExamAnswer` khi nộp bài, không phải bảng ghi riêng bắt buộc — tính runtime thay vì lưu bảng mới (quyết định triển khai: History chỉ cần liệt kê `ExamSession` đã `submitted` với `mode` bắt đầu `'mini_'`, tính lại accuracy/XP từ `ExamAnswer` khi hiển thị, tránh 2 nguồn sự thật).

Câu sai vẫn ghi `Mistake` (Review Module) như Full Exam đã làm — Mini Test **không tạo hệ thống lỗi riêng**.

## 6. Question Types

Dùng nguyên bộ Question Type đã có ở `quiz_generator.dart` (10 nhóm) + `_ExamOptionTile`/Reading/Listening đã có ở `ExamRunnerScreen` — **không thêm loại câu hỏi mới cho Mini Test**. Việc chọn loại nào xuất hiện phụ thuộc "Nguồn câu" đã tick ở Settings (§4), không cấu hình riêng từng loại như prompt gốc liệt kê chi tiết (Meaning Selection/Reading Selection/... ) vì đây đã là hành vi có sẵn của `quiz_generator.dart`, tránh việc tạo tầng cấu hình trùng lặp không cần thiết.

## 7. Exam Screen — tái dùng, khác biệt tối thiểu

- **Cập nhật khi triển khai (Task 2, sau khi đọc kỹ `jlpt_exam_content_providers.dart`)**: bản nháp đầu tài liệu này nói "không sửa `ExamRunnerScreen`" — SAI, vì `examBlueprintProvider` tra `jlpt_exam_blueprints` bằng đúng cặp `(level_id, mode)` với `.limit(1)`, một hàng DÙNG CHUNG mọi người dùng. Nếu Mini Test ghi blueprint động vào bảng đó với `mode='mini_quick5'` cố định, 2 người làm Quick 5 cùng lúc sẽ đụng độ (người này đọc nhầm đề của người kia). Quyết định thật: `ExamRunnerScreen` được thêm 1 field optional **`overrideSections`** (`List<ExamRunSection>?`, mặc định null) — khi khác null, bỏ qua hoàn toàn 2 provider tra blueprint và dùng thẳng danh sách đã build sẵn ở `buildMiniTestRunSections` (§13). Full Exam không truyền field này nên hành vi cũ giữ nguyên 100% — vẫn là thay đổi additive, nhỏ, không phải "sửa lại" Full Exam, chỉ khác so với dự định ban đầu là KHÔNG THỂ 0 thay đổi.
- Route `/review/jlpt-exam/:levelId/session/:mode` (dùng chung cả Full Exam lẫn Mini Test) đọc `state.extra as List<ExamRunSection>?` — Full Exam push không kèm `extra` (giữ `null`), Mini Test push kèm sections đã build.
- `_sectionLabels` (2 chỗ trong `exam_runner_screen.dart`) có thêm khoá `'mixed': 'Tổng hợp'` cho section gộp nhiều nguồn của Mini Test (Quick 5/Daily) — Full Exam không dùng type này nên không ảnh hưởng.
- 2 khác biệt hành vi còn lại giữ như bản nháp đầu:
  1. `_ExamHeader` ẩn `SectionTimerChip` khi Timer = "Không giới hạn" (đã là timer mode có sẵn ở Full Exam Practice, không phải khái niệm mới).
  2. Sau khi nộp, điều hướng sang **Mini Test Result** (§10) thay vì `exam_result_screen.dart` (PassFailBadge) — route khác nhau dựa theo `mode` bắt đầu bằng `'mini_'`.
- Không cần Section dot nếu Mini Test chỉ có 1 "section" gộp (Mixed nguồn câu) — chỉ hiện section dot khi người dùng tick nhiều nguồn khác loại thời gian (VD Vocab+Listening) tương tự Full Exam.

## 8. Practice feedback (giữa bài)

- Theo đúng nguyên tắc đã có ở `JLPT_MOCK_EXAM_DESIGN.md` §1: **Exam Mode không lộ đáp án giữa bài** — nhưng Mini Test về bản chất là luyện tập hằng ngày, không phải "thi thật", nên mặc định coi Mini Test là **Practice Mode**: sau mỗi câu hiện ngay Đáp án đúng + Giải thích ngắn (tái dùng `explanation` field đã có trong `quiz_generator.dart` nếu có, hoặc để trống nếu câu đó chưa có giải thích — không tự bịa nội dung).
- AI Explanation/Native Usage/Common Mistakes chi tiết theo từng câu: **mở rộng**, phụ thuộc AI infra giống AI Analysis ở Full Exam — không phải MVP.

## 9. Result Screen (Mini Test — rút gọn, khác `exam_result_screen.dart`)

```
┌─────────────────────────────────────────┐
│         🎉  Hoàn thành Daily Mini Test    │
│                                           │
│         8/10 đúng · 80%                  │
│      ⏱ 6 phút 20 giây                    │
│      +40 XP                              │
│                                           │
│  Điểm yếu lần này                        │
│  ▓▓▓▓░░░░ Ngữ pháp (2/5 đúng)            │
│                                           │
│  Điểm mạnh                                │
│  ▓▓▓▓▓▓▓▓ Từ vựng (5/5 đúng)             │
│                                           │
│  💡 Gợi ý: Ôn lại N5 -ば trước khi        │
│      làm Weak Point Mini tiếp theo        │
│                                           │
│  [ Ôn ngay điểm yếu ]  [ Làm lại ]        │
└─────────────────────────────────────────┘
```

- **Không có `PassFailBadge`** (§1) — đây là khác biệt cốt lõi so với `exam_result_screen.dart` của Full Exam.
- "Ôn ngay điểm yếu" dẫn thẳng sang Weak Point Mini mới (tái dùng chính luồng §2), không mở màn riêng.
- Gợi ý (💡) là rule đơn giản theo dimension điểm thấp nhất, **không phải AI** ở bản MVP — AI Recommendations chi tiết hơn (Lessons/Grammar/Vocabulary/Kanji/AI Kaiwa/Review Schedule) là **mở rộng**, tái dùng đúng ranh giới đã đặt ở `JLPT_MOCK_EXAM_DESIGN.md` §11 (AI chỉ đề xuất, `computeNextSchedule` hiện có ghi lịch, AI không tự ghi).

## 10. Statistics

Không tạo màn Statistics riêng cho Mini Test — thêm 1 lát cắt "Mini Test" vào JLPT Statistics đã thiết kế (`JLPT_MOCK_EXAM_DESIGN.md` §12), giống cách Full Exam đã làm. Hiển thị thêm so với Full Exam: Daily/Weekly/Monthly count theo biến thể, Best/Average Score theo variant, Streak (đếm mọi biến thể gộp chung — không tách streak riêng từng biến thể để tránh rối), Heatmap Calendar (phụ thuộc `fl_chart`, cùng gap `[NEEDS_CONFIRMATION]` đã ghi nhận trước đó).

## 11. Gamification

| Cơ chế | MVP hay mở rộng | Ghi chú |
|---|---|---|
| XP sau mỗi Mini Test | MVP | **Không có Coin** (quyết định 2026-08-06). Tái dùng nguyên `_xpPerCorrect = 10` (`quiz_screen.dart:61`) — mỗi câu đúng +10 XP; hoàn thành 1 Mini Test/ngày (bất kỳ biến thể) +15 XP kiểu thưởng thêm, cùng pattern `DailyMissionXpController` (`mission_providers.dart`, chặn trùng ngày qua field tương đương `mission_xp_dates`) |
| Streak (mọi biến thể) | MVP | Dùng chung `profiles.streak_count`/`last_study_date` (§5) — không tạo bảng riêng |
| Perfect Score / Speed / Accuracy Badge | Mở rộng | Chưa có xác nhận backend badge nào tồn tại, giữ chỗ UI "Sắp ra mắt" như pattern đã dùng ở `_ReviewRow` |
| Daily/Weekly Challenge, Leaderboard, Treasure Chest | Mở rộng, phụ thuộc AI Challenge Mode (Addendum B, `JLPT_MOCK_EXAM_DESIGN.md`) | Không thiết kế chi tiết logic thưởng tới khi có xác nhận backend |

## 12. Design tokens & component (dùng lại, không tạo hệ màu riêng)

Dùng nguyên token đã định nghĩa ở `REVIEW_DESIGN.md` §5 và component đã có ở `JLPT_MOCK_EXAM_DESIGN.md` §13 (`SectionTimerChip`, `QuestionPaletteSheet`, `ReadingPassagePane`). Bổ sung riêng cho Mini Test:

| Component mới | Mô tả |
|---|---|
| `MiniTestHomeCard` | Card hero + "Đề hôm nay" + Streak/Accuracy tile + Quick Start, §3 |
| `MiniTestVariantRow` | Hàng danh sách 4 biến thể — tái dùng đúng layout `_ModeCard` (`jlpt_exam_mode_screen.dart`), đổi icon/label |
| `MiniTestSettingsSheet` | Bottom sheet §4, ẩn hoàn toàn khi biến thể = Quick 5 |
| `MiniTestResultCard` | Result Screen rút gọn §9, khác `PassFailBadge`/`_PassFailBadge` của Full Exam |

## 13. State management (Riverpod)

```
miniTestHomeStatsProvider(levelId)     // FutureProvider — streak, accuracy trung bình, điểm gần nhất, đề hôm nay (§3)
miniTestBlueprintProvider(levelId, variant, settings)
                                        // FutureProvider — build MiniTestBlueprint runtime (§5),
                                        //   KHÔNG đọc từ bảng jlpt_exam_blueprints như Full Exam
examSessionControllerProvider(sessionId)
                                        // TÁI DÙNG NGUYÊN — đã có ở JLPT_MOCK_EXAM_DESIGN.md §14
miniTestResultProvider(sessionId)      // FutureProvider — tính accuracy/XP/weak-strong dimension khi nộp bài,
                                        //   thay cho examResultProvider (không tính scaledScore/PassFail)
```

- Đặt tại `lib/features/review/jlpt_exam/mini_test/` (thư mục con mới trong `jlpt_exam/`, giữ đúng cấu trúc feature-first hiện có) — không tách thành feature top-level riêng vì Mini Test vẫn thuộc "Ôn tập → JLPT Mock Exam".
- Route đăng ký ở `lib/core/router/app_router.dart` theo đúng pattern `GoRoute` hiện tại (file này đang có thay đổi chưa commit — kiểm tra tránh xung đột route khi triển khai thật).

## 14. Flutter Widget Tree

```
MiniTestHomeScreen (ConsumerWidget)
└── Scaffold
    └── body: ListView
        ├── MiniTestHomeCard
        │     ├── HeroIllustration (tái dùng asset/style hero card sẵn có)
        │     ├── Row [ReviewStatTile(Streak), ReviewStatTile(Accuracy)]
        │     └── PrimaryButton "Bắt đầu ngay"
        ├── MiniTestVariantRow × 4 (Quick 5 / Daily / Weak Point / AI)
        ├── SecondaryButton "Tiếp tục đề dang dở" (điều kiện hiện)
        └── TextButton "Xem lịch sử"

MiniTestSettingsSheet (ConsumerWidget, mở qua showModalBottomSheet)
└── Column [QuestionCountSelector, DifficultySelector, SourceCheckboxGroup, TimerToggle, PrimaryButton "Bắt đầu"]

ExamRunnerScreen (TÁI DÙNG NGUYÊN — không đổi widget tree đã có ở JLPT_MOCK_EXAM_DESIGN.md §15)

MiniTestResultScreen (ConsumerWidget)
└── Scaffold
    └── body: Column
          ├── ResultHeaderConfetti (điều kiện: chỉ khi accuracy ≥ ngưỡng, §16)
          ├── ScoreSummaryRow (đúng/tổng, %, thời gian, XP)
          ├── WeaknessRow × N (tái dùng component Review Module)
          ├── StrengthRow × N
          ├── SuggestionCard (rule-based, §9)
          └── Row [PrimaryButton "Ôn ngay điểm yếu", SecondaryButton "Làm lại"]
```

## 15. Animation specification

| Tương tác | Hiệu ứng | Duration | Reduced motion |
|---|---|---|---|
| Mở Home Screen | Card `MiniTestHomeCard` fade+slide-up nhẹ | `base` 200ms | Tắt slide, giữ fade |
| Chọn biến thể → Settings sheet | Slide-up bottom sheet (giống Question Palette) | `base` | Tắt slide, fade nhanh |
| Trong bài thi | Tái dùng nguyên bảng đã có ở `JLPT_MOCK_EXAM_DESIGN.md` §16 (không định nghĩa lại) | — | — |
| Hoàn thành Mini Test, accuracy ≥ 80% | `ConfettiBurst` (tái dùng Review §8) | `celebrate` 600ms | Banner tĩnh "Hoàn thành + XP", không confetti |
| Hoàn thành Mini Test, accuracy < 80% | Không confetti, chỉ `XpFloatingText` nhẹ | `fast` 120ms | Hiện số XP tĩnh ngay, không bay |

Ngưỡng 80% cho confetti là **giả định thiết kế hợp lý**, không phải số đã xác nhận `[NEEDS_CONFIRMATION nếu muốn khác]`.

## 16. Responsive & Dark Mode

- **Mobile**: 1 cột như mô tả §3/§9.
- **Tablet (≥600dp)**: `MiniTestVariantRow` chuyển lưới 2×2 thay vì danh sách dọc (4 biến thể vừa đẹp dạng lưới); `MiniTestResultCard` căn giữa max-width ~480dp.
- **Landscape**: Home Screen giữ cuộn dọc bình thường (không có nội dung học dài như Reading nên không cần rule đặc biệt).
- **Dark Mode**: dùng lại đúng gap đã ghi nhận ở `REVIEW_DESIGN.md` §5 — `AppTheme` hiện chưa có palette dark tuỳ biến cho module Review/Mock Exam, chỉ dùng `ColorScheme.fromSeed` mặc định của Material. Mini Test **không tự định nghĩa thêm 1 bộ màu dark riêng** — chờ giá trị dark chung được chốt (đã là `[NEEDS_CONFIRMATION]` từ trước, không lặp lại vấn đề mới).

## 17. Accessibility

- `MiniTestVariantRow`: mỗi hàng có `Semantics(label: "Quick 5, 2 đến 3 phút, khởi động nhanh")` gộp đủ tên + thời gian + mục tiêu, không chỉ dựa icon màu.
- `MiniTestResultCard`: đọc theo thứ tự Điểm số → Thời gian → XP → Điểm yếu → Điểm mạnh → Gợi ý (khớp thứ tự hiển thị, tránh gây khó hiểu khi dùng VoiceOver/TalkBack).
- Kích thước chạm mọi nút (Quick Start, Variant Row, Settings control) tối thiểu 44×44dp — theo đúng chuẩn đã áp dụng toàn bộ Review/Mock Exam Module.
- Không phụ thuộc animation: kết quả Pass-equivalent (accuracy cao) luôn có biểu diễn tĩnh (số %, badge text), confetti chỉ là hiệu ứng phụ.

## 18. Production-ready Flutter structure (khi triển khai)

```
lib/features/review/jlpt_exam/mini_test/
  mini_test_home_screen.dart
  mini_test_settings_sheet.dart
  mini_test_result_screen.dart
  models/
    mini_test_variant.dart          // enum quick5/daily/weakPoint/ai
    mini_test_blueprint.dart
    mini_test_result.dart
  providers/
    mini_test_home_providers.dart   // miniTestHomeStatsProvider
    mini_test_blueprint_providers.dart
    mini_test_result_providers.dart
```

- Không đổi `exam_runner_screen.dart`/`jlpt_exam_session_providers.dart` hiện có — Mini Test chỉ **gọi vào** (build `ExamBlueprint`/`ExamSession` rồi push route session sẵn có), giữ đúng ranh giới "tái dùng, không sửa file Full Exam đang chạy".
- Cần thêm case trong `app_router.dart` cho các route mới ở §2/§9 — file này đang có thay đổi uncommitted (xem git status), triển khai thật cần rebase/kiểm tra tránh đè lên thay đổi đang dở.

## 19. UX rationale — vì sao tách 4 biến thể thay vì 1 nút Mini Test

- 1 nút "Mini Test" buộc người dùng phải tự nghĩ "hôm nay nên luyện gì" mỗi lần mở app — đúng vấn đề mà ứng dụng luyện thi truyền thống hay mắc: coi Mini Test chỉ là "đề rút gọn", không phải công cụ ra quyết định thay người học.
- 4 biến thể ánh xạ đúng 4 tình huống thực tế: rảnh 2 phút (Quick 5) → có 5-10 phút theo lộ trình (Daily) → biết mình yếu chỗ nào, muốn sửa (Weak Point) → muốn app tự lo hết (AI). Đây là phễu độ cam kết tăng dần, không phải 4 tính năng rời rạc.
- Việc dùng chung 1 exam engine (§7) giữ chi phí triển khai thấp — khác biệt thực sự chỉ nằm ở bước chọn nguồn câu, không nhân bản 4 lần code Question Screen/Result Screen.
- Bỏ Pass/Fail Prediction khỏi Mini Test (§1) là quyết định UX quan trọng: giữ đúng ranh giới "Mini Test = luyện tập", "Full Exam = mô phỏng thi thật" — tránh làm loãng ý nghĩa của Pass/Fail Prediction vốn đã có disclaimer cẩn thận ở Full Exam.

## 20. Gợi ý tăng độ hấp dẫn (giữ bản sắc Nihongo, không copy app khác)

- **"Đề hôm nay" đổi mỗi ngày** (§3) — biến Mini Test thành lý do quay lại app hằng ngày, giống cơ chế Daily Challenge nhưng không cần chờ AI Challenge Mode (Addendum B) mới có.
- **Streak gộp cả 4 biến thể** (§5, §10) — khuyến khích thử biến thể khác nhau mỗi ngày thay vì lặp lại đúng 1 kiểu, mà vẫn giữ 1 con số streak duy nhất dễ hiểu (không chia nhỏ streak theo biến thể gây rối).
- **"Ôn ngay điểm yếu" ở cuối Result** (§9) nối thẳng sang Weak Point Mini — tạo vòng lặp luyện tập liên tục trong 1 phiên, không bắt người dùng quay lại Home Screen giữa chừng.
- **Quick 5 không có màn Settings** — cố tình giữ ma sát bằng 0 cho biến thể "khởi động", đúng insight gốc "chỉ có vài phút rảnh" — mọi bước cấu hình thêm đều là rào cản với đúng nhóm người dùng biến thể này nhắm tới.
- Các gợi ý xa hơn (Leaderboard, Treasure Chest, Daily/Weekly Challenge kết hợp AI Kaiwa) **đã có chỗ** ở AI Challenge Mode (Addendum B, `JLPT_MOCK_EXAM_DESIGN.md`) — không lặp lại đặc tả ở đây để tránh 2 tài liệu mô tả trùng 1 tính năng tương lai.

## 21. MVP / Mở rộng / Cần xác nhận

| Khu vực | MVP | Mở rộng | Cần xác nhận trước khi code |
|---|---|---|---|
| Quick 5 | Có — random đơn giản, không settings | — | — |
| Daily Mini Test | Có — nguồn từ lộ trình/`ReviewSchedule` đã có | — | — |
| Weak Point Mini | Có — tái dùng `isSmartPick()`, ngưỡng **5 mục** (quyết định 2026-08-06), dưới ngưỡng fallback random kèm thông báo | — | — |
| AI Mini Test | — (phụ thuộc AI infra như Full Exam AI Mock Exam) | Toàn bộ | Đã chốt dùng **quota riêng** (2026-08-06) — còn thiếu: con số quota cụ thể (bao nhiêu lượt/ngày, giới hạn theo gì) `[NEEDS_CONFIRMATION]` |
| Result Screen rút gọn (không Pass/Fail) | Có | AI Recommendations chi tiết | — |
| Streak/XP | Có (MVP) — XP tái dùng `_xpPerCorrect=10` + thưởng 15 XP/ngày kiểu mission; Streak dùng chung `profiles.streak_count` (2026-08-06) | Badge/Leaderboard/Treasure Chest | — |
| Mini Test Statistics (lát cắt trong JLPT Statistics) | Tile số liệu cơ bản | Heatmap Calendar | Dependency `fl_chart` (gap đã có sẵn) |
| Dark Mode riêng Mini Test | Dùng theme mặc định hiện có | Palette dark tuỳ biến module | Giá trị dark cụ thể (gap chung toàn app, không riêng Mini Test) |

## 22. Câu hỏi cần xác nhận — ĐÃ TRẢ LỜI 2026-08-06

Người dùng trả lời qua form (AskUserQuestion) sau khi đọc bản nháp đầu của tài liệu này:

1. **Coin** — chọn "Bỏ Coin, chỉ dùng XP". Áp dụng: xoá `coinEarned` khỏi `MiniTestResult` (§5), xoá 🪙 khỏi Result Screen (§9), xoá "Coin" khỏi Gamification (§11) và widget tree (§14).
2. **Streak** — chọn "Dùng chung streak toàn app". Áp dụng: xoá `MiniTestStreak` khỏi §5, thay bằng ghi chú tái dùng `profiles.streak_count`/`last_study_date`.
3. **Ngưỡng Weak Point Mini** — chọn "5 mục". Áp dụng: §21 cập nhật ngưỡng cụ thể, không còn để trống `[NEEDS_CONFIRMATION]`.
4. **Quota AI Mini Test** — chọn "Quota/giới hạn riêng cho AI Mini Test" (khác đề xuất mặc định "dùng chung"). Áp dụng: §21 ghi rõ hướng đã chọn; **con số quota cụ thể vẫn còn mở** `[NEEDS_CONFIRMATION]` — sẽ hỏi lại khi bắt tay vào task AI Mini Test (không chặn 3 biến thể đầu).

Còn 1 điểm mở duy nhất chưa chặn được xác định trước khi code 3 biến thể đầu (Quick 5/Daily/Weak Point): **con số quota AI Mini Test cụ thể** (§21) — để dành tới khi làm task AI Mini Test, không cần trả lời ngay.

## Trạng thái soạn

- [x] Đặc tả đủ IA, User Flow, Wireframe, UI Layout, Component List, Widget Tree, State Flow, Animation, Responsive, Dark Mode, Accessibility, cấu trúc file production-ready, UX rationale, gợi ý tăng hấp dẫn — theo đúng 14 mục prompt gốc yêu cầu 2026-08-06.
- [x] Tích hợp đúng đề xuất 4 biến thể (Quick 5/Daily/Weak Point/AI) thay cho 1 nút Mini Test, đối chiếu với code thật đang có (`jlpt_exam_mode_screen.dart`, `exam_runner_screen.dart`, `exam_blueprint.dart`, `jlpt_scoring.dart`, `reading_passage.dart`).
- [x] 4/5 điểm chặn triển khai đã được người dùng trả lời (§22) — Coin, Streak, ngưỡng Weak Point, hướng quota AI đều đã chốt.
- [ ] Chưa triển khai source code — đúng phạm vi giai đoạn hiện tại.
- Bước tiếp theo: chia task nhỏ theo thứ tự Quick 5 → Daily → Weak Point → AI Mini Test (xem breakdown TaskCreate trong phiên làm việc) — con số quota AI cụ thể hỏi lại khi tới task AI Mini Test.
