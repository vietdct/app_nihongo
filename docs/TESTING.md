# Testing

> Soạn lại sau khi file gốc bị mất (xoá nhầm ngoài git). Chiến lược chi tiết chưa được xác nhận lại đầy đủ — đây là khung tối thiểu dựa trên những gì quan sát được trong source.

## Công cụ

- `flutter_test` cho unit/widget test.
- `mocktail` cho mock.

## Test đã biết tồn tại (từ khảo sát source, chưa chắc đầy đủ)

- `test/domain/vocabulary_test.dart` — `Vocabulary.primaryMeaning`.
- `test/domain/quiz_generator_test.dart`.
- `test/domain/srs_scheduler_test.dart` (tham chiếu trong `docs/TASK.md`).

Danh sách đầy đủ, coverage, và test integration/E2E: `[NEEDS_CONFIRMATION]`.

## Nguyên tắc

- Ưu tiên regression test khi sửa bug.
- Chạy test cụ thể liên quan đến thay đổi trước, chỉ chạy toàn bộ khi cần.
- Không commit test giả (test luôn pass bất kể logic).

## Lệnh

```bash
flutter test path/to/test_file.dart   # test cụ thể
flutter test                          # toàn bộ
```

Xem `docs/COMMANDS.md` về trạng thái xác minh lệnh.
