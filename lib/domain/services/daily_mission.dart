/// Ngưỡng hoàn thành mỗi mission "Today's Mission" — cùng con số đã hiện
/// trên UI Home từ trước (10 từ vựng, 5 kanji, 1 bài quiz, 1 lượt Kaiwa).
const dailyMissionVocabTarget = 10;
const dailyMissionKanjiTarget = 5;

/// Trạng thái thật của 4 mục "Today's Mission" — tính từ dữ liệu người dùng
/// đã có (không có mission nào tự chấm "xong" do người dùng tự tick).
class DailyMissionStatus {
  const DailyMissionStatus({
    required this.vocabDone,
    required this.kanjiDone,
    required this.quizDone,
    required this.kaiwaDone,
  });

  final bool vocabDone;
  final bool kanjiDone;
  final bool quizDone;
  final bool kaiwaDone;

  int get doneCount =>
      (vocabDone ? 1 : 0) +
      (kanjiDone ? 1 : 0) +
      (quizDone ? 1 : 0) +
      (kaiwaDone ? 1 : 0);
}

/// [vocabActivityTimestamps]/[kanjiActivityTimestamps]: `updated_at` của mỗi
/// dòng `user_vocab_progress`/`user_kanji_progress` (1 dòng/từ hoặc chữ nhờ
/// unique constraint, nên đếm số mốc rơi vào hôm nay = số từ/chữ đã chạm
/// hôm nay). [kaiwaActivityTimestamps]: `lastMessageAt` của mỗi hội thoại
/// Kaiwa. [lastQuizCompletedAt]: mốc quiz hoàn thành gần nhất (Quiz không có
/// log buổi làm bài nào khác để đếm).
DailyMissionStatus computeDailyMissionStatus({
  required List<DateTime> vocabActivityTimestamps,
  required List<DateTime> kanjiActivityTimestamps,
  required List<DateTime> kaiwaActivityTimestamps,
  DateTime? lastQuizCompletedAt,
  DateTime? now,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  bool isToday(DateTime dt) => _dateOnly(dt) == today;

  final vocabCount = vocabActivityTimestamps.where(isToday).length;
  final kanjiCount = kanjiActivityTimestamps.where(isToday).length;
  final kaiwaCount = kaiwaActivityTimestamps.where(isToday).length;
  final quizDone = lastQuizCompletedAt != null && isToday(lastQuizCompletedAt);

  return DailyMissionStatus(
    vocabDone: vocabCount >= dailyMissionVocabTarget,
    kanjiDone: kanjiCount >= dailyMissionKanjiTarget,
    quizDone: quizDone,
    kaiwaDone: kaiwaCount >= 1,
  );
}

// Supabase trả timestamp dạng UTC — phải quy về giờ địa phương trước khi
// lấy ngày, nếu không hoạt động lúc nửa đêm giờ VN (UTC+7) sẽ bị tính nhầm
// sang "hôm qua" theo lịch UTC.
DateTime _dateOnly(DateTime dt) {
  final local = dt.toLocal();
  return DateTime(local.year, local.month, local.day);
}
