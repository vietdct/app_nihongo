import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/domain/entities/vocab_progress.dart';
import 'package:nihongo/features/vocabulary/providers/vocab_review_providers.dart';

void main() {
  final now = DateTime(2026, 7, 28);

  group('classifyVocabReview', () {
    test('never reviewed (null progress) is due', () {
      expect(classifyVocabReview(null, now: now), VocabReviewReason.due);
    });

    test('reviewed before but last grade reset interval to 1 day is forgotten', () {
      const progress = VocabProgress(vocabId: 'v1', reviewCount: 2, intervalDays: 1, easeFactor: 2.0);
      expect(classifyVocabReview(progress, now: now), VocabReviewReason.forgotten);
    });

    test('first-ever review with interval 1 is not forgotten (reviewCount 0)', () {
      const progress = VocabProgress(vocabId: 'v1', reviewCount: 0, intervalDays: 0);
      expect(classifyVocabReview(progress, now: now), VocabReviewReason.due);
    });

    test('due date more than threshold days in the past is overdue', () {
      final progress = VocabProgress(
        vocabId: 'v1',
        reviewCount: 3,
        intervalDays: 7,
        easeFactor: 2.5,
        dueAt: now.subtract(const Duration(days: 3)),
      );
      expect(classifyVocabReview(progress, now: now), VocabReviewReason.overdue);
    });

    test('due date just past (below overdue threshold) is plain due', () {
      final progress = VocabProgress(
        vocabId: 'v1',
        reviewCount: 3,
        intervalDays: 7,
        easeFactor: 2.5,
        dueAt: now.subtract(const Duration(hours: 6)),
      );
      expect(classifyVocabReview(progress, now: now), VocabReviewReason.due);
    });

    test('low ease factor without being overdue is weak', () {
      final progress = VocabProgress(
        vocabId: 'v1',
        reviewCount: 4,
        intervalDays: 5,
        easeFactor: 1.6,
        dueAt: now.subtract(const Duration(hours: 1)),
      );
      expect(classifyVocabReview(progress, now: now), VocabReviewReason.weak);
    });

    test('forgotten takes priority over overdue when both signals present', () {
      final progress = VocabProgress(
        vocabId: 'v1',
        reviewCount: 5,
        intervalDays: 1,
        easeFactor: 1.3,
        dueAt: now.subtract(const Duration(days: 10)),
      );
      expect(classifyVocabReview(progress, now: now), VocabReviewReason.forgotten);
    });

    test('normal healthy progress not yet due-critical is plain due', () {
      final progress = VocabProgress(
        vocabId: 'v1',
        reviewCount: 6,
        intervalDays: 14,
        easeFactor: 2.6,
        dueAt: now.subtract(const Duration(minutes: 5)),
      );
      expect(classifyVocabReview(progress, now: now), VocabReviewReason.due);
    });
  });
}
