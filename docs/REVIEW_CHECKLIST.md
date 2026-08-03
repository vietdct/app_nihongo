# Review Checklist

> Soạn lại sau khi file gốc bị mất (xoá nhầm ngoài git). Nội dung dưới đây dựng lại từ quy trình review đã mô tả trong `guides/PROJECT_PROMPT_WORKFLOW.md` — không phải bản gốc, nhưng cùng tiêu chí.

## Ưu tiên khi review (theo thứ tự)

1. Sai requirement / acceptance criteria.
2. Bug hoặc regression.
3. Security (injection, secret leak, unsafe input).
4. Authentication và authorization.
5. Transaction hoặc concurrency (đặc biệt các thao tác Supabase ghi đồng thời).
6. API / contract compatibility (Edge Functions, local DB schema).
7. Thiếu test quan trọng cho thay đổi.

## Không liệt kê

- Vấn đề style thuần tuý không có tác động thực tế (đã có `dart format`/lint xử lý).

## Định dạng mỗi finding

- Mức độ.
- File và vị trí.
- Điều kiện xảy ra.
- Tác động.
- Cách sửa đề xuất.

## Nếu không phát hiện vấn đề

Nêu rõ: phạm vi đã review, test đã kiểm tra, rủi ro chưa được kiểm chứng.
