import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/services/daily_mission.dart';

List<DateTime> _timesToday(DateTime now, int count) =>
    List.generate(count, (i) => DateTime(now.year, now.month, now.day, i % 23 + 1));

void main() {
  group('computeDailyMissionStatus', () {
    final now = DateTime(2026, 7, 28, 20);
    final yesterday = DateTime(2026, 7, 27, 9);

    test('rỗng hết thì không mission nào xong', () {
      final status = computeDailyMissionStatus(
        vocabActivityTimestamps: const [],
        kanjiActivityTimestamps: const [],
        kaiwaActivityTimestamps: const [],
        now: now,
      );
      expect(status.vocabDone, false);
      expect(status.kanjiDone, false);
      expect(status.quizDone, false);
      expect(status.kaiwaDone, false);
      expect(status.doneCount, 0);
    });

    test('vocab: đủ 10 mốc hôm nay mới tính xong, 9 thì chưa', () {
      final under = computeDailyMissionStatus(
        vocabActivityTimestamps: _timesToday(now, dailyMissionVocabTarget - 1),
        kanjiActivityTimestamps: const [],
        kaiwaActivityTimestamps: const [],
        now: now,
      );
      expect(under.vocabDone, false);

      final exact = computeDailyMissionStatus(
        vocabActivityTimestamps: _timesToday(now, dailyMissionVocabTarget),
        kanjiActivityTimestamps: const [],
        kaiwaActivityTimestamps: const [],
        now: now,
      );
      expect(exact.vocabDone, true);
    });

    test('kanji: đủ 5 mốc hôm nay mới tính xong', () {
      final status = computeDailyMissionStatus(
        vocabActivityTimestamps: const [],
        kanjiActivityTimestamps: _timesToday(now, dailyMissionKanjiTarget),
        kaiwaActivityTimestamps: const [],
        now: now,
      );
      expect(status.kanjiDone, true);
    });

    test('mốc hôm qua không được tính vào hôm nay', () {
      final status = computeDailyMissionStatus(
        vocabActivityTimestamps: List.filled(dailyMissionVocabTarget, yesterday),
        kanjiActivityTimestamps: List.filled(dailyMissionKanjiTarget, yesterday),
        kaiwaActivityTimestamps: [yesterday],
        lastQuizCompletedAt: yesterday,
        now: now,
      );
      expect(status.vocabDone, false);
      expect(status.kanjiDone, false);
      expect(status.kaiwaDone, false);
      expect(status.quizDone, false);
    });

    test('kaiwa: chỉ cần 1 mốc hôm nay là xong', () {
      final status = computeDailyMissionStatus(
        vocabActivityTimestamps: const [],
        kanjiActivityTimestamps: const [],
        kaiwaActivityTimestamps: [now],
        now: now,
      );
      expect(status.kaiwaDone, true);
    });

    test('quiz: lastQuizCompletedAt null thì chưa xong', () {
      final status = computeDailyMissionStatus(
        vocabActivityTimestamps: const [],
        kanjiActivityTimestamps: const [],
        kaiwaActivityTimestamps: const [],
        now: now,
      );
      expect(status.quizDone, false);
    });

    test('quiz: lastQuizCompletedAt đúng hôm nay thì xong', () {
      final status = computeDailyMissionStatus(
        vocabActivityTimestamps: const [],
        kanjiActivityTimestamps: const [],
        kaiwaActivityTimestamps: const [],
        lastQuizCompletedAt: DateTime(now.year, now.month, now.day, 6),
        now: now,
      );
      expect(status.quizDone, true);
    });

    test('mốc UTC nhưng đúng thời điểm hiện tại vẫn tính là hôm nay (bug quy đổi múi giờ)', () {
      final rightNowUtc = DateTime.now().toUtc();
      final status = computeDailyMissionStatus(
        vocabActivityTimestamps: const [],
        kanjiActivityTimestamps: const [],
        kaiwaActivityTimestamps: [rightNowUtc],
      );
      expect(status.kaiwaDone, true);
    });

    test('cả 4 mission xong thì doneCount = 4', () {
      final status = computeDailyMissionStatus(
        vocabActivityTimestamps: _timesToday(now, dailyMissionVocabTarget),
        kanjiActivityTimestamps: _timesToday(now, dailyMissionKanjiTarget),
        kaiwaActivityTimestamps: [now],
        lastQuizCompletedAt: now,
        now: now,
      );
      expect(status.doneCount, 4);
    });
  });
}
