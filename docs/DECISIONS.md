# Decisions (ADR log)

> File gốc bị mất (xoá nhầm ngoài git); các ADR đã ghi trước đó không khôi phục được nội dung thật. Ghi quyết định mới theo mẫu dưới đây, không suy đoán lại các quyết định cũ.

## Mẫu ADR

```text
### <Số thứ tự> — <Tên quyết định>
- Ngày:
- Bối cảnh:
- Quyết định:
- Lý do:
- Trade-off:
- Hệ quả:
```

## Đã biết (suy ra từ codebase, không phải ADR chính thức)

- Backend: Supabase (Postgres + Auth + Edge Functions).
- Local storage: Drift/SQLite.
- State management: Riverpod.
- Điều hướng: go_router.
- Kiến trúc: feature-first kết hợp phân lớp (`core/`, `data/`, `domain/`, `features/`, `shared/`).

Lý do chọn các công nghệ trên và trade-off đã cân nhắc: `[NEEDS_CONFIRMATION]` — không có ADR gốc để đối chiếu.
