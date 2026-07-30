import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/kaiwa_message.dart';
import '../../../domain/services/lesson_mission_generator.dart';
import 'lesson_mission_service.dart';
import 'level_providers.dart';

class LessonMissionState {
  const LessonMissionState({
    this.messages = const [],
    this.completedVocabIds = const {},
    this.completedGrammarIds = const {},
    this.sending = false,
    this.started = false,
    this.error,
  });

  final List<KaiwaMessage> messages;
  final Set<String> completedVocabIds;
  final Set<String> completedGrammarIds;
  final bool sending;
  final bool started;
  final String? error;

  LessonMissionState copyWith({
    List<KaiwaMessage>? messages,
    Set<String>? completedVocabIds,
    Set<String>? completedGrammarIds,
    bool? sending,
    bool? started,
    String? error,
    bool clearError = false,
  }) =>
      LessonMissionState(
        messages: messages ?? this.messages,
        completedVocabIds: completedVocabIds ?? this.completedVocabIds,
        completedGrammarIds: completedGrammarIds ?? this.completedGrammarIds,
        sending: sending ?? this.sending,
        started: started ?? this.started,
        error: clearError ? null : (error ?? this.error),
      );
}

/// Điều khiển 1 phiên Mission Challenge — cộng dồn tiến độ (id từ
/// vựng/ngữ pháp mục tiêu đã dùng đúng) từ dữ liệu thô của từng lượt gọi
/// `LessonMissionService`, không tự "đoán hoàn thành" bằng 1 lượt AI riêng.
class LessonMissionController extends StateNotifier<LessonMissionState> {
  LessonMissionController(this._service, this._mission, this._jlptLevel) : super(const LessonMissionState());

  final LessonMissionService? _service;
  final LessonMission _mission;
  final String _jlptLevel;

  bool get isComplete =>
      _mission.totalTargets > 0 &&
      state.completedVocabIds.length == _mission.targetVocab.length &&
      state.completedGrammarIds.length == _mission.targetGrammar.length;

  Future<void> start() async {
    final service = _service;
    if (service == null || state.started || state.sending) return;
    state = state.copyWith(sending: true, clearError: true);
    try {
      final result = await service.start(mission: _mission, jlptLevel: _jlptLevel);
      state = state.copyWith(messages: [result.aiMessage], sending: false, started: true);
    } catch (e) {
      state = state.copyWith(sending: false, error: e.toString());
    }
  }

  Future<void> send(String text) async {
    final service = _service;
    final trimmed = text.trim();
    if (service == null || trimmed.isEmpty || state.sending) return;
    state = state.copyWith(sending: true, clearError: true);
    try {
      final result = await service.send(
        mission: _mission,
        jlptLevel: _jlptLevel,
        history: state.messages,
        text: trimmed,
      );
      final newVocabIds = {
        for (final v in _mission.targetVocab)
          if (result.usedVocabJp.contains(v.word)) v.id,
      };
      final newGrammarIds = {
        for (final g in _mission.targetGrammar)
          if (result.usedGrammarTitles.contains(g.title)) g.id,
      };
      state = state.copyWith(
        messages: [
          ...state.messages,
          if (result.userMessage != null) result.userMessage!,
          result.aiMessage,
        ],
        completedVocabIds: {...state.completedVocabIds, ...newVocabIds},
        completedGrammarIds: {...state.completedGrammarIds, ...newGrammarIds},
        sending: false,
      );
    } catch (e) {
      state = state.copyWith(sending: false, error: e.toString());
    }
  }
}

/// Family key là chính [LessonMission] — cùng 1 instance được dùng lại suốt
/// phiên `LessonRunnerScreen` (tạo 1 lần trong `lessonRunnerStepsProvider`,
/// xem `LessonMissionStep`), nên định danh đối tượng ổn định giữa các rebuild.
final lessonMissionControllerProvider =
    StateNotifierProvider.autoDispose.family<LessonMissionController, LessonMissionState, LessonMission>(
  (ref, mission) {
    final service = ref.watch(lessonMissionServiceProvider);
    final jlptLevel = ref.watch(selectedLevelCodeProvider);
    return LessonMissionController(service, mission, jlptLevel);
  },
);
