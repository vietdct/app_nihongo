-- Grammar Practice mở rộng (Đợt 4): dữ liệu tách-từ thật cho câu ví dụ, soạn
-- thủ công (tiếng Nhật không có khoảng trắng, không tự tách chính xác được).
-- practice_tokens: example_jp tách thành từ/cụm có nghĩa, ĐÚNG THỨ TỰ — dùng
-- cho bài ghép câu (word order) và bài điền từ (fill blank).
-- practice_blank_index: index trong practice_tokens là từ/trợ từ bị ẩn cho
-- bài điền từ — null nếu mẫu này dùng cho bài ghép câu thay vì điền từ, hoặc
-- chưa soạn (mảng rỗng mặc định, honest — tự rơi về bài ghép-câu-với-mẫu).
alter table grammar_points
  add column practice_tokens text[] not null default '{}',
  add column practice_blank_index integer;
