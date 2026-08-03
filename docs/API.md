# API

> Soạn lại sau khi file gốc bị mất (xoá nhầm ngoài git). Project gọi Supabase trực tiếp từ client (không có REST API riêng đã biết) cộng với các Supabase Edge Functions dưới đây — đóng vai trò bề mặt API cần tài liệu hoá.

## Edge Functions hiện có (đã xác nhận tồn tại, chưa xác nhận contract chi tiết)

| Function | Mục đích (suy đoán từ tên) |
|---|---|
| `auth-login-username` | Đăng nhập bằng username |
| `ai-grammar-tutor` | Trợ lý AI cho ngữ pháp |
| `ai-kanji-tutor` | Trợ lý AI cho Kanji |
| `ai-kaiwa-chat` | Chat hội thoại AI |
| `ai-kaiwa-tutor` | Hướng dẫn hội thoại AI |
| `ai-lesson-mission` | Nhiệm vụ bài học AI |
| `ai-pronunciation-feedback` | Phản hồi phát âm |

Request/response contract, validation, auth, error format, idempotency của từng function: `[NEEDS_CONFIRMATION]` — đọc `supabase/functions/<tên>/index.ts` tương ứng khi cần sửa.

## Ràng buộc

- Không tạo endpoint/function ngoài phạm vi task đang duyệt.
- Không thay đổi contract hiện có nếu task không yêu cầu breaking change.
