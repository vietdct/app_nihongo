import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/features/review/providers/mixed_quiz_providers.dart';

void main() {
  group('MixedQuizConfig', () {
    test('2 config có cùng nội dung (kể cả Set khác instance) coi là bằng nhau',
        () {
      const a = MixedQuizConfig(
        questionCount: 10,
        enabledSources: {
          MixedQuizSource.multipleChoice,
          MixedQuizSource.typing,
        },
        timedMode: true,
      );
      const b = MixedQuizConfig(
        questionCount: 10,
        enabledSources: {
          MixedQuizSource.typing,
          MixedQuizSource.multipleChoice,
        }, // thứ tự khai báo khác, cùng nội dung
        timedMode: true,
      );

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('khác enabledSources thì không bằng nhau', () {
      const a = MixedQuizConfig(
        questionCount: 10,
        enabledSources: {MixedQuizSource.multipleChoice},
      );
      const b = MixedQuizConfig(
        questionCount: 10,
        enabledSources: {MixedQuizSource.typing},
      );

      expect(a, isNot(equals(b)));
    });

    test('khác questionCount/timedMode/survivalMode thì không bằng nhau', () {
      const base = MixedQuizConfig(questionCount: 10);

      expect(base, isNot(equals(const MixedQuizConfig(questionCount: 20))));
      expect(
        base,
        isNot(equals(const MixedQuizConfig(questionCount: 10, timedMode: true))),
      );
      expect(
        base,
        isNot(equals(
            const MixedQuizConfig(questionCount: 10, survivalMode: true),),),
      );
    });

    test('mặc định enabledSources bật hết mọi nhóm', () {
      const config = MixedQuizConfig(questionCount: 10);
      expect(config.enabledSources.length, MixedQuizSource.values.length);
    });
  });
}
