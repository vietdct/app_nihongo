---
name: resume-nihongo
description: Resume work on the app_nihongo Flutter project at the start of a session or after a break, loading only minimal context to save tokens. Use when the user says "tiếp tục project app_nihongo", "làm tiếp app_nihongo", "resume nihongo", "tiếp tục công việc", opens a new chat to continue prior work on this repo, or asks "trạng thái hiện tại của project là gì" / "đang làm tới đâu rồi".
---

# Tiếp tục phiên làm việc — app_nihongo

Mục tiêu: nạp đúng lượng context tối thiểu để tiếp tục công việc dở dang, không đọc lại toàn bộ repo hay lịch sử hội thoại cũ.

## Các bước

1. Đọc `docs/PROGRESS.md`.
2. Chỉ đọc thêm các file được liệt kê trong mục "Context tối thiểu cho phiên sau" của `PROGRESS.md`. Không đọc file nào khác trừ khi bước 4 cho thấy thiếu thông tin.
3. Tóm tắt trạng thái hiện tại trong tối đa 5 bullet: mục tiêu, đã xong gì, đang chặn gì (nếu có).
4. Nếu `PROGRESS.md` không đủ thông tin để xác định bước tiếp theo, hỏi đúng một câu cụ thể về phần còn thiếu — không đoán và không quét toàn bộ repository để tự suy luận.
5. Xác nhận bước tiếp theo (mục "Bước tiếp theo" trong PROGRESS.md) rồi tiếp tục thực hiện đúng bước đó.
6. Không điều tra lại phần đã được đánh dấu "Không cần đọc lại" trong PROGRESS.md.

## Nếu người dùng đưa yêu cầu/task mới thay vì tiếp tục task cũ

Coi đây là task mới: dùng `docs/CONTEXT_INDEX.md` để chọn tối đa 1–3 tài liệu chuyên môn liên quan, cập nhật `docs/TASK.md` theo đúng quy trình trong `CLAUDE.md` (Task → Plan → Implement → Review → Progress) thay vì tiếp tục task cũ trong PROGRESS.md.

## Ràng buộc

- Không quét toàn bộ repository.
- Không đọc `node_modules`, build output, cache, coverage, log hoặc file generated.
- Không sửa code trước khi bước tiếp theo đã được xác nhận rõ.
