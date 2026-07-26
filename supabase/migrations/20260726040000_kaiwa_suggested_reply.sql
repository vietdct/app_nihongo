-- AI Kaiwa: lưu thêm gợi ý câu trả lời tiếp theo (tính năng "Gợi ý trả lời")
-- do AI sinh cùng lúc với reply_jp — chỉ có ý nghĩa ở message role 'ai'.
alter table kaiwa_messages add column suggested_reply_jp text;
alter table kaiwa_messages add column suggested_reply_vi text;
