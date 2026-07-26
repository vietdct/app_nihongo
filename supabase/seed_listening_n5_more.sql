-- Mở rộng nội dung nghe hiểu N5: thêm 3 thể loại câu hỏi khác với 16 bài
-- "hội thoại hỏi chi tiết" đã có (seed_listening_n5.sql), giống cấu trúc đề
-- thi thật JLPT (4 mondai khác dạng) để đỡ lặp lại đúng 1 kiểu:
--   - Hội thoại "làm gì trước/tiếp theo" (giống Mondai 1 課題理解)
--   - Độc thoại/thông báo 1 người nói (giống Mondai 2 dạng thông báo)
--   - Câu ngắn + chọn phản hồi phù hợp (giống Mondai 4 即時応答)
-- Chạy: supabase db query --linked -f supabase/seed_listening_n5_more.sql

insert into listening_dialogues (id, level_id, turns, question_vi, options, correct_index)
select v.id, (select id from jlpt_levels where code = 'N5'), v.turns::jsonb, v.question_vi, v.options::jsonb, v.correct_index
from (values
  -- Hội thoại "làm gì trước/tiếp theo"
  ('77777777-0000-0000-0000-000000000017'::uuid,
   '[{"speaker":"A","jp":"明日旅行に行きますね。もう準備しましたか。"},{"speaker":"B","jp":"いいえ、まだです。まずかばんに服を入れます。"},{"speaker":"A","jp":"そうですか。私は先にパスポートを確認します。"},{"speaker":"B","jp":"それはいいですね。私もあとで確認します。"}]',
   'A sẽ làm gì trước tiên?',
   '["Kiểm tra hộ chiếu","Xếp quần áo vào vali","Mua vé máy bay","Gọi điện cho bạn"]',
   0),

  ('77777777-0000-0000-0000-000000000018'::uuid,
   '[{"speaker":"A","jp":"お客さんが来る前に、何をしますか。"},{"speaker":"B","jp":"先に部屋を掃除して、それから料理を作ります。"},{"speaker":"A","jp":"買い物はしましたか。"},{"speaker":"B","jp":"いいえ、まだです。掃除のあとで行きます。"}]',
   'B sẽ làm gì đầu tiên?',
   '["Dọn phòng","Nấu ăn","Đi mua sắm","Gọi điện thoại"]',
   0),

  ('77777777-0000-0000-0000-000000000019'::uuid,
   '[{"speaker":"A","jp":"宿題をしてから、ゲームをしてもいいですか。"},{"speaker":"B","jp":"いいですよ。でも、宿題を先にしてくださいね。"},{"speaker":"A","jp":"わかりました。今からやります。"}]',
   'A sẽ làm gì trước khi chơi game?',
   '["Làm bài tập về nhà","Đi ngủ","Ăn cơm","Xem tivi"]',
   0),

  ('77777777-0000-0000-0000-000000000020'::uuid,
   '[{"speaker":"A","jp":"会議の前に何を準備しますか。"},{"speaker":"B","jp":"資料をコピーして、それから会議室を予約します。"},{"speaker":"A","jp":"資料は何枚必要ですか。"},{"speaker":"B","jp":"十枚お願いします。"}]',
   'B sẽ làm gì trước tiên để chuẩn bị họp?',
   '["Photo tài liệu","Đặt phòng họp","Gọi điện cho khách","Viết báo cáo"]',
   0),

  ('77777777-0000-0000-0000-000000000021'::uuid,
   '[{"speaker":"A","jp":"今日は何をしますか。"},{"speaker":"B","jp":"まず買い物に行って、それから料理を作ります。洗濯はそのあとです。"},{"speaker":"A","jp":"忙しいですね。"}]',
   'B sẽ làm gì cuối cùng trong ngày?',
   '["Giặt đồ","Đi mua sắm","Nấu ăn","Dọn dẹp"]',
   0),

  ('77777777-0000-0000-0000-000000000022'::uuid,
   '[{"speaker":"A","jp":"病院へ行ってから、どこへ行きますか。"},{"speaker":"B","jp":"薬局へ行って、薬をもらいます。そのあと家へ帰ります。"}]',
   'B sẽ đi đâu ngay sau khi rời bệnh viện?',
   '["Hiệu thuốc","Về nhà ngay","Đi làm","Đi siêu thị"]',
   0),

  ('77777777-0000-0000-0000-000000000023'::uuid,
   '[{"speaker":"A","jp":"明日のテストの前に、何をしますか。"},{"speaker":"B","jp":"今晩勉強して、朝早く起きてもう一度復習します。"},{"speaker":"A","jp":"メールのチェックはしませんか。"},{"speaker":"B","jp":"それは勉強のあとにします。"}]',
   'B ôn bài lại vào lúc nào?',
   '["Sáng sớm hôm sau","Ngay bây giờ","Sau khi kiểm tra email","Buổi tối muộn"]',
   0),

  ('77777777-0000-0000-0000-000000000024'::uuid,
   '[{"speaker":"A","jp":"空港に着いたら、まず何をしますか。"},{"speaker":"B","jp":"チェックインカウンターに行って、荷物を預けます。それから搭乗口へ行きます。"}]',
   'Việc đầu tiên làm ở sân bay là gì?',
   '["Đến quầy check-in gửi hành lý","Đi thẳng ra cửa lên máy bay","Ăn ở nhà hàng sân bay","Mua đồ miễn thuế"]',
   0),

  -- Độc thoại / thông báo 1 người nói
  ('77777777-0000-0000-0000-000000000025'::uuid,
   '[{"speaker":"A","jp":"天気予報をお伝えします。今日の午前中は晴れですが、午後から雨が降るでしょう。夜は風も強くなりますので、ご注意ください。"}]',
   'Theo bản tin, chiều nay thời tiết thế nào?',
   '["Có mưa","Nắng","Có tuyết","Nhiều mây, không mưa"]',
   0),

  ('77777777-0000-0000-0000-000000000026'::uuid,
   '[{"speaker":"A","jp":"まもなく二番線に電車が参ります。危ないですから、黄色い線の内側にお下がりください。この電車は各駅停車、東京行きです。"}]',
   'Tàu sắp đến ở sân ga số mấy?',
   '["Sân ga số 2","Sân ga số 1","Sân ga số 3","Sân ga số 4"]',
   0),

  ('77777777-0000-0000-0000-000000000027'::uuid,
   '[{"speaker":"A","jp":"はじめまして。私はグエンと申します。ベトナムから来ました。日本語学校の学生です。趣味は料理と音楽です。よろしくお願いします。"}]',
   'Người nói đến từ đâu?',
   '["Việt Nam","Nhật Bản","Trung Quốc","Hàn Quốc"]',
   0),

  ('77777777-0000-0000-0000-000000000028'::uuid,
   '[{"speaker":"A","jp":"本日はご来店ありがとうございました。当店は午後八時に閉店いたします。あと十分でお会計をお願いいたします。"}]',
   'Cửa hàng đóng cửa lúc mấy giờ?',
   '["8 giờ tối","10 giờ tối","8 giờ sáng","9 giờ tối"]',
   0),

  -- Câu ngắn + chọn phản hồi phù hợp
  ('77777777-0000-0000-0000-000000000029'::uuid,
   '[{"speaker":"A","jp":"コーヒーと紅茶とどちらがいいですか。"}]',
   'Câu trả lời phù hợp nhất là gì?',
   '["Tôi thích cà phê hơn.","Bây giờ là 3 giờ.","Nhà vệ sinh ở đằng kia.","Tôi tên là Yamada."]',
   0),

  ('77777777-0000-0000-0000-000000000030'::uuid,
   '[{"speaker":"A","jp":"明日一緒に映画を見ませんか。"}]',
   'Câu trả lời phù hợp nhất là gì?',
   '["Đồng ý, đi chứ!","Cái đó giá 500 yên.","Bây giờ là 5 giờ.","Đây là quyển sách của tôi."]',
   0),

  ('77777777-0000-0000-0000-000000000031'::uuid,
   '[{"speaker":"A","jp":"すみません、今何時ですか。"}]',
   'Câu trả lời phù hợp nhất là gì?',
   '["Bây giờ là 3 giờ 15 phút.","Đây là quyển từ điển.","Tôi thích mùa đông.","Ga ở phía bên kia."]',
   0),

  ('77777777-0000-0000-0000-000000000032'::uuid,
   '[{"speaker":"A","jp":"お誕生日おめでとうございます。"}]',
   'Câu trả lời phù hợp nhất là gì?',
   '["Cảm ơn bạn rất nhiều.","Không, tôi không đi.","Cái đó rất đắt.","Trời hôm nay mưa."]',
   0)
) as v(id, turns, question_vi, options, correct_index)
on conflict (id) do update set
  turns = excluded.turns,
  question_vi = excluded.question_vi,
  options = excluded.options,
  correct_index = excluded.correct_index;
