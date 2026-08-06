/// 1 phần của đề thi trong [ExamBlueprint] — khớp đúng field trong cột
/// jsonb `sections` của bảng `jlpt_exam_blueprints` (xem migration
/// `20260804090000_jlpt_exam.sql`). [type] hiện chỉ 'vocabulary'/'grammar'
/// được xử lý (Task 4); 'listening'/'reading' đã có trong blueprint nhưng
/// engine chưa sinh câu hỏi cho tới Task 5/6 — xem
/// docs/JLPT_MOCK_EXAM_DESIGN.md §3, §6.
class ExamSectionSpec {
  const ExamSectionSpec({
    required this.type,
    required this.questionCount,
    required this.timeMinutes,
  });

  factory ExamSectionSpec.fromJson(Map<String, dynamic> json) =>
      ExamSectionSpec(
        type: json['type'] as String,
        questionCount: json['question_count'] as int,
        timeMinutes: json['time_minutes'] as int,
      );

  final String type;
  final int questionCount;
  final int timeMinutes;
}

/// Cấu trúc 1 đề JLPT theo level+mode — đọc từ `jlpt_exam_blueprints`
/// (nội dung tham chiếu, đọc công khai). Số câu/số phút trong [sections] ở
/// bản seed hiện tại là TẠM, chưa phải Official Timing chính thức (Task 7
/// sẽ tra số liệu công khai để cập nhật).
class ExamBlueprint {
  const ExamBlueprint({
    required this.id,
    required this.levelId,
    required this.mode,
    required this.sections,
  });

  factory ExamBlueprint.fromRow(Map<String, dynamic> row) => ExamBlueprint(
        id: row['id'] as String,
        levelId: row['level_id'] as String,
        mode: row['mode'] as String,
        sections: [
          for (final s in row['sections'] as List)
            ExamSectionSpec.fromJson(s as Map<String, dynamic>),
        ],
      );

  final String id;
  final String levelId;
  final String mode;
  final List<ExamSectionSpec> sections;
}
