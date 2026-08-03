# Hướng dẫn cho project hoàn toàn mới

Dùng khi project mới chỉ có ý tưởng hoặc chưa có source code. Mục tiêu là làm rõ requirement, chọn công nghệ có căn cứ, scaffold tối thiểu và triển khai từng task nhỏ.

## Cấu trúc mục tiêu

```text
project-root/
├── README.md
├── CLAUDE.md
├── source-code/
└── docs/
    ├── CONTEXT_INDEX.md
    ├── REQUIREMENTS.md
    ├── PROJECT.md
    ├── ARCHITECTURE.md
    ├── DECISIONS.md
    ├── ENVIRONMENT.md
    ├── COMMANDS.md
    ├── TASK.md
    ├── PROGRESS.md
    └── [tài liệu chuyên môn khi cần]
```

## Nguyên tắc

- Không viết code khi requirement còn mơ hồ.
- Không chọn framework chỉ vì phổ biến.
- Tách rõ MVP và phần làm sau.
- Ghi rõ giả định và câu hỏi chưa xác nhận.
- Thiết kế vừa đủ cho quy mô hiện tại.
- Không triển khai toàn bộ MVP trong một task.

## Thứ tự thực hiện

```text
1. Sao chép Context Kit
2. Làm rõ ý tưởng
3. Chốt MVP
4. Điền REQUIREMENTS.md
5. Xác định constraint
6. Chọn stack và ghi DECISIONS.md
7. Điền PROJECT.md
8. Thiết kế ARCHITECTURE.md
9. Thiết kế API/DATABASE/SECURITY khi cần
10. Điền TESTING.md và ENVIRONMENT.md
11. Lập kế hoạch scaffold
12. Scaffold và xác minh COMMANDS.md
13. Tạo README.md
14. Chia MVP thành task
15. Triển khai từng task
16. Review và cập nhật PROGRESS.md
```

## Bước 1: Sao chép Context Kit

Tạo thư mục project rồi sao chép `CLAUDE.md` và thư mục `docs/`. Chưa cần tạo source code.

File đầu tiên cần xử lý:

```text
REQUIREMENTS.md
```

## Bước 2: Làm rõ ý tưởng

### Prompt 1 — Phân tích ý tưởng

```text
Tuân theo CLAUDE.md.

Tôi đang bắt đầu project hoàn toàn mới. Chưa tạo code,
chưa chọn framework và chưa thiết kế database.

Ý tưởng:
[Mô tả ý tưởng]

Hãy phân tích:

1. Vấn đề cần giải quyết.
2. Đối tượng người dùng.
3. Luồng sử dụng chính.
4. Chức năng bắt buộc cho MVP.
5. Chức năng có thể để sau.
6. Dữ liệu chính.
7. Yêu cầu phi chức năng.
8. Giả định hiện tại.
9. Rủi ro và điểm chưa rõ.
10. Câu hỏi cần xác nhận.

Không viết code, không chọn framework, không thiết kế database chi tiết
và không tự thêm chức năng.
```

## Bước 3: Chốt MVP

### Prompt 2 — Phạm vi MVP

```text
Dựa trên thông tin đã xác nhận, hãy chia phạm vi thành:

- Must have.
- Should have.
- Could have.
- Out of scope.

Với mỗi Must have, ghi actor, input, hành vi, output,
trường hợp lỗi chính và acceptance criteria.

Không viết code và chưa chọn kiến trúc.
```

## Bước 4: Điền `REQUIREMENTS.md`

### Prompt 3 — Requirements

```text
Phạm vi MVP được chấp nhận.

Hãy cập nhật docs/REQUIREMENTS.md với:

- Mục tiêu và actor.
- Phạm vi và ngoài phạm vi.
- Functional requirements có ID.
- Non-functional requirements.
- Business rules.
- Acceptance criteria.
- Dữ liệu và state transition.
- Giả định và câu hỏi còn lại.

Mỗi requirement phải ngắn và kiểm chứng được.
Không thêm chức năng mới và không biến giả định thành Confirmed.
```

## Bước 5: Xác định constraint

### Prompt 4 — Constraint kỹ thuật

```text
Đọc docs/REQUIREMENTS.md.

Trước khi chọn công nghệ, hãy xác định constraint về:

- Scale và performance.
- Security và privacy.
- Availability.
- Integration.
- Deployment và operation.
- Kỹ năng team.
- Budget và deadline.

Liệt kê thông tin còn thiếu. Chưa đề xuất framework.
```

## Bước 6: Chọn stack

### Prompt 5 — So sánh công nghệ

```text
Dựa trên requirement và constraint đã xác nhận,
hãy đề xuất tối đa 3 phương án công nghệ.

Đánh giá mức phù hợp requirement, tốc độ phát triển,
độ phức tạp vận hành, testability, security, chi phí,
khả năng mở rộng, kỹ năng team và lock-in.

Đưa một khuyến nghị cùng trade-off. Chưa scaffold hoặc viết code.
```

Sau khi chọn:

```text
Phương án [Tên] được chấp nhận. Hãy ghi quyết định vào
docs/DECISIONS.md theo ADR: bối cảnh, quyết định, lý do,
trade-off và hệ quả.
```

## Bước 7: Điền `PROJECT.md`

### Prompt 6 — Project context

```text
Đọc docs/REQUIREMENTS.md và quyết định công nghệ đã chấp nhận.

Cập nhật docs/PROJECT.md với tên, mục đích, người dùng,
trạng thái, công nghệ, cấu trúc dự kiến, luồng chính,
quy ước ban đầu và khu vực nhạy cảm.

Không thêm chi tiết chưa được quyết định.
```

## Bước 8: Thiết kế kiến trúc tối thiểu

### Prompt 7 — Architecture

```text
Đọc docs/REQUIREMENTS.md, docs/PROJECT.md và docs/DECISIONS.md.

Đề xuất kiến trúc tối thiểu cho MVP, gồm:

- Component và trách nhiệm.
- Dependency direction.
- Luồng chính.
- Storage tổng quan.
- Authentication/authorization nếu cần.
- Tích hợp ngoài.
- Test boundary.

Không chọn microservice, queue, cache hoặc abstraction
nếu chưa có requirement rõ ràng. Chưa scaffold code.
```

Sau khi duyệt:

```text
Kiến trúc được chấp nhận. Hãy cập nhật docs/ARCHITECTURE.md
và ghi ADR bổ sung vào docs/DECISIONS.md nếu cần.
```

## Bước 9: Thiết kế chuyên môn khi cần

Chỉ đọc và cập nhật đúng file liên quan.

### API

```text
Đọc REQUIREMENTS.md và ARCHITECTURE.md. Đề xuất API tối thiểu
cho MVP: endpoint, request/response, auth, validation,
error contract và idempotency. Không tạo endpoint ngoài MVP.
Cập nhật docs/API.md sau khi được duyệt.
```

### Database

```text
Đọc REQUIREMENTS.md và ARCHITECTURE.md. Đề xuất data model tối thiểu:
entity, quan hệ, constraint, invariant, trạng thái, index có căn cứ
và dữ liệu nhạy cảm. Không tạo bảng cho chức năng ngoài MVP.
Cập nhật docs/DATABASE.md sau khi được duyệt.
```

### Security

```text
Đọc requirement, architecture và phần API/database liên quan.
Xác định security baseline: data classification, authentication,
authorization, validation, secret management, logging/privacy
và threat quan trọng. Cập nhật docs/SECURITY.md sau khi duyệt.
```

### Testing

```text
Đọc REQUIREMENTS.md và ARCHITECTURE.md. Đề xuất testing strategy:
unit, integration, contract, E2E/smoke, fixture, mock,
permission test và thứ tự chạy. Ưu tiên giá trị thay vì coverage hình thức.
Cập nhật docs/TESTING.md sau khi duyệt.
```

## Bước 10: Điền `ENVIRONMENT.md`

### Prompt 8 — Environment

```text
Dựa trên stack và kiến trúc đã chấp nhận,
cập nhật docs/ENVIRONMENT.md với runtime, package manager,
dịch vụ local, tên biến môi trường, các environment
và quy trình setup dự kiến.

Không tạo credential hoặc ghi secret thật.
```

## Bước 11: Lập kế hoạch scaffold

### Prompt 9 — Scaffold plan

```text
Đọc CLAUDE.md, PROJECT.md, ARCHITECTURE.md,
ENVIRONMENT.md và TESTING.md.

Đề xuất kế hoạch scaffold tối thiểu:

1. File và thư mục cần tạo.
2. Dependency bắt buộc.
3. Cấu hình development.
4. Entry point hoặc health check.
5. Một test chứng minh môi trường hoạt động.
6. Lệnh kiểm tra.

Không triển khai feature và không thêm dependency có thể chỉ cần sau này.
Chưa tạo file cho đến khi kế hoạch được duyệt.
```

## Bước 12: Scaffold và xác minh

### Prompt 10 — Tạo skeleton

```text
Kế hoạch scaffold được chấp nhận.

Hãy tạo skeleton tối thiểu, chỉ thêm dependency đã duyệt,
tạo config an toàn với placeholder, entry point/health check
và một test chứng minh project hoạt động.

Chạy format, lint, type-check, test hoặc build phù hợp.
Cập nhật docs/COMMANDS.md chỉ với lệnh đã xác nhận thành công.
Chưa triển khai feature nghiệp vụ.
```

## Bước 13: Tạo `README.md`

### Prompt 11 — README

```text
Đọc docs/PROJECT.md, docs/ENVIRONMENT.md và docs/COMMANDS.md.

Tạo README.md dành cho developer mới gồm:
tổng quan, MVP, công nghệ, requirements, quick start,
commands, project structure, link tài liệu và workflow.

Chỉ dùng lệnh đã xác nhận. Không ghi secret và không chép
toàn bộ tài liệu chuyên môn vào README.
```

## Bước 14: Chia MVP thành task

### Prompt 12 — Task breakdown

```text
Đọc docs/REQUIREMENTS.md và docs/ARCHITECTURE.md.

Chia MVP thành các vertical slice nhỏ. Mỗi task phải có:

- Hành vi kiểm chứng được.
- Phạm vi.
- Acceptance criteria.
- Dependency.
- Cách test.

Đề xuất thứ tự thực hiện nhưng chưa viết code.
```

Chọn task đầu tiên và cập nhật `docs/TASK.md`.

## Bước 15: Thực hiện từng task

### Prompt 13 — Plan

```text
Tuân theo CLAUDE.md. Đọc TASK.md và REQUIREMENTS.md.
Dùng CONTEXT_INDEX.md để chọn tối đa hai tài liệu chuyên môn.

Đối chiếu acceptance criteria, xác định file cần sửa,
test cần có, rủi ro và kế hoạch tối đa 5 bước.
Chưa sửa code.
```

### Prompt 14 — Implement

```text
Kế hoạch được chấp nhận. Thực hiện đúng docs/TASK.md.

Thay đổi nhỏ nhất đáp ứng acceptance criteria.
Không thêm abstraction hoặc dependency chưa cần.
Không triển khai task tiếp theo.
Chạy test cụ thể trước.
Cập nhật tài liệu nếu contract hoặc cách chạy thay đổi.

Báo cáo file thay đổi, test, kết quả và vấn đề còn lại.
```

## Bước 16: Review và bàn giao

### Prompt 15 — Review

```text
Đọc docs/REVIEW_CHECKLIST.md và review riêng thay đổi hiện tại.
Ưu tiên correctness, security, compatibility và thiếu test.
Không mở rộng kiến trúc ngoài requirement.
```

### Prompt 16 — Progress

```text
Cập nhật docs/PROGRESS.md thành snapshot dưới 100 dòng.
Gồm mục tiêu, việc hoàn thành, file thay đổi, test và kết quả,
vấn đề còn lại, bước tiếp theo và tối đa 5 file cần đọc phiên sau.
Viết đè nội dung cũ, không ghi lịch sử hội thoại.
```

## Công thức ngắn

```text
Ý tưởng → REQUIREMENTS → Constraints → Stack/DECISIONS
→ PROJECT → ARCHITECTURE → API/DATABASE/SECURITY/TESTING
→ ENVIRONMENT → Scaffold/COMMANDS → README
→ TASK → PLAN → IMPLEMENT → TEST/REVIEW → PROGRESS
```

## Những lỗi cần tránh

- Code trước khi chốt MVP.
- Xây toàn bộ project trong một prompt.
- Chọn microservice hoặc abstraction quá sớm.
- Thiết kế database trước business rule.
- Thêm dependency “để dành”.
- Ghi README bằng lệnh chưa chạy thử.
- Để Claude tự quyết requirement mơ hồ.
- Đọc toàn bộ tài liệu trong mọi task.
