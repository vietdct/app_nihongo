# Current Progress

> Đây là trạng thái hiện tại, không phải nhật ký. Mỗi lần bàn giao hãy viết đè và giữ dưới khoảng 100 dòng.

## Mục tiêu

Đổ toàn bộ dữ liệu N5 (kanji, từ vựng, ngữ pháp) từ 4 PDF người dùng cung cấp
vào Supabase production, tổ chức theo khung 25 bài Minna no Nihongo Shokyu I.
Nội dung đã đủ; đang cải thiện độ chính xác gắn dữ liệu vào đúng bài bằng
nguồn tham khảo thật (jes.edu.vn). Không có việc dở dang khẩn cấp.

## Trạng thái hiện tại — đã apply production, CHƯA commit git

- **Nội dung N5**: `lessons`=25, `kanji`=91, `vocabulary`=1530,
  `grammar_points`=119. `lesson_items`: vocabulary=959 (869 khớp chính xác từ
  nguồn thật jes.edu.vn), kanji=96 (96 dòng / 78 kanji duy nhất có gắn bài,
  13/91 kanji CHƯA gắn bài nào — xem mục Kanji bên dưới), grammar=119.
- **Tiêu đề 25 bài (2026-08-10, mới xong)**: đối chiếu lại toàn bộ chủ đề ngữ
  pháp thật từng bài (`scratchpad/grammar_titles_by_lesson.json`, ngoài repo)
  và phát hiện nhiều tiêu đề cũ (viết từ trí nhớ ở phiên trước) bị lệch/đảo
  chủ đề — rõ nhất là Bài 24-25 vẫn giữ tiêu đề cũ "Giả định, tuy nhiên" /
  "Thể bị động" dù nội dung grammar_points đã sửa đúng (cho-nhận/たら) từ
  trước. Đã viết lại đúng cả 25 tiêu đề theo chủ đề thật. File:
  `supabase/fix_lesson_titles.sql` (đã apply, đã verify lại bằng SQL).
- **Kiểm tra Kanji (2026-08-10)**: dump toàn bộ 91 kanji (onyomi/kunyomi/hán
  việt/nghĩa/số nét), đối chiếu kiến thức N5 chuẩn — **không phát hiện lỗi sai
  âm đọc/nghĩa/số nét**. Vấn đề còn lại là GẮN BÀI (lesson_items), không phải
  dữ liệu kanji: chỉ 78/91 kanji có gắn vào bài nào đó, 13 kanji chưa gắn bài,
  nhiều bài (12,14,16-21,25) không có kanji nào cả — cách gắn này là suy đoán
  từ phiên trước, không có nguồn thật để đối chiếu (jes.edu.vn chỉ có
  từ vựng+ngữ pháp theo bài, không có danh sách kanji theo bài). **Chưa sửa**,
  cần quyết định của người dùng nếu muốn làm tiếp (xem Bước tiếp theo).
- **Đối chiếu nguồn thật jes.edu.vn (đợt trước)**: relink 869/1530 từ vựng
  đúng bài (`supabase/relink_vocab_bai1_25_from_source.sql`, đã apply). Sửa
  ngữ pháp Bài 24-25 sai chủ đề, viết lại đúng chủ đề
  (`supabase/fix_lesson24_25_grammar.sql`, đã apply). Ngữ pháp Bài 1-23: thử
  fuzzy-match nhưng ~30% khớp sai → không áp dụng, giữ nguyên cách gắn cũ.
- **Bug refresh dữ liệu (đã sửa, đã verify qua ảnh chụp thật)**:
  `ContentRepositoryImpl.refreshFromRemote` (lib/data/repositories/
  content_repository_impl.dart) thiếu phân trang cho vocabulary + `.inFilter`
  quá dài cho vocabulary_meanings. Đã sửa, user xác nhận qua ảnh: Từ vựng
  1530/1530, Kanji 91/91, Ngữ pháp 118/118, đủ 25 bài.
- **Giới hạn đã biết**: ~660 từ vựng và 13 kanji vẫn chưa gắn vào bài cụ thể
  (vẫn dùng được qua tìm kiếm/quiz). Nghe/Đọc chưa có PDF nguồn nên chưa làm.

## File mới/sửa chưa commit

`content_repository_impl.dart`, `seed_content_n5_full.sql`,
`seed_content_n5_lessons_11_23.sql`, `seed_content_n5_lesson_links.sql`,
`seed_content_n5_lesson24_25_grammar.sql`, `relink_vocab_bai1_25_from_source.sql`,
`fix_lesson24_25_grammar.sql`, `fix_lesson_titles.sql`.

## Kiểm tra

Verify bằng SQL trực tiếp trên production (`supabase db query --linked`,
không test local được vì máy không có Docker) + ảnh chụp simulator thật từ
người dùng xác nhận UI hiển thị đúng số liệu (đợt trước, chưa chụp lại sau
đợt sửa tiêu đề lần này).

## Bước tiếp theo

1. Hỏi người dùng có muốn commit các file trên vào git không (vẫn đang chờ).
2. Hỏi người dùng có muốn gắn nốt 13 kanji + làm lại gắn-bài cho kanji ở các
   bài đang trống (12,14,16-21,25) không — cần nguồn thật hoặc chấp nhận suy
   đoán như trước.
3. (Tuỳ chọn) Nếu có PDF/nguồn Nghe-Đọc N5, làm nốt phần đó.
4. (Tuỳ chọn, không gấp) Tay-curate lại gắn ngữ pháp Bài 11-23 bằng dữ liệu
   thật đã lấy được, thay vì fuzzy-match tự động.
