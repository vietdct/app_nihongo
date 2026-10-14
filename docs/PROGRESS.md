# Current Progress

> Đây là trạng thái hiện tại, không phải nhật ký. Mỗi lần bàn giao hãy viết đè và giữ dưới khoảng 100 dòng.

## Luyện tập 4 phần — Đợt 1+2 (2026-10-11) — CHƯA commit, CHƯA apply DB
- Yêu cầu: Từ vựng/Ngữ pháp/Kanji/Nghe hiểu; N5–N1 vs IT khác chiến lược ra đề; không tự phát âm ở bất kỳ đâu (kể cả Thi thử).
- Đợt 1 (xong): bỏ tự phát âm ở `quiz_screen.dart` + `exam_runner_screen.dart` (không tự đọc câu hỏi; `dispose` huỷ lượt đọc). Đồng hồ câu nghe chỉ chạy sau khi bấm Play lần đầu (`_timerWaitsForAudio`).
- Đợt 2 (xong phần code): `lib/domain/services/practice_strategy.dart` (`PracticeProfile` jlpt/it, `JlptPracticeStrategy` giữ hành vi cũ, `ItPracticeStrategy`); `quiz_providers.dart` dùng chiến lược thay cho `isIt`.
  IT: Ngữ pháp = câu soạn sẵn → "câu nào dùng đúng mẫu" → nghĩa/mẫu; Kanji = hỏi cách đọc CẢ TỪ (`generateWordReadingQuestions`, nhiễu = nhầm nguyên âm/trường âm/đục-trong/っ; 323/480 từ đủ điều kiện); Từ vựng cloze nhiễu cùng loại từ + lời giải (câu + dịch).
  `QuizQuestion` thêm `explanationVi`/`sourceNote`; `_FeedbackPanel` hiện "Giải thích" sau khi trả lời. Thẻ Kanji IT ở `quiz_category_screen.dart` đếm "n từ có Kanji" theo phạm vi (không còn "toàn khóa").
- Dữ liệu (CHƯA apply — user rà soát rồi chạy theo thứ tự):
  1. `supabase/migrations/20261011090000_grammar_practice_questions.sql` (bảng mới + RLS đọc công khai)
  2. `supabase/seed_grammar_practice_it_b2.sql` — 62 câu điền chỗ trống, 15 bài. Câu = NGUYÊN VĂN từ 練習① (`nihongo_B2/第N課/04-luyen-tap.md`, đã script kiểm tra), `source='book'` + `source_ref`. 3 đáp án nhiễu + lời giải do Claude soạn → cần người biết tiếng Nhật đọc lướt. Không gán `grammar_point_id`. Bài 8/12/13 ít câu vì phần còn lại không tạo được nhiễu chắc chắn sai.
  App đọc bảng qua `grammar_practice_providers.dart` (Supabase trực tiếp như `listening_dialogues`, KHÔNG mirror Drift; lỗi/chưa có bảng → rỗng, app vẫn chạy).
- Test mới: `test/domain/practice_strategy_test.dart`, `test/features/quiz/{quiz_screen_audio,quiz_explanation,level_strategy_providers}_test.dart`, `test/features/review/exam_runner_audio_test.dart`. `flutter test` 227 pass; `flutter analyze lib test` 0 error/warning.
- Verify simulator (iPhone 17 Pro, light): IT → Luyện tập (4 thẻ) → Kanji hỏi "出張" 4 cách đọc + khung Giải thích. Chưa xem: Ngữ pháp curated (cần apply DB), dark mode, iPhone nhỏ.
- Còn lại: khung phản hồi cao hơn khi có lời giải dài → che bớt đáp án trên màn nhỏ (cần xem tay); câu Nghe hiểu IT chưa thêm dạng mới (45 câu sẵn có); Từ vựng IT chưa có dạng "chọn thuật ngữ theo tình huống" riêng; N5–N1 chưa có câu soạn sẵn.

## Redesign UX khóa IT (phiên 2026-10-03) — CHƯA commit

- Mới: `lib/features/lesson/it_learning_hub.dart` (IT Learning Hub: tiến độ khóa, Tiếp tục học, 4 lối vào nhanh, Lộ trình 15 bài).
  `LessonListScreen` rẽ sang Hub khi level == IT; Home thêm nút "Xem lộ trình khóa học" (`/lessons` trước đó không có lối vào).
- Runner: `LessonProgressHeader` thêm nhãn "n/5 · PHASE" (mọi level); "chốt chặng" `widgets/lesson_phase_complete_sheet.dart`
  hiện khi qua pha (trừ Input), số liệu đếm thật từ danh sách bước (không có điểm số — chưa lưu kết quả từng câu).
- IT: tiêu đề Từ vựng/Ngữ pháp kèm số lượng, "Học theo bài · Flashcard", Kanji = "Kanji trong từ vựng IT" + ghi chú nguồn.
- Sửa sau khi xem simulator: `deriveLessonObjectives` (mẫu câu dài chỉ nêu số lượng, trước đó nối cả đoạn hội thoại thành 1 khối),
  thẻ ngữ pháp thu nhỏ cỡ chữ khi tiêu đề dài (`lesson_understand_cards.dart`), Review hiện "Đang ôn: Từ vựng a · Ngữ pháp b".
- Verify simulator (iPhone 17 Pro, light): Hub, header Runner, chốt chặng (Understand → Practice: 45 thẻ = 34 từ + 11 mẫu câu), Từ vựng IT, khôi phục bước đã lưu.
  Chưa xem tay: bản sửa cỡ chữ ngữ pháp + mục tiêu (đã build lại nhưng chưa mở lại), Kanji/Ngữ pháp IT, dark mode, iPhone nhỏ/Pro Max.
- Dữ liệu cần rà (seed_content_it_b2.sql): ví dụ của 人事管理 có bản dịch không khớp câu tiếng Nhật.
- NEEDS DATA: tiến độ từng loại (từ/nghe/ngữ pháp đã học trong bài), pha hiện tại lưu riêng. Chưa làm: lọc Ngữ pháp theo bài, Mission/Review có ngữ cảnh.

## Mục tiêu hiện tại

Redesign Vocabulary Detail Bottom Sheet khớp 100% mockup Claude Design
"Vocabulary Detail v2" (ちゃんと). ĐÃ XONG phần UI + 1 từ demo có đủ nội dung.
CHƯA commit git.

## Khoá IT (phiên gần nhất) — nhập lại 第1課–第15課 theo `nihongo_B2/`

Nội dung IT cũ (AI tự soạn, `seed_content_it_original.sql`) đã bị thay hoàn toàn
bằng giáo trình *ITの日本語 B2 会話編* của user. Đã apply production:

- `supabase/seed_content_it_b2.sql` (chỉ insert/upsert, idempotent): 15 bài,
  480 từ vựng (gồm bảng "Cụm từ"), 86 mẫu câu, 566 `lesson_items`.
- `supabase/seed_listening_it_b2.sql`: 45 câu nghe (3/bài), hội thoại nguyên văn
  từ sách; 3 đáp án sai mỗi câu do Claude tự soạn — user nên đọc lướt.
- Chưa nhập: 練習 (bài tập) và đáp án `日本語/` — app chưa có loại nội dung này.
- Đã reset `user_lesson_progress` IT (user tự chạy xoá).
- Flashcard theo bài: `vocabulary_home_screen.dart` (mục "Flashcard theo bài" →
  `/vocabulary/flashcards?lesson=<id>&shuffle=1`), `vocabulary_flashcard_screen.dart`
  (bộ lọc bài + toggle Ngẫu nhiên/Theo sách), `app_router.dart` (query params).
  `flutter analyze` sạch; đã verify trên simulator (IT bài 1: 34 thẻ).
- Ví dụ từ vựng IT: `seed_content_it_b2.sql` giờ ghi `example_jp/vi` + extra cho cả 480 từ
  (286 từ lấy nguyên văn câu trong sách kèm bản dịch, 194 từ do Claude soạn — user nên rà soát).
- Chi tiết từ vựng thiết kế lại: màn mới `vocabulary_lookup_screen.dart` (từ file
  thiết kế của user, dùng font đóng gói sẵn, không thêm google_fonts). `showVocabDetailSheet`
  (`vocabulary_list_screen.dart`) giờ push màn này; class `VocabDetailSheet` cũ còn nguyên
  nhưng không còn được mở. So sánh (`comparisons`) chỉ ちゃんと có, chưa hiển thị ở màn mới.
- Lookup v2 đợt 2: chữ trang trí kanji dời lên góc trên phải (không còn nằm sau nút Nghe);
  chọn tốc độ 0.5–1.5× (`AudioPlaybackSpeed` trong `core/services/jp_voice_prefs.dart`, lưu
  SharedPreferences `jp_tts_speed`, toàn app, mặc định 1.0×); nút Nghe có trạng thái đang phát
  (bấm lại để dừng); ví dụ hiện 2 câu + "Xem thêm"; mục "使い方 · Cách dùng" (mở rộng, ẩn nếu
  không có dữ liệu); tab Kanji có On/Kun; tab Liên quan thêm "Từ gần nghĩa"; nút Chưa nhớ/Đã thuộc
  tô nổi theo trạng thái. Thẻ kanji ở tab Phân tích Kanji bấm được → mở `KanjiDetailScreen`
  (thêm tham số `levelId` + `kanjiByLevelProvider` để mở kanji của cấp độ khác, vì IT không có
  bộ kanji riêng). Nét vẽ kanji: `supabase/seed_kanji_stroke_data.sql` (KanjiVG r20250816, đã
  apply production) bổ sung 884 chữ → 918/918 kanji (N5/N4/N2) có `stroke_data`, khớp 100% với
  34 chữ đã có từ trước. Sau đó thêm 644 chữ có trong từ vựng nhưng chưa có bảng `kanji`
  (`supabase/seed_kanji_missing_from_vocab.sql`, đã apply production; cấp = cấp thấp nhất của từ
  chứa chữ, chỉ-có-ở-IT xếp N2): nay N5 427 / N4 344 / N2 791, đều có `stroke_data`. On/Kun +
  số nét từ Kanjidic2, Hán Việt + nghĩa tiếng Việt do Claude soạn (đối chiếu Unihan) — user nên
  rà soát; 匂 届 枠 捗 丼 để trống Hán Việt. `seed_kanji_stroke_count_fix.sql` điền `stroke_count`
  từ số nét (619 chữ N2 trước đó null). App: `refreshFromRemote` tải thêm Kanji cấp khác mà từ
  vựng dùng (`_syncKanjiOfOtherLevels` + `upsertKanji`); `watchKanji` cho cấp không có Kanji riêng
  (IT) trả về Kanji có trong từ vựng cấp đó (`watchKanjiUsedByVocabulary`) → tab Kanji IT có 452
  chữ, đều vẽ được nét. Bấm 1 chữ Kanji (danh sách, gần đây, Kanji hôm nay, tìm bằng vẽ, họ Kanji,
  thẻ Kanji trong từ vựng) giờ chỉ xem đúng chữ đó (`KanjiDetailScreen(single: true)`, route
  `/kanji/:id` không có `extra`); bộ thẻ vuốt chỉ còn ở "Tiếp tục học" (`extra: 'deck'`) và Smart
  Review (`extra` = Set id). Số thứ tự nét (`kanji_stroke_canvas.dart`, `_NumberLayout`): chữ số cam có viền trắng đặt ở
  chỗ trống gần điểm bắt đầu nét, chỉ hiện cho nét đã/đang vẽ (nét đang vẽ có ô cam), không ô đen/
  đường nối (trừ khi số bị đẩy xa >9); nút "123" góc dưới phải khung để ẩn/hiện số. Nghe hiểu hội thoại: `core/services/dialogue_player.dart` (segment = 1 lượt thoại, phát tuần tự, nghỉ 300ms khi đổi người, tạm dừng/tiếp tục đúng segment/nghe lại, tô lượt đang đọc, `currentSpeaker`) + `core/services/speaker_voices.dart` (`assignSpeakerVoices`: mỗi nhân vật 1 giọng ja-JP thật khác nhau, xen kẽ nữ/nam; thiếu giọng → dùng chung xoay vòng + tách bằng cao độ 1.35/0.7 — simulator chỉ có 1 giọng ja-JP là Kyoko; dùng cả ở `exam_runner_screen` khi thi/Review→Nghe hiểu); `ListeningTurn.tryParse` (dữ liệu cũ thiếu speaker → 'A', bỏ lượt rỗng); script hiện avatar + màu theo nhân vật (≥2 người) và nút 🔊 từng dòng; nhãn "Đang phát · B · 2/3". Không có cache audio (TTS máy đọc trực tiếp, không tạo file). Test: `test/core/dialogue_player_test.dart`, `dialogue_voices_test.dart`, `test/shared/dialogue_script_view_test.dart` + `shared/dialogue_script_view.dart` (script che bằng ＊,
  nút mắt cuối mỗi lượt để hiện, "Hiện tất cả"); dùng ở `QuizScreen` (Nghe hiểu) và
  `LessonListeningView`. Màn Nghe hiểu (`QuizScreen`, câu hội thoại) dùng bố cục riêng
  `quiz/widgets/listening_question_body.dart`: `ListeningPhase` (listening/answered/timeout/reviewing)
  là nguồn duy nhất quyết định dựng Script — chỉ `reviewing` (đã trả lời + bấm "Scriptを見る") mới dựng
  `DialogueScriptCard`, lúc nghe chỉ có placeholder "Script đã ẩn"; hết giờ → bottom sheet
  `showListeningTimeoutSheet`; hạn giờ câu hội thoại = 20s + 0,2s/ký tự (30–180s); tốc độ 0.75/1.0/1.25×.
  Test: `test/features/quiz/listening_question_body_test.dart`. `exam_runner_screen.dart` (thi thử) chưa đổi. Chưa có dữ liệu: pitch accent, romaji, trái nghĩa, collocation.
  Chưa test iPhone nhỏ/Pro Max, chưa test tay mục Cách dùng (chỉ ちゃんと có dữ liệu).

## Mục tiêu trước đó (vocabulary sheet)

## Việc đã hoàn thành (phiên 2026-08-11, sau phiên grammar_meanings)

1. **UI khớp thiết kế** (`lib/features/vocabulary/vocabulary_list_screen.dart`):
   - Sheet co giãn theo nội dung, cap 88% màn hình (không cố định %), tay cầm
     cố định phía trên, nội dung cuộn riêng — `LayoutBuilder` + `ConstrainedBox`
     + `Flexible(SingleChildScrollView)` thay cho `FractionallySizedBox` cũ.
   - Header: chữ 40px không FittedBox, nút "Nghe" weight 600, style khớp
     pixel với mockup (đã dùng đúng `AppColors` sẵn có — bảng màu trùng
     mockup gần như 100%).
   - Nghĩa: luôn đánh số (kể cả 1 nghĩa).
   - Ví dụ: gộp `exampleJp/Vi` + `extraExamplesJp/Vi` (nhiều câu/nghĩa),
     highlight từ vựng trong câu bằng badge cam (`WidgetSpan`).
   - **4 section mới theo mockup**: Cách dùng thường gặp (xanh lá), Sắc thái
     (hồng, hỗ trợ `**bold**` inline), Từ gần nghĩa (ngọc lam, khác với "Từ
     liên quan" cũ — đó là từ ghép cùng Kanji, đây là đồng nghĩa), So sánh
     (2 thẻ song song), Lỗi thường gặp (đỏ, dùng `AppColors.danger` có sẵn).
     Tất cả ẩn hoàn toàn nếu không có dữ liệu (không bịa).
2. **Schema mới** (đã hỏi user, chọn "tự biên soạn nội dung mẫu"):
   - Migration `supabase/migrations/20260811000000_vocabulary_extra_content.sql`
     (12 cột mới trên `vocabulary`: common_usage_*, nuance_points,
     similar_words*, comparison_*, common_mistake_*) — đã apply production.
   - Migration `20260811010000_vocabulary_meanings_extra_examples.sql`
     (extra_examples_jp/vi trên `vocabulary_meanings`, cùng mẫu
     `grammar_points.extra_examples_jp/vi`) — đã apply production.
   - `lib/data/local/tables.dart` (schemaVersion 10→11),
     `lib/domain/entities/vocabulary.dart` (+`VocabUsageExample`,
     `VocabSimilarWord`, `VocabComparison`), `vocab_meaning.dart`
     (+`extraExamplesJp/Vi`, `allExamples`), `content_repository_impl.dart`
     (decode/encode 2 chiều Supabase ⇄ Drift).
   - `dart run build_runner build`: OK. `flutter analyze`: sạch (8 info
     RadioGroup cũ, không liên quan).
3. **Nội dung demo**: `supabase/seed_vocab_extra_content_chanto.sql` — đã
   biên soạn + apply cho ちゃんと (N4, id `9b0ce664-2f33-5e99-90f7-fe4062d49aae`).
   Các từ khác chưa có nội dung 4 mục mới (sẽ ẩn cho tới khi biên soạn thêm).
4. **Verify trên iPhone 17 Pro Simulator**: mở ちゃんと qua search, xác nhận
   trực quan đúng — Cách dùng thường gặp, Ví dụ (có highlight), Sắc thái, Từ
   gần nghĩa, So sánh đều hiện đúng màu/layout như mockup. Phần cuối "Lỗi
   thường gặp" (title đỏ) hiện đúng nhưng chưa chụp được nội dung đầy đủ do
   gesture cuộn trong sheet bị kẹt trên simulator (không phải lỗi code — các
   section trước đó đã cuộn/hiện đúng nhiều lần).

## File đã sửa/thêm (phiên này)

- Sửa: `vocabulary_list_screen.dart`, `tables.dart`, `app_database.dart`,
  `content_repository_impl.dart`, `vocabulary.dart`, `vocab_meaning.dart`.
- Mới: 2 migration + 1 seed content ở trên.
- `app_router.dart`: đã sửa tạm để test rồi revert — `git diff` sạch.

## Vấn đề còn lại

- Chỉ ちゃんと có đủ nội dung 4 mục mới; các từ khác cần biên soạn thủ công
  từng từ (không tự động/AI bịa hàng loạt — theo quyết định của user).
- Chưa verify hết nội dung "Lỗi thường gặp" trên simulator (xem trên) — nên
  double-check khi có dịp.
- Chưa test Android/tablet/iPhone nhỏ.
- Chưa commit git (gồm cả phiên grammar_meanings trước đó).

## Bước tiếp theo

1. Hỏi user có muốn commit không.
2. Nếu cần mở rộng nội dung 4 mục mới cho từ khác — biên soạn thêm seed SQL
   tương tự `seed_vocab_extra_content_chanto.sql`.

## Luyện tập IT (2026-10-03) — CHƯA commit
- Tab Lessons (`QuizCategoryScreen`) với khóa IT: tiêu đề "Luyện tập", hiện bài đang học, chọn phạm vi (Bài hiện tại / Toàn bộ IT) + số câu 5/10/20 (state cục bộ), thẻ có số lượng thật, link "Ôn tập hôm nay (SRS)". N5–N1 giữ nguyên.
- Route `/quiz/:category` và `/listening` nhận query `lesson`, `count`. `levelCategoryQuizQuestionsProvider` đổi key thành record `QuizRequest`.
- Kanji IT không gắn theo bài → tự rơi về toàn khóa (thẻ ghi "· toàn khóa").
- Đã thêm: phạm vi "Các bài đã học" (bài đã hoàn thành hoặc đã bắt đầu, chip chỉ hiện khi >1 bài), số câu áp dụng cho Nghe hiểu toàn IT. Query `lesson` nhận nhiều id cách nhau bằng dấu phẩy.
- Đã có sẵn, không làm lại: dạng Nghĩa→JP/Cách đọc, màn kết quả có "Làm lại".
- Đã thêm (IT): Ngữ pháp có dạng "Câu nào dùng đúng mẫu X?" (từ exampleJp thật, chỉ mẫu tiêu đề ≤20 ký tự, ví dụ ≤60), Từ vựng có tối đa 1/3 câu điền từ vào câu ví dụ thật (398/480 từ đủ điều kiện). Tiêu đề quiz hiện 第N課 / Các bài đã học. Test: `test/domain/grammar_sentence_pick_test.dart`.
- DỮ LIỆU CẦN USER RÀ: 44/86 mẫu ngữ pháp IT có `title` >20 ký tự (nhiều mẫu là cả câu hội thoại, không phải mẫu câu); 7 mẫu thiếu `example_jp`; một số `meaning` ngữ pháp là ghi chú (vd "Giới thiệu trách nhiệm phía SES").
- Chưa làm: feedback sau trả lời Ngữ pháp (giải thích + ví dụ), điền chỗ trống Ngữ pháp kiểu practice_tokens (không có dữ liệu), quay về Lesson Runner từ Practice (chưa test).
- Files: `quiz_category_screen.dart`, `quiz_providers.dart`, `app_router.dart`. Đã verify trên simulator (iPhone 17 Pro, light mode).

## Voice profile cho Nghe hiểu (2026-10-05) — CHƯA commit
- `speaker_voices.dart`: thêm `VoiceProfile` (natural 1.0/1.0, calm pitch 0.92 rate×0.94, bright pitch 1.08 rate×1.05), gán xoay vòng theo thứ tự xuất hiện của nhân vật (khớp màu script). Bỏ các mức pitch cực đoan cũ (1.35/0.7). Giọng ja-JP thật vẫn ưu tiên khác nhau; thiếu giọng thì dùng chung nhưng khác profile.
- `dialogue_player.dart` và `exam_runner_screen.dart`: rate = tốc độ chọn × hệ số profile; pitch theo profile, không đổi theo tốc độ.
- Cần nghe thử trên máy thật (simulator không đại diện đủ giọng ja-JP) để chỉnh số nếu quá nhẹ/quá rõ.

## Giọng đọc tự nhiên hơn (2026-10-05) — CHƯA commit
- Nguyên nhân giọng đơ: mỗi màn tự tạo FlutterTts với rate 0.45 (chậm hơn mặc định 0.5), không chọn giọng chất lượng cao, pitch bị chỉnh.
- `jp_voice_prefs.dart`: `kTtsNormalRate=0.5` (1.0× = tốc độ thường), `voiceQualityRank`, `loadJapaneseVoices` sắp giọng premium/enhanced lên đầu, `configureJpTts` (khởi tạo chung + giọng đã lưu hoặc giọng tốt nhất), `prepareJpForSpeech` (bỏ 〜, … → nghỉ, Latin+さん), `JpSpeedChips`/`showJpSpeedSheet`.
- Áp dụng cho: `JpSpeakButton` (từ vựng/kanji/ngữ pháp; giữ nút loa để chỉnh tốc độ), `quiz_screen` (câu đơn + picker có hàng tốc độ), `exam_runner_screen`, `vocabulary_lookup_screen`, `DialoguePlayer`. Kaiwa chưa đổi.
- VoiceProfile nhẹ hơn: calm 0.96/×0.97, bright 1.04/×1.03.
- Giới hạn: máy chỉ có giọng "default" thì vẫn nghe hơi máy móc; picker có gợi ý tải giọng Enhanced/Premium trong Cài đặt iOS.

## Audio hội thoại tạo sẵn (cloud TTS) — 2026-10-05
- Lý do: máy/simulator chỉ có 1 giọng Nhật (Kyoko) → TTS máy không ra 2–3 giọng.
- `DialogueAudio` (`lib/core/services/dialogue_audio.dart`): phát mp3 từ bucket public `listening-audio`, tên file = `s{slot%3}/{FNV-1a64 nội dung}.mp3`; thiếu file/mất mạng → quay về TTS máy. `DialoguePlayer` dùng nó trước mỗi lượt.
- `tool/generate_listening_audio.py` tạo file (Google Cloud TTS Neural2 B/C/D = 3 giọng; 247 file, ~10k ký tự, N5 + IT). Cần `GOOGLE_TTS_API_KEY`, rồi `supabase storage cp -r build/listening_audio ss:///listening-audio --linked --experimental`.
- Migration `20261005090000_listening_audio_bucket.sql` đã apply production (bucket public).
- 2026-10-05: đã tạo đủ 247 file (Gemini TTS: Kore=slot0, Charon=slot1; chưa có hội thoại 3 người nên slot2/Puck chưa dùng) và upload bucket `listening-audio` (s0/, s1/ ở gốc; còn thư mục thừa `listening_audio/` chưa xoá được). Script hỗ trợ `--provider gemini`, `GEMINI_TTS_MODEL`.
- 2026-10-06 Luyện nói: `DialogueAudio.playSentence` + `sentenceAudioPath` (`m/{hash}.mp3`), `kaiwa_shadowing_screen.dart` phát file (0.9×) trước, thiếu thì TTS máy. Đã tạo đủ 488 câu (`--source shadowing`, giọng Kore, ~14MB) và upload `m/` vào gốc bucket.
- Kaiwa chat vẫn TTS máy: `pickVoiceForStyle` (speaker_voices.dart) chọn giọng máy đúng giới theo `voice_style` persona, pitch nam thấp hơn.
- Việc còn lại (Luyện nói/Kaiwa): thử trên app (log `[TTS] audio exists=true`); xoá thư mục thừa `listening_audio/` trong bucket; đề thi thử (`exam_runner`), từ vựng, kanji, câu hỏi nghe đơn chưa có audio; xoá/đổi mọi API key đã lộ trong chat.
- Việc còn lại: nghe thử trên app (chạy lại hoàn toàn vì thêm audioplayers); câu hỏi đơn (`displayJp`) vẫn dùng TTS máy; thêm dependency `audioplayers`.

### Audio từ vựng IT (2026-10-06)
- `JpSpeakButton` (`lib/shared/jp_speak_button.dart`) giờ thử `DialogueAudio.playSentence` (thư mục `m/`) trước, không có file → TTS máy.
- `tool/generate_listening_audio.py --source vocab --level IT`: từ + câu ví dụ IT = 873 file (846 còn thiếu, ~11.7k ký tự), vào `m/`. Chưa chạy tạo/upload.
- Lưu ý: màn ngữ pháp chưa có nút loa cho câu ví dụ (chỉ đọc `grammar.title` ở thẻ bài học).

### Audio cloud — trạng thái chốt (2026-10-07)
- Đã upload + xác minh khớp dung lượng 1581 file bucket `listening-audio`: `m/` 1334 (từ vựng+ví dụ IT 873, Luyện nói 488, trùng 27), `s0/` 139 + `s1/` 108 (hội thoại).
- Từ vựng IT + ví dụ + Luyện nói: Cloud TTS giọng **Chirp3-HD-Achernar** (không lời nhắc → hết tiếng Anh/rè); từ đọc theo cột `reading` (nếu reading là "—" thì đọc chính từ). Hội thoại giữ Gemini Kore/Charon; 12 câu lỗi tạo lại bằng Chirp3-HD Kore/Charon.
- `JpSpeakButton` + `vocabulary_lookup_screen.dart` phát file cloud trước (theo tốc độ đã lưu), không có → TTS máy. Kaiwa vẫn TTS máy.
- Script `tool/generate_listening_audio.py`: `--source vocab --level IT`, `--source shadowing`, `--cloud` (ép Cloud TTS), env `GOOGLE_TTS_API_KEY` (key AIza), `GOOGLE_TTS_VOICE`, `GOOGLE_TTS_VOICES` (hội thoại: giọng theo slot), `SHORT_WITH_GEMINI`. File Cloud TTS được thêm thẻ ID3 (nếu không Supabase từ chối 415).
- Bài học: Gemini TTS đọc lời nhắc tiếng Anh/rè với câu ngắn → dùng Cloud TTS; đo lỗi bằng độ dài audio so với số ký tự.
- 2026-10-07: mở rộng `--source vocab --level ALL` (từ N5/N4/N2 + ví dụ, vì màn IT hiện từ liên quan/kanji cấp khác → rơi về giọng máy). Tổng 5258 file bucket (`m/` 5011, `s0/` 139, `s1/` 108) đã khớp. Upload lớn hay bị 504 → chia nhỏ thư mục `m` rồi chạy lại. JpSpeakButton/lookup in log `[TTS] fallback giọng máy: "…"` (debug) để tìm từ còn thiếu.
- 2026-10-07: thêm `--source grammar` (tiêu đề, ví dụ, ví dụ mở rộng, ví dụ nghĩa) và `--source kanji` (cách đọc đầu tiên + câu ví dụ), cùng giọng Achernar. Tổng 7778 file bucket (`m/` 7531, `s0/` 139, `s1/` 108) đã khớp dung lượng (1 file báo lệch chỉ là lỗi HEAD tạm thời). Thêm widget `lib/shared/jp_example_text.dart` (câu + nút loa) cho ví dụ ở màn ngữ pháp (chi tiết, flashcard, ôn, so sánh), thẻ bài học và kanji chi tiết.
- Chưa làm: hội thoại đa giọng bằng Cloud TTS, câu nghe đơn lẻ trong quiz (`quiz_screen.dart`), tin nhắn AI của nhiệm vụ bài học, nút loa riêng cho từng cách đọc kanji trong thẻ bài học. Người dùng đang cân nhắc đổi giọng khỏi Achernar (nếu đổi phải tạo lại ~7500 file và upload lại). Cần xoá/rotate các key đã lộ trong chat.
- Bước tiếp: test màn kanji/ngữ pháp trên simulator (log `[TTS] audio exists=true`, xem `[TTS] fallback giọng máy`), chốt giọng.

- 2026-10-12: đã apply lên production migration `20261011090000_grammar_practice_questions.sql` + `seed_grammar_practice_it_b2.sql` (62 câu / 15 bài / source=book, 1 policy RLS). Verify bằng SQL count.

- 2026-10-12 (tiếp): (1) Từ vựng IT thêm dạng "tình huống → thuật ngữ" (`QuizGenerator.generateVocabSituation`, dùng trong `ItPracticeStrategy.vocabulary`: cloze ≤1/4 + tình huống ≤1/4 + base). Dữ liệu IT thật: 397 từ có ví dụ đủ Nhật+Việt; `part_of_speech` của IT đều null nên nhiễu là từ IT ngẫu nhiên (đã loại nhiễu có nghĩa xuất hiện trong câu tình huống). (2) Giọng đọc Quiz: câu đơn giờ thử file cloud `m/` (`DialogueAudio.playSentence`) trước, thiếu mới dùng TTS máy; câu điền chỗ trống (`QuizQuestion.hasBlank/spokenJp`) ẩn nút loa tới khi trả lời rồi đọc câu hoàn chỉnh. (3) `tool/generate_listening_audio.py --source practice` tạo audio 62 câu đáp án đầy đủ của Ngữ pháp soạn sẵn — CHƯA chạy (cần GOOGLE_TTS_API_KEY), chưa có file thì rơi về giọng máy. `flutter test` 232 pass.

- 2026-10-13 Nghe hiểu IT: audit — 45 câu = 15 hội thoại × 3 câu (nguyên văn モデル会話), đáp án đúng là lựa chọn dài nhất ở 36/45 câu. Tạo `supabase/seed_listening_it_b2_v2.sql` (đã apply production 2026-10-14: 75 câu, 5 câu/bài, 15 bài; verify bằng SQL): (A) viết lại 3 đáp án sai của 28 câu cũ (UPDATE có điều kiện theo đáp án đúng), (B) thêm 30 câu mới (2/bài, cùng hội thoại, dùng lại audio; đáp án đúng đã kiểm chứng có trong hội thoại, câu hỏi + đáp án sai do AI soạn, không có cột nguồn nên không gắn nhãn trong app). Chạy SAU `seed_listening_it_b2.sql` (file đó `delete` toàn bộ hội thoại IT). `DialogueListeningGenerator` ưu tiên hội thoại khác nhau trước khi lặp lại.

- 2026-10-14 Animation Giai đoạn 1 (CHƯA commit): `lib/core/theme/app_motion.dart` (tokens fast 140/standard 220/emphasized 300ms, curve, `reduced(context)`); `lib/shared/motion/{press_scale,animated_progress_bar,fade_switcher}.dart`. PressScale bọc 14 card điều hướng (home, quiz_category, lesson_list, it_learning_hub, vocab/kanji/grammar home) + 4 nút CTA (grammar_home x2, kaiwa_home, login khi không loading); AnimatedProgressBar thay 9 thanh tiến độ tĩnh (home, quiz header, kanji/grammar home, it hub, learning_overview, grammar practice/flashcard, exam runner); FadeSwitcher cho trạng thái tải→dữ liệu ở lesson_list và it_learning_hub. Tất cả tôn trọng `MediaQuery.disableAnimations`. Test: `test/shared/motion_test.dart` (13). `flutter test` 246 pass. Chưa làm: panel mở/đóng (không có panel hiện hữu phù hợp), transition route, quiz/flashcard/listening/XP/confetti (Giai đoạn 2–3).

- 2026-10-14 Animation Giai đoạn 2 (Quiz/Listening/flashcard): thêm `shared/motion/{enter_transition,shake_once,answer_feedback}.dart`. Quiz + Listening: đáp án đổi màu mượt (AnimatedContainer), icon tick/X (không chỉ dựa vào màu), đáp án sai rung 1 lần (≤5px, 320ms), co nhẹ khi nhấn; câu mới vào bằng fade+trượt (EnterTransition theo key câu — không giữ bản cũ nên không bấm nhầm/double-submit); khung phản hồi trượt lên + AnimatedSize (tắt khi giảm chuyển động); nút loa/Play có PressScale; dialogue_script_view dùng token + giảm chuyển động; FlipCard lật tức thì khi giảm chuyển động. Test: `test/features/quiz/quiz_motion_test.dart` (5) + 8 test trong `motion_test.dart`. `flutter test` 259 pass. Chưa làm: confetti/XP tăng số/streak (Giai đoạn 3), flashcard đã có vuốt/lật sẵn nên không đổi thêm.
