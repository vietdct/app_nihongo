# Release

> Soạn lại sau khi file gốc bị mất (xoá nhầm ngoài git). Phần đã xác nhận lấy từ `.claude/skills/release-ios/SKILL.md`.

## iOS — build release lên thiết bị thật (đã xác nhận, có quy trình riêng)

Dùng skill `.claude/skills/release-ios/SKILL.md`. Tóm tắt:

- `env.json` phải trỏ Supabase cloud (`https://iogokoqxmtnbhsuwaveg.supabase.co`), không phải local emulator.
- Kiểm tra Edge Function nào có thay đổi local chưa deploy trước khi build.
- Signing: `DEVELOPMENT_TEAM = 7F5FC9KAFS`, `CODE_SIGN_STYLE = Automatic`, bundle id `com.tencuaban.nihongo`.
- Build: `flutter build ios --release --dart-define-from-file=env.json`.
- Cài: `flutter install --release -d <device-udid>`.
- Free Apple Developer account: chứng chỉ hết hạn sau ~7 ngày, cần build lại.

## Android — chưa có quy trình xác nhận

- Theo `docs/PROGRESS.md`: Android release hiện vẫn dùng debug signing key, bundle ID mẫu `com.tencuaban.nihongo`. Chưa có quy trình release chính thức.
- `[NEEDS_CONFIRMATION]`: signing thật, package name production, quy trình lên Play Store.

## App Store / TestFlight, Web, macOS

`[NEEDS_CONFIRMATION]` — chưa có quy trình được xác nhận trong repo.
