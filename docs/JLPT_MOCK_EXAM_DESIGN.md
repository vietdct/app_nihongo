# JLPT Mock Exam — Design

> Đặc tả theo prompt gốc "JLPT Examination Designer / Senior Product Designer / Flutter Design Architect" do người dùng cung cấp ngày 2026-08-04. Giai đoạn này **chỉ đặc tả**, không sửa source code — theo đúng cách làm đã dùng ở `docs/REVIEW_DESIGN.md`. Quyết định chưa có căn cứ từ code/backend hiện có đánh dấu `[NEEDS_CONFIRMATION]`.

## 0. Căn cứ từ codebase hiện có

- **JLPT Level**: `lib/domain/entities/jlpt_level.dart` (code N5–N1, orderIndex) + `jlptLevelsProvider` (`lib/features/lesson/providers/level_providers.dart:9`) — **tái dùng trực tiếp** cho bước "Choose Level", không tạo entity level mới.
- **Quiz engine hiện có** (`lib/domain/services/quiz_generator.dart`, 884 dòng, 10 nhóm sinh câu hỏi) và `QuizScreen` (`lib/features/quiz/quiz_screen.dart`, 1842 dòng) đã có: multiple choice, fill blank, typing, sentence ordering, error correction, listening (ẩn chữ Nhật), `timedMode` (đồng hồ toàn bài), `survivalMode`, Result Page. **Đây là nền tái dùng cho Vocabulary/Grammar section của Mock Exam.**
- **Giới hạn của `QuizScreen` hiện tại** (không phải thiếu sót, chỉ là phạm vi khác): luồng tuyến tính 1-câu-1-lúc, không có Question Palette/nhảy câu, không có nhiều section với đồng hồ riêng từng section, không có Bookmark/Flag. → JLPT Mock Exam cần **engine mới** (`ExamRunnerShell`, §6), không sửa `QuizScreen`.
- **Listening**: `ListeningDialogue` entity + `listeningDialoguesForLevelProvider` (`lib/features/quiz/providers/listening_dialogue_providers.dart`) — bảng `listening_dialogues` (turns hội thoại + câu hỏi + 4 lựa chọn) **tái dùng được cho Listening section**, dạng câu hỏi đã đúng phong cách JLPT (nghe hội thoại → chọn đáp án).
- **Reading**: chưa có feature/entity đọc-hiểu dạng đoạn văn (`find lib/features -iname "*reading*"` → rỗng). Passage + câu hỏi đọc hiểu là **nội dung mới hoàn toàn**, cần bảng dữ liệu mới `[NEEDS_CONFIRMATION]`.
- **Weak-point selection**: `isSmartPick()` dùng chung (`lib/features/review/providers/vocab_review_providers.dart`, đã tổng quát hoá từ `review_smart_screen.dart` theo `docs/PROGRESS.md`) — **tái dùng cho Weak Point Test mode**, không viết lại rule chọn điểm yếu.
- **AI infra**: AI Kaiwa (Edge Function + Claude) và `review_coach_service.dart` là 2 pattern gọi AI đã tồn tại, có giới hạn quota/context — **AI Mock Exam và AI Analysis tái dùng pattern này** (§11), không tự thiết kế provider AI mới.
- **SRS**: `lib/domain/services/srs_scheduler.dart` (SM-2 rút gọn) — **không dùng để chấm điểm Mock Exam** (JLPT chấm điểm thô theo section, không phải spaced repetition), nhưng dùng ở bước "cập nhật `ReviewSchedule`" sau khi biết câu nào sai (đồng bộ với Review Module hiện có, xem §5).
- Không có bảng `exam_attempt/exam_session/exam_blueprint` nào trong `lib/data/local/tables.dart` hay Supabase schema hiện tại → mọi entity ở §5 là **khái niệm**, cần schema mới khi triển khai.

## 1. Nguyên tắc thiết kế

- Cảm giác thi **giống đề thật JLPT** (layout câu hỏi, đánh số, không có gợi ý/dịch trong Exam Mode) nhưng vỏ UI vẫn dùng đúng token hiện có của Nihongo (nền `canvas`, card bo góc, không đổ bóng nặng) — không chép giao diện app khác.
- **Exam Mode** (đề thật) và **Practice Mode** (luyện từng phần) là hai trạng thái tách bạch rõ ràng bằng UI, không chỉ bằng 1 cờ ẩn: Exam Mode luôn tắt furigana/replay/dictionary; Practice Mode được mở tất cả.
- Không tự chấm "đỗ/trượt" bằng con số bịa — Pass/Fail Prediction phải nêu rõ đây là **ước lượng dựa trên điểm mô phỏng**, không phải kết quả thi thật (JLPT chấm theo thang điểm quy đổi riêng của Japan Foundation, Nihongo không có quyền truy cập công thức đó).
- Tái dùng tối đa: engine sinh câu hỏi Vocab/Grammar, dữ liệu Listening, rule điểm yếu, hạ tầng AI — chỉ xây mới phần JLPT không có: cấu trúc đề theo section có đồng hồ riêng, Question Palette, Reading passage, chấm điểm theo thang JLPT.
- Mọi animation có phương án tắt khi `MediaQuery.disableAnimations` (§16), giống quy tắc đã áp dụng ở Review Module.

## 2. Kiến trúc thông tin (IA)

```
Tab "Ôn tập" (/review)
└── 🏆 JLPT Mock Exam                    /review/jlpt-exam      (mới, mục nổi bật ⭐)
    ├── Chọn Level (N5–N1)               /review/jlpt-exam/level
    ├── Chọn Mode                        /review/jlpt-exam/:levelId/mode
    │   ├── Full Exam                    → /review/jlpt-exam/:levelId/full/settings
    │   ├── Mini Test                    → /review/jlpt-exam/:levelId/mini/settings
    │   ├── Section Practice             → /review/jlpt-exam/:levelId/practice/:section
    │   ├── Custom Test                  → /review/jlpt-exam/:levelId/custom/settings
    │   ├── Weak Point Test              → /review/jlpt-exam/:levelId/weak-point/settings
    │   └── AI Mock Exam                 → /review/jlpt-exam/:levelId/ai/generating
    ├── Settings (Choose Time/Timing/Random/Adaptive) — màn chung, tham số khác theo mode
    ├── Exam Screen                      /review/jlpt-exam/session/:sessionId
    │   ├── Vocabulary section
    │   ├── Grammar section
    │   ├── Reading section
    │   └── Listening section
    ├── Result                           /review/jlpt-exam/session/:sessionId/result
    ├── AI Analysis                      /review/jlpt-exam/session/:sessionId/analysis
    └── JLPT Statistics                  /review/jlpt-exam/statistics
```

- 4 section (Vocabulary/Grammar/Reading/Listening) là **con** của 1 session, không phải route riêng như Vocabulary/Kanji Review hiện có — vì JLPT thi theo khối, không tách app-level.
- Section Practice tái sử dụng route `mode=practice` để mở đúng 1 section không giới hạn giờ, không tạo `ExamSession` đầy đủ (nhẹ hơn, không cần chấm tổng).

## 3. Exam Modes

| Mode | Mục tiêu | Đồng hồ | Nguồn câu hỏi |
|---|---|---|---|
| Full Exam | Mô phỏng đề thi thật đầy đủ 4 section | Official Timing theo level (N5/N4 ước lượng ngắn hơn N3–N1) — số phút chính xác theo cấu trúc JLPT thật `[NEEDS_CONFIRMATION: cần bảng thời gian chính thức từng level/section]` | Random có trọng số theo blueprint (§5 `ExamBlueprint`), không lặp câu đã thi gần đây nếu đủ ngân hàng câu hỏi |
| Mini Test | Bản rút gọn ~25–30% số câu mỗi section, cùng tỉ lệ | Tỉ lệ theo Official Timing | Cùng blueprint, giảm count |
| Section Practice | Luyện riêng 1 section, không tính là 1 "đề" | Unlimited (mặc định) hoặc bấm giờ tuỳ chọn | Random trong section đó |
| Custom Test | Người dùng tự chọn section nào, số câu mỗi loại — giống UX `ReviewMixedQuizCustomScreen` đã có (`lib/features/review/review_mixed_quiz_custom_screen.dart`) | Tuỳ chọn Official/Unlimited | Theo lựa chọn |
| Weak Point Test | Tái dùng `isSmartPick()` để ưu tiên câu thuộc điểm yếu, chỉ áp dụng cho Vocab/Grammar (Reading/Listening không có "điểm yếu theo item" rõ ràng, dùng theo dimension `sourceType`) | Unlimited | Lọc theo `WeaknessSignal` (khái niệm đã định nghĩa ở `REVIEW_DESIGN.md` §3) |
| AI Mock Exam | AI soạn 1 đề mini theo lịch sử lỗi của người dùng — **đây là tiền đề trực tiếp cho "🔥 AI Challenge Mode"** (§22), không phải 2 tính năng trùng nhau: AI Mock Exam giữ đúng format JLPT (4 section, chấm theo thang JLPT); AI Challenge Mode mở rộng thêm Speaking/Kaiwa và không cố giữ format thi thật | Unlimited hoặc Official (người dùng chọn) | AI sinh dựa trên `Mistake`/`WeaknessSignal` (đã có khái niệm ở Review Module), fallback sang random blueduy nếu chưa đủ dữ liệu lỗi |

## 4. Settings

- **Choose Level**: N5–N1, dùng `jlptLevelsProvider` hiện có.
- **Choose Time / Official Timing / Unlimited Mode**: 3 lựa chọn loại trừ nhau, hiển thị rõ số phút cụ thể khi chọn Official (không để trống số).
- **Random Questions**: bật/tắt xáo thứ tự trong mỗi section (không xáo giữa các section — JLPT luôn theo đúng khối Vocab→Grammar→Reading→Listening).
- **Adaptive Difficulty**: chỉ áp dụng cho Practice/Custom/AI Mock Exam, **không** áp dụng cho Full Exam/Mini Test (đề thi thật JLPT không đổi độ khó theo người làm) — quy tắc đổi độ khó tái dùng nguyên tắc đã có ở `REVIEW_DESIGN.md` §4 ("3 đúng nhanh liên tiếp → tăng khó, 2 sai liên tiếp → hạ khó").

## 5. Mô hình dữ liệu khái niệm

Không đổi schema Supabase trong giai đoạn này. Entity dưới đây là khái niệm hướng dẫn implementation sau.

| Entity | Trường chính | Ghi chú |
|---|---|---|
| `ExamBlueprint` | levelId, mode, sections: [{type, questionCount, timeMinutes, questionTypeWeights}] | Cấu hình "1 đề JLPT trông như thế nào" theo level+mode; Official Timing đọc từ đây |
| `ReadingPassage` | id, levelId, title, bodyJa, questions: [{questionJa, options, correctIndex}] | **Nội dung mới**, chưa có nguồn — cần soạn/seed `[NEEDS_CONFIRMATION]` |
| `ExamSession` | id, userId, levelId, mode, startedAt, submittedAt, status (`inProgress/submitted/abandoned`), sectionResults[] | 1 lần làm đề; khác `ReviewSession` (Review Module) — Mock Exam có chấm điểm theo thang JLPT, Review Session không |
| `ExamAnswer` | sessionId, sectionType, questionId, selectedIndex, isCorrect, bookmarked, flagged, timeSpentMs | Ghi từng câu; `bookmarked`/`flagged` là 2 cờ độc lập (đánh dấu xem lại vs đánh dấu nghi ngờ) |
| `ExamSectionResult` | sessionId, sectionType, rawScore, scaledScore, passThreshold | `scaledScore`/`passThreshold` theo thang điểm JLPT thật (Vocab+Grammar gộp 1 điểm, Reading riêng, Listening riêng — N5/N4 khác N3–N1) `[NEEDS_CONFIRMATION: cần bảng quy đổi chính thức, không tự bịa hệ số]` |
| `PassFailPrediction` | sessionId, predictedPass (bool), confidence, note | Luôn kèm disclaimer "ước lượng, không phải kết quả thật" (§1) |

Quan hệ: `ExamSession 1—N ExamAnswer`, `ExamSession 1—4 ExamSectionResult`, `ExamBlueprint` là template dùng để tạo `ExamSession` mới, không lưu theo user.

**Đồng bộ với Review Module**: sau khi `ExamSession` kết thúc, câu sai được ghi thêm 1 `Mistake` (entity đã có trong `REVIEW_DESIGN.md` §3) để vào Sổ tay lỗi chung — Mock Exam **không tạo hệ thống lỗi riêng**, tái dùng Mistake Notebook đã thiết kế.

## 6. Exam Engine — khác `QuizScreen` ở đâu

```
examSessionControllerProvider (StateNotifierProvider, family theo sessionId)
  state:
    currentSectionIndex, currentQuestionIndex
    answers: Map<questionId, ExamAnswer>   // cho phép sửa lại câu đã trả lời (khác Review — JLPT thật cho quay lại sửa)
    sectionTimers: Map<sectionType, Duration>  // Official Timing: mỗi section có đồng hồ RIÊNG, hết giờ section tự khoá và chuyển section kế
    flags/bookmarks
  actions:
    selectAnswer(questionId, index)     // không tính đúng/sai ngay — JLPT không cho biết đáp án khi đang thi
    toggleFlag(questionId) / toggleBookmark(questionId)
    jumpToQuestion(index)               // Question Palette gọi thẳng, không cần Next tuần tự
    nextSection() / submitExam()        // chấm toàn bộ 1 lần khi nộp bài, không chấm từng câu như QuizScreen
```

- Khác biệt cốt lõi với `QuizScreen`: (1) không hiện đúng/sai ngay sau mỗi câu, (2) cho phép nhảy câu tự do TRONG 1 section (không được lùi/sửa section trước — quyết định 2026-08-05, xem ngay dưới), (3) đồng hồ theo **section** không phải toàn bài, (4) chấm điểm 1 lần lúc nộp.
- **Khoá section sau khi nộp (2026-08-05, theo yêu cầu người dùng)**: `_goPrev()` chỉ lùi được trong section hiện tại (`_questionIndex > 0`), KHÔNG còn cho lùi sang section trước như bản đầu — đúng cấu trúc JLPT thật (mỗi phần thi có giờ riêng, nộp phần nào chốt phần đó, không được quay lại sửa). Ở câu cuối 1 section, `_goNext()` hiện hộp thoại xác nhận "Nộp phần X?" trước khi thật sự qua section kế (bấm "Kiểm tra lại" thì ở lại, không mất gì) — hết giờ section (timer) vẫn tự động qua section kế NGAY, không hỏi xác nhận (không có gì để người dùng "quyết định" khi đã hết giờ). Trong nội bộ 1 section vẫn tự do xem/sửa lại câu đã làm qua Next/Prev/Bảng câu hỏi như cũ.
- **TTS ngắt đúng khi đổi section (2026-08-05)**: sửa bug tiếng đọc Nghe hiểu của câu cũ tiếp tục phát đè khi đã chuyển sang section khác (VD Đọc hiểu) — `_tts.stop()` giờ gọi ngay khi `_answerKey` đổi (mọi lượt điều hướng), không chỉ khi câu MỚI cũng là Nghe hiểu như trước.
- Vì khác biệt đủ lớn, đề xuất **không kế thừa `QuizScreen`**, viết `ExamRunnerShell` mới ở `lib/features/review/jlpt_exam/` (đặt cùng cây `features/review` vì Mock Exam là 1 mục trong tab Ôn tập, giống cách `Mixed Quiz` đang nằm trong `lib/features/review/`).
- Sinh câu hỏi Vocab/Grammar: **gọi lại** `quiz_generator.dart` (không viết generator mới) — chỉ bọc thêm layer chọn theo `ExamBlueprint` thay vì random đơn giản.

## 7. Exam Screen — layout

```
┌─────────────────────────────────────────┐
│ ⏱ 12:34   Vocabulary  ●●●○ (section dot) │  ← đồng hồ section + tên section
├─────────────────────────────────────────┤
│ Câu 8/25                    [🔖][🚩]     │  ← số câu, bookmark, flag
│ ▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░ (progress bar) │
│                                           │
│   ________ を 食べます。                   │
│   ① りんご   ② りんごを   ③ りんごが  ④ に │
│                                           │
├─────────────────────────────────────────┤
│ [‹ Trước]     [Bảng câu hỏi ▦]  [Sau ›]  │  ← Previous / Question Palette / Next
└─────────────────────────────────────────┘

Question Palette (bottom sheet):
┌───────────────────────────┐
│  1  2  3  4  5  6  7  8   │  ← số xanh=đã làm, viền cam=flagged,
│  9 10 11 12 13 14 15 16   │    chấm nhỏ=bookmarked, xám=chưa làm
│ 17 18 19 20 21 22 23 24   │
│ 25                        │
│         [Nộp bài]         │
└───────────────────────────┘
```

- Reading section thêm khung passage cố định bên trên/trái (tablet: 2 cột passage|câu hỏi; mobile: cuộn, passage co lại còn tiêu đề khi cuộn xuống câu hỏi — xem §17).
- Listening section thay khối câu hỏi text bằng nút Play + waveform tĩnh, số lần nghe còn lại hiển thị rõ khi ở Exam Mode (0 lần nếu đã nghe hết, không cho bấm lại — §9).

## 8. Reading section

- **Passage**: hiển thị nguyên văn, không dịch, không từ điển tra cứu (Dictionary Disabled ở Exam Mode) — long-press chỉ cho phép **Highlight** (đổi màu nền chữ, lưu tạm trong session, không lưu vĩnh viễn), không mở popup nghĩa.
- **Furigana Option**: chỉ hiện toggle ở Practice Mode; Exam Mode luôn ẩn furigana (giống đề thi thật, trừ N5 vốn có furigana theo đề thật `[NEEDS_CONFIRMATION: N5 đề thật có furigana sẵn hay không]`).
- Nội dung passage là **mới hoàn toàn**, cần quy trình soạn/duyệt riêng (không tự sinh AI cho đề thi thật Full Exam vì cần độ chính xác cao) — AI chỉ sinh passage cho **AI Mock Exam** (§11), Full Exam/Mini Test dùng passage đã duyệt tay.
- **Task 6 (2026-08-04)**: đã soạn 1 đoạn văn N5 mẫu "山田さんの一日" (3 câu hỏi), seed ở migration `20260804092000_jlpt_exam_reading_seed_n5.sql`, gắn vào blueprint N5 full_exam (`type: "reading"`). MVP giữ đơn giản: passage **luôn hiện sẵn cùng câu hỏi** (đúng bản chất đọc hiểu — khác Listening ẩn transcript), KHÔNG làm sticky/collapse-khi-cuộn như phác thảo §7 (không cần thiết với 1 đoạn văn ngắn, để tránh over-engineer); Highlight/Furigana-toggle **chưa làm** (`[NEEDS_CONFIRMATION]`/theo dõi riêng, không nằm trong scope tối thiểu Task 6). Xem `ReadingQuestionGenerator` (`lib/domain/services/reading_question_generator.dart`) + `_ReadingPassageCard` (`lib/features/review/jlpt_exam/exam_runner_screen.dart`).

## 9. Listening section

- **Official-style Audio**: tái dùng cơ chế phát audio đã có ở Quiz (`_AudioPlayButton`, `lib/features/quiz/quiz_screen.dart:715`) làm điểm khởi đầu về UI nút play, không viết lại từ đầu.
- **Replay Disabled (Exam Mode)**: mỗi track chỉ phát được đúng 1 lần (đúng JLPT thật) — nút Play biến thành disabled + icon "đã nghe" sau khi phát xong.
- **Replay Enabled (Practice Mode)**: không giới hạn số lần.
- **Đã kiểm tra schema** (`supabase/migrations/20260726030000_listening_dialogues.sql`): bảng `listening_dialogues` **không có cột `audio_url`** — chỉ có `turns` (jsonb text hội thoại), `question_ja/question_vi`, `options`, `correct_index`. Không có audio thu sẵn nào cho Listening; âm thanh (mục tiếp theo) là TTS máy đọc, không phải file ghi âm thật.
- **Transcript ẨN mặc định trong Exam Mode** (quyết định 2026-08-04, theo yêu cầu người dùng): KHÔNG hiện sẵn transcript hội thoại cùng lúc với câu hỏi — chỉ hiện câu hỏi tiếng Nhật (`questionJa`) + 4 đáp án để chọn, mô phỏng đúng "nghe 1 lần rồi chọn" của thi thật thay vì cho đọc lại thoải mái. Có nút "Bấm để xem lại nội dung" để mở transcript ra xem (phục vụ luyện tập/đối chiếu), không bắt buộc như thi thật — trạng thái ẩn/hiện reset về ẩn mỗi khi sang câu khác, không lưu Supabase, không ảnh hưởng chấm điểm. Xem `_ListeningTranscriptReveal` (`lib/features/review/jlpt_exam/exam_runner_screen.dart`).
- **TTS thật (2026-08-05, theo yêu cầu người dùng)**: `_ExamBodyState` tái dùng đúng pattern `flutter_tts` + giọng đã lưu chung với AI Kaiwa/Quiz (`jp_voice_prefs.dart`) — tự động đọc to (`_speakListening`) mỗi khi vào 1 câu Nghe hiểu mới: lần lượt từng lượt thoại (đổi cao độ theo speaker A/B để nghe như 2 người), sau đó đọc tiếp câu hỏi (`promptVi` = `questionJa`) — khác `QuizScreen._speakCurrent` (chỉ đọc hội thoại, không đọc câu hỏi). Có nút "Nghe lại" để phát lại bất cứ lúc nào, không giới hạn số lần (khác quyết định "Replay Disabled" phác thảo ở trên — MVP ưu tiên đơn giản, không cần đúng luật "nghe 1 lần" của thi thật vì transcript đã ẩn mặc định rồi).

## 10. After Exam — Result

- **Task 7 (2026-08-04) — ĐÃ LÀM**: `lib/domain/services/jlpt_scoring.dart` — bảng `jlptScoringRules` (N1–N5) lấy từ số liệu công khai JLPT (jlpt.jp — mục Test Sections/Test Time và Passing Score by Level, ổn định từ đợt cải cách 2010): N1–N3 chấm 3 nhóm điểm (Từ vựng-Ngữ pháp / Đọc hiểu / Nghe hiểu, mỗi nhóm tối đa 60, tổng 180); N4–N5 gộp Từ vựng+Ngữ pháp+Đọc hiểu thành 1 nhóm (tối đa 120) + Nghe hiểu (tối đa 60). Ngưỡng đỗ tổng: N1=100, N2=90, N3=95, N4=90, N5=80; điểm liệt mỗi nhóm N1-N3=19/60, N4-N5=38/120 (ngôn ngữ+đọc) và 19/60 (nghe). `scaledScore` = quy đổi TUYẾN TÍNH đơn giản từ điểm thô (rawCorrect/rawTotal × điểm tối đa nhóm) — KHÔNG phải công thức IRT thật JEES dùng nội bộ (không công khai), luôn kèm disclaimer ở `PassFailBadge`. Số liệu tra từ hiểu biết đã có sẵn (WebSearch lỗi lúc triển khai), người dùng nên đối chiếu lại với jlpt.jp nếu cần độ chính xác tuyệt đối.
- **Official Timing (Task 7 — ĐÃ LÀM)**: `officialTimingMinutesBySectionType` phân bổ lại tổng phút thi thật của level (N5=90, N4=115, N3=140, N2=155, N1=165 phút) cho 4 section runner theo tỉ lệ số câu — vì đề thật gộp Ngữ pháp+Đọc hiểu chung 1 khối giờ, không có số phút chính thức tách riêng cho từng phần app tự chia, nên đây là ước lượng theo tỉ lệ (tổng luôn khớp đúng tổng thời gian thi thật). Áp dụng trong `buildExamRunSections`, ghi đè `spec.timeMinutes` khi level có rule; fallback về giá trị blueprint gốc nếu chưa có rule.
- **Total Score** + breakdown theo đúng nhóm điểm chính thức ở trên (không tách Vocab/Grammar thành 2 điểm — khớp cấu trúc JLPT thật).
- **Pass/Fail Prediction (ĐÃ LÀM)**: `_PassFailBadge` trong `exam_result_screen.dart` — đỗ khi tổng điểm ≥ ngưỡng VÀ không nhóm nào dưới điểm liệt, kèm disclaimer bắt buộc (§1). Level chưa có rule công khai → không hiện badge, chỉ hiện điểm thô (giữ nguyên hành vi cũ).
- **Estimated JLPT Level**: chỉ hiện khi làm Full Exam/Mini Test ở level thấp nhất người dùng chưa từng đỗ mô phỏng — không suy luận "lên level" từ 1 lần làm duy nhất `[NEEDS_CONFIRMATION: ngưỡng bao nhiêu lần đạt mới ước lượng nâng level]`.
- **Weak Areas**: nhóm theo dimension (giống `WeaknessRow` đã thiết kế ở Review Module).
- **AI Analysis**: nút riêng dẫn sang `/review/jlpt-exam/session/:id/analysis` (không tự động chạy AI ngay khi nộp bài — tôn trọng quota, giống nguyên tắc AI Coach).

## 11. AI Mock Exam & AI Analysis

- Tái dùng đúng pattern giới hạn context/quota đã áp dụng ở AI Kaiwa và `review_coach_service.dart`: gửi tối đa N mistake/weakness gần nhất, không gửi toàn bộ lịch sử.
- AI Analysis giải thích **từng câu sai** theo 4 nhóm (Grammar/Vocabulary/Reading mistakes/Listening mistakes) + đề xuất Lessons/Grammar/Vocabulary/Kanji liên quan + đề xuất Review Schedule (gọi thẳng `computeNextSchedule` hiện có để tạo `ReviewSchedule` cho các item sai, không để AI tự ghi lịch — đúng ranh giới đã đặt ở `REVIEW_DESIGN.md` §12).
- Model/provider cụ thể, giới hạn quota riêng cho Mock Exam AI: `[NEEDS_CONFIRMATION]` — quyết định trước khi triển khai, giống câu hỏi tương đương ở Review Module.

## 12. JLPT Statistics

- Là 1 lát cắt trong Review Statistics tổng (`/review/statistics` đã thiết kế) — **không tạo màn Statistics riêng biệt hoàn toàn độc lập**, chỉ thêm tab/section "JLPT Mock Exam" bên trong màn Statistics đã có, tránh 2 nơi hiển thị số liệu ôn tập.
- Hiển thị: History (điểm từng lần thi theo thời gian), Average Score, Progress theo level, Completion Time, Accuracy, Heatmap (phụ thuộc `fl_chart` — cùng gap `[NEEDS_CONFIRMATION]` đã ghi ở `REVIEW_DESIGN.md` §0/§15.12), JLPT Prediction xu hướng qua nhiều lần thi.

## 13. Design tokens & component (mở rộng, không tạo hệ màu riêng)

Dùng lại token đã định nghĩa ở `REVIEW_DESIGN.md` §5 (`mastered`, `dueSoon`, `overdue`, `xpGold`, spacing/radius/motion). Bổ sung riêng cho Mock Exam:

| Component mới | Mô tả |
|---|---|
| `ExamRunnerShell` | Khung Exam Screen: header đồng hồ+section dot, thân câu hỏi, footer Prev/Palette/Next — thay `QuestionRunnerShell` (Review Module) vì cần thêm section dot + palette |
| `QuestionPaletteSheet` | Bottom sheet lưới số câu, màu theo trạng thái (đã làm/flagged/bookmarked/chưa làm) |
| `SectionTimerChip` | Giống `_WholeQuizTimerChip` (`quiz_screen.dart:654`) nhưng đổi label theo section, đổi màu khi < 2 phút |
| `PassFailBadge` | Badge Pass/Fail + disclaimer text bắt buộc đi kèm |
| `ReadingPassagePane` | Khung passage có Highlight, co giãn theo scroll (mobile) / cột riêng (tablet) |

## 14. State management (Riverpod)

```
jlptExamBlueprintProvider(levelId, mode)   // FutureProvider — đọc ExamBlueprint, quyết định số câu/thời gian mỗi section
examSessionControllerProvider(sessionId)   // StateNotifierProvider.family — xem §6
examResultProvider(sessionId)              // FutureProvider — chấm điểm khi submit, tạo ExamSectionResult + PassFailPrediction
jlptStatisticsProvider(userId)             // FutureProvider — đọc lịch sử ExamSession, dùng ở §12
```

- Feature-first: đặt tại `lib/features/review/jlpt_exam/providers/`, chỉ đọc `quiz_generator.dart`, `listeningDialoguesForLevelProvider`, `jlptLevelsProvider`, `isSmartPick()` đã có — không sửa các file này.
- Route đăng ký tại `lib/core/router/app_router.dart` theo pattern `GoRoute` hiện tại.

## 15. Widget tree (Exam Screen, rút gọn)

```
ExamScreen (ConsumerStatefulWidget)
└── Scaffold
    ├── ExamAppBar (SectionTimerChip + section dots)
    └── body: ExamRunnerShell
        ├── QuestionHeaderRow (số câu + bookmark/flag icon button)
        ├── LinearProgressIndicator
        ├── Expanded → QuestionBody
        │     ├── ReadingPassagePane (chỉ Reading section)
        │     ├── ListeningPlayButton (chỉ Listening section)
        │     └── AnswerOptionsList (dùng lại style option-tile từ quiz_generator/QuizScreen)
        └── BottomBar: [Trước] [Bảng câu hỏi ▦ → mở QuestionPaletteSheet] [Sau]
```

## 16. Animation specification

| Tương tác | Hiệu ứng | Duration | Reduced motion |
|---|---|---|---|
| Chuyển câu | Slide ngang, giống Review Module | `base` 200ms | Tắt slide, giữ nội dung |
| Mở Question Palette | Slide-up bottom sheet | `base` | Tắt slide, fade nhanh |
| Hết giờ section | Đồng hồ đổi đỏ + rung nhẹ (haptic, không bắt buộc animation) | `fast` 120ms | Chỉ đổi màu, không rung hình |
| Nộp bài thành công | `ConfettiBurst` (tái dùng từ Review §8) chỉ khi Pass dự đoán | `celebrate` 600ms | Banner tĩnh, không confetti khi Fail (tránh phản cảm) |

## 17. Responsive & platform

- **Mobile**: 1 cột; Reading passage cuộn cùng câu hỏi, passage co lại còn thanh tiêu đề dính (`SliverAppBar` pinned) khi cuộn xuống câu hỏi.
- **Tablet (≥600dp)**: Reading section 2 cột cố định (passage trái, câu hỏi phải); Question Palette hiện dạng side panel thay vì bottom sheet.
- **Landscape**: đồng hồ + section dot dồn lên 1 dòng gọn, ưu tiên chiều cao cho nội dung câu hỏi.
- Nền tảng ưu tiên: theo `[NEEDS_CONFIRMATION]` chung đã ghi ở `REVIEW_DESIGN.md` §9 (chưa chốt iOS/Android trước).

## 18. Accessibility

- Question Palette: mỗi số câu có `Semantics(label: "Câu 8, đã làm, đã đánh dấu")` gộp đủ 3 trạng thái trong 1 label, không chỉ dựa màu.
- Reading passage: hỗ trợ Dynamic Type, không giới hạn cứng số dòng hiển thị.
- Đồng hồ sắp hết giờ: có cảnh báo dạng text ("Còn 2 phút") song song với đổi màu, không chỉ dựa màu đỏ.
- Kích thước chạm nút Prev/Next/Palette/Flag/Bookmark tối thiểu 44×44dp — theo đúng chuẩn đã áp dụng ở Review Module.

## 19. MVP / Mở rộng / Cần xác nhận

| Khu vực | MVP | Mở rộng | Cần xác nhận trước khi code |
|---|---|---|---|
| Full Exam / Mini Test | Vocab+Grammar (tái dùng quiz_generator) + Listening (tái dùng listening_dialogues) | Reading đầy đủ | Nội dung Reading passage, bảng thời gian Official Timing chính thức, thang điểm quy đổi JLPT thật |
| Section Practice | Tất cả section trừ Reading (chờ nội dung) | Reading practice | — |
| Custom Test | Tái dùng UX `ReviewMixedQuizCustomScreen` | — | — |
| Weak Point Test | Tái dùng `isSmartPick()` cho Vocab/Grammar | Áp dụng cho Reading/Listening theo dimension | Ngưỡng dữ liệu tối thiểu (giống câu hỏi tương đương Review Module) |
| AI Mock Exam | — (phụ thuộc AI infra + Reading AI-gen) | Toàn bộ | Provider/quota AI riêng, có cho AI tự sinh Reading passage không (khác Full Exam thi thật) |
| Question Palette/Bookmark/Flag | Có, MVP bắt buộc (khác biệt cốt lõi với QuizScreen) | — | — |
| Pass/Fail Prediction, Estimated Level | Disclaimer rõ + công thức đơn giản dựa threshold | Mô hình dự đoán tinh hơn theo lịch sử nhiều lần thi | Thang điểm/threshold chính thức từng level |
| JLPT Statistics/Heatmap | Tile số liệu (giống Review Statistics MVP) | Biểu đồ/heatmap | Dependency chart (`fl_chart`) — gap đã có sẵn |
| Audio thật cho Listening | Transcript text (đã xác nhận: bảng không có cột `audio_url`, xem §9) | Phát âm thanh thật — cần thêm cột + quy trình thu âm | Có chấp nhận đổi schema Supabase để thêm `audio_url` không |

## 20. Câu hỏi cần xác nhận — ĐÃ TRẢ LỜI 2026-08-04

1. ~~Bảng thời gian Official Timing / thang điểm quy đổi~~ — **quyết định**: dùng số phút thi và ngưỡng điểm tối thiểu để đỗ theo tài liệu JLPT **công khai** làm mặc định (tra cứu cụ thể ở Task 7 — Result screen), không tự bịa số. Vì JEES không công khai công thức quy đổi thang điểm nội bộ chính xác, mọi `scaledScore` là **mô phỏng gần đúng**, luôn kèm disclaimer "ước lượng, không phải kết quả thật" ở `PassFailBadge` (§1, §10, §13). **Task 7 (2026-08-04) — ĐÃ LÀM**: xem bảng số liệu cụ thể + nguồn ở §10. Lưu ý: WebSearch lỗi lúc triển khai nên số liệu lấy từ hiểu biết sẵn có (không phải fetch trực tiếp từ jlpt.jp lúc code), nên đối chiếu lại nếu cần độ chính xác tuyệt đối.
2. ~~Nguồn nội dung Reading passage~~ — **quyết định**: tự soạn passage mẫu (không copy đề thật), theo cấu trúc JLPT từng level, seed vào bảng `reading_passages` mới (Task 6).
3. ~~`listening_dialogues.audio_url`~~ — đã xác nhận bằng cách đọc schema: bảng **không có cột này**. MVP Listening hiển thị transcript text, không phát âm thanh thật (không bịa TTS).
4. Thứ tự triển khai — **quyết định**: menu/route trước → exam engine + Vocab/Grammar → Listening → Reading → Result/Pass-Fail → AI Mock Exam/Analysis sau cùng (xem breakdown 8 task đang track qua TaskCreate trong phiên làm việc).
5. AI Mock Exam/AI Analysis: giữ đúng phạm vi Addendum B — **mở rộng sau cùng**, không phải MVP, vì phụ thuộc mọi phần trước đã ổn định.
6. Nền tảng ưu tiên (iOS/Android) — vẫn để ngỏ như `REVIEW_DESIGN.md` §17; giả định thực tế cho việc verify UI trong quá trình code: máy dev hiện có Android SDK/emulator đã verify, chưa có Xcode → ưu tiên verify bằng Android trước, không có nghĩa là quyết định sản phẩm cuối cùng ưu tiên Android.

---

## Addendum A — Cập nhật IA tổng của tab "Ôn tập" theo đề xuất người dùng

Đề xuất chia lại menu Review (kèm 🎲 Mixed Quiz và 🏆 JLPT Mock Exam là 2 mục nổi bật) **khớp với hiện trạng đã triển khai**, chỉ cần thêm 2 mục mới vào `review_screen.dart` (đang là `ListView` các `_ReviewRow`, xem `lib/features/review/review_screen.dart:47`):

```
Ôn tập (/review)
├── 📅 Today's Review        /review/today            (đã có)
├── 📚 Vocabulary Review     /vocabulary/flashcards    (đã có, tên hiển thị "Flashcard Từ vựng")
├── 📝 Grammar Review        /grammar                  (đã có)
├── 🈶 Kanji Review          /kanji                    (đã có)
├── 🎧 Listening Review      —                         (chưa có, xem REVIEW_DESIGN.md §15.6)
├── 🗣 Speaking Review       —                         (chưa có, xem REVIEW_DESIGN.md §15.7)
├── 🤖 AI Review Coach       /review/coach             (đã có)
├── 📒 Mistake Notebook      /review/mistakes          (đã có, tên hiển thị "Sổ tay lỗi")
├── 📊 Statistics            /review/statistics        (đã có)
├── 🎲 Mixed Quiz ⭐         /review/mixed-quiz        (đã có)
└── 🏆 JLPT Mock Exam ⭐     /review/jlpt-exam         (mới — tài liệu này)
```

Không cần đổi kiến trúc `ReviewScreen`, chỉ thêm 2 `_ReviewRow` mới trỏ route mới — đúng tinh thần "tái dùng pattern có sẵn" đã áp dụng cho toàn bộ Review Module.

## Addendum B — 🔥 AI Challenge Mode (spec rút gọn)

Đề xuất bổ sung của người dùng: đề mini AI sinh **mỗi ngày** (10–15 phút), theo dữ liệu học/lỗi riêng từng người, kết hợp Từ vựng + Kanji + Ngữ pháp + Đọc hiểu + Nghe + AI Kaiwa.

- **Quan hệ với AI Mock Exam (§3, §11)**: AI Challenge Mode là **bước mở rộng tiếp theo** của AI Mock Exam — dùng chung engine sinh đề theo lỗi (§11) nhưng (a) chạy mỗi ngày tự động thay vì người dùng tự bấm, (b) thêm phần Speaking/AI Kaiwa mà AI Mock Exam JLPT không có (JLPT thật không thi nói), (c) không cần giữ đúng cấu trúc điểm JLPT — chấm theo XP/streak như Review Module, không theo `scaledScore`.
- **Vì sao xếp là mở rộng, không phải MVP**: phụ thuộc *đồng thời* AI Mock Exam (đã cần AI infra + Reading content) **và** AI Memory Review (đã được `REVIEW_DESIGN.md` §13 khuyến nghị "mở rộng sau MVP" vì là tính năng phức tạp nhất). AI Challenge Mode gộp cả hai + thêm ràng buộc "mỗi ngày 1 đề khác nhau" (cần theo dõi đã sinh đề hôm nay chưa, tránh gọi AI trùng) → rủi ro triển khai cao nhất trong toàn bộ phạm vi đã bàn.
- **Đề xuất thứ tự MVP thực tế**: Dashboard/Today's/3 Review đã có (theo `REVIEW_DESIGN.md` §18) → Mixed Quiz (đã xong) → JLPT Mock Exam phần Vocab/Grammar/Listening (tài liệu này, tái dùng nhiều nhất) → AI Review Coach/AI Mock Exam → **AI Challenge Mode xếp cuối cùng**, vì mỗi bước trước là điều kiện cần của bước sau.
- Chi tiết IA/wireframe/data model đầy đủ cho AI Challenge Mode: **để ngỏ, chưa đặc tả** trong tài liệu này — nên mở tài liệu riêng (`docs/AI_CHALLENGE_MODE_DESIGN.md`) khi các phần điều kiện trên đã triển khai, tránh đặc tả chi tiết cho thứ còn quá xa để tránh lỗi thời trước khi code tới.

## Trạng thái soạn

- [x] Đặc tả đủ 6 Exam Mode, 4 section, Settings, Exam Screen, Reading, Listening, After Exam, AI Analysis, Statistics theo prompt gốc.
- [x] Có data model khái niệm, state management Riverpod, widget tree, animation, responsive, accessibility.
- [x] Phân biệt MVP/mở rộng/cần xác nhận (§19).
- [x] Tích hợp đề xuất IA Review tổng (Addendum A) và đánh giá AI Challenge Mode (Addendum B) theo đúng thứ tự phụ thuộc thực tế, không hứa hẹn quá phạm vi.
- [ ] Chưa triển khai source code — đúng phạm vi giai đoạn hiện tại.
- Bước tiếp theo: người dùng trả lời §20, đặc biệt câu 1–4 (thời gian/thang điểm/nguồn Reading/audio Listening thật) vì đây là 4 điểm chặn triển khai lớn nhất, sau đó mở task implementation riêng ưu tiên Vocab/Grammar/Listening section (tái dùng nhiều nhất, rủi ro thấp nhất).

## Cập nhật 2026-08-06 — rút từ 6 xuống 3 Exam Mode

Tại thời điểm này chỉ Full Exam và Mini Test có code thật; Section Practice,
Custom Test, Weak Point Test, AI Mock Exam vẫn là stub "đang phát triển"
(xem `jlpt_exam_mode_screen.dart`). Theo yêu cầu người dùng, rút màn "Chọn
chế độ thi" từ 6 xuống còn 3:

- **Bỏ hẳn** Weak Point Test — trùng mục đích với "Weak Point Mini" đã có
  sẵn trong Mini Test (§ Mini Test đã triển khai, xem
  `docs/JLPT_MINI_TEST_DESIGN.md`).
- **Bỏ hẳn** AI Mock Exam — cùng lý do đã bỏ AI Mini Test khỏi Mini Test
  (2026-08-06): AI tự soạn đề không nằm trong phạm vi sản phẩm.
- **Gộp** Section Practice vào Custom Test — chọn đúng 1 section + không
  giới hạn giờ trong Custom Test cho kết quả tương đương Section Practice.

§3, §19 ở trên giữ nguyên làm lịch sử đặc tả gốc, không xoá — 3 chế độ còn
lại (Full Exam/Mini Test/Custom Test) là phạm vi thật hiện tại.
