-- Bổ sung 4 điểm ngữ pháp cho Bài 24-25 (đang trống) — tái hiện từ trí nhớ về
-- 2 bài cuối Minna no Nihongo Shokyu I (thể ば/のに và giới thiệu thể bị
-- động), KHÔNG tra cứu đối chiếu được nguồn chính thức trong phiên này. Độ
-- tin cậy thấp hơn phần ngữ pháp Bài 1-13 đã trích trực tiếp từ PDF — coi là
-- bản nháp, nên rà soát lại nếu có giáo trình gốc.
insert into grammar_points (id, title, explanation, example_jp, example_vi, level_id)
select v.id, v.title, v.explanation, v.example_jp, v.example_vi,
       (select id from jlpt_levels where code = 'N5')
from (values
  ('b2c3d4e5-0000-4000-8000-000000000101'::uuid, '~ば~',
   'Thể điều kiện (giả định): nếu ~ thì ~. Cách chia: động từ nhóm I đổi い→えば (かう→かえば); nhóm II bỏ ます thêm れば (たべます→たべれば); nhóm III: する→すれば, くる→くれば. Tính từ -i: bỏ い thêm ければ; tính từ -na/danh từ: thêm なら.',
   '春になれば、桜が咲きます。', 'Nếu vào xuân thì hoa anh đào sẽ nở.'),
  ('b2c3d4e5-0000-4000-8000-000000000102'::uuid, '~ば~ほど~',
   'Càng ~ thì càng ~. Kết hợp thể ば của một từ với chính từ đó ở dạng thường, diễn tả mức độ tăng dần song song.',
   '安ければ安いほどいいです。', 'Càng rẻ thì càng tốt.'),
  ('b2c3d4e5-0000-4000-8000-000000000103'::uuid, '普通形+のに',
   'Mặc dù ~ nhưng (lại) ~, thường mang sắc thái ngạc nhiên, bất mãn hoặc tiếc nuối trước kết quả trái ngược mong đợi. Nối sau thể thường của động từ/tính từ/danh từ (danh từ và tính từ -na thêm な trước のに).',
   'このレストランは高いのに、あまりおいしくないです。', 'Nhà hàng này đắt thế mà lại không ngon lắm.'),
  ('b2c3d4e5-0000-4000-8000-000000000104'::uuid, '受身形（〜られます）',
   'Thể bị động, giới thiệu cơ bản: nhóm I đổi âm い→あ rồi thêm れます (かく→かかれます); nhóm II bỏ ます thêm られます (ほめます→ほめられます); nhóm III: する→されます, くる→こられます. Chủ ngữ là đối tượng bị/được tác động, người thực hiện hành động đánh dấu bằng に.',
   'この本は多くの人に読まれています。', 'Cuốn sách này được nhiều người đọc.')
) as v(id, title, explanation, example_jp, example_vi)
on conflict (id) do nothing;

insert into lesson_items (lesson_id, item_type, item_id, order_index)
select (select id from lessons where order_index = v.order_index), 'grammar', v.item_id::uuid, 0
from (values
  (24, 'b2c3d4e5-0000-4000-8000-000000000101'),
  (24, 'b2c3d4e5-0000-4000-8000-000000000102'),
  (24, 'b2c3d4e5-0000-4000-8000-000000000103'),
  (25, 'b2c3d4e5-0000-4000-8000-000000000104')
) as v(order_index, item_id)
on conflict (lesson_id, item_type, item_id) do nothing;
