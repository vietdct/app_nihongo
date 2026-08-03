---
name: wrap-nihongo
description: End a work session on app_nihongo by overwriting docs/PROGRESS.md with a short snapshot, so the next session can resume with minimal token usage. Use when the user says "kết thúc phiên", "bàn giao", "lưu tiến độ", "cập nhật progress", "chốt phiên làm việc", "wrap up", or before closing a chat that made non-trivial changes to app_nihongo.
---

# Kết thúc phiên làm việc — app_nihongo

Mục tiêu: ghi lại đúng trạng thái hiện tại vào `docs/PROGRESS.md` để phiên sau tốn ít token nhất khi tiếp tục (dùng cùng với skill `resume-nihongo`).

## Cách làm

Viết đè toàn bộ `docs/PROGRESS.md` (không nối thêm lịch sử cũ), giữ dưới khoảng 100 dòng, gồm đúng các mục sau:

1. **Mục tiêu** — mục tiêu hiện tại của công việc đang làm.
2. **Trạng thái** — giai đoạn (vd: Hoàn tất / Đang làm / Bị chặn) và việc hoàn thành gần nhất.
3. **Đã hoàn thành** — liệt kê ngắn gọn, không chép code hay log dài.
4. **File đã thay đổi** — đường dẫn + mô tả 1 dòng mỗi file.
5. **Kiểm tra** — lệnh test/build đã chạy và kết quả thật (Pass/Fail/chưa chạy). Không tuyên bố đã chạy nếu chưa chạy.
6. **Vấn đề còn lại** — rủi ro hoặc phần chưa xử lý.
7. **Bước tiếp theo** — hành động cụ thể, có thể thực hiện ngay ở phiên sau.
8. **Context tối thiểu cho phiên sau** — tối đa 5 file cần đọc, và phần không cần đọc lại.

## Ràng buộc

- Không ghi lịch sử hội thoại hay diễn giải dài dòng.
- Không chép toàn bộ diff hoặc log build vào file.
- Không tự nhận đã test/build thành công nếu chưa thực sự kiểm chứng trong phiên này.
- Nếu có thay đổi code chưa commit, nhắc người dùng nhưng không tự `git add`/`git commit` trừ khi được yêu cầu.
