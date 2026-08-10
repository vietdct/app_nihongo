# Current Progress

> Đây là trạng thái hiện tại, không phải nhật ký. Mỗi lần bàn giao hãy viết đè và giữ dưới khoảng 100 dòng.

## Mục tiêu

Đổ toàn bộ dữ liệu N5 (kanji, từ vựng, ngữ pháp) từ 4 PDF người dùng cung cấp
vào Supabase production, tổ chức theo khung 25 bài Minna no Nihongo Shokyu I.
Đã hoàn tất, đã apply production. Không có việc dở dang.

## Trạng thái — đã apply production (chưa commit git)

- **Trích xuất + seed nội dung mới**: 57 kanji, 1276 từ vựng, 60 ngữ pháp mới
  từ PDF (vision-read, không OCR vì PDF là ảnh scan). File:
  `supabase/seed_content_n5_full.sql` (đã apply, có patch UUID trùng cho 2
  điểm ngữ pháp `~に~`/`~と~` — xem comment đầu file).
- **Bài 11-23**: tạo mới 13 bài, gắn 60 điểm ngữ pháp mới + 2 điểm patch vào
  đúng bài theo chủ đề ngữ pháp thực tế (tự nhóm, KHÔNG phải mục lục SGK gốc
  vì WebSearch lỗi trong phiên, không tra cứu đối chiếu được). File:
  `supabase/seed_content_n5_lessons_11_23.sql` (đã apply).
- **Bài 24-25 + gắn từ vựng/kanji vào bài**: tạo thêm Bài 24-25, gắn 315 từ
  vựng + 71 kanji (khớp string với danh sách từ-theo-bài MNN tái hiện từ trí
  nhớ, độ tin cậy Bài 1-13 cao, Bài 14-25 thấp hơn) vào lesson_items. File:
  `supabase/seed_content_n5_lesson_links.sql` (đã apply).
- **Bài 24-25 (ngữ pháp)**: 2 bài này ban đầu gần như trống (PDF ngữ pháp
  nguồn không có nội dung giáp ranh N4). Theo yêu cầu người dùng, đã tự viết
  4 điểm ngữ pháp từ trí nhớ (~ば, ~ば~ほど, ~のに cho Bài 24; 受身形 giới
  thiệu cho Bài 25) — độ tin cậy THẤP hơn phần trích trực tiếp từ PDF, coi là
  bản nháp. File: `supabase/seed_content_n5_lesson24_25_grammar.sql` (đã
  apply). Người dùng đã xác nhận CHỐT ở mức này cho từ vựng (Bài 24 = 3 từ +
  1 kanji, Bài 25 = 1 từ — chỉ đúng số khớp được thật, không bịa thêm từ mới
  ngoài PDF nguồn) — không cần làm thêm việc này nữa trừ khi có nguồn mới.
- **Bug refresh dữ liệu về máy (đã tìm và sửa)**: `ContentRepositoryImpl.
  refreshFromRemote` (lib/data/repositories/content_repository_impl.dart)
  bị 2 lỗi khiến app không bao giờ đồng bộ đủ dữ liệu mới: (1) fetch
  `vocabulary` không phân trang → PostgREST cắt còn đúng 1000/1530 dòng;
  (2) fetch `vocabulary_meanings` bằng `.inFilter` với ~1000-1530 ID cùng
  lúc → URL quá dài, server trả 400, exception làm dừng luôn các bước sau
  (kanji/grammar/lessons không bao giờ được refresh). Đã sửa: thêm
  `_fetchAllRows()` phân trang bằng `.range()` cho vocabulary/kanji/
  grammar_points/lessons, và chia `vocabulary_meanings` thành lô 150 ID/lần.
  Đã verify logic đúng bằng cách gọi thử REST API trực tiếp (lấy đủ
  1530/1530 vocab, 1534 meanings, không lỗi). **Chưa verify lại qua UI thật**
  vì simulator bị lỗi input kẹt suốt phiên (xem "Vấn đề còn lại").
- Số liệu hiện tại trên production: `lessons`=25, `kanji`=91,
  `vocabulary`=1530, `grammar_points`=118, `lesson_items` (vocab=443,
  kanji=96, grammar=118).
- **Giới hạn đã biết**: phần lớn 1530 từ vựng (~1087 từ) và 20 kanji còn lại
  CHƯA gắn vào bài cụ thể nào — vì kho từ lõi MNN (~400 từ/25 bài theo trí
  nhớ tái hiện) nhỏ hơn nhiều so với tổng từ trích từ 4 PDF nguồn (nhiều từ
  bổ sung/trùng nghĩa ngoài SGK lõi). Các từ này vẫn dùng được bình thường
  qua tìm kiếm/ôn tập/quiz, chỉ không hiện trong danh sách "từ vựng của bài".
  Nghe/Đọc (listening/reading) chưa có PDF nguồn nên chưa làm.

## Kiểm tra

- Verify bằng SQL trực tiếp trên production (không test được local vì máy
  không có Docker) — đã confirm số liệu ở trên qua `supabase db query
  --linked`.
- Verify UI bằng simulator: Home, danh sách Kanji hiển thị đúng dữ liệu mới.
  Grammar/Lesson tab bị cản bởi lỗi input kẹt định kỳ của simulator (vấn đề
  môi trường đã gặp nhiều lần) — không verify sâu được qua UI, đã bù bằng
  verify SQL trực tiếp.

## Vấn đề còn lại

- 5 file SQL seed (`seed_content_n5_full.sql`,
  `seed_content_n5_lessons_11_23.sql`, `seed_content_n5_lesson_links.sql`,
  `seed_content_n5_lesson24_25_grammar.sql`) đã apply production nhưng
  **chưa commit git**. Code fix `content_repository_impl.dart` cũng **chưa
  commit**.
- Đã verify bằng ảnh chụp màn hình thật từ người dùng: Từ vựng 1530/1530,
  Kanji 91/91, Ngữ pháp 118/118, dropdown chọn bài lên tới Bài 25 — bug
  refresh đã hết, xác nhận OK trên simulator sau khi sửa
  `content_repository_impl.dart`.
- Việc gắn bài cho Bài 11-25 và cho phần lớn từ vựng/kanji, cùng 4 điểm ngữ
  pháp Bài 24-25, dựa trên trí nhớ tái hiện, không đối chiếu được nguồn
  chính thức — nên coi là bản nháp tổ chức ban đầu, có thể cần rà soát lại
  nếu người dùng có bản mục lục MNN gốc.

## Bước tiếp theo

1. Hỏi người dùng có muốn commit toàn bộ (5 file seed SQL + code fix
   `content_repository_impl.dart`) vào git không.
2. (Tuỳ chọn) Nếu người dùng có PDF/nguồn Nghe-Đọc N5, tiếp tục làm nốt phần
   đó theo đúng scope ban đầu.
