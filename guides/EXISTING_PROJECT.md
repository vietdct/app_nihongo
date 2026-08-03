# Hướng dẫn cho project có sẵn

Dùng khi repository đã có source code. Mục tiêu là giúp Claude hiểu vừa đủ, xác minh cách chạy rồi mới sửa code, không quét toàn bộ project.

## Cấu trúc mục tiêu

```text
project-root/
├── README.md
├── CLAUDE.md
└── docs/
    ├── CONTEXT_INDEX.md
    ├── PROJECT.md
    ├── ENVIRONMENT.md
    ├── COMMANDS.md
    ├── ARCHITECTURE.md
    ├── REQUIREMENTS.md
    ├── TASK.md
    ├── PROGRESS.md
    └── [tài liệu chuyên môn khi cần]
```

## Nguyên tắc

- Không yêu cầu Claude đọc toàn bộ repository.
- Không đọc dependency folder, build output, cache, coverage, log hoặc generated files.
- Không đọc giá trị `.env`, credential, token hoặc private key.
- Không sửa code trước khi xác định task, phạm vi và cách kiểm tra.
- Mỗi task chỉ nạp tối đa 1–3 tài liệu context liên quan nhất.

## Thứ tự thực hiện

```text
1. Sao chép Context Kit
2. Khảo sát repository
3. Điền PROJECT.md
4. Kiểm tra hoặc tạo README.md
5. Điền ENVIRONMENT.md
6. Xác minh COMMANDS.md
7. Điền ARCHITECTURE.md nếu cần
8. Điền GLOSSARY.md nếu dùng tiếng Nhật
9. Tạo TASK.md
10. Lập kế hoạch
11. Triển khai và kiểm tra
12. Review
13. Cập nhật PROGRESS.md
```

## Bước 1: Sao chép Context Kit

Sao chép `CLAUDE.md` và thư mục `docs/` vào thư mục gốc. Chưa cần điền toàn bộ tài liệu.

Ưu tiên ban đầu:

```text
PROJECT.md → ENVIRONMENT.md → COMMANDS.md → ARCHITECTURE.md
```

## Bước 2: Khảo sát repository

### Prompt 1 — Khảo sát

```text
Tuân theo CLAUDE.md.

Đây là lần đầu làm việc với project này. Trước tiên chỉ khảo sát,
chưa sửa code và chưa chạy lệnh thay đổi hệ thống.

Hãy đọc README.md nếu có, dependency manifest, file cấu hình chính
và cây thư mục ở độ sâu nhỏ.

Xác định:
1. Mục đích có thể suy ra của project.
2. Ngôn ngữ, framework và package manager.
3. Entry point.
4. Tối đa 10 file hoặc thư mục quan trọng.
5. Lệnh có khả năng sử dụng nhưng chưa xác nhận.
6. Thông tin còn thiếu hoặc mâu thuẫn.

Không quét toàn bộ repository. Không đọc dependency folder,
build output, coverage, cache, log, generated files hoặc secret.
Không cài dependency, chạy migration, deploy hoặc sửa file.
Giữ kết quả dưới 500 từ.
```

## Bước 3: Điền `PROJECT.md`

### Prompt 2 — Project context

```text
Dựa trên kết quả khảo sát đã được xác nhận, hãy đề xuất nội dung
cho docs/PROJECT.md.

Chỉ ghi thông tin ổn định. Không ghi suy đoán như sự thật.
Đánh dấu [NEEDS_CONFIRMATION] cho phần chưa chắc chắn.
Chỉ liệt kê tối đa 10 file hoặc thư mục quan trọng.
Không chép lại toàn bộ README.md.
Chưa sửa file; hiển thị bản đề xuất trước.
```

Sau khi kiểm tra:

```text
Nội dung được chấp nhận. Hãy cập nhật docs/PROJECT.md,
xóa placeholder không sử dụng và giữ file ngắn gọn.
```

## Bước 4: Kiểm tra hoặc tạo `README.md`

### Prompt 3 — README

```text
Đọc README.md nếu có và docs/PROJECT.md.

Chưa sửa file. Hãy kiểm tra mô tả project, hướng dẫn setup,
các lệnh, link tài liệu và điểm mâu thuẫn giữa hai file.
Phân biệt lệnh đã xác nhận với lệnh mới chỉ là suy đoán.
Không tự chọn nguồn đúng nếu có mâu thuẫn.
```

Nếu chưa có README:

```text
Dựa trên docs/PROJECT.md, hãy tạo README.md ngắn gọn gồm:
tổng quan, công nghệ, yêu cầu môi trường, quick start,
cấu trúc project và link tới docs.

Dùng placeholder cho lệnh chưa xác nhận. Không ghi secret.
```

## Bước 5: Điền `ENVIRONMENT.md`

### Prompt 4 — Môi trường

```text
Đọc docs/PROJECT.md và các file cấu hình môi trường trực tiếp liên quan.

Đề xuất docs/ENVIRONMENT.md gồm runtime, package manager,
dịch vụ phụ thuộc, tên biến môi trường và khác biệt giữa
local, test, staging, production.

Không đọc giá trị secret. Đánh dấu [NEEDS_CONFIRMATION]
cho thông tin chưa chắc chắn. Chưa cài dependency hoặc chạy ứng dụng.
```

## Bước 6: Xác minh `COMMANDS.md`

### Prompt 5 — Lệnh

```text
Đọc docs/ENVIRONMENT.md và package/build configuration.

Đề xuất các lệnh cần xác minh theo thứ tự:
runtime → package manager → dependency → test cụ thể
→ lint/type-check → build → toàn bộ test.

Với mỗi lệnh, ghi mục đích, khả năng thay đổi dữ liệu,
dependency bên ngoài và điều kiện thành công.
Không chạy ngay. Không đề xuất deploy, production migration hoặc reset dữ liệu.
```

Sau khi cho phép:

```text
Chạy từng lệnh đã được chấp nhận. Chỉ thêm lệnh đã xác nhận
vào docs/COMMANDS.md. Nếu thất bại, báo bằng chứng và không tự sửa
vấn đề ngoài phạm vi.
```

## Bước 7: Điền `ARCHITECTURE.md`

Chỉ cần khi project có nhiều module, layer hoặc service.

### Prompt 6 — Kiến trúc

```text
Đọc docs/PROJECT.md và chỉ các entry point/module chính đã xác định.

Đề xuất docs/ARCHITECTURE.md mô tả kiến trúc hiện tại:
component, trách nhiệm, dependency direction, luồng chính,
transaction boundary và cross-cutting concerns.

Không quét toàn bộ source và không đề xuất kiến trúc mới.
Đánh dấu [NEEDS_CONFIRMATION] cho phần suy luận.
```

## Bước 8: Chuẩn bị tiếng Nhật

### Prompt 7 — Thuật ngữ

```text
Đọc các tài liệu nghiệp vụ tiếng Nhật được chỉ định.

Đề xuất thuật ngữ cần thêm vào docs/GLOSSARY.md, gồm:
日本語, 読み方 nếu chắc chắn, English/Code, tiếng Việt,
nghĩa trong project và từ không nên dùng.

Không tạo từ điển tổng quát. Nội dung chưa rõ đánh dấu [要確認].
```

## Bước 9: Tạo `TASK.md`

### Prompt 8 — Task

```text
Tuân theo CLAUDE.md.

Tôi cần thực hiện:
[Mô tả công việc]

Chưa sửa code. Hãy đề xuất docs/TASK.md gồm kết quả cần đạt,
phạm vi được sửa và không được sửa, acceptance criteria,
file/module liên quan, cách kiểm tra và câu hỏi cần xác nhận.

Không quét toàn bộ repository và không biến giả định thành requirement.
```

## Bước 10: Lập kế hoạch

### Prompt 9 — Plan

```text
Đọc CLAUDE.md, docs/TASK.md và docs/REQUIREMENTS.md nếu liên quan.
Dùng docs/CONTEXT_INDEX.md để chọn tối đa hai tài liệu chuyên môn.

Đối chiếu requirement, xác định nguyên nhân hoặc hướng triển khai,
file trực tiếp liên quan, rủi ro và kế hoạch tối đa 5 bước.

Chưa sửa code. Không refactor ngoài phạm vi.
```

## Bước 11: Triển khai

### Prompt 10 — Implement

```text
Kế hoạch được chấp nhận. Hãy thực hiện đúng docs/TASK.md.

Sửa tối thiểu nhưng xử lý đúng nguyên nhân.
Không refactor ngoài phạm vi hoặc thêm dependency chưa được phép.
Chạy test cụ thể trước. Không deploy hoặc chạy production migration.
Dừng và báo nếu requirement mâu thuẫn.

Báo cáo file thay đổi, test và kết quả, phần chưa kiểm tra
cùng rủi ro còn lại.
```

## Bước 12: Review

```text
Đọc docs/REVIEW_CHECKLIST.md và review riêng thay đổi hiện tại.
Ưu tiên sai requirement, regression, security, transaction,
API compatibility và thiếu test. Không liệt kê style issue
nếu không có tác động thực tế.
```

## Bước 13: Cập nhật `PROGRESS.md`

```text
Cập nhật docs/PROGRESS.md thành snapshot dưới 100 dòng.
Viết đè nội dung cũ, không ghi lịch sử hội thoại.

Bao gồm mục tiêu, trạng thái, việc hoàn thành, file thay đổi,
test và kết quả, phần chưa kiểm tra, vấn đề còn lại,
bước tiếp theo và tối đa 5 file cần đọc ở phiên sau.
```

## Phiên tiếp theo

```text
Tuân theo CLAUDE.md. Đọc docs/PROGRESS.md và chỉ các file
trong phần “Context tối thiểu cho phiên sau”.

Tóm tắt trạng thái trong tối đa 5 bullet, xác nhận bước tiếp theo
rồi tiếp tục. Không điều tra lại phần đã xác nhận.
```

## Công thức ngắn

```text
Khảo sát → PROJECT → README → ENVIRONMENT → COMMANDS
→ ARCHITECTURE → TASK → PLAN → IMPLEMENT
→ TEST/REVIEW → PROGRESS
```
