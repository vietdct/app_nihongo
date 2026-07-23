-- Seed dữ liệu N5 thật — đủ để dựng và test UI (Pha 2).
-- Chạy: supabase db query --linked -f supabase/seed_content_n5.sql
-- Không phải toàn bộ N5 — chỉ ~30 từ / 15 kanji / 2 bài học đại diện.
-- UUID cố định để lesson_items có thể tham chiếu ổn định, dễ chạy lại (idempotent).

-- ─────────────────────────────────────────────────────────────
-- Kanji (15 chữ N5 cơ bản)
-- ─────────────────────────────────────────────────────────────
insert into kanji (id, character, onyomi, kunyomi, meaning_vi, stroke_count, example_jp, example_vi, level_id)
select v.id, v.character, v.onyomi, v.kunyomi, v.meaning_vi, v.stroke_count, v.example_jp, v.example_vi,
       (select id from jlpt_levels where code = 'N5')
from (values
  ('11111111-0000-0000-0000-000000000001'::uuid, '日', 'にち・じつ', 'ひ', 'ngày, mặt trời', 4, '今日は日曜日です。', 'Hôm nay là chủ nhật.'),
  ('11111111-0000-0000-0000-000000000002'::uuid, '月', 'げつ・がつ', 'つき', 'tháng, mặt trăng', 4, '来月、日本へ行きます。', 'Tháng sau tôi sẽ đi Nhật.'),
  ('11111111-0000-0000-0000-000000000003'::uuid, '火', 'か', 'ひ', 'lửa', 4, '火曜日に会いましょう。', 'Hẹn gặp vào thứ Ba nhé.'),
  ('11111111-0000-0000-0000-000000000004'::uuid, '水', 'すい', 'みず', 'nước', 4, '水を飲みます。', 'Tôi uống nước.'),
  ('11111111-0000-0000-0000-000000000005'::uuid, '木', 'もく・ぼく', 'き', 'cây', 4, '木の下で休みます。', 'Nghỉ ngơi dưới gốc cây.'),
  ('11111111-0000-0000-0000-000000000006'::uuid, '金', 'きん', 'かね', 'vàng, tiền', 8, 'お金がありません。', 'Tôi không có tiền.'),
  ('11111111-0000-0000-0000-000000000007'::uuid, '土', 'ど', 'つち', 'đất', 3, '土曜日は休みです。', 'Thứ Bảy được nghỉ.'),
  ('11111111-0000-0000-0000-000000000008'::uuid, '人', 'じん・にん', 'ひと', 'người', 2, 'あの人は先生です。', 'Người kia là giáo viên.'),
  ('11111111-0000-0000-0000-000000000009'::uuid, '子', 'し', 'こ', 'con, trẻ em', 3, '子供が好きです。', 'Tôi thích trẻ em.'),
  ('11111111-0000-0000-0000-000000000010'::uuid, '女', 'じょ', 'おんな', 'nữ', 3, '女の人が来ました。', 'Một người phụ nữ đã đến.'),
  ('11111111-0000-0000-0000-000000000011'::uuid, '男', 'だん・なん', 'おとこ', 'nam', 7, '男の子が二人います。', 'Có hai bé trai.'),
  ('11111111-0000-0000-0000-000000000012'::uuid, '先', 'せん', 'さき', 'trước, đầu tiên', 6, '先に行ってください。', 'Xin hãy đi trước.'),
  ('11111111-0000-0000-0000-000000000013'::uuid, '生', 'せい', 'い（きる）・う（まれる）', 'sinh, sống', 5, '学生は勉強します。', 'Học sinh học bài.'),
  ('11111111-0000-0000-0000-000000000014'::uuid, '学', 'がく', 'まな（ぶ）', 'học', 8, '日本語を学びます。', 'Tôi học tiếng Nhật.'),
  ('11111111-0000-0000-0000-000000000015'::uuid, '校', 'こう', '—', 'trường học', 10, '学校へ行きます。', 'Tôi đi đến trường.')
) as v(id, character, onyomi, kunyomi, meaning_vi, stroke_count, example_jp, example_vi)
on conflict (character) do nothing;

-- ─────────────────────────────────────────────────────────────
-- Từ vựng — nhóm "Mua sắm" (12 từ)
-- ─────────────────────────────────────────────────────────────
insert into vocabulary (id, word, reading, meaning_vi, part_of_speech, example_jp, example_vi, level_id)
select v.id, v.word, v.reading, v.meaning_vi, v.part_of_speech, v.example_jp, v.example_vi,
       (select id from jlpt_levels where code = 'N5')
from (values
  ('22222222-0000-0000-0000-000000000001'::uuid, '買い物', 'かいもの', 'việc mua sắm', 'danh từ', '週末に買い物に行きます。', 'Cuối tuần tôi đi mua sắm.'),
  ('22222222-0000-0000-0000-000000000002'::uuid, '買う', 'かう', 'mua', 'động từ', '新しい靴を買いました。', 'Tôi đã mua giày mới.'),
  ('22222222-0000-0000-0000-000000000003'::uuid, '高い', 'たかい', 'đắt, cao', 'tính từ -i', 'このかばんは高いです。', 'Cái túi này đắt.'),
  ('22222222-0000-0000-0000-000000000004'::uuid, '安い', 'やすい', 'rẻ', 'tính từ -i', 'この店は安いです。', 'Cửa hàng này rẻ.'),
  ('22222222-0000-0000-0000-000000000005'::uuid, '店', 'みせ', 'cửa hàng', 'danh từ', '駅の前に店があります。', 'Có cửa hàng trước ga.'),
  ('22222222-0000-0000-0000-000000000006'::uuid, 'お金', 'おかね', 'tiền', 'danh từ', 'お金を払います。', 'Tôi trả tiền.'),
  ('22222222-0000-0000-0000-000000000007'::uuid, '値段', 'ねだん', 'giá cả', 'danh từ', '値段を聞きました。', 'Tôi đã hỏi giá.'),
  ('22222222-0000-0000-0000-000000000008'::uuid, 'デパート', 'でぱーと', 'trung tâm thương mại', 'danh từ', 'デパートで服を買います。', 'Tôi mua quần áo ở trung tâm thương mại.'),
  ('22222222-0000-0000-0000-000000000009'::uuid, 'スーパー', 'すーぱー', 'siêu thị', 'danh từ', 'スーパーで野菜を買います。', 'Tôi mua rau ở siêu thị.'),
  ('22222222-0000-0000-0000-000000000010'::uuid, '財布', 'さいふ', 'ví tiền', 'danh từ', '財布を忘れました。', 'Tôi quên ví tiền.'),
  ('22222222-0000-0000-0000-000000000011'::uuid, 'レジ', 'れじ', 'quầy thu ngân', 'danh từ', 'レジに並びます。', 'Tôi xếp hàng ở quầy thu ngân.'),
  ('22222222-0000-0000-0000-000000000012'::uuid, '品物', 'しなもの', 'hàng hoá', 'danh từ', '品物がたくさんあります。', 'Có nhiều hàng hoá.')
) as v(id, word, reading, meaning_vi, part_of_speech, example_jp, example_vi)
on conflict (id) do nothing;

-- ─────────────────────────────────────────────────────────────
-- Từ vựng — nhóm "Đời sống học đường" (12 từ)
-- ─────────────────────────────────────────────────────────────
insert into vocabulary (id, word, reading, meaning_vi, part_of_speech, example_jp, example_vi, level_id)
select v.id, v.word, v.reading, v.meaning_vi, v.part_of_speech, v.example_jp, v.example_vi,
       (select id from jlpt_levels where code = 'N5')
from (values
  ('22222222-0000-0000-0000-000000000013'::uuid, '学校', 'がっこう', 'trường học', 'danh từ', '毎日学校へ行きます。', 'Ngày nào tôi cũng đi học.'),
  ('22222222-0000-0000-0000-000000000014'::uuid, '先生', 'せんせい', 'giáo viên', 'danh từ', '先生に質問します。', 'Tôi hỏi giáo viên.'),
  ('22222222-0000-0000-0000-000000000015'::uuid, '学生', 'がくせい', 'học sinh, sinh viên', 'danh từ', '私は学生です。', 'Tôi là học sinh.'),
  ('22222222-0000-0000-0000-000000000016'::uuid, '教室', 'きょうしつ', 'phòng học', 'danh từ', '教室で勉強します。', 'Tôi học trong phòng học.'),
  ('22222222-0000-0000-0000-000000000017'::uuid, '勉強', 'べんきょう', 'việc học tập', 'danh từ・する', '日本語を勉強します。', 'Tôi học tiếng Nhật.'),
  ('22222222-0000-0000-0000-000000000018'::uuid, '授業', 'じゅぎょう', 'tiết học, bài giảng', 'danh từ', '授業は九時に始まります。', 'Tiết học bắt đầu lúc 9 giờ.'),
  ('22222222-0000-0000-0000-000000000019'::uuid, '宿題', 'しゅくだい', 'bài tập về nhà', 'danh từ', '宿題を忘れました。', 'Tôi quên làm bài tập.'),
  ('22222222-0000-0000-0000-000000000020'::uuid, '試験', 'しけん', 'kỳ thi', 'danh từ', '来週試験があります。', 'Tuần sau có kỳ thi.'),
  ('22222222-0000-0000-0000-000000000021'::uuid, '図書館', 'としょかん', 'thư viện', 'danh từ', '図書館で本を読みます。', 'Tôi đọc sách ở thư viện.'),
  ('22222222-0000-0000-0000-000000000022'::uuid, '友達', 'ともだち', 'bạn bè', 'danh từ', '友達と遊びます。', 'Tôi chơi với bạn bè.'),
  ('22222222-0000-0000-0000-000000000023'::uuid, '休み', 'やすみ', 'kỳ nghỉ, sự nghỉ', 'danh từ', '今日は休みです。', 'Hôm nay được nghỉ.'),
  ('22222222-0000-0000-0000-000000000024'::uuid, '卒業', 'そつぎょう', 'tốt nghiệp', 'danh từ・する', '来年卒業します。', 'Sang năm tôi tốt nghiệp.')
) as v(id, word, reading, meaning_vi, part_of_speech, example_jp, example_vi)
on conflict (id) do nothing;

-- ─────────────────────────────────────────────────────────────
-- Từ vựng — chung (6 từ, chưa gắn bài học, để test tra cứu/duyệt)
-- ─────────────────────────────────────────────────────────────
insert into vocabulary (id, word, reading, meaning_vi, part_of_speech, example_jp, example_vi, level_id)
select v.id, v.word, v.reading, v.meaning_vi, v.part_of_speech, v.example_jp, v.example_vi,
       (select id from jlpt_levels where code = 'N5')
from (values
  ('22222222-0000-0000-0000-000000000025'::uuid, '今日', 'きょう', 'hôm nay', 'danh từ', '今日は暑いです。', 'Hôm nay trời nóng.'),
  ('22222222-0000-0000-0000-000000000026'::uuid, '明日', 'あした', 'ngày mai', 'danh từ', '明日また来ます。', 'Ngày mai tôi sẽ đến lại.'),
  ('22222222-0000-0000-0000-000000000027'::uuid, '昨日', 'きのう', 'hôm qua', 'danh từ', '昨日映画を見ました。', 'Hôm qua tôi đã xem phim.'),
  ('22222222-0000-0000-0000-000000000028'::uuid, '時間', 'じかん', 'thời gian', 'danh từ', '時間がありません。', 'Tôi không có thời gian.'),
  ('22222222-0000-0000-0000-000000000029'::uuid, '電話', 'でんわ', 'điện thoại', 'danh từ・する', '友達に電話します。', 'Tôi gọi điện cho bạn.'),
  ('22222222-0000-0000-0000-000000000030'::uuid, '家族', 'かぞく', 'gia đình', 'danh từ', '家族と住んでいます。', 'Tôi sống cùng gia đình.')
) as v(id, word, reading, meaning_vi, part_of_speech, example_jp, example_vi)
on conflict (id) do nothing;

-- ─────────────────────────────────────────────────────────────
-- Bài học
-- ─────────────────────────────────────────────────────────────
insert into lessons (id, level_id, title, description, order_index)
values
  ('33333333-0000-0000-0000-000000000001'::uuid, (select id from jlpt_levels where code = 'N5'),
   '買い物 — Đi mua sắm', 'Từ vựng cơ bản khi đi mua sắm: cửa hàng, giá cả, thanh toán.', 1),
  ('33333333-0000-0000-0000-000000000002'::uuid, (select id from jlpt_levels where code = 'N5'),
   '学校生活 — Đời sống học đường', 'Từ vựng và kanji về trường lớp, học tập, thầy cô, bạn bè.', 2)
on conflict (id) do nothing;

-- ─────────────────────────────────────────────────────────────
-- Gắn từ vựng/kanji vào bài học theo thứ tự
-- ─────────────────────────────────────────────────────────────
insert into lesson_items (lesson_id, item_type, item_id, order_index)
select '33333333-0000-0000-0000-000000000001'::uuid, 'vocabulary', id, row_number() over ()
from vocabulary where id in (
  '22222222-0000-0000-0000-000000000001','22222222-0000-0000-0000-000000000002',
  '22222222-0000-0000-0000-000000000003','22222222-0000-0000-0000-000000000004',
  '22222222-0000-0000-0000-000000000005','22222222-0000-0000-0000-000000000006',
  '22222222-0000-0000-0000-000000000007','22222222-0000-0000-0000-000000000008',
  '22222222-0000-0000-0000-000000000009','22222222-0000-0000-0000-000000000010',
  '22222222-0000-0000-0000-000000000011','22222222-0000-0000-0000-000000000012'
)
on conflict (lesson_id, item_type, item_id) do nothing;

insert into lesson_items (lesson_id, item_type, item_id, order_index)
select '33333333-0000-0000-0000-000000000002'::uuid, 'vocabulary', id, row_number() over () + 100
from vocabulary where id in (
  '22222222-0000-0000-0000-000000000013','22222222-0000-0000-0000-000000000014',
  '22222222-0000-0000-0000-000000000015','22222222-0000-0000-0000-000000000016',
  '22222222-0000-0000-0000-000000000017','22222222-0000-0000-0000-000000000018',
  '22222222-0000-0000-0000-000000000019','22222222-0000-0000-0000-000000000020',
  '22222222-0000-0000-0000-000000000021','22222222-0000-0000-0000-000000000022',
  '22222222-0000-0000-0000-000000000023','22222222-0000-0000-0000-000000000024'
)
on conflict (lesson_id, item_type, item_id) do nothing;

insert into lesson_items (lesson_id, item_type, item_id, order_index)
select '33333333-0000-0000-0000-000000000002'::uuid, 'kanji', id, row_number() over () + 200
from kanji where character in ('学', '校', '先', '生')
on conflict (lesson_id, item_type, item_id) do nothing;
