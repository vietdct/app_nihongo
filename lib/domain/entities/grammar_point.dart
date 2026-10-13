import 'grammar_meaning.dart';

/// 1 điểm ngữ pháp, kèm nội dung học sâu (lỗi thường gặp/mẹo nhớ/so sánh)
/// ngoài công thức + ví dụ cơ bản.
class GrammarPoint {
  const GrammarPoint({
    required this.id,
    required this.title,
    required this.explanation,
    required this.levelId,
    this.exampleJp,
    this.exampleVi,
    this.commonMistake,
    this.memoryTip,
    this.comparisonNote,
    this.extraExamplesJp = const [],
    this.extraExamplesVi = const [],
    this.practiceTokens = const [],
    this.practiceBlankIndex,
    this.meanings = const [],
  });

  final String id;
  final String title;
  final String explanation;
  final String levelId;
  final String? exampleJp;
  final String? exampleVi;
  final String? commonMistake;
  final String? memoryTip;
  final String? comparisonNote;

  /// Nghĩa tách riêng, mỗi nghĩa kèm ví dụ riêng — dùng để hiển thị "Ý NGHĨA"
  /// theo từng mục thay vì 1 đoạn văn dài, xem migration
  /// `20260810110000_grammar_meanings.sql`. Rỗng = điểm ngữ pháp này chưa
  /// được soạn theo cấu trúc mới, UI sẽ fallback về [explanation] phẳng như
  /// cũ (N4/N5 hiện tại).
  final List<GrammarMeaning> meanings;

  /// Ví dụ bổ sung ngoài exampleJp/exampleVi (câu chính, gắn với
  /// practiceTokens) — cùng độ dài, ghép theo index (extraExamplesJp[i] đi
  /// cùng extraExamplesVi[i]), thể hiện cách dùng khác của cùng mẫu ngữ pháp.
  final List<String> extraExamplesJp;
  final List<String> extraExamplesVi;

  /// example_jp tách thành từ/cụm có nghĩa, đúng thứ tự — soạn thủ công, xem
  /// migration `20260727040000_grammar_practice_tokens.sql`. Rỗng nếu mẫu
  /// này chưa được soạn cho Practice mở rộng.
  final List<String> practiceTokens;

  /// Index trong [practiceTokens] là từ/trợ từ bị ẩn cho bài điền từ — null
  /// nếu mẫu này dùng cho bài ghép câu thay vì điền từ (hoặc chưa soạn).
  final int? practiceBlankIndex;
}
