-- Sửa ngữ pháp Bài 24-25: 4 điểm viết từ trí nhớ ở phiên trước (thể ば/のに,
-- 受身形) SAI CHỦ ĐỀ so với nguồn thật (jes.edu.vn/minano-nihongo, các trang
-- ngu-phap-minna-no-nihongo-bai-24/25). Theo nguồn thật:
--   Bài 24 = động từ cho/nhận (あげます／もらいます／くれます)
--   Bài 25 = thể điều kiện たら
-- Xoá 4 điểm cũ, viết lại 5 điểm mới đúng chủ đề. Nội dung giải thích/ví dụ
-- vẫn viết từ trí nhớ (site chặn truy cập lại nên không lấy được nguyên văn
-- giải thích của site) — độ tin cậy về CHỦ ĐỀ cao (đối chiếu được), độ tin
-- cậy về câu chữ giải thích/ví dụ ở mức tương tự phần Bài 1-13 (không trích
-- trực tiếp), người dùng đã đồng ý cách làm này.
begin;

delete from lesson_items where item_type = 'grammar' and item_id in (
  'b2c3d4e5-0000-4000-8000-000000000101'::uuid,
  'b2c3d4e5-0000-4000-8000-000000000102'::uuid,
  'b2c3d4e5-0000-4000-8000-000000000103'::uuid,
  'b2c3d4e5-0000-4000-8000-000000000104'::uuid
);
delete from grammar_points where id in (
  'b2c3d4e5-0000-4000-8000-000000000101'::uuid,
  'b2c3d4e5-0000-4000-8000-000000000102'::uuid,
  'b2c3d4e5-0000-4000-8000-000000000103'::uuid,
  'b2c3d4e5-0000-4000-8000-000000000104'::uuid
);

insert into grammar_points (id, title, explanation, example_jp, example_vi, level_id)
select v.id, v.title, v.explanation, v.example_jp, v.example_vi,
       (select id from jlpt_levels where code = 'N5')
from (values
  ('b2c3d4e5-0000-4000-8000-000000000201'::uuid,
   'あげます・もらいます・くれます (cho, nhận)',
   'Động từ chỉ việc cho/nhận đồ vật. あげます: tôi (hoặc người khác) cho/tặng ai đó. もらいます: tôi (hoặc người khác) nhận được từ ai đó (người cho đánh dấu bằng に hoặc から). くれます: người khác cho/tặng tôi (hoặc người thân trong nhóm của tôi) — luôn hướng về phía người nói.',
   'わたしは　ミラーさんに　花を　あげました。',
   'Tôi đã tặng hoa cho anh Miller.'),
  ('b2c3d4e5-0000-4000-8000-000000000202'::uuid,
   '～てあげます／～てもらいます (làm giúp / được làm giúp)',
   'Động từ thể て + あげます: tôi làm gì đó giúp ai (cẩn thận khi dùng với người trên vì có thể nghe kể ơn). Động từ thể て + もらいます: tôi được ai đó làm giúp việc gì cho mình, người thực hiện hành động đánh dấu bằng に.',
   'わたしは　友達に　本を　貸して　あげました。わたしは　先生に　漢字を　教えて　もらいました。',
   'Tôi đã cho bạn mượn sách. Tôi đã được thầy giáo dạy cho chữ Hán.'),
  ('b2c3d4e5-0000-4000-8000-000000000203'::uuid,
   '～てくれます (ai đó làm giúp tôi)',
   'Động từ thể て + くれます: người khác làm gì đó giúp tôi (hoặc người trong nhóm của tôi), hành động luôn hướng về phía người nói, mang sắc thái biết ơn.',
   '友達が　わたしに　地図を　かいて　くれました。',
   'Bạn tôi đã vẽ bản đồ giúp tôi.'),
  ('b2c3d4e5-0000-4000-8000-000000000204'::uuid,
   '～たら～ (thể điều kiện たら)',
   'Động từ/tính từ/danh từ thể た + ら, diễn tả điều kiện hoặc trình tự thời gian: nếu/khi ~ thì ~. Vế sau thường là hành động hoặc sự việc xảy ra sau khi điều kiện ở vế trước được thoả mãn.',
   '雨が　ふったら、うちに　います。',
   'Nếu trời mưa thì tôi sẽ ở nhà.'),
  ('b2c3d4e5-0000-4000-8000-000000000205'::uuid,
   'もし～たら～ (nếu như...)',
   'もし kết hợp với thể たら để nhấn mạnh tính giả định của điều kiện, thường dùng cho tình huống chưa chắc xảy ra hoặc mang tính giả thuyết.',
   'もし　じかんが　あったら、いっしょに　えいがを　みませんか。',
   'Nếu như có thời gian thì cùng đi xem phim không?')
) as v(id, title, explanation, example_jp, example_vi)
on conflict (id) do nothing;

insert into lesson_items (lesson_id, item_type, item_id, order_index)
select (select id from lessons where order_index = v.order_index), 'grammar', v.item_id::uuid, v.ord
from (values
  (24, 'b2c3d4e5-0000-4000-8000-000000000201', 0),
  (24, 'b2c3d4e5-0000-4000-8000-000000000202', 1),
  (24, 'b2c3d4e5-0000-4000-8000-000000000203', 2),
  (25, 'b2c3d4e5-0000-4000-8000-000000000204', 0),
  (25, 'b2c3d4e5-0000-4000-8000-000000000205', 1)
) as v(order_index, item_id, ord)
on conflict (lesson_id, item_type, item_id) do nothing;

commit;
