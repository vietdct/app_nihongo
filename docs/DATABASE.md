# Database

> Soạn lại sau khi file gốc bị mất (xoá nhầm ngoài git). Data model chi tiết chưa được xác nhận lại — cần đọc `supabase/migrations/` trước khi điền đầy đủ.

## Đã xác nhận

- Backend: Supabase (Postgres).
- Local: Drift/SQLite (`lib/data/`).
- Migration: `supabase/migrations/`.
- Seed: file seed nội dung N5 và luyện nghe trong thư mục `supabase/`.

## Chưa xác nhận

- Entity, quan hệ, constraint, invariant, index: `[NEEDS_CONFIRMATION]`.
- Bảng liên quan mistake history, statistics, AI coach (nhắc trong `docs/TASK.md`): `[NEEDS_CONFIRMATION]`.
- Dữ liệu nhạy cảm cần phân loại riêng: `[NEEDS_CONFIRMATION]`.

## Quy tắc

- Không chạy migration hoặc seed trên production nếu chưa có quy trình backup/rollback được xác nhận.
- Không tạo bảng cho chức năng ngoài phạm vi task đang làm.
