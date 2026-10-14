import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/supabase_providers.dart';
import '../../../domain/entities/profile.dart';
import '../../../domain/services/progress_change.dart';
import '../../profile/providers/study_heatmap_providers.dart';
import 'profile_providers.dart';

/// Sự kiện hiệu ứng đang chờ UI hiển thị (đã xác nhận từ dữ liệu thật).
@immutable
class ProgressEvents {
  const ProgressEvents({this.newDays = const {}, this.milestone});

  /// Ngày học mới (đã chuẩn hoá) chưa được hiển thị hiệu ứng.
  final Set<DateTime> newDays;

  /// Mốc streak (3/7/30) vừa đạt chưa được hiển thị hiệu ứng.
  final int? milestone;

  static const none = ProgressEvents();

  @override
  bool operator ==(Object other) =>
      other is ProgressEvents &&
      other.milestone == milestone &&
      setEquals(other.newDays, newDays);

  @override
  int get hashCode => Object.hash(milestone, Object.hashAllUnordered(newDays));
}

/// Phát hiện thay đổi THẬT của streak/ngày học giữa hai snapshot thành công
/// trong cùng phiên — không bao giờ tự tính hay tự thêm dữ liệu.
///
/// - Snapshot thành công đầu tiên (của mỗi nguồn) chỉ là baseline: không
///   hiệu ứng. Loading/error không phải snapshot nên không tạo sự kiện và
///   không xoá baseline.
/// - Đổi tài khoản → baseline mới (provider dựng lại).
/// - Baseline và hàng chờ chỉ nằm trong bộ nhớ (không ghi DB). Notifier sống
///   cả phiên nên Home dựng lại/đổi tab không tạo baseline mới.
/// - So sánh theo GIÁ TRỊ đã chuẩn hoá, không theo object/timestamp: refresh
///   trả cùng dữ liệu → không sự kiện.
/// - UI "tiêu thụ" sự kiện bằng [takeNewDays]/[takeMilestone] khi thật sự hiển
///   thị; sự kiện chưa tiêu thụ chỉ giữ giá trị tối thiểu (tập ngày + 1 mốc).
class ProgressChangeTracker extends Notifier<ProgressEvents> {
  int? _streakBaseline;
  Set<DateTime>? _daysBaseline;
  bool _building = false;

  @override
  ProgressEvents build() {
    ref.watch(currentUserProvider.select((u) => u?.id));
    _streakBaseline = null;
    _daysBaseline = null;
    _building = true;
    ref.listen<AsyncValue<Profile?>>(
      profileProvider,
      (_, next) {
        final profile = _successValue(next);
        if (profile != null) onStreakSnapshot(profile.streakCount);
      },
      fireImmediately: true,
    );
    ref.listen<AsyncValue<Set<DateTime>>>(
      studyDaysProvider,
      (_, next) {
        final days = _successValue(next);
        if (days != null) onStudyDaysSnapshot(days);
      },
      fireImmediately: true,
    );
    _building = false;
    return ProgressEvents.none;
  }

  /// Giá trị của snapshot THÀNH CÔNG; null khi đang tải (kể cả tải lại còn giữ
  /// giá trị cũ) hoặc lỗi.
  T? _successValue<T>(AsyncValue<T> v) =>
      v.isLoading || v.hasError ? null : v.valueOrNull;

  /// Một snapshot streak thành công. Công khai để test logic độc lập với
  /// provider.
  @visibleForTesting
  void onStreakSnapshot(int streak) {
    final previous = _streakBaseline;
    _streakBaseline = streak;
    final milestone = streakMilestoneReached(previous, streak);
    if (milestone != null && !_building) {
      state = ProgressEvents(newDays: state.newDays, milestone: milestone);
    }
  }

  @visibleForTesting
  void onStudyDaysSnapshot(Set<DateTime> days) {
    final next = normalizeStudyDays(days);
    final previous = _daysBaseline;
    _daysBaseline = next;
    if (previous == null || _building) return;
    final fresh = newStudyDays(previous, next);
    if (fresh.isNotEmpty) {
      state = ProgressEvents(
        newDays: {...state.newDays, ...fresh},
        milestone: state.milestone,
      );
    }
  }

  /// Lấy và xoá hàng chờ ngày học mới (UI gọi khi sắp phát hiệu ứng).
  Set<DateTime> takeNewDays() {
    final days = state.newDays;
    if (days.isNotEmpty) {
      state = ProgressEvents(milestone: state.milestone);
    }
    return days;
  }

  /// Lấy và xoá mốc streak đang chờ; null nếu không có.
  int? takeMilestone() {
    final m = state.milestone;
    if (m != null) state = ProgressEvents(newDays: state.newDays);
    return m;
  }
}

final progressChangeTrackerProvider =
    NotifierProvider<ProgressChangeTracker, ProgressEvents>(
  ProgressChangeTracker.new,
);
