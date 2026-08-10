-- Bài 11-23 (mở rộng nối tiếp 10 bài cũ) — gom 60 điểm ngữ pháp mới trích từ
-- "Tổng hợp ngữ pháp N5.pdf" theo chủ điểm ngữ pháp thực tế (KHÔNG phải chép
-- lại mục lục chính thức Minna no Nihongo — không tra cứu/đối chiếu được
-- trong phiên này vì WebSearch lỗi; tên bài mô tả đúng nội dung ngữ pháp bên
-- trong, không khẳng định khớp 100% thứ tự SGK gốc). Không có Bài 24-25 (sai
-- khiến, bị động) vì 60 điểm trích xuất không có nội dung đó (N4-adjacent,
-- ngoài phạm vi PDF nguồn) — không tạo bài rỗng.
-- Từ vựng/kanji mới CHƯA được gắn vào bài học cụ thể nào (xem PROGRESS.md).

insert into lessons (id, level_id, title, description, order_index)
select v.id, (select id from jlpt_levels where code = 'N5'), v.title, null, v.order_index
from (values
  ('fcebc89f-6f7d-5796-a469-91115a4b9fa2'::uuid, 'Bài 11 — Số lượng, đếm đồ vật', 11),
  ('52ffc1f5-9f9a-56da-b6f7-e5de2b75f82f'::uuid, 'Bài 12 — So sánh', 12),
  ('074a2893-9c8d-58d4-8ffb-5d2315bea2e4'::uuid, 'Bài 13 — Cho, nhận, xin phép, đề nghị giúp', 13),
  ('cef9c944-fe32-5a62-9fb3-d42b046b9e4c'::uuid, 'Bài 14 — Cấm đoán, bắt buộc', 14),
  ('734c149e-160f-5574-8320-31d4bd08ccb3'::uuid, 'Bài 15 — Liệt kê hành động, kinh nghiệm', 15),
  ('fadb7021-9c71-5ce1-8a70-9f4b5ac59efb'::uuid, 'Bài 16 — Trước/sau khi làm gì', 16),
  ('51a14c44-04dd-5caa-9dc6-8faffe833028'::uuid, 'Bài 17 — Danh từ hoá động từ', 17),
  ('a37fcfa9-0a24-55ac-902e-3bcce7d5c1d2'::uuid, 'Bài 18 — Trích dẫn, tường thuật', 18),
  ('aa6dfaa7-6b6e-50a4-a0a6-9098b3872a43'::uuid, 'Bài 19 — Suy đoán, phỏng đoán', 19),
  ('3ec5303a-3f44-56bc-bd4f-7212264f63f4'::uuid, 'Bài 20 — Lý do, giải thích', 20),
  ('5370a363-2857-5a62-b9a7-b22718393de8'::uuid, 'Bài 21 — Trạng thái tiếp diễn, thói quen', 21),
  ('56c31fb2-01bd-5954-acf4-2e54ed0406ad'::uuid, 'Bài 22 — Mức độ, phó từ phủ định', 22),
  ('ded7b53c-b95a-5562-9caa-80c350e9846d'::uuid, 'Bài 23 — Liên từ, danh từ song song', 23)
) as v(id, title, order_index)
on conflict do nothing;

insert into lesson_items (lesson_id, item_type, item_id, order_index)
select (select id from lessons where order_index = v.order_index), 'grammar', v.item_id::uuid, 0
from (values
  (1, 'babe69ed-5246-58e4-a036-37d405ce7243'),
  (1, '34273e89-35e5-5387-a92c-b96dd5217ae0'),
  (7, '47485cae-93d4-5387-8367-dabda17d0ddb'),
  (5, '836c10ff-b3f1-52d5-9dc5-404e0ffd93e2'),
  (4, '87f83460-102a-520f-a922-4477efbf4c04'),
  (6, 'c568bcf9-a602-50e1-b52e-a2a8226210f4'),
  (5, '05a684f6-6077-5c98-a6ad-d559f88c1cf6'),
  (4, '87f83460-102a-520f-a922-4477efbf4c04'),
  (5, '05a684f6-6077-5c98-a6ad-d559f88c1cf6'),
  (20, '5164d278-2cee-5fac-ad5a-1db92164fac5'),
  (4, '67144ddd-3226-5a16-988d-bf58ab714369'),
  (8, '7f7fded5-0305-5f11-9baf-e46c5baf2efa'),
  (22, '4cb16502-c36e-56e0-910c-23417cc615fc'),
  (22, '49b30190-ff03-516b-8799-bb35cd777263'),
  (6, 'd451bf4b-29a9-5720-8075-d9ea9d2f7e95'),
  (3, '0661ae4e-8e39-5a41-86f9-1488b6629228'),
  (3, 'f085451d-8485-5250-9c5a-d1c17ee79065'),
  (11, 'ef906ac4-a8d6-5c5b-a870-6cab02edfa44'),
  (11, '5a0db655-791b-5d3a-b351-5fdbe3d61d77'),
  (6, 'b1a4cdef-7402-5f4c-b14d-762aeedda1df'),
  (13, 'a9c7422b-28fc-5d9d-a5fa-2e21cbe64ba1'),
  (7, '2d624cff-6c4e-5027-a47b-957c9a0de43a'),
  (7, '0a6e0bac-ec52-5a3e-9301-81bfd872f6d6'),
  (5, 'eb63ca7d-33f3-5614-89c5-1ccdd32fae7c'),
  (9, 'c96bd43c-9d9f-58ea-949a-b326bcad2329'),
  (14, '40bdac0c-56b6-57e3-907e-7e3d616df997'),
  (9, '3fbc7ac3-af15-5da8-8378-aa33cfca625b'),
  (9, 'c6ddf09c-6861-5f34-95d9-f9c60995e946'),
  (14, '2e2ea440-9b42-59d4-8dc7-4be409359ac3'),
  (14, 'be07cc26-e73e-57f9-815a-a7ad7ea5675b'),
  (14, '291620a5-e4ec-5a16-a8f8-e7f1aa567179'),
  (14, '34d2167f-9374-5d34-a402-bdd913a1941c'),
  (22, '864c47fe-5009-5183-b55d-619ea5418d32'),
  (20, '414df9f6-606f-5584-a2ef-3b72b999f769'),
  (17, '3d3b2bfd-7c35-59a5-b69b-6726924b3cf5'),
  (17, 'f777f0b8-312f-5912-9b97-e95bfdb1a811'),
  (17, '6b7c7e2c-f0b3-525a-9d31-9fded6659116'),
  (21, '11e55bb3-1e8a-525b-bea7-f0c25d43e8b0'),
  (21, '3f9e2a82-420e-530a-af81-b63670dd8bf2'),
  (12, 'b3f5eec8-1e15-5a7b-ad6d-bf5bdb62acc7'),
  (12, 'ee0cb88a-1cb1-57a6-ab2c-513f5e2d706d'),
  (12, 'eb7676e8-e51c-5262-8d40-3efd974b32b0'),
  (12, 'c0c4818f-0258-5897-aadc-f102688da4b2'),
  (19, 'a8cd75af-775d-5276-b093-d93200a4709c'),
  (22, '6fbb8fd5-792a-5eed-beb3-bc281734802a'),
  (15, '001dda56-7a1a-5e9c-99ea-6a092f478601'),
  (21, '765675e4-cfb0-5f75-b558-378d7d4187e4'),
  (15, '5654b8db-adca-5d0d-bd8a-08eedcf0ca4e'),
  (15, '19fd0c7b-94de-550d-b13e-a34b6c61dee8'),
  (15, '24db2e94-d6ab-5c1e-8762-8c5c4e336a9a'),
  (23, '449e4ae7-8b67-52b2-812b-420505001a4f'),
  (20, '1b552490-7571-516b-b2dc-36a7dbc7860e'),
  (16, '92d9ba87-b8cb-5da4-baa9-e008061235bf'),
  (16, '17d5e613-034f-5c28-b921-6cac9a82b059'),
  (16, '0fb13e20-3af9-5269-9862-f7b6d0c99ade'),
  (16, '2eab616d-84b1-59fa-962c-6e70cbb69fe7'),
  (19, '45fa9d08-7db9-5a8b-adde-219509b28c13'),
  (19, 'a42d66a4-9dc8-5cc9-8322-13ce5d4802ca'),
  (18, '738d780d-cb0c-5da4-86b6-32bf35566022'),
  (18, '06ff9c8c-127c-5157-9b8c-03c887303336'),
  (13, 'a1b2c3d4-0000-4000-8000-000000000008'),
  (4, 'a1b2c3d4-0000-4000-8000-000000000009')
) as v(order_index, item_id)
on conflict (lesson_id, item_type, item_id) do nothing;
