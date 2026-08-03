# Commands

> Soạn lại sau khi file gốc bị mất (xoá nhầm ngoài git).

## Đã xác nhận (chạy thành công trong phiên 2026-08-03)

| Lệnh | Kết quả |
|---|---|
| `flutter analyze` | `No issues found!` — giới hạn quyền sandbox trước đó không còn tái hiện |
| `flutter test test/domain/srs_scheduler_test.dart test/features/vocabulary/vocab_review_providers_test.dart` | 15/15 pass |

## Đã xác nhận (chạy thành công trong phiên 2026-08-04, Mixed Quiz Task 2-9)

| Lệnh | Kết quả |
|---|---|
| `flutter analyze` | `No issues found!` |
| `flutter test` (toàn bộ, không giới hạn file) | 139/139 pass (sau Task 9) |

## Cần xác minh trước khi coi là đáng tin

| Lệnh | Mục đích | Thay đổi dữ liệu | Cần network |
|---|---|---|---|
| `flutter pub get` | Cài dependency | Không | Có |
| `dart format --output=none --set-exit-if-changed lib test` | Kiểm tra format | Không | Không |
| `flutter run --dart-define-from-file=env.json` | Chạy app dev | Không (đọc dữ liệu qua Supabase) | Có |
| `supabase start` | Chạy Supabase local (cần Docker) | Có (local) | Không |
| `supabase db reset` | Reset DB local theo migration | Có (local, phá huỷ dữ liệu local) | Không |
| `supabase functions serve` | Chạy Edge Functions local | Không | Có |

## Build (chưa xác nhận)

```bash
flutter build apk --release --dart-define-from-file=env.json
flutter build appbundle --release --dart-define-from-file=env.json
flutter build ios --release --dart-define-from-file=env.json
```

Xem thêm `.claude/skills/release-ios/SKILL.md` cho quy trình build release iOS lên thiết bị thật đã được xác nhận.

## Ghi chú

- Chỉ thêm lệnh vào bảng "đã xác nhận" sau khi chạy thành công thật trong phiên làm việc.
