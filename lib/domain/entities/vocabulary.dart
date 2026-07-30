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

  /// Nghĩa chính (hiển thị ở nơi chỉ có chỗ cho 1 dòng, VD: tile danh sách).
  String get primaryMeaning => meanings.isEmpty ? '' : meanings.first.meaningVi;
}
