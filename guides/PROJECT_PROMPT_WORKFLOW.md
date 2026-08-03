# Quy trình Prompt khi làm việc với một project

Khi đã có một project, không cần gửi toàn bộ prompt hoặc yêu cầu Claude đọc toàn bộ tài liệu. Hãy dùng theo hai tình huống:

1. **Lần đầu đưa Claude vào project:** thiết lập context.
2. **Mỗi lần làm một task:** chạy chu trình `Task → Plan → Implement → Review → Progress`.

---

# A. Lần đầu mở project

Chỉ cần thực hiện phần này một lần cho mỗi project hoặc khi kiến trúc đã thay đổi lớn.

## Bước 1: Đặt các file vào project

```text
project-root/
├── README.md
├── CLAUDE.md
├── source-code/
└── docs/
    ├── CONTEXT_INDEX.md
    ├── PROJECT.md
    ├── ENVIRONMENT.md
    ├── COMMANDS.md
    ├── ARCHITECTURE.md
    ├── REQUIREMENTS.md
    ├── TASK.md
    └── PROGRESS.md
```

Chưa cần điền toàn bộ file ngay.

## Bước 2: Prompt khảo sát đầu tiên

```text
Tuân theo CLAUDE.md.

Đây là lần đầu làm việc với project này.

Trước tiên chỉ khảo sát, chưa sửa code.

Hãy đọc:

1. README.md nếu tồn tại.
2. Package/dependency manifest.
3. File cấu hình build và runtime chính.
4. Cây thư mục ở độ sâu nhỏ.

Hãy xác định:

- Mục đích của project.
- Ngôn ngữ và framework.
- Package manager.
- Entry point.
- Tối đa 10 thư mục hoặc file quan trọng.
- Cách chạy có thể có nhưng chưa được xác nhận.
- Thông tin thiếu hoặc mâu thuẫn.

Không được:

- Đọc toàn bộ repository.
- Đọc node_modules, vendor, dist, build, coverage, cache hoặc log.
- Đọc giá trị .env, credential hoặc token.
- Cài dependency.
- Chạy migration hoặc deploy.
- Sửa bất kỳ file nào.

Giữ kết quả dưới 500 từ.
```

## Bước 3: Yêu cầu tạo context project

Sau khi kiểm tra kết quả khảo sát:

```text
Kết quả khảo sát cơ bản đã đúng.

Hãy cập nhật:

- docs/PROJECT.md
- docs/ENVIRONMENT.md

Yêu cầu:

- Chỉ ghi thông tin đã được xác nhận.
- Đánh dấu [NEEDS_CONFIRMATION] cho thông tin chưa chắc chắn.
- Chỉ ghi tên biến môi trường, không đọc hoặc ghi giá trị secret.
- Xóa placeholder không sử dụng.
- Không sửa source code.
```

## Bước 4: Xác minh các lệnh

### Prompt đề xuất lệnh

```text
Đọc:

- docs/PROJECT.md
- docs/ENVIRONMENT.md
- package/build configuration

Hãy đề xuất các lệnh cần xác minh theo thứ tự:

1. Runtime và package manager.
2. Cài dependency nếu cần.
3. Chạy một test cụ thể.
4. Lint.
5. Type-check.
6. Build.
7. Toàn bộ test nếu cần.

Với mỗi lệnh, ghi:

- Mục đích.
- Có thay đổi dữ liệu hay không.
- Có cần network hay không.
- Điều kiện thành công.

Chưa chạy lệnh.
Không đề xuất deploy, production migration hoặc reset dữ liệu.
```

### Prompt cho phép chạy

```text
Hãy chạy các lệnh an toàn đã đề xuất.

Chỉ cập nhật docs/COMMANDS.md với những lệnh đã chạy và xác nhận.

Nếu lệnh thất bại:

- Báo lỗi đầu tiên.
- Nêu nguyên nhân gần nhất.
- Không tự sửa vấn đề ngoài phạm vi.
- Không tiếp tục chạy các lệnh phụ thuộc vào lệnh đã thất bại.
```

Đến đây project đã được thiết lập cơ bản.

---

# B. Mỗi lần bắt đầu một task

Chu trình sử dụng thường xuyên:

```text
1. Tạo TASK
2. Lập PLAN
3. IMPLEMENT
4. TEST
5. REVIEW
6. Cập nhật PROGRESS
```

## Prompt 1: Tạo task

Thay `[Mô tả công việc]` bằng yêu cầu thật.

```text
Tuân theo CLAUDE.md.

Tôi cần thực hiện công việc sau:

[Mô tả công việc]

Trước tiên chưa sửa code.

Hãy cập nhật docs/TASK.md với:

- Kết quả cần đạt.
- Phạm vi được sửa.
- Phạm vi không được sửa.
- Acceptance criteria.
- File hoặc module có khả năng liên quan.
- Cách kiểm tra hoàn thành.
- Câu hỏi cần xác nhận.

Không quét toàn bộ repository.
Không tự biến giả định thành requirement.
Giữ task ngắn gọn và có thể kiểm chứng.
```

### Ví dụ

```text
Tuân theo CLAUDE.md.

Tôi cần sửa lỗi người dùng không thể đăng nhập khi email chứa
chữ hoa.

Trước tiên chưa sửa code.

Hãy cập nhật docs/TASK.md với:

- Kết quả cần đạt.
- Phạm vi được sửa.
- Phạm vi không được sửa.
- Acceptance criteria.
- File hoặc module có khả năng liên quan.
- Cách kiểm tra hoàn thành.
- Câu hỏi cần xác nhận.

Không quét toàn bộ repository.
Không tự biến giả định thành requirement.
```

## Prompt 2: Lập kế hoạch

Sau khi `TASK.md` đã đúng:

```text
Đọc:

- CLAUDE.md
- docs/TASK.md
- docs/REQUIREMENTS.md nếu task liên quan nghiệp vụ

Dùng docs/CONTEXT_INDEX.md để chọn tối đa hai tài liệu chuyên môn
cần thiết.

Chỉ đọc source code trực tiếp liên quan đến task.

Hãy:

1. Đối chiếu task với requirement.
2. Xác định nguyên nhân hoặc hướng triển khai.
3. Xác định các file cần sửa.
4. Xác định test cần chạy hoặc bổ sung.
5. Nêu rủi ro và phạm vi ảnh hưởng.
6. Đưa kế hoạch tối đa 5 bước.

Chưa sửa code.
Không refactor ngoài phạm vi.
Nếu thiếu thông tin quan trọng, hãy hỏi một câu cụ thể.
```

Đọc và kiểm tra kế hoạch trước khi cho Claude sửa code.

## Prompt 3: Cho phép triển khai

Nếu kế hoạch đúng:

```text
Kế hoạch được chấp nhận.

Hãy thực hiện đúng kế hoạch và phạm vi trong docs/TASK.md.

Yêu cầu:

- Sửa tối thiểu nhưng xử lý đúng nguyên nhân.
- Không refactor ngoài phạm vi.
- Không thay đổi public API nếu task không yêu cầu.
- Không thêm dependency nếu chưa được phép.
- Không sửa unrelated files.
- Chạy test cụ thể liên quan trước.
- Nếu cùng một hướng thất bại hai lần, dừng và đánh giá lại.
- Nếu requirement mâu thuẫn, dừng và báo lại.
- Không deploy hoặc chạy production migration.

Khi hoàn thành, báo cáo:

1. Nguyên nhân hoặc cách triển khai.
2. File đã thay đổi.
3. Test đã chạy và kết quả.
4. Phần chưa kiểm tra.
5. Rủi ro hoặc vấn đề còn lại.
```

## Prompt 4: Review code

Sau khi Claude sửa xong:

```text
Đọc docs/REVIEW_CHECKLIST.md.

Review riêng phần thay đổi của task hiện tại.

Ưu tiên:

1. Sai requirement.
2. Bug hoặc regression.
3. Security.
4. Authentication và authorization.
5. Transaction hoặc concurrency.
6. API compatibility.
7. Thiếu test quan trọng.

Không liệt kê vấn đề style nếu không có tác động thực tế.

Mỗi finding phải có:

- Mức độ.
- File và vị trí.
- Điều kiện xảy ra.
- Tác động.
- Cách sửa đề xuất.

Nếu không phát hiện vấn đề, hãy nói rõ:

- Phạm vi đã review.
- Test đã kiểm tra.
- Rủi ro chưa được kiểm chứng.
```

Nếu review phát hiện lỗi:

```text
Hãy sửa các finding đã xác nhận.

Chỉ sửa finding của task hiện tại.
Không mở rộng phạm vi hoặc refactor unrelated code.

Sau khi sửa, chạy lại test liên quan và báo kết quả.
```

## Prompt 5: Kết thúc phiên

Đây là bước quan trọng để giảm token ở phiên tiếp theo:

```text
Cập nhật docs/PROGRESS.md thành snapshot hiện tại.

Yêu cầu:

- Giữ dưới 100 dòng.
- Viết đè nội dung cũ.
- Không ghi lịch sử hội thoại.
- Không chép code hoặc log dài.

Bao gồm:

1. Mục tiêu hiện tại.
2. Trạng thái.
3. Việc đã hoàn thành.
4. File đã thay đổi.
5. Test đã chạy và kết quả.
6. Phần chưa kiểm tra.
7. Vấn đề hoặc rủi ro còn lại.
8. Bước tiếp theo cụ thể.
9. Tối đa 5 file cần đọc ở phiên sau.
10. Những phần không cần đọc lại.
```

Sau đó có thể đóng chat hiện tại.

---

# C. Khi mở phiên mới để tiếp tục

Không đưa lại toàn bộ lịch sử. Chỉ dùng:

```text
Tuân theo CLAUDE.md.

Đọc docs/PROGRESS.md.

Chỉ đọc các file được liệt kê trong phần
“Context tối thiểu cho phiên sau”.

Hãy:

1. Tóm tắt trạng thái trong tối đa 5 bullet.
2. Xác nhận bước tiếp theo.
3. Tiếp tục đúng bước đó.
4. Không điều tra lại phần đã được xác nhận.
5. Không quét toàn bộ repository.

Nếu PROGRESS.md không đủ thông tin, chỉ hỏi đúng thông tin còn thiếu.
```

---

# D. Prompt theo từng loại công việc

## Sửa bug

Thứ tự file:

```text
CLAUDE.md
→ TASK.md
→ TROUBLESHOOTING.md
→ TESTING.md
→ Source code liên quan
```

Prompt:

```text
Đọc CLAUDE.md, docs/TASK.md, docs/TROUBLESHOOTING.md
và docs/TESTING.md.

Hãy:

1. Phân biệt expected và actual behavior.
2. Tìm nguyên nhân trước khi sửa.
3. Tạo regression test nếu phù hợp.
4. Sửa tối thiểu.
5. Chạy test cụ thể trước.

Chưa sửa code. Trước tiên đưa kế hoạch tối đa 5 bước.
```

## Làm feature

Thứ tự file:

```text
CLAUDE.md
→ REQUIREMENTS.md
→ TASK.md
→ ARCHITECTURE.md
→ API.md hoặc DATABASE.md nếu cần
```

Prompt:

```text
Đọc CLAUDE.md, docs/REQUIREMENTS.md và docs/TASK.md.

Chỉ đọc thêm docs/ARCHITECTURE.md, docs/API.md hoặc
docs/DATABASE.md nếu feature liên quan trực tiếp.

Đối chiếu acceptance criteria, xác định file cần thay đổi,
test cần có, compatibility và phạm vi ảnh hưởng.

Chưa sửa code. Đưa kế hoạch tối đa 5 bước.
```

## Thay đổi API

Thứ tự file:

```text
CLAUDE.md
→ TASK.md
→ REQUIREMENTS.md
→ API.md
→ SECURITY.md nếu cần
→ DATABASE.md nếu thay đổi dữ liệu
```

Prompt:

```text
Đọc CLAUDE.md, docs/TASK.md, docs/REQUIREMENTS.md và docs/API.md.

Đánh giá:

- Request và response contract.
- Validation.
- Authentication và authorization.
- Error format.
- Client bị ảnh hưởng.
- Breaking change.
- Idempotency.
- Test cần bổ sung.

Chỉ đọc SECURITY.md hoặc DATABASE.md nếu thay đổi liên quan.
Trước tiên đưa kế hoạch, chưa sửa code.
```

## Công việc tiếng Nhật

Thứ tự file:

```text
JAPANESE_STYLE.md
→ GLOSSARY.md
→ REQUIREMENTS.md nếu liên quan nghiệp vụ
```

Prompt:

```text
Đọc docs/JAPANESE_STYLE.md và docs/GLOSSARY.md.

Hãy xử lý nội dung tiếng Nhật sau:

[Nội dung]

Yêu cầu:

- Giữ nguyên code, identifier, API và error message.
- Dùng thuật ngữ trong GLOSSARY.md.
- Không tự thêm thông tin.
- Phân biệt sự thật, giả định và nội dung chưa xác nhận.
- Đánh dấu [要確認] cho điểm chưa rõ.
- Viết ngắn gọn và lịch sự.
```

---

# Chu trình ngắn nhất cần nhớ

Chỉ cần nhớ sáu prompt:

```text
1. TASK
2. PLAN
3. IMPLEMENT
4. TEST
5. REVIEW
6. PROGRESS
```

Cách sử dụng hằng ngày:

```text
Bắt đầu task
    ↓
Tạo TASK.md
    ↓
Yêu cầu kế hoạch
    ↓
Duyệt kế hoạch
    ↓
Cho phép triển khai
    ↓
Review và test
    ↓
Cập nhật PROGRESS.md
    ↓
Mở chat mới nếu context đã dài
```

Không cần chạy lại prompt khảo sát project ở mỗi task. Prompt khảo sát chỉ dùng lần đầu hoặc khi kiến trúc project đã thay đổi lớn.
