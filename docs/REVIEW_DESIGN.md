# Review Module — Design

> Soạn lại theo `docs/TASK.md` (Acceptance Criteria) và prompt thiết kế gốc do người dùng cung cấp lại ngày 2026-08-03. Giai đoạn này **chỉ đặc tả**, không sửa source code. Mọi quyết định chưa có căn cứ từ code/backend hiện có được đánh dấu `[NEEDS_CONFIRMATION]`.

## 0. Căn cứ từ codebase hiện có

- Route review đã tồn tại: `/vocabulary/review`, `/kanji/review`, `/grammar/review`, `/kaiwa/review`, `/kanji/statistics`, `/kaiwa/statistics` (`lib/core/router/app_router.dart`) và tab tổng `ReviewScreen` (`lib/features/review/review_screen.dart`) hiện chỉ là danh sách link sang từng module.
- SRS: `lib/domain/services/srs_scheduler.dart` — SM-2 rút gọn 3 mức (`forgot/hard/good`), ease kẹp `[1.3, 3.0]`, interval tối đa 365 ngày. **Đây là thuật toán nền phải tái dùng**, không thay thế.
- Token màu: `lib/core/theme/app_theme.dart` — nền kem `canvas`, accent cam san hô, mỗi module 1 màu riêng (moss=Từ vựng, indigo=Kanji, plum=Ngữ pháp, teal=Kaiwa). Dark mode hiện **chưa có override riêng** (chỉ `ColorScheme.fromSeed` mặc định) → cần bổ sung, ghi ở §5.
- Không có bảng `attempt/mistake/schedule/weakness` cục bộ (`lib/data/local/tables.dart` chỉ có nội dung tĩnh: Vocabulary/Kanji/GrammarPoints/Lessons). Tiến độ (progress) hiện lấy qua provider Supabase riêng từng module (`vocab_progress_providers.dart`, `kanji_progress_providers.dart`, `grammar_progress_providers.dart`, `kaiwa_conversation_providers.dart`) — Review Module cần **hợp nhất tín hiệu** từ các provider này, mô hình dữ liệu ở §3 là khái niệm, ánh xạ implementation cụ thể để ngỏ.
- Không có package chart/canvas vẽ heatmap (`fl_chart` không có trong `pubspec.yaml`). Thống kê dạng biểu đồ cần dependency mới → nằm ngoài phạm vi sửa của giai đoạn này, đánh dấu `[NEEDS_CONFIRMATION: cần thêm package]`.

## 1. Nguyên tắc thiết kế

- Kế thừa ngôn ngữ thị giác hiện có (nền kem, thẻ bo góc 16–18px, border 1px màu `border`, không đổ bóng nặng) — **không tạo hệ màu mới cho riêng Review**.
- Mỗi khu vực Review giữ đúng màu module đã gán (Từ vựng=moss, Kanji=indigo, Ngữ pháp=plum, Kaiwa=teal); phần **liên module** (Dashboard, AI Coach, Mistake Notebook, Smart Review) dùng accent cam trung tính.
- Ưu tiên rõ ràng > trang trí: mỗi màn hình trả lời được "hôm nay ôn gì, mất bao lâu, vì sao" trong 1 lượt nhìn.
- Không sao chép layout của ứng dụng SRS phổ biến khác; điểm khác biệt của Nihongo là **AI Memory Review** (§12) — gộp lỗi đa kỹ năng vào một tình huống hội thoại duy nhất, khai thác dữ liệu Kaiwa đã có sẵn.
- Mọi hoạt ảnh có phương án tắt khi `MediaQuery.disableAnimations` (§8).

## 2. Kiến trúc thông tin toàn module

```
Tab "Ôn tập" (/review)
├── Review Dashboard              /review
│   ├── → Today's Review          /review/today
│   ├── → Smart Review            /review/smart
│   └── → Review Statistics       /review/statistics
├── Today's Review                /review/today
│   ├── → Vocabulary Review       /vocabulary/review        (đã có)
│   ├── → Grammar Review          /grammar/review            (đã có)
│   ├── → Kanji Review            /kanji/review               (đã có)
│   ├── → Listening Review        /review/listening           (mới)
│   ├── → Speaking Review         /review/speaking            (mới)
│   └── → Mixed/Priority Review   /review/today/session       (mới)
├── AI Review Coach               /review/coach                (mới)
├── Weak Points                   /review/weak-points          (mới)
├── Mistake Notebook              /review/mistakes             (mới)
├── Smart Review                  /review/smart                (mới)
└── Review Statistics             /review/statistics            (hợp nhất, xem §0)
```

- Vocabulary/Grammar/Kanji Review **giữ nguyên route hiện có** — Review Module bổ sung lớp điều phối (Dashboard, Today's, Smart, Coach, Weak Points, Mistake Notebook, Statistics tổng) chứ không viết lại 3 màn đã chạy.
- Listening Review, Speaking Review: chưa có màn hình nguồn tương ứng trong repo (`lib/features/review` hiện chỉ có 1 file) → route và entity nguồn dữ liệu `[NEEDS_CONFIRMATION]`.
- Điều hướng: mỗi khu vực con có nút "Quay lại Dashboard" và deep-link trực tiếp (vd. từ notification "Có 12 thẻ đến hạn" → thẳng `/review/today`).

## 3. Mô hình dữ liệu khái niệm

Không đổi schema Supabase/Drift trong giai đoạn này. Các entity dưới đây mô tả **khái niệm** để hướng dẫn implementation sau này.

| Entity | Trường chính | Ghi chú |
|---|---|---|
| `ReviewItem` | id, sourceType (`vocab/kanji/grammar/listening/speaking/kaiwa`), sourceId, userId | Tham chiếu tới nội dung gốc đã có (`VocabularyTable`, `KanjiTable`, `GrammarPointsTable`...), không nhân bản dữ liệu |
| `ReviewSchedule` | itemId, intervalDays, easeFactor, dueAt, lastGrade | Ánh xạ trực tiếp `SrsScheduleResult` hiện có; 1 dòng/item/user |
| `ReviewAttempt` | id, itemId, sessionId, questionType, isCorrect, responseTimeMs, selfGrade (`SrsGrade`), confidence `[NEEDS_CONFIRMATION: có thu thập confidence 1-5 không]` | Log từng lượt trả lời, nguồn tính accuracy/retention |
| `Mistake` | id, attemptId, originalAnswer, correctAnswer, explanation, aiComment, note, bookmarked, reviewCount | 1 Mistake sinh ra khi `isCorrect=false`; là nguồn cho Mistake Notebook |
| `WeaknessSignal` | userId, dimension (`grammarPoint/vocabTopic/kanji/listeningType/speakingSituation`), score, sampleSize, updatedAt | Điểm yếu tính rolling từ `ReviewAttempt`, không phải bảng mới độc lập — có thể là view/aggregate |
| `ReviewSession` | id, userId, type (`today/smart/aiMemory/mixed`), startedAt, completedAt, itemIds[], xpEarned | Gói 1 lượt ôn để tính thời lượng, XP, streak |
| `StatisticsSnapshot` | userId, date, reviewedCount, accuracy, retentionRate, studyTimeMinutes | Tổng hợp theo ngày cho biểu đồ; có thể derive on-the-fly thay vì lưu snapshot `[NEEDS_CONFIRMATION]` |

Quan hệ: `ReviewItem 1—1 ReviewSchedule`, `ReviewItem 1—N ReviewAttempt`, `ReviewAttempt 0—1 Mistake`, `ReviewSession 1—N ReviewAttempt`.

## 4. SRS & Adaptive Review — nguyên tắc

**Giữ nguyên `computeNextSchedule()`** (SM-2 rút gọn) làm lõi lập lịch cho mọi loại nội dung (từ vựng/kanji/ngữ pháp). Phần mở rộng cho Review Module:

- **Chọn thứ tự ôn trong ngày** (không phải công thức ease): ưu tiên theo `dueAt` quá hạn xa nhất trước, sau đó theo `WeaknessSignal.score` thấp nhất. Đây là quy tắc sắp xếp, không đổi thuật toán ease.
- **Ánh xạ tín hiệu → `SrsGrade`**: response time và số lần sai gần đây dùng để **gợi ý** grade mặc định hiển thị cho người dùng xác nhận (vd. trả lời đúng nhưng chậm > ngưỡng → gợi ý "Hard" thay vì "Good"), người học vẫn tự chọn cuối cùng — giữ triết lý "tự chấm" đã ghi trong code hiện tại, không để AI âm thầm ghi đè.
- Ngưỡng response-time cụ thể, trọng số confidence, công thức `WeaknessSignal.score`: **`[NEEDS_CONFIRMATION]`** — cần dữ liệu thật để hiệu chỉnh, không đưa số liệu giả định vào spec.
- **Difficulty thích ứng** trong 1 phiên (Vocabulary/Grammar Review §13.3–13.4): nếu 3 câu liên tiếp đúng nhanh → tăng độ khó câu hỏi tiếp theo (đổi từ multiple-choice sang typing/listening); nếu sai 2 liên tiếp → hạ về multiple-choice + gợi ý. Đây là rule cấp UI/session, tách khỏi lập lịch dài hạn của SM-2.

## 5. Design tokens (mở rộng từ `AppColors`/`AppTheme`)

Không tạo bảng màu mới; **bổ sung role còn thiếu**:

| Token mới | Light | Dark `[NEEDS_CONFIRMATION: giá trị dark chưa duyệt]` | Dùng cho |
|---|---|---|---|
| `AppColors.mastered` | = `moss` | — | Badge "Đã thuộc" trong Statistics/Weak Points |
| `AppColors.dueSoon` | = `accent` | — | Badge "Sắp đến hạn" |
| `AppColors.overdue` | = `danger` | — | Badge quá hạn nhiều ngày |
| `AppColors.xpGold` | `#F5B400` (mới) | — | XP counter, coin |
| Spacing scale | 4 / 8 / 12 / 16 / 20 / 24 / 32 | giống light | dùng lại đúng bội số đã thấy trong code hiện tại (`EdgeInsets.all(15)`, `SizedBox(height: 10)` → chuẩn hoá dần, không bắt buộc sửa code cũ) |
| Radius | card=18, chip/pill=999, sheet-top=24 | như hiện có | khớp `cardTheme`, `bottomSheetTheme` đã định nghĩa |
| Motion duration | fast=120ms, base=200ms, slow=320ms, celebrate=600ms | như light | dùng ở §8 |

**Dark mode**: `AppTheme._base()` hiện chỉ override cho `isLight`; nhánh dark dùng `ColorScheme.fromSeed` mặc định của Material. Review Module cần palette dark tương đương (nền tối ấm, không xám lạnh, giữ 4 màu module dễ phân biệt trên nền tối) — **giá trị cụ thể `[NEEDS_CONFIRMATION]`**, đây là gap có sẵn từ trước, không riêng của Review.

## 6. Component library (dùng chung, feature-first: đặt tại `lib/shared/widgets/review/`)

| Component | Mô tả | Trạng thái |
|---|---|---|
| `ReviewStatTile` | Ô số liệu tròn góc: số + nhãn (Due hôm nay, Streak, Accuracy...) | Mới |
| `DueBadge` | Pill nhỏ hiển thị số lượng đến hạn theo màu module | Mới |
| `ReviewCalendarHeatmap` | Lưới ô màu theo mật độ ôn tập | Mới — cần chart/canvas dependency `[NEEDS_CONFIRMATION]` |
| `SrsGradeBar` | 3 nút Forgot/Hard/Good sau mỗi thẻ, tái dùng logic `SrsGrade` | Mới, bọc quanh `computeNextSchedule` hiện có |
| `QuestionRunnerShell` | Khung chung: progress bar trên cùng, nội dung câu hỏi giữa, nút hành động dưới — dùng cho mọi Question Type ở §"Question Types" | Mới, thay cho việc mỗi loại câu hỏi tự viết khung riêng |
| `MistakeCard` | Thẻ hiển thị original/correct/explanation + nút bookmark/note | Mới |
| `WeaknessRow` | Thanh tiến độ + nhãn mức yếu (Kém/Trung bình/Khá) | Mới |
| `AiCoachBubble` | Bong bóng chat AI Coach, tái dùng style bubble đã có ở `kaiwa_chat_screen.dart` `[cần đối chiếu, không copy 100% vì Coach không phải hội thoại tự do]` | Tái dùng có điều chỉnh |
| `XpFloatingText` / `StreakFlame` / `ConfettiBurst` | Micro-interaction gamification | Mới, xem §8 |
| `_ReviewRow` (đã có trong `review_screen.dart`) | Hàng danh sách icon+title+subtitle | **Tái dùng**, không viết lại — Dashboard/Today's có thể kế thừa pattern này cho các mục danh sách |

## 7. State management pattern (Riverpod + GoRouter)

Mẫu chung áp dụng cho mọi khu vực (minh hoạ 1 lần, không lặp lại 12 lần):

```
reviewTodayProvider (FutureProvider)
  ├── đọc vocabProgressProvider, kanjiProgressProvider,
  │     grammarProgressProvider, kaiwaConversationsProvider (đã có)
  ├── gộp thành List<ReviewItem> theo §3, lọc dueAt <= now
  └── expose: todayCount, estimatedMinutes, breakdown theo sourceType

reviewSessionControllerProvider (StateNotifierProvider, family theo sessionId)
  ├── state: danh sách item, vị trí hiện tại, kết quả tạm
  ├── action: submitAnswer() → tính isCorrect → gọi computeNextSchedule()
  │     → ghi ReviewAttempt (+Mistake nếu sai) → cập nhật XP/streak provider
  └── khi hết danh sách → điều hướng kết quả phiên (summary sheet)
```

- Feature-first: provider của Review Module nằm ở `lib/features/review/providers/`, chỉ **đọc** (không sửa) provider của `vocabulary/grammar/kanji/kaiwa` đã có — đúng ràng buộc "không sửa module khác" trong `TASK.md`.
- Route mới đăng ký tại `lib/core/router/app_router.dart` theo đúng pattern `GoRoute(path: ..., builder: ...)` đang dùng.

## 8. Animation specification

| Tương tác | Hiệu ứng | Duration | Reduced motion |
|---|---|---|---|
| Lật flashcard | 3D flip theo trục Y | `base` (200ms) | Thay bằng crossfade 1 khung |
| Trả lời đúng | Scale bounce nhẹ + tick icon | `fast` (120ms) | Chỉ đổi màu viền, không scale |
| Streak tăng | `StreakFlame` phóng to rồi giữ | `slow` (320ms) | Đổi số ngay, bỏ phóng to |
| Hoàn thành phiên | `ConfettiBurst` + XP bay vào thanh XP | `celebrate` (600ms) | Chỉ hiện banner tĩnh "Hoàn thành + XP" |
| Chuyển câu hỏi | Slide ngang | `base` | Giữ, chỉ tắt khi `disableAnimations=true` |

Quy tắc bắt buộc: mọi widget hoạt ảnh đọc `MediaQuery.of(context).disableAnimations` (hoặc `AccessibilityFeatures.disableAnimations`) và fallback sang trạng thái tĩnh — không có animation nào là đường duy nhất để hiểu kết quả (vd. "đúng/sai" luôn kèm icon + text, không chỉ dựa màu/animation).

## 9. Responsive & platform rules

- **Mobile (mặc định)**: 1 cột, `QuestionRunnerShell` full-width, bottom action bar cố định.
- **Tablet (≥ 600dp width)**: Dashboard và Statistics chuyển sang lưới 2 cột cho `ReviewStatTile`; Question Runner giữ max-width ~560dp căn giữa để không kéo dãn dòng chữ tiếng Nhật quá rộng.
- **Landscape**: ẩn app bar title lớn, dồn `SrsGradeBar` sang cạnh phải màn hình thay vì đáy (tránh che nội dung câu hỏi trên màn hình ngắn).
- Nền tảng ưu tiên triển khai trước (iOS/Android) chưa xác định — `[NEEDS_CONFIRMATION]` (câu hỏi #5 trong `TASK.md`); thiết kế ở đây trung lập nền tảng, không phụ thuộc gesture riêng của 1 OS.

## 10. Accessibility requirements

- **Dynamic Type**: mọi text trong component ở §6 dùng `Theme.of(context).textTheme`, không hard-code `fontSize` cố định cho nội dung học (chữ Nhật, đáp án) — cho phép co giãn tới ít nhất 130% trước khi bắt buộc truncate.
- **VoiceOver/TalkBack**: `SrsGradeBar` có `Semantics(label: "Đánh giá: Quên/Khó/Tốt")` rõ ràng; `MistakeCard` đọc theo thứ tự Đáp án đã chọn → Đáp án đúng → Giải thích.
- **Contrast**: badge màu (`dueSoon`, `overdue`, `mastered`) phải đạt tối thiểu WCAG AA (4.5:1) trên nền `canvas`/`card` — cần kiểm bằng công cụ khi có giá trị màu cuối cùng, đặc biệt `xpGold` trên nền sáng dễ thiếu tương phản.
- **Không phụ thuộc animation**: đã nêu ở §8 — mọi trạng thái (đúng/sai/hoàn thành/streak) có biểu diễn tĩnh tương đương.
- **Kích thước chạm**: nút `SrsGradeBar` và các lựa chọn trắc nghiệm tối thiểu 44×44dp.

## 11. Gamification

| Cơ chế | MVP hay mở rộng | Ghi chú |
|---|---|---|
| Review XP | MVP | Cộng dựa trên `ReviewAttempt` đúng, hệ số theo độ khó — công thức cụ thể `[NEEDS_CONFIRMATION]` |
| Review Streak | MVP | Tái dùng khái niệm streak nếu đã có ở module khác `[NEEDS_CONFIRMATION: có streak chung toàn app chưa]` |
| Daily/Weekly Goal | MVP | Người dùng đặt số thẻ/phút mục tiêu |
| Coins, Treasure Box, League, Achievement, Perfect Review Badge | Mở rộng | **Chưa có xác nhận backend nào tồn tại** (câu hỏi #4 trong `TASK.md`) — không thiết kế chi tiết logic thưởng cho tới khi có câu trả lời, chỉ giữ chỗ UI (badge rỗng, "Sắp ra mắt" theo đúng pattern đã dùng ở `_ReviewRow` cho "Quiz tổng hợp") |

## 12. AI Review Coach

- **Vai trò**: phân tích lỗi theo dimension ở `WeaknessSignal` (§3), trả lời câu hỏi dạng chat cố định theo prompt gốc: "Vì sao tôi hay sai?", "Giải thích lại", "Cho ví dụ dễ hơn/khó hơn", "Tạo quiz từ lỗi của tôi", "Ôn lại bài hôm qua".
- **Input cho AI**: N mistake gần nhất (đã ẩn danh hoá dữ liệu cá nhân nếu cần) + điểm yếu theo dimension — **không** gửi toàn bộ lịch sử, giữ quota như đã làm ở AI Kaiwa (`docs/DECISIONS.md`/`nihongo-ai-kaiwa` — xem provider hiện có cho pattern giới hạn context/token đã áp dụng).
- **Ranh giới rõ**: Coach chỉ **diễn giải** và **đề xuất** quiz/phiên ôn; việc tạo phiên thật do `reviewSessionControllerProvider` (§7) thực hiện, tránh AI trực tiếp ghi `ReviewSchedule`.
- Model/provider AI cụ thể, giới hạn quota riêng cho Coach: `[NEEDS_CONFIRMATION]` — tái dùng hạ tầng AI Kaiwa hiện có hay tạo Edge Function riêng, cần quyết định trước khi triển khai.

## 13. AI Memory Review — tính năng trọng tâm

Đúng như đề xuất trong yêu cầu gốc: thay vì ôn từng phần rời rạc, gộp **các lỗi gần đây thuộc nhiều kỹ năng** thành một tình huống hội thoại duy nhất.

**Luồng tạo bài ôn tích hợp:**

1. Lấy tối đa N (`[NEEDS_CONFIRMATION: N cụ thể]`) `Mistake` gần nhất, ưu tiên đa dạng `sourceType` (ít nhất 1 ngữ pháp + 1 từ vựng/kanji nếu có).
2. Chọn 1 tình huống Kaiwa phù hợp (tái dùng ngân hàng tình huống đã có ở `kaiwa/topics`, không tạo kho tình huống mới) mà các mẫu ngữ pháp/từ vựng/kanji đó có thể xuất hiện tự nhiên.
3. Sinh kịch bản hội thoại (dùng hạ tầng AI Kaiwa hiện có) trong đó người học **buộc phải** dùng đúng mẫu ngữ pháp từng sai, đọc đúng Kanji từng quên, dùng lại từ vựng từng quên — trả lời bằng giọng nói, hoàn thành hội thoại.
4. Sau khi hoàn thành, chấm lại từng điểm lỗi cũ riêng biệt (không chỉ chấm hội thoại tổng thể) để cập nhật đúng `ReviewSchedule` của từng `ReviewItem` gốc — đây là điểm khác biệt cốt lõi: 1 phiên nhưng cập nhật N lịch ôn riêng.

**Trạng thái màn hình**: loading (đang soạn tình huống — có thể mất vài giây do gọi AI, cần skeleton + thông báo rõ), empty (chưa đủ dữ liệu lỗi để tạo bài ôn tích hợp → gợi ý làm review thường trước), active (hội thoại), success (tổng kết: từng lỗi cũ đã được sửa hay chưa), error (AI lỗi/quota hết → fallback về Kaiwa review thường), offline (`[NEEDS_CONFIRMATION: offline scope]` — nhiều khả năng tính năng này **yêu cầu mạng bắt buộc** vì cần AI, không có bản offline).

**MVP hay giai đoạn sau**: câu hỏi #3 trong `TASK.md` chưa có câu trả lời — đây là tính năng phức tạp nhất (phụ thuộc AI Kaiwa + tổng hợp đa nguồn), khuyến nghị đặt là **mở rộng sau MVP** trừ khi được xác nhận khác, vì MVP cần Dashboard/Today's/SRS cơ bản chạy ổn định trước.

## 14. Smart Review

- AI/rule engine tự quyết: nội dung ôn (kết hợp `ReviewSchedule` quá hạn + `WeaknessSignal` thấp), độ khó câu hỏi (theo §4 "difficulty thích ứng"), loại câu hỏi (random có trọng số, tránh lặp cùng loại quá 2 lần liên tiếp), thứ tự, chủ đề hội thoại nếu có phần Kaiwa.
- Khác Today's Review ở chỗ: Today's Review = "những gì đến hạn hôm nay theo lịch", Smart Review = "AI chọn thay bạn, có thể gồm cả mục chưa đến hạn nhưng đang yếu".
- Không để thuật toán chọn nội dung là hộp đen hoàn toàn: hiển thị lý do ngắn gọn trên mỗi item ("Vì bạn hay sai từ này", "Đã 5 ngày chưa ôn Kanji này").

## 15. 12 khu vực — chi tiết theo mẫu chung

Mẫu áp dụng cho mỗi khu vực: **Mục tiêu · Route · User flow · Trạng thái màn hình · Ghi chú widget/tái dùng**. Component/token dùng lại tham chiếu §5–§8, không lặp lại định nghĩa.

### 15.1 Review Dashboard — `/review`
- Mục tiêu: trả lời "hôm nay ôn gì, mất bao lâu, đang ổn không" trong 1 màn hình.
- Flow: mở tab → thấy `ReviewStatTile` (Due hôm nay, Streak, Accuracy, Retention) → nút chính "Ôn ngay" (đẩy thẳng vào Today's Review) → nút phụ "Tiếp tục" nếu có phiên dang dở → `ReviewCalendarHeatmap` (mật độ 30 ngày) → Daily/Weekly Goal progress.
- Trạng thái: loading (skeleton `ReviewStatTile`), empty (chưa có item nào đến hạn → thông điệp tích cực + gợi ý học bài mới), active/success (số liệu thật), error (không tải được → nút thử lại, không chặn truy cập từng module con), offline (số liệu cache gần nhất + banner "đang offline" `[NEEDS_CONFIRMATION: mức độ hỗ trợ offline]`).
- Widget: kế thừa cấu trúc `ListView` + card như `review_screen.dart` hiện có, thêm hàng `ReviewStatTile` dạng `GridView` phía trên danh sách link cũ.

### 15.2 Today's Review — `/review/today`
- Mục tiêu: liệt kê rõ theo nguồn (Vocabulary/Grammar/Kanji/Listening/Speaking/Mixed) + độ khó + thời gian ước tính, để người học chọn ôn từng phần hay ôn gộp.
- Flow: Dashboard → Today's → chọn 1 nguồn (đi thẳng route module đó, đã có sẵn `/vocabulary/review` v.v.) hoặc chọn "Ôn tất cả" (Mixed) → `QuestionRunnerShell` chạy tuần tự qua các nguồn.
- Trạng thái: empty = "Không có gì đến hạn hôm nay" (khác Dashboard rỗng do chưa học gì); các trạng thái khác theo mẫu chung §8/§9.
- Ghi chú: Listening/Speaking Due chưa có nguồn dữ liệu xác nhận → hiển thị "Sắp ra mắt" như pattern `_ReviewRow` hiện có cho tới khi §15.6/15.7 được duyệt.

### 15.3 Vocabulary Review — `/vocabulary/review` (đã có, chỉ bổ sung)
- Giữ màn hình hiện có; Review Module chỉ thêm: Adaptive Difficulty (theo §4) và ghi `ReviewAttempt`/`Mistake` khi trả lời sai để nuôi Mistake Notebook — không đổi UI đã chạy nếu không có yêu cầu riêng.
- Question type áp dụng: Flashcard, Meaning Recall, Listening, Typing, Sentence Completion (Speaking/Image Matching → mở rộng, cần asset ảnh/mic pipeline riêng `[NEEDS_CONFIRMATION]`).

### 15.4 Grammar Review — `/grammar/review` (đã có, chỉ bổ sung)
- Tương tự 15.3: giữ UI, bổ sung ghi Attempt/Mistake + AI Explanation (gọi Coach §12) khi người học chọn "Giải thích lại".
- Question type: Multiple Choice, Sentence Correction, Rewrite Sentence (Conversation Completion → liên quan Kaiwa, cân nhắc gộp vào AI Memory Review thay vì làm riêng).

### 15.5 Kanji Review — `/kanji/review` (đã có, chỉ bổ sung)
- Giữ UI; bổ sung Adaptive Difficulty + Mistake logging.
- Question type: Meaning, Reading, Recognition (Stroke Order/Writing/Handwriting: repo đã có `kanji/draw` route riêng → Review chỉ **liên kết tới**, không viết lại pipeline vẽ).

### 15.6 Listening Review — `/review/listening` (mới)
- Chưa có màn nguồn tương ứng trong repo hiện tại (chỉ có `/listening` ở lesson, không rõ có tách riêng phần luyện nghe không) → phạm vi, nguồn audio, dictation engine: `[NEEDS_CONFIRMATION]`.
- Thiết kế khung: `QuestionRunnerShell` + nút phát lại audio + ô nhập/typing cho Dictation, câu hỏi trắc nghiệm cho Comprehension.

### 15.7 Speaking Review — `/review/speaking` (mới)
- Phụ thuộc pipeline ghi âm/chấm phát âm đã dùng ở Kaiwa (`speech_to_text`, `record`) — tái dùng, không viết lại service ghi âm.
- Voice Feedback cụ thể (chấm điểm phát âm ra sao): `[NEEDS_CONFIRMATION]` — hiện chưa rõ có model chấm phát âm hay chỉ so khớp text từ speech-to-text.

### 15.8 AI Review Coach — `/review/coach`
- Xem chi tiết §12. UI dạng chat, tái sử dụng bubble style từ `kaiwa_chat_screen.dart` có điều chỉnh (Coach có thêm "quick action chips" cho 5 câu hỏi mẫu trong prompt gốc).

### 15.9 Weak Points — `/review/weak-points`
- Mục tiêu: liệt kê điểm yếu theo dimension (`WeaknessSignal`, §3) dùng `WeaknessRow`, nhóm theo Ngữ pháp/Từ vựng/Kanji/Nghe/Nói/Chủ đề/JLPT section/Tình huống hội thoại.
- Mỗi dòng có gợi ý cải thiện ngắn (1 câu, do AI Coach sinh hoặc rule tĩnh nếu chưa đủ dữ liệu) + nút "Ôn ngay điểm này" → tạo `ReviewSession` lọc theo dimension đó.
- Trạng thái empty: chưa đủ dữ liệu (cần tối thiểu bao nhiêu attempt mới tính weakness `[NEEDS_CONFIRMATION]`) → thông điệp "Ôn thêm để thấy điểm yếu của bạn".

### 15.10 Mistake Notebook — `/review/mistakes`
- Danh sách `MistakeCard`, filter theo nguồn/thời gian/bookmark, tìm kiếm theo text.
- Mỗi mistake: Đáp án đã chọn, Đáp án đúng, Giải thích, Ví dụ, Lịch sử ôn lại (bao nhiêu lần đã gặp lại và kết quả), Bookmark, AI Comment, Ghi chú cá nhân (editable).
- Trạng thái empty tích cực: "Chưa có lỗi nào được ghi nhận" (không phải điều xấu, cần văn phong khích lệ, đúng phong cách Nihongo hiện có).

### 15.11 Smart Review — `/review/smart`
- Xem §14. UI: 1 nút lớn "Bắt đầu Smart Review" + preview ngắn số lượng/loại câu hỏi AI đã chọn trước khi vào, cho phép huỷ nếu không muốn.

### 15.12 Review Statistics — `/review/statistics`
- Hợp nhất số liệu, không tách riêng theo module như hiện tại `kanji/statistics`, `kaiwa/statistics` đang làm — Review Statistics là **tầng tổng hợp phía trên**, các trang con giữ nguyên cho chi tiết từng module.
- Hiển thị: Daily/Weekly/Monthly Review, Retention Rate, Accuracy, Study Time, Mastered/Forgotten Items, Heatmap Calendar, JLPT Progress theo cấp N5–N1.
- Cần `ReviewCalendarHeatmap` và biểu đồ đường/cột → phụ thuộc dependency mới (§0), nên **Statistics dạng số (tile) là MVP, biểu đồ trực quan là mở rộng** cho tới khi duyệt thêm package.

## 16. Bảng tổng hợp MVP / Mở rộng / Cần xác nhận

| Khu vực | MVP | Mở rộng | Cần xác nhận trước khi code |
|---|---|---|---|
| Dashboard | Stat tile số liệu thật, nút Ôn ngay | Heatmap trực quan | Offline scope |
| Today's Review | Liệt kê theo nguồn có sẵn (Vocab/Grammar/Kanji) | Listening/Speaking/Mixed đầy đủ | Nguồn dữ liệu Listening/Speaking |
| Vocabulary/Grammar/Kanji Review | Bổ sung Adaptive Difficulty + Mistake logging trên UI đã có | Image Matching, Handwriting nâng cao | — |
| Listening Review | — | Toàn bộ | Route/entity nguồn |
| Speaking Review | — | Toàn bộ | Voice scoring model |
| AI Review Coach | 5 câu hỏi mẫu cố định | Hội thoại tự do mở rộng | Provider/quota AI riêng |
| Weak Points | Danh sách + gợi ý tĩnh | Gợi ý do AI sinh động | Ngưỡng dữ liệu tối thiểu |
| Mistake Notebook | CRUD note/bookmark, filter cơ bản | Tìm kiếm nâng cao, export | — |
| Smart Review | Rule-based chọn nội dung | AI tối ưu hoá thứ tự/chủ đề | Công thức weighting |
| AI Memory Review | — (khuyến nghị mở rộng, xem §13) | Toàn bộ | Có phải MVP không (câu hỏi #3) |
| Review Statistics | Tile số liệu | Biểu đồ/heatmap | Dependency chart |
| Gamification | XP, Streak, Goal | Coin/League/Treasure/Achievement | Backend nào đã tồn tại (câu hỏi #4) |

## 17. Câu hỏi cần xác nhận (giữ nguyên từ `docs/TASK.md`, chưa có câu nào được trả lời)

1. Review Module dùng schema/API hiện có hay được đề xuất mới khi triển khai?
2. Thuật toán SRS: giữ nguyên `computeNextSchedule`, mở rộng, hay thay mới?
3. AI Memory Review có bắt buộc trong MVP không?
4. Gamification nào đã có backend thật (XP/coin/streak/league/achievement/treasure/challenge)?
5. Nền tảng ưu tiên triển khai trước: iOS, Android hay cả hai?
6. Có mascot/brand asset chính thức bắt buộc tái dùng không?

Bổ sung phát sinh trong quá trình soạn lại:

7. Có thu thập "confidence" tự đánh giá (1–5) mỗi lượt trả lời không, hay chỉ dùng 3 mức `SrsGrade` hiện có? (§4)
8. Offline scope cho từng khu vực — đặc biệt AI Coach/AI Memory Review vốn cần mạng bắt buộc? (§9, §13)
9. Có được thêm dependency chart/canvas (vd. `fl_chart`) cho Statistics/Heatmap không? (§0, §15.12)

## 18. Trạng thái soạn lại

- [x] Soạn lại đủ 12 khu vực + các mục toàn cục (tokens, component, data model, SRS, state flow, animation, responsive, accessibility, gamification, AI Memory Review) theo Acceptance Criteria trong `docs/TASK.md`.
- [x] Phân biệt MVP / mở rộng / cần xác nhận (§16).
- [ ] Chưa triển khai source code — đúng phạm vi giai đoạn hiện tại.
- Bước tiếp theo: người dùng trả lời §17, sau đó mở task triển khai riêng cho từng khu vực theo thứ tự ưu tiên (đề xuất: Dashboard + Today's + bổ sung 3 Review đã có trước, vì rủi ro thấp nhất và tái dùng nhiều nhất).
