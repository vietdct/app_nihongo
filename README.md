# Nihongo — Ứng dụng học tiếng Nhật (JLPT N5–N1)

App đa nền tảng (Android + iOS) từ một codebase **Flutter**, backend chạy trên **Supabase**.
Tài liệu thiết kế & playbook thi công đầy đủ được lưu riêng (artifact); repo này bám theo
**Playbook thi công từng bước**.

Trạng thái hiện tại: **Pha 1 — Nền móng & Auth** (khung code đã dựng, chờ cài toolchain để chạy).

---

## Pha 0 — Chuẩn bị môi trường (làm một lần trên máy)

Chưa có Flutter/Docker/Supabase CLI thì cài theo thứ tự sau (macOS):

```bash
# 1) Flutter SDK (khuyên dùng để có phiên bản mới)
#    Xem: https://docs.flutter.dev/get-started/install/macos
#    Sau khi cài, thêm flutter/bin vào PATH rồi:
flutter doctor            # sửa cho tới khi Flutter + Android toolchain xanh

# 2) Docker Desktop (Supabase local cần Docker)
#    https://www.docker.com/products/docker-desktop/

# 3) Supabase CLI
brew install supabase/tap/supabase
supabase --version
```

Xong khi: `flutter doctor` xanh ở Flutter + Android toolchain, và có một emulator để chạy.

---

## Khởi động project (sau khi cài xong toolchain)

```bash
cd app_nihongo

# 1) Sinh phần nền tảng android/ ios/ (chưa có trong repo).
#    Lệnh này có thể ghi đè pubspec.yaml/lib — khôi phục lại bản trong repo ngay sau đó:
flutter create . --org com.tencuaban --project-name nihongo --platforms=android,ios
git checkout -- pubspec.yaml lib/ analysis_options.yaml

flutter pub get

# 2) Bật Supabase local + áp migration
supabase init          # nếu chưa có supabase/config.toml
supabase start         # in ra API URL + anon key của local
supabase db reset      # áp migration trong supabase/migrations/

# 3) Tạo env.json từ mẫu, điền anon key local vừa in ra
cp env.example.json env.json
#   sửa SUPABASE_ANON_KEY trong env.json

# 4) Chạy app
flutter run --dart-define-from-file=env.json
```

Xong khi: đăng ký một tài khoản email → thấy row mới trong `auth.users` và `profiles`
(trigger chạy) → vào được màn Home.

### Bật đăng nhập Google (tuỳ chọn ở Pha 1)

1. Tạo OAuth Client ID trong Google Cloud Console.
2. Supabase Dashboard → Authentication → Providers → Google → dán Client ID/Secret.
3. Cấu hình redirect URL theo hướng dẫn Supabase cho Android/iOS.

---

## Cấu trúc thư mục (theo mục 8 tài liệu thiết kế)

```
lib/
├── main.dart                    # khởi tạo Supabase + ProviderScope
├── app.dart                     # MaterialApp.router + theme
├── core/
│   ├── config/env.dart          # đọc SUPABASE_URL/ANON_KEY qua --dart-define
│   ├── theme/app_theme.dart     # Material 3, màu kon-iro / shu-iro
│   ├── router/app_router.dart   # go_router + redirect theo trạng thái đăng nhập
│   └── network/                 # supabase_providers.dart (client, auth state)
├── data/                        # (Pha 2+) Drift, repository, dto
├── domain/                      # (Pha 2+) entity, usecase
└── features/
    ├── auth/                    # login_screen, auth_controller
    └── home/                    # home_screen (placeholder)

supabase/
└── migrations/                  # schema + RLS (version control)
```

## Lệnh hay dùng

```bash
flutter analyze                            # phân tích tĩnh
flutter test                               # chạy test
flutter run --dart-define-from-file=env.json
```

## Lộ trình

| Pha | Nội dung | Tag |
|-----|----------|-----|
| 1 | Nền móng & Auth | `v0.1-foundation` |
| 2 | Nội dung học liệu (Drift offline) | `v0.2-content` |
| 3 | Flashcard SRS & Quiz | `v0.3-core-loop` |
| 4 | Ngữ pháp & Subscription | `v0.4-monetization` |
| 5 | AI & Notification | `v0.5-ai` |
| 6 | Offline & Hiệu năng | `v0.6-beta` |
| 7 | JLPT Mock Test & iOS | `v0.9-rc` |
| 8 | Ra mắt Google Play & App Store | `v1.0` |
