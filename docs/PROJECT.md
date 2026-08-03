# Project Context

> File này từng tồn tại nhưng bị xoá nhầm ngoài git (chưa từng commit) vào khoảng 2026-08-03. Nội dung dưới đây được soạn lại dựa trên `README.md` hiện có; phần chưa xác nhận giữ nguyên đánh dấu `[NEEDS_CONFIRMATION]`.

## Tên và mục đích

Nihongo — ứng dụng Flutter hỗ trợ học tiếng Nhật theo khung JLPT N5–N1.

## Người dùng

Người học tiếng Nhật theo JLPT N5–N1. Phân khúc cụ thể (học sinh, người đi làm, freemium/premium...): `[NEEDS_CONFIRMATION]`.

## Trạng thái

- Version trong `pubspec.yaml`: `0.1.0+1`, chưa phát hành lên pub.dev.
- Trạng thái chạy thực tế của toàn bộ tính năng: `[NEEDS_CONFIRMATION]`.

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

SDK yêu cầu: Dart `^3.5.0`, Flutter `>=3.24.0`.

## Nền tảng

Repository có cấu hình cho Android, iOS, macOS, Web. Mức độ hoàn thiện từng nền tảng: `[NEEDS_CONFIRMATION]`.

## Module hiện có (từ `lib/features/`)

`auth`, `home`, `lesson`, `vocabulary`, `kanji`, `grammar`, `kaiwa`, `quiz`, `review`, `profile`, `premium`.

## Cấu trúc dự kiến

Xem chi tiết trong `docs/ARCHITECTURE.md` và mục "Cấu trúc repository" của `README.md`.

## Khu vực nhạy cảm

- Không commit `env.json`, API key, service role key, keystore, credential.
- Auth và các Edge Function AI (`ai-*`, `auth-login-username`) xử lý dữ liệu người dùng — xem `docs/SECURITY.md` khi sửa.
