# Context Index

> Dùng bảng này để chọn đúng tài liệu. Không đọc toàn bộ thư mục `docs` theo mặc định.

| Công việc | File nên đọc | File chỉ đọc khi cần |
|---|---|---|
| Hiểu tổng quan dự án | `PROJECT.md` | `ARCHITECTURE.md`, `DECISIONS.md` |
| Bắt đầu task mới | `TASK.md` | `REQUIREMENTS.md`, file kỹ thuật liên quan |
| Tiếp tục phiên trước | `PROGRESS.md` | Các file trong phần “Context tối thiểu” |
| Làm feature | `TASK.md`, `REQUIREMENTS.md` | `ARCHITECTURE.md`, `API.md`, `DATABASE.md` |
| Sửa bug | `TASK.md`, `TROUBLESHOOTING.md` | `PROGRESS.md`, `TESTING.md` |
| Thay đổi API | `API.md`, `REQUIREMENTS.md` | `SECURITY.md`, `DECISIONS.md` |
| Thay đổi database | `DATABASE.md`, `REQUIREMENTS.md` | `SECURITY.md`, `RELEASE.md` |
| Viết hoặc sửa test | `TESTING.md` | `REQUIREMENTS.md`, `COMMANDS.md` |
| Code review | `REVIEW_CHECKLIST.md` | `SECURITY.md`, file domain liên quan |
| Bảo mật | `SECURITY.md` | `API.md`, `DATABASE.md` |
| Build, lint, test | `COMMANDS.md` | `TESTING.md`, `ENVIRONMENT.md` |
| Release/deploy | `RELEASE.md` | `COMMANDS.md`, `ENVIRONMENT.md` |
| Dịch hoặc viết tiếng Nhật | `JAPANESE_STYLE.md`, `GLOSSARY.md` | `REQUIREMENTS.md` |
| Quyết định kiến trúc | `ARCHITECTURE.md`, `DECISIONS.md` | `PROJECT.md` |

## Quy tắc

- Bắt đầu với tối đa 1–3 file phù hợp nhất.
- Chỉ mở thêm tài liệu khi có câu hỏi cụ thể.
- Không nạp đồng thời `API.md`, `DATABASE.md`, `SECURITY.md` và `TESTING.md` nếu task chỉ liên quan một khu vực.
- Ưu tiên file hoặc symbol trực tiếp liên quan hơn tài liệu tổng quát.
