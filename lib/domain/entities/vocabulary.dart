import 'vocab_meaning.dart';

/// Model thuần Dart — không phụ thuộc Drift/Supabase, dùng xuyên suốt domain/presentation.
class Vocabulary {
  const Vocabulary({
    required this.id,
    required this.word,
    required this.reading,
    required this.levelId,
    required this.meanings,
    this.partOfSpeech,
    this.audioUrl,
    this.category,
    this.commonUsagePattern,
    this.commonUsageDesc,
    this.commonUsageExamples = const [],
    this.nuancePoints = const [],
    this.similarWords = const [],
    this.comparisons = const [],
    this.commonMistakeNote,
    this.commonMistakeSuggestions = const [],
  });

  final String id;
  final String word;
  final String reading;
  final String levelId;

  /// Luôn có ít nhất 1 phần tử với dữ liệu hợp lệ; có thể nhiều nếu từ đa nghĩa.
  final List<VocabMeaning> meanings;
  final String? partOfSpeech;
  final String? audioUrl;

  /// Chủ đề để duyệt/lọc (VD: "Mua sắm", "Gia đình") — null nếu từ chưa được gán.
  final String? category;

  /// Mẫu câu thường gặp (VD: "ちゃんと + Verb") kèm giải thích ngắn — null nếu
  /// từ chưa có nội dung này (chỉ 1 số từ được biên soạn thủ công).
  final String? commonUsagePattern;
  final String? commonUsageDesc;
  final List<VocabUsageExample> commonUsageExamples;

  /// Các nét sắc thái riêng của từ (mỗi phần tử 1 gạch đầu dòng) — rỗng nếu
  /// chưa có nội dung.
  final List<String> nuancePoints;

  /// Từ gần nghĩa hoặc cùng chủ đề (khác với "từ liên quan" — vốn là các từ
  /// ghép chứa chung Kanji, suy ra tự động, xem `ContentRepository.findRelatedVocabulary`).
  final List<VocabSimilarWord> similarWords;

  /// So sánh trực tiếp với 1 từ gần nghĩa khác.
  final List<VocabComparison> comparisons;

  /// Lỗi dịch/hiểu thường gặp + gợi ý cách dịch tự nhiên hơn.
  final String? commonMistakeNote;
  final List<String> commonMistakeSuggestions;

  /// Nghĩa chính (hiển thị ở nơi chỉ có chỗ cho 1 dòng, VD: tile danh sách).
  String get primaryMeaning => meanings.isEmpty ? '' : meanings.first.meaningVi;
}

/// 1 cụm/câu ví dụ minh hoạ cho 1 mẫu cách dùng thường gặp (VD: phrase
/// "ちゃんと食べる", meaningVi "ăn đàng hoàng").
class VocabUsageExample {
  const VocabUsageExample({required this.phrase, required this.meaningVi});

  final String phrase;
  final String meaningVi;
}

/// 1 từ gần nghĩa/đồng nghĩa kèm nghĩa ngắn gọn.
class VocabSimilarWord {
  const VocabSimilarWord({required this.word, required this.meaningVi});

  final String word;
  final String meaningVi;
}

/// So sánh từ chính với 1 từ gần nghĩa khác — [mainWordDesc] mô tả từ chính
/// trong đúng ngữ cảnh so sánh này (có thể khác nghĩa chung ở [Vocabulary.meanings]).
class VocabComparison {
  const VocabComparison({
    required this.word,
    required this.mainWordDesc,
    required this.otherWordDesc,
  });

  final String word;
  final String mainWordDesc;
  final String otherWordDesc;
}
