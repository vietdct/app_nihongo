-- Nội dung mẫu "mini từ điển" cho ちゃんと (N4, id 9b0ce664-2f33-5e99-90f7-fe4062d49aae)
-- — bản demo để xác nhận UI khớp thiết kế "Vocabulary Detail v2" trước khi
-- biên soạn thêm cho các từ khác. Xem migration
-- 20260811000000_vocabulary_extra_content.sql / 20260811010000_vocabulary_meanings_extra_examples.sql.

update vocabulary set
  common_usage_pattern = 'ちゃんと + Verb',
  common_usage_desc = 'Đứng trước động từ để nhấn mạnh việc làm đúng cách, nghiêm túc, không qua loa.',
  common_usage_examples_jp = ARRAY['ちゃんと食べる', 'ちゃんと勉強する', 'ちゃんと確認する'],
  common_usage_examples_vi = ARRAY['ăn đàng hoàng, ăn đầy đủ', 'học hành nghiêm túc', 'kiểm tra kỹ càng'],
  nuance_points = ARRAY[
    'Làm việc gì đó **đúng cách**, không qua loa',
    'Thái độ **nghiêm túc**, có trách nhiệm',
    'Kết quả **đầy đủ**, hoàn chỉnh'
  ],
  similar_words = ARRAY['しっかり', 'きちんと'],
  similar_words_meaning_vi = ARRAY['vững chắc, chắc chắn', 'ngăn nắp, đúng quy cách'],
  comparison_words = ARRAY['きちんと'],
  comparison_main_descs = ARRAY['Thân mật hơn, thường dùng trong hội thoại hàng ngày.'],
  comparison_other_descs = ARRAY['Trang trọng, chuẩn mực hơn, thường dùng trong văn viết.'],
  common_mistake_note = 'Người học thường dịch ちゃんと trực tiếp thành **"nghiêm túc"**, nhưng trong nhiều tình huống nghĩa tự nhiên hơn là:',
  common_mistake_suggestions = ARRAY['đúng cách', 'đàng hoàng', 'cẩn thận']
where id = '9b0ce664-2f33-5e99-90f7-fe4062d49aae';

update vocabulary_meanings set
  example_jp = 'ちゃんと勉強してください。',
  example_vi = 'Hãy học hành nghiêm túc.',
  extra_examples_jp = ARRAY['ちゃんと確認しました。', '約束はちゃんと守ってね。'],
  extra_examples_vi = ARRAY['Tôi đã kiểm tra cẩn thận rồi.', 'Nhớ giữ lời hứa đàng hoàng nhé.']
where vocabulary_id = '9b0ce664-2f33-5e99-90f7-fe4062d49aae' and order_index = 0;
