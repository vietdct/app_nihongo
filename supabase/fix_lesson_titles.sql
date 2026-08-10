-- Sửa lại tiêu đề 25 bài cho đúng chủ đề ngữ pháp thật (đối chiếu jes.edu.vn,
-- xem scratchpad/grammar_titles_by_lesson.json). Nhiều tiêu đề cũ (viết từ trí
-- nhớ ở phiên trước) bị lệch/đảo chủ đề so với nội dung thật, ví dụ: Bài 24-25
-- vẫn giữ tiêu đề cũ "Giả định, tuy nhiên" / "Thể bị động" dù nội dung
-- grammar_points đã được sửa đúng (cho-nhận / たら) trong fix_lesson24_25_grammar.sql.
begin;

update lessons set title = v.title
from (values
  (1,  'Bài 1 — Giới thiệu bản thân'),
  (2,  'Bài 2 — Chỉ định đồ vật (これ・それ・あれ)'),
  (3,  'Bài 3 — Vị trí, nơi chốn (ここ・そこ・あそこ)'),
  (4,  'Bài 4 — Giờ giấc, thời gian biểu'),
  (5,  'Bài 5 — Đi, đến, về'),
  (6,  'Bài 6 — Mua sắm, rủ rê làm gì'),
  (7,  'Bài 7 — Cho, nhận (đợt 1); đã làm xong'),
  (8,  'Bài 8 — Tính từ'),
  (9,  'Bài 9 — Sở thích, khả năng, lý do'),
  (10, 'Bài 10 — Có gì, có ai ở đâu (đồ vật, gia đình)'),
  (11, 'Bài 11 — Số lượng, đếm đồ vật'),
  (12, 'Bài 12 — So sánh'),
  (13, 'Bài 13 — Muốn có, muốn làm'),
  (14, 'Bài 14 — Thể て — nhờ vả, đang làm'),
  (15, 'Bài 15 — Xin phép, cấm đoán'),
  (16, 'Bài 16 — Nối hành động, làm xong rồi làm'),
  (17, 'Bài 17 — Cấm đoán, bắt buộc (thể ない)'),
  (18, 'Bài 18 — Danh từ hoá động từ (こと), trước khi làm gì'),
  (19, 'Bài 19 — Liệt kê hành động, kinh nghiệm'),
  (20, 'Bài 20 — Thể lịch sự và thể thông thường'),
  (21, 'Bài 21 — Trích dẫn, suy đoán, phỏng đoán'),
  (22, 'Bài 22 — Mệnh đề bổ nghĩa cho danh từ'),
  (23, 'Bài 23 — とき (Khi...)'),
  (24, 'Bài 24 — Cho, nhận (đợt 2): あげます・もらいます・くれます'),
  (25, 'Bài 25 — Điều kiện たら')
) as v(order_index, title)
where lessons.order_index = v.order_index;

commit;
