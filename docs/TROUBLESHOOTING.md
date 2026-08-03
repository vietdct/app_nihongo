# Troubleshooting

> Soạn lại sau khi file gốc bị mất (xoá nhầm ngoài git). Chỉ ghi vấn đề đã thực sự gặp phải, có nguồn.

## Lỗi cấp quyền Flutter SDK cache ngoài sandbox

- Triệu chứng: `flutter pub get`, `flutter analyze`, `flutter test` và build đều không chạy được, hệ thống báo lỗi cấp quyền (404) dù đã đồng ý.
- Trạng thái: ghi nhận trong `docs/PROGRESS.md`, chưa xác định nguyên nhân gốc, chưa có cách khắc phục xác nhận.
- `[NEEDS_CONFIRMATION]`: cần thử lại ngoài môi trường sandbox hiện tại hoặc cấp quyền truy cập Flutter SDK cache cụ thể.

## Mẫu ghi vấn đề mới

```text
### <Tên vấn đề>
- Triệu chứng:
- Expected vs actual:
- Nguyên nhân:
- Cách sửa:
- Regression test (nếu có):
```
