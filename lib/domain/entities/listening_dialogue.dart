/// Người nói mặc định khi dữ liệu cũ không ghi rõ ai đang nói.
const defaultSpeakerId = 'A';

/// 1 lượt thoại trong 1 đoạn hội thoại nghe hiểu — `speaker` là mã nhân vật
/// (cũng là nhãn hiển thị: "A", "B", ...), dùng để chọn giọng đọc TTS và màu
/// trong script (không có audio thu sẵn).
class ListeningTurn {
  const ListeningTurn({required this.speaker, required this.jp});

  final String speaker;
  final String jp;

  /// Đọc 1 lượt thoại từ JSON, chịu được dữ liệu cũ/thiếu: chỉ là chuỗi
  /// (không có speaker), thiếu/rỗng `speaker` → [defaultSpeakerId]; nội dung
  /// rỗng → null (bỏ lượt đó).
  static ListeningTurn? tryParse(Object? raw) {
    final String? speaker;
    final Object? jp;
    if (raw is Map) {
      speaker = (raw['speaker'] ?? raw['speaker_id'])?.toString();
      jp = raw['jp'];
    } else {
      speaker = null;
      jp = raw;
    }
    final text = jp is String ? jp.trim() : '';
    if (text.isEmpty) return null;
    final id = speaker?.trim() ?? '';
    return ListeningTurn(
      speaker: id.isEmpty ? defaultSpeakerId : id,
      jp: text,
    );
  }
}

/// Danh sách lượt thoại → thứ tự nhân vật theo lần xuất hiện đầu tiên.
extension ListeningTurns on List<ListeningTurn> {
  /// Các nhân vật khác nhau, theo thứ tự xuất hiện (chỉ số = "slot" giọng/màu).
  List<String> get speakerOrder =>
      <String>{for (final t in this) t.speaker}.toList(growable: false);

  bool get hasMultipleSpeakers => speakerOrder.length > 1;
}

/// 1 bài nghe hiểu kiểu JLPT (Minna no Nihongo): hội thoại 2 người thật,
/// độ dài khác nhau (2-8 lượt thoại tuỳ bài), kèm 1 câu hỏi trắc nghiệm về
/// nội dung — nội dung do người soạn viết tay, không sinh tự động.
class ListeningDialogue {
  const ListeningDialogue({
    required this.id,
    required this.levelId,
    required this.turns,
    required this.questionJa,
    required this.options,
    required this.correctIndex,
  });

  final String id;
  final String levelId;
  final List<ListeningTurn> turns;

  /// Câu hỏi bằng tiếng Nhật (đề bài) — người học luyện đọc/nghe hiểu tiếng
  /// Nhật thật, không phải đọc tiếng Việt rồi chỉ nghe hội thoại tiếng Nhật.
  final String questionJa;
  final List<String> options;
  final int correctIndex;
}
