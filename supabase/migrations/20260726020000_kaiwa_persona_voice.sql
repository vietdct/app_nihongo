-- AI Kaiwa — ẩn bớt nhân vật + gán hồ sơ giọng đọc riêng cho từng nhân vật.
--
-- Ẩn thay vì xoá: 山田先生 và けん đã có hội thoại thật của người dùng
-- (persona_id được kaiwa_conversations tham chiếu, không có on delete cascade),
-- xoá thẳng sẽ vi phạm khoá ngoại hoặc phải xoá luôn lịch sử chat của họ.
-- is_active = false chỉ ẩn khỏi màn hình chọn nhân vật, dữ liệu cũ giữ nguyên.
alter table kaiwa_personas add column is_active boolean not null default true;

update kaiwa_personas set is_active = false where name in ('山田先生', 'さくら', 'けん');

-- voice_style: khoá cấu hình pitch/tốc độ đọc cho flutter_tts, map ở phía app
-- (lib/features/kaiwa/kaiwa_chat_screen.dart) — để mỗi nhân vật nghe khác nhau
-- dù cùng dùng chung 1 giọng engine của máy.
update kaiwa_personas set voice_style = case name
  when '田中先生'      then 'female_warm'
  when 'ゆい'          then 'female_energetic'
  when '店員'          then 'female_bright'
  when 'おばあちゃん'  then 'female_elderly'
  when 'けんた'        then 'male_neutral'
  when 'お客さん'      then 'male_firm'
  when '部長'          then 'male_stern'
  when '山田先生'      then 'male_neutral'
  when 'さくら'        then 'female_bright'
  when 'けん'          then 'male_neutral'
  else voice_style
end;
