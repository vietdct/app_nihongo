# Architecture

> Soạn lại sau khi file gốc bị mất (xoá nhầm ngoài git). Dựa trên khảo sát source hiện có; phần suy luận đánh dấu `[NEEDS_CONFIRMATION]`.

## Cấu trúc thư mục

```text
lib/
├── main.dart       # Entry point
├── app.dart        # MaterialApp, theme và router
├── core/           # Config, network, router, theme và service dùng chung
├── data/           # Database cục bộ và repository implementation
├── domain/         # Entity, repository contract và domain service
├── features/       # UI và provider theo chức năng (feature-first)
└── shared/         # Thành phần dùng chung
```

## Luồng khởi động (đã xác nhận từ mã nguồn)

1. `lib/main.dart` gọi `WidgetsFlutterBinding.ensureInitialized()`.
2. Kiểm tra `SUPABASE_URL` và `SUPABASE_ANON_KEY`.
3. Khởi tạo Supabase.
4. Khởi chạy `NihongoApp` bên trong `ProviderScope` (Riverpod).

## Dependency direction

`features/` (UI + provider) → `domain/` (entity, repository contract, service) → `data/` (implementation, local DB/Supabase). `core/` và `shared/` dùng chung cho mọi lớp. Chi tiết boundary cụ thể giữa các layer: `[NEEDS_CONFIRMATION]`.

## Backend

- Supabase: Postgres, Auth, Edge Functions (Deno) trong `supabase/functions/`.
- Edge Functions hiện có: `auth-login-username`, `ai-grammar-tutor`, `ai-kanji-tutor`, `ai-kaiwa-chat`, `ai-kaiwa-tutor`, `ai-lesson-mission`, `ai-pronunciation-feedback`.
- Local storage: Drift/SQLite.

## Cross-cutting concerns

Error handling, logging, caching/offline strategy, transaction boundary cụ thể: `[NEEDS_CONFIRMATION]` — cần đối chiếu source trước khi dùng làm nguồn chính.
