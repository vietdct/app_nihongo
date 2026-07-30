-- Đổi câu hỏi nghe hiểu từ tiếng Việt sang tiếng Nhật (đề bài + đáp án đều
-- bằng tiếng Nhật, đúng tinh thần luyện nghe/đọc hiểu thật thay vì chỉ đọc
-- bản dịch tiếng Việt rồi nghe minh hoạ tiếng Nhật) — xem seed_listening_n5.sql
-- và seed_listening_n5_more.sql cho nội dung tiếng Nhật đã soạn lại.
alter table listening_dialogues rename column question_vi to question_ja;
