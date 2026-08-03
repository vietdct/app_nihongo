# Security

> Soạn lại sau khi file gốc bị mất (xoá nhầm ngoài git). Baseline chi tiết (threat model, authorization matrix...) chưa được xác nhận lại đầy đủ.

## Nguyên tắc đã xác nhận (từ `README.md` / `CLAUDE.md`)

- Không commit file cấu hình thật, API key, token, service role key, keystore hoặc credential.
- Flutter client chỉ dùng Supabase anon/publishable key, không dùng service role key.
- Edge Functions dùng `SUPABASE_SERVICE_ROLE_KEY`, `GOOGLE_AI_API_KEY`, `ANTHROPIC_API_KEY` — các biến này chỉ tồn tại phía server (Edge Functions), không đưa vào client.
- Không đọc giá trị secret trong `.env`/`env.json` khi không thật sự cần.

## Authentication

- Supabase Auth + Edge Function `auth-login-username` cho đăng nhập bằng username.
- Chi tiết luồng, rate limit, validation: `[NEEDS_CONFIRMATION]` — xem thêm memory phiên trước về "vá lỗ hổng auth-login-username" nếu cần đối chiếu.

## Data classification, authorization matrix, logging/privacy

`[NEEDS_CONFIRMATION]` — cần khảo sát lại source (`lib/features/auth/`, `supabase/functions/auth-login-username/`) trước khi điền.
