/// Thang điểm & ngưỡng đỗ JLPT — số liệu công khai từ trang chính thức JLPT
/// (jlpt.jp), ổn định từ đợt cải cách 2010 tới nay (không tự bịa số, xem
/// quyết định docs/JLPT_MOCK_EXAM_DESIGN.md §20 mục 1). `scaledScore` app
/// tính là MÔ PHỎNG tuyến tính (rawCorrect/rawTotal * điểm tối đa nhóm),
/// KHÔNG phải công thức quy đổi IRT (Item Response Theory) thật mà JEES
/// dùng nội bộ và không công khai — vì vậy luôn hiển thị kèm disclaimer ở
/// UI (xem `PassFailBadge` trong `exam_result_screen.dart`).
library;

import '../../features/review/jlpt_exam/models/exam_blueprint.dart';

/// 1 nhóm điểm chính thức JLPT (VD "Từ vựng-Ngữ pháp", "Đọc hiểu"). N4/N5
/// gộp Từ vựng+Ngữ pháp+Đọc hiểu làm 1 nhóm điểm; N1-N3 tách Đọc hiểu thành
/// nhóm riêng — đúng cấu trúc CHẤM ĐIỂM JLPT thật (khác cấu trúc 4 section
/// app tự chia lúc LÀM bài — xem `ExamRunSection`).
class JlptScoreCategory {
  const JlptScoreCategory({
    required this.key,
    required this.label,
    required this.rawSectionTypes,
    required this.maxScore,
    required this.minPassScore,
  });

  final String key;
  final String label;
  final List<String> rawSectionTypes;
  final int maxScore;
  final int minPassScore;
}

class JlptScoringRule {
  const JlptScoringRule({
    required this.categories,
    required this.totalMaxScore,
    required this.totalMinPassScore,
    required this.officialTotalMinutes,
  });

  final List<JlptScoreCategory> categories;
  final int totalMaxScore;
  final int totalMinPassScore;

  /// Tổng thời gian thi thật (phút) — dùng để phân bổ Official Timing cho
  /// các section runner, xem [officialTimingMinutesBySectionType].
  final int officialTotalMinutes;
}

const _n1n2n3Categories = [
  JlptScoreCategory(
    key: 'language_knowledge',
    label: 'Từ vựng - Ngữ pháp',
    rawSectionTypes: ['vocabulary', 'grammar'],
    maxScore: 60,
    minPassScore: 19,
  ),
  JlptScoreCategory(
    key: 'reading',
    label: 'Đọc hiểu',
    rawSectionTypes: ['reading'],
    maxScore: 60,
    minPassScore: 19,
  ),
  JlptScoreCategory(
    key: 'listening',
    label: 'Nghe hiểu',
    rawSectionTypes: ['listening'],
    maxScore: 60,
    minPassScore: 19,
  ),
];

const _n4n5Categories = [
  JlptScoreCategory(
    key: 'language_reading',
    label: 'Từ vựng - Ngữ pháp - Đọc hiểu',
    rawSectionTypes: ['vocabulary', 'grammar', 'reading'],
    maxScore: 120,
    minPassScore: 38,
  ),
  JlptScoreCategory(
    key: 'listening',
    label: 'Nghe hiểu',
    rawSectionTypes: ['listening'],
    maxScore: 60,
    minPassScore: 19,
  ),
];

/// Nguồn: trang công khai JLPT (jlpt.jp) — mục "Test Sections, Test Time"
/// và "Passing Score/Reference Score by Level". Tổng điểm tối đa luôn 180
/// (3 nhóm x 60 với N1-N3; 120+60 với N4/N5).
const jlptScoringRules = <String, JlptScoringRule>{
  'N1': JlptScoringRule(
    categories: _n1n2n3Categories,
    totalMaxScore: 180,
    totalMinPassScore: 100,
    officialTotalMinutes: 165,
  ),
  'N2': JlptScoringRule(
    categories: _n1n2n3Categories,
    totalMaxScore: 180,
    totalMinPassScore: 90,
    officialTotalMinutes: 155,
  ),
  'N3': JlptScoringRule(
    categories: _n1n2n3Categories,
    totalMaxScore: 180,
    totalMinPassScore: 95,
    officialTotalMinutes: 140,
  ),
  'N4': JlptScoringRule(
    categories: _n4n5Categories,
    totalMaxScore: 180,
    totalMinPassScore: 90,
    officialTotalMinutes: 115,
  ),
  'N5': JlptScoringRule(
    categories: _n4n5Categories,
    totalMaxScore: 180,
    totalMinPassScore: 80,
    officialTotalMinutes: 90,
  ),
};

class JlptCategoryResult {
  const JlptCategoryResult({required this.category, required this.scaledScore});

  final JlptScoreCategory category;
  final int scaledScore;

  bool get passed => scaledScore >= category.minPassScore;
}

class JlptExamPrediction {
  const JlptExamPrediction({
    required this.categoryResults,
    required this.totalScaledScore,
    required this.totalMaxScore,
    required this.totalMinPassScore,
  });

  final List<JlptCategoryResult> categoryResults;
  final int totalScaledScore;
  final int totalMaxScore;
  final int totalMinPassScore;

  /// Đỗ khi TỔNG điểm đạt ngưỡng VÀ không nhóm nào dưới điểm liệt — đúng
  /// quy tắc JLPT thật (rớt "điểm liệt" 1 nhóm thì trượt dù tổng đủ).
  bool get passed =>
      totalScaledScore >= totalMinPassScore &&
      categoryResults.every((c) => c.passed);
}

/// null khi [levelCode] chưa có rule công khai (UI cần tự xử lý — chỉ hiện
/// điểm thô, không hiện Pass/Fail, xem `ExamResultScreen`).
JlptExamPrediction? predictJlptResult({
  required String levelCode,
  required Map<String, ({int correct, int total})> rawScores,
}) {
  final rule = jlptScoringRules[levelCode];
  if (rule == null) return null;

  final results = <JlptCategoryResult>[];
  for (final category in rule.categories) {
    var correct = 0;
    var total = 0;
    for (final type in category.rawSectionTypes) {
      final s = rawScores[type];
      if (s == null) continue;
      correct += s.correct;
      total += s.total;
    }
    final scaled =
        total == 0 ? 0 : (correct / total * category.maxScore).round();
    results.add(JlptCategoryResult(category: category, scaledScore: scaled));
  }

  return JlptExamPrediction(
    categoryResults: results,
    totalScaledScore: results.fold(0, (sum, r) => sum + r.scaledScore),
    totalMaxScore: rule.totalMaxScore,
    totalMinPassScore: rule.totalMinPassScore,
  );
}

/// Phân bổ lại Official Timing (tổng phút thi thật của [levelCode]) cho
/// từng section runner theo tỉ lệ số câu — đề JLPT thật gộp Ngữ pháp+Đọc
/// hiểu chung 1 khối giờ nên KHÔNG có số phút chính thức riêng cho từng
/// phần app tự chia (vocabulary/grammar/listening/reading); đây là ước
/// lượng theo tỉ lệ số câu, tổng luôn khớp đúng tổng thời gian thi thật
/// (phần cuối nhận phần dư làm tròn để tổng không lệch). Trả về null nếu
/// chưa có rule cho [levelCode] — UI cần fallback về `spec.timeMinutes` gốc
/// trong blueprint.
Map<String, int>? officialTimingMinutesBySectionType({
  required String levelCode,
  required List<ExamSectionSpec> sections,
}) {
  final rule = jlptScoringRules[levelCode];
  if (rule == null || sections.isEmpty) return null;

  final totalQuestions =
      sections.fold(0, (sum, s) => sum + s.questionCount);
  if (totalQuestions == 0) return null;

  final result = <String, int>{};
  var allocated = 0;
  for (var i = 0; i < sections.length; i++) {
    final spec = sections[i];
    final isLast = i == sections.length - 1;
    final minutes = isLast
        ? rule.officialTotalMinutes - allocated
        : (spec.questionCount / totalQuestions * rule.officialTotalMinutes)
            .round();
    result[spec.type] = minutes;
    allocated += minutes;
  }
  return result;
}
