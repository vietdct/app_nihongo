# Environment

> Soạn lại sau khi file gốc bị mất (xoá nhầm ngoài git). Chỉ ghi tên biến, không ghi giá trị secret.

## Runtime

- Dart `^3.5.0`, Flutter `>=3.24.0` (theo `pubspec.yaml`).
- Package manager: Dart Pub.
- Phiên bản thực tế trên máy dev: `[NEEDS_CONFIRMATION]`.

## Dịch vụ phụ thuộc

- Supabase (backend, Postgres, Auth, Edge Functions/Deno).
- Drift/SQLite cho lưu trữ cục bộ.

## Biến môi trường — Flutter client (`--dart-define-from-file`, ví dụ `env.json`)

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

## Biến môi trường — Supabase Edge Functions

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `GOOGLE_AI_API_KEY`
- `GEMINI_MODEL`
- `PRONUNCIATION_GEMINI_MODEL`
- `ANTHROPIC_API_KEY`
- `ANTHROPIC_MODEL`

## Khác biệt local / production

- Local: `env.example.json` là mẫu tên biến; Supabase local chạy qua `supabase start` (cần Docker).
- Production: dùng project cloud `iogokoqxmtnbhsuwaveg.supabase.co` (xem `.claude/skills/release-ios/SKILL.md`).
- Biến nào đang thực sự cấu hình trên môi trường deploy: `[NEEDS_CONFIRMATION]`.

## Ràng buộc

- Không commit file cấu hình thật, API key, token, service role key, keystore hoặc credential.
- Flutter client chỉ dùng anon/publishable key.
