# Project Instructions

## Mục tiêu làm việc

- Hoàn thành đúng yêu cầu với thay đổi nhỏ nhất cần thiết.
- Ưu tiên độ chính xác, khả năng kiểm chứng và tiết kiệm context.
- Không tự mở rộng phạm vi, đổi kiến trúc hoặc refactor ngoài yêu cầu.

## Cách lấy context

1. Đọc yêu cầu hiện tại và các file người dùng chỉ định trước.
2. Dùng `docs/CONTEXT_INDEX.md` để chọn tối đa 1–3 tài liệu liên quan nhất.
3. Chỉ đọc `docs/COMMANDS.md` trước khi chạy build, test, lint hoặc database.
4. Đọc `docs/PROGRESS.md` khi tiếp tục công việc từ phiên trước.
5. Đọc `docs/DECISIONS.md` khi thay đổi có liên quan đến quyết định kiến trúc.
6. Không đọc toàn bộ thư mục chỉ để “tìm hiểu dự án”. Tìm theo tên, symbol và nơi sử dụng trước.

## Phạm vi mặc định

- Bỏ qua `node_modules`, `vendor`, `.git`, `dist`, `build`, `.next`, `coverage`, cache, log và file generated.
- Không đọc file bí mật như `.env`, credential, private key hoặc token nếu không thật sự cần.
- Không sửa dependency, lockfile, cấu hình CI/CD hoặc schema database nếu nhiệm vụ không yêu cầu.
- Không xóa dữ liệu, reset repository hoặc chạy lệnh phá huỷ khi chưa được cho phép rõ ràng.

## Quy trình

- Với việc đơn giản: thực hiện trực tiếp.
- Với việc nhiều bước: đưa kế hoạch ngắn 3–5 bước rồi thực hiện.
- Trước khi sửa, xác định nguyên nhân và các file trực tiếp liên quan.
- Sửa tận gốc nhưng giữ diff nhỏ, phù hợp phong cách hiện có.
- Chạy kiểm tra cụ thể nhất trước; chỉ mở rộng khi cần.
- Nếu cùng một hướng thất bại hai lần, dừng thử ngẫu nhiên và đánh giá lại nguyên nhân.
- Nếu thiếu thông tin quan trọng, hỏi một câu cụ thể thay vì quét rộng.

## Cách trả lời

- Ngắn gọn, không lặp lại đề bài hoặc chép toàn bộ file.
- Kết quả cuối gồm: nguyên nhân, thay đổi, kiểm tra và vấn đề còn lại.
- Nêu rõ file đã sửa và kết quả test thực tế.
- Không tuyên bố đã chạy test hoặc hoàn thành nếu chưa kiểm chứng.
- Mặc định giữ câu trả lời dưới 300 từ, trừ khi người dùng yêu cầu chi tiết.

## Kết thúc phiên

Khi công việc kéo dài hoặc người dùng yêu cầu bàn giao, cập nhật `docs/PROGRESS.md`:

- Mục tiêu hiện tại.
- Việc đã hoàn thành.
- File đã thay đổi.
- Kiểm tra đã chạy và kết quả.
- Vấn đề còn lại.
- Bước tiếp theo cụ thể.

Giữ `docs/PROGRESS.md` ngắn; thay nội dung cũ thay vì nối lịch sử vô hạn.
