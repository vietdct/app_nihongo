# Nihongo — Ứng dụng học tiếng Nhật JLPT

Nihongo là ứng dụng Flutter hỗ trợ học tiếng Nhật theo khung JLPT N5–N1. Theo mã nguồn và cấu hình hiện có, project bao gồm các module bài học, từ vựng, Kanji, ngữ pháp, quiz, hội thoại, ôn tập và hồ sơ người học.

Project sử dụng Supabase cho backend và Drift/SQLite cho lưu trữ cục bộ. Một số Supabase Edge Functions tích hợp dịch vụ AI và xử lý đăng nhập bằng username.

> Trạng thái trong manifest: `0.1.0+1`, không phát hành lên pub.dev. Trạng thái chạy thực tế của toàn bộ tính năng: `[NEEDS_CONFIRMATION]`.

## Công nghệ đã xác nhận

| Thành phần | Công nghệ |
|---|---|
| Ngôn ngữ ứng dụng | Dart |
| Framework | Flutter |
| State management và DI | Riverpod |
| Điều hướng | go_router |
| Backend client | Supabase Flutter |
| Database cục bộ | Drift / SQLite |
| Edge Functions | Supabase Functions / Deno |
| Giọng nói | speech_to_text, flutter_tts, record |
| Kiểm thử | flutter_test, mocktail |
| Package manager | Dart Pub |

Yêu cầu SDK được khai báo trong `pubspec.yaml`:

- Dart `^3.5.0`.
- Flutter `>=3.24.0`.

Phiên bản Flutter và Dart thực tế đang được dùng trên máy phát triển: `[NEEDS_CONFIRMATION]`.

## Nền tảng

Repository có cấu hình cho:

- Android.
- iOS.
- macOS.
- Web.

Mức độ hoàn thiện và hỗ trợ phát hành của từng nền tảng: `[NEEDS_CONFIRMATION]`.

## Module hiện có trong mã nguồn

Các thư mục dưới `lib/features/` xác nhận project có mã nguồn cho:

- `auth`: xác thực người dùng.
- `home`: màn hình chính và thông tin học tập.
- `lesson`: danh sách, chi tiết và luồng học bài.
- `vocabulary`: danh sách, flashcard và ôn từ vựng.
- `kanji`: danh sách, chi tiết, luyện viết và ôn Kanji.
- `grammar`: nội dung, luyện tập và ôn ngữ pháp.
- `kaiwa`: hội thoại, shadowing và thống kê.
- `quiz`: kiểm tra theo nội dung.
- `review`: ôn tập tổng hợp.
- `profile`: hồ sơ người học.
- `premium`: giao diện liên quan đến Premium.

Các Supabase Edge Functions hiện có:

- `auth-login-username`.
- `ai-grammar-tutor`.
- `ai-kanji-tutor`.
- `ai-kaiwa-chat`.
- `ai-kaiwa-tutor`.
- `ai-lesson-mission`.
- `ai-pronunciation-feedback`.

Việc các module và Edge Functions hoạt động hoàn chỉnh trên môi trường local hoặc production: `[NEEDS_CONFIRMATION]`.

## Kiến trúc tổng quan

Project được tổ chức theo hướng feature-first kết hợp phân lớp:

```text
lib/
├── main.dart       # Entry point
├── app.dart        # MaterialApp, theme và router
├── core/           # Config, network, router, theme và service dùng chung
├── data/           # Database cục bộ và repository implementation
├── domain/         # Entity, repository contract và domain service
├── features/       # UI và provider theo chức năng
└── shared/         # Thành phần dùng chung
```

Luồng khởi động đã xác nhận từ mã nguồn:

1. `lib/main.dart` gọi `WidgetsFlutterBinding.ensureInitialized()`.
2. Kiểm tra `SUPABASE_URL` và `SUPABASE_ANON_KEY`.
3. Khởi tạo Supabase.
4. Khởi chạy `NihongoApp` bên trong `ProviderScope`.

## Cấu hình môi trường

Ứng dụng Flutter đọc cấu hình bằng `--dart-define-from-file`.

Biến bắt buộc ở Flutter client:

- `SUPABASE_URL`.
- `SUPABASE_ANON_KEY`.

Tên biến được Edge Functions tham chiếu:

- `SUPABASE_URL`.
- `SUPABASE_ANON_KEY`.
- `SUPABASE_SERVICE_ROLE_KEY`.
- `GOOGLE_AI_API_KEY`.
- `GEMINI_MODEL`.
- `PRONUNCIATION_GEMINI_MODEL`.
- `ANTHROPIC_API_KEY`.
- `ANTHROPIC_MODEL`.

Biến nào đang được cấu hình trên môi trường deploy: `[NEEDS_CONFIRMATION]`.

Không commit file cấu hình thật, API key, token, service role key, keystore hoặc credential. Chỉ sử dụng anon/publishable key ở Flutter client.

## Cách chạy dự kiến

Các lệnh dưới đây được suy ra từ Flutter, cấu hình source và README hiện có nhưng chưa được chạy xác nhận trong lần cập nhật tài liệu này.

```bash
flutter pub get
cp env.example.json env.json
flutter run --dart-define-from-file=env.json
```

Trước khi chạy, cần cung cấp tên biến sau trong `env.json`:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
```

Trạng thái chạy thành công trên Android, iOS, macOS hoặc Web: `[NEEDS_CONFIRMATION]`.

## Supabase local

Repository có:

- `supabase/config.toml`.
- Migration trong `supabase/migrations/`.
- Edge Functions trong `supabase/functions/`.
- Các file seed nội dung N5 và luyện nghe ở thư mục `supabase/`.

Cách chạy dự kiến, chưa được xác nhận trong lần cập nhật này:

```bash
supabase start
supabase db reset
supabase functions serve
```

Yêu cầu Docker, phiên bản Supabase CLI, thứ tự seed và khả năng tương thích migration: `[NEEDS_CONFIRMATION]`.

Không chạy migration hoặc seed trên production nếu chưa có quy trình backup và rollback được xác nhận.

## Kiểm tra dự kiến

Repository có test trong `test/`. Các lệnh dự kiến:

```bash
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test
```

Kết quả analyze và test hiện tại: `[NEEDS_CONFIRMATION]`.

## Build dự kiến

Các lệnh build tiêu chuẩn có thể phù hợp với project nhưng chưa được chạy xác nhận:

```bash
flutter build apk --release --dart-define-from-file=env.json
flutter build appbundle --release --dart-define-from-file=env.json
flutter build ios --release --dart-define-from-file=env.json
```

Android signing, iOS signing, bundle identifier, package name và cấu hình phát hành cửa hàng: `[NEEDS_CONFIRMATION]`.

## Cấu trúc repository

```text
app_nihongo/
├── android/              # Cấu hình Android
├── ios/                  # Cấu hình iOS
├── macos/                # Cấu hình macOS
├── web/                  # Cấu hình Web
├── assets/fonts/         # Font đóng gói cục bộ
├── lib/                  # Mã nguồn Flutter
├── supabase/             # Config, migration, function và seed
├── test/                 # Test Flutter/Dart
├── docs/                 # Tài liệu project
├── env.example.json      # Mẫu tên cấu hình client
├── pubspec.yaml          # Manifest dependency
└── pubspec.lock          # Phiên bản dependency đã khóa
```

## Tài liệu liên quan

- `docs/PROJECT.md`: context ổn định của project.
- `docs/ENVIRONMENT.md`: runtime, service và tên biến môi trường.
- `docs/ARCHITECTURE.md`: `[NEEDS_CONFIRMATION]` — cần đối chiếu với source trước khi sử dụng làm nguồn chính.
- `docs/COMMANDS.md`: `[NEEDS_CONFIRMATION]` — cần cập nhật sau khi các lệnh được chạy thành công.
- `docs/PROGRESS.md`: `[NEEDS_CONFIRMATION]` — cần kiểm tra độ mới trước khi tiếp tục task.

## Giấy phép

File `LICENSE` chưa được xác nhận trong khảo sát hiện tại. Chính sách sử dụng và phân phối source: `[NEEDS_CONFIRMATION]`.
