-- Nội dung nghe hiểu N5 kiểu JLPT/Minna no Nihongo: hội thoại 2 người thật,
-- độ dài khác nhau (2-8 lượt thoại), mỗi bài kèm 1 câu hỏi trắc nghiệm.
-- Chạy: supabase db query --linked -f supabase/seed_listening_n5.sql

insert into listening_dialogues (id, level_id, turns, question_vi, options, correct_index)
select v.id, (select id from jlpt_levels where code = 'N5'), v.turns::jsonb, v.question_vi, v.options::jsonb, v.correct_index
from (values
  ('77777777-0000-0000-0000-000000000001'::uuid,
   '[{"speaker":"A","jp":"すみません、この傘はいくらですか。"},{"speaker":"B","jp":"千二百円です。"}]',
   'Cây ô đó giá bao nhiêu?',
   '["1200 yên","12000 yên","120 yên","2100 yên"]',
   0),

  ('77777777-0000-0000-0000-000000000002'::uuid,
   '[{"speaker":"A","jp":"明日何時に会いますか。"},{"speaker":"B","jp":"十時はどうですか。"},{"speaker":"A","jp":"いいですよ。じゃ、十時に会いましょう。"}]',
   'Họ sẽ gặp nhau lúc mấy giờ?',
   '["10 giờ","9 giờ","11 giờ","10 giờ 30"]',
   0),

  ('77777777-0000-0000-0000-000000000003'::uuid,
   '[{"speaker":"A","jp":"すみません、お手洗いはどこですか。"},{"speaker":"B","jp":"あちらです。"}]',
   'Người B trả lời nhà vệ sinh ở đâu?',
   '["Chỉ tay hướng phía xa (\"đằng kia\")","Ở tầng 2","Bên trái quầy lễ tân","Nói là không có ở đây"]',
   0),

  ('77777777-0000-0000-0000-000000000004'::uuid,
   '[{"speaker":"A","jp":"今週の日曜日、何をしますか。"},{"speaker":"B","jp":"友達と映画を見ます。"},{"speaker":"A","jp":"いいですね。何の映画ですか。"},{"speaker":"B","jp":"アニメの映画です。"}]',
   'Người B sẽ làm gì vào Chủ nhật này?',
   '["Xem phim hoạt hình với bạn","Đi mua sắm một mình","Đi làm thêm giờ","Ở nhà nghỉ ngơi"]',
   0),

  ('77777777-0000-0000-0000-000000000005'::uuid,
   '[{"speaker":"A","jp":"すみません、駅までどう行きますか。"},{"speaker":"B","jp":"この道をまっすぐ行って、右に曲がってください。"},{"speaker":"A","jp":"歩いてどのくらいかかりますか。"},{"speaker":"B","jp":"十分ぐらいです。"}]',
   'Đi bộ đến ga mất khoảng bao lâu?',
   '["Khoảng 10 phút","Khoảng 30 phút","Khoảng 1 giờ","Khoảng 5 phút"]',
   0),

  ('77777777-0000-0000-0000-000000000006'::uuid,
   '[{"speaker":"A","jp":"いらっしゃいませ。何になさいますか。"},{"speaker":"B","jp":"コーヒーをください。"},{"speaker":"A","jp":"ホットですか、アイスですか。"},{"speaker":"B","jp":"アイスをお願いします。"}]',
   'Khách gọi loại cà phê nào?',
   '["Cà phê đá","Cà phê nóng","Trà đá","Nước cam"]',
   0),

  ('77777777-0000-0000-0000-000000000007'::uuid,
   '[{"speaker":"A","jp":"来月旅行に行きませんか。"},{"speaker":"B","jp":"いいですね。どこに行きますか。"},{"speaker":"A","jp":"京都はどうですか。"},{"speaker":"B","jp":"京都は好きです。何日行きますか。"},{"speaker":"A","jp":"三日間です。"},{"speaker":"B","jp":"じゃ、新幹線で行きましょう。"}]',
   'Họ định đi du lịch mấy ngày?',
   '["3 ngày","2 ngày","1 tuần","5 ngày"]',
   0),

  ('77777777-0000-0000-0000-000000000008'::uuid,
   '[{"speaker":"A","jp":"田中さん、辞書を貸してください。"},{"speaker":"B","jp":"いいですよ。はい、どうぞ。"},{"speaker":"A","jp":"ありがとうございます。あとで返します。"},{"speaker":"B","jp":"ゆっくりでいいですよ。"}]',
   'A mượn cái gì của Tanaka?',
   '["Quyển từ điển","Cây bút","Quyển sách","Cái ô"]',
   0),

  ('77777777-0000-0000-0000-000000000009'::uuid,
   '[{"speaker":"A","jp":"誕生日はいつですか。"},{"speaker":"B","jp":"五月三日です。"}]',
   'Sinh nhật của người đó là ngày nào?',
   '["Ngày 3 tháng 5","Ngày 5 tháng 3","Ngày 13 tháng 5","Ngày 30 tháng 5"]',
   0),

  ('77777777-0000-0000-0000-000000000010'::uuid,
   '[{"speaker":"A","jp":"もしもし、今晩七時に予約したいですが。"},{"speaker":"B","jp":"何名様ですか。"},{"speaker":"A","jp":"四人です。"},{"speaker":"B","jp":"少々お待ちください。……はい、大丈夫です。お名前をお願いします。"},{"speaker":"A","jp":"山田です。"},{"speaker":"B","jp":"山田様、七時に四名様ですね。お待ちしております。"},{"speaker":"A","jp":"ありがとうございます。"}]',
   'Ông Yamada đặt bàn cho mấy người?',
   '["4 người","7 người","2 người","3 người"]',
   0),

  ('77777777-0000-0000-0000-000000000011'::uuid,
   '[{"speaker":"A","jp":"明日の天気はどうですか。"},{"speaker":"B","jp":"天気予報によると、雨が降るそうです。"},{"speaker":"A","jp":"そうですか。じゃ、傘を持って行きます。"},{"speaker":"B","jp":"午後は晴れるかもしれません。"},{"speaker":"A","jp":"それなら傘はいらないかもしれませんね。"}]',
   'Theo dự báo, ban đầu ngày mai thời tiết thế nào?',
   '["Có mưa","Nắng cả ngày","Có tuyết","Nhiều mây, không mưa"]',
   0),

  ('77777777-0000-0000-0000-000000000012'::uuid,
   '[{"speaker":"A","jp":"大人二枚とこども一枚をください。"},{"speaker":"B","jp":"全部で三千五百円です。"},{"speaker":"A","jp":"はい、どうぞ。"}]',
   'Người khách mua bao nhiêu vé?',
   '["2 vé người lớn và 1 vé trẻ em","3 vé người lớn","1 vé người lớn và 2 vé trẻ em","2 vé trẻ em"]',
   0),

  ('77777777-0000-0000-0000-000000000013'::uuid,
   '[{"speaker":"A","jp":"田中さんはアルバイトをしていますか。"},{"speaker":"B","jp":"はい、コンビニで働いています。"},{"speaker":"A","jp":"週に何回ですか。"},{"speaker":"B","jp":"週に三回です。"}]',
   'Tanaka làm thêm ở đâu?',
   '["Cửa hàng tiện lợi","Nhà hàng","Thư viện","Trường học"]',
   0),

  ('77777777-0000-0000-0000-000000000014'::uuid,
   '[{"speaker":"A","jp":"どうしましたか。"},{"speaker":"B","jp":"昨日から頭が痛いです。それに熱もあります。"},{"speaker":"A","jp":"そうですか。薬を飲みましたか。"},{"speaker":"B","jp":"いいえ、まだ飲んでいません。"},{"speaker":"A","jp":"じゃ、この薬を一日三回飲んでください。"},{"speaker":"B","jp":"わかりました。ありがとうございます。"}]',
   'Bệnh nhân có triệu chứng gì?',
   '["Đau đầu và sốt","Đau bụng","Ho và sổ mũi","Đau răng"]',
   0),

  ('77777777-0000-0000-0000-000000000015'::uuid,
   '[{"speaker":"A","jp":"このりんごは一ついくらですか。"},{"speaker":"B","jp":"百五十円です。"}]',
   'Một quả táo giá bao nhiêu?',
   '["150 yên","1500 yên","15 yên","1050 yên"]',
   0),

  ('77777777-0000-0000-0000-000000000016'::uuid,
   '[{"speaker":"A","jp":"明日どこで会いますか。"},{"speaker":"B","jp":"駅の前はどうですか。"},{"speaker":"A","jp":"いいですね。何時にしますか。"},{"speaker":"B","jp":"九時半にしましょう。"},{"speaker":"A","jp":"わかりました。じゃ、明日九時半に駅の前で。"}]',
   'Họ sẽ gặp nhau ở đâu và mấy giờ?',
   '["Trước ga lúc 9 giờ 30","Trước ga lúc 9 giờ","Trong công viên lúc 9 giờ 30","Ở nhà lúc 9 giờ"]',
   0)
) as v(id, turns, question_vi, options, correct_index)
on conflict (id) do update set
  turns = excluded.turns,
  question_vi = excluded.question_vi,
  options = excluded.options,
  correct_index = excluded.correct_index;
