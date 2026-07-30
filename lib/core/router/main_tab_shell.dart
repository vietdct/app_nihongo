import 'package:flutter/material.dart';

import '../../features/grammar/grammar_home_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/kaiwa/kaiwa_home_screen.dart';
import '../../features/kanji/kanji_home_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/quiz/quiz_category_screen.dart';
import '../../features/review/review_screen.dart';
import '../theme/app_theme.dart';

/// Shell chứa 7 tab gốc (Home/Lesson/Grammar/Kanji/Kaiwa/Review/Hồ sơ) dùng
/// chung 1 thanh điều hướng dưới đáy — đúng số tab + icon trong mockup
/// "Nihongo App Redesign". "Lesson" trỏ tới màn chọn quiz thật (`/quiz`,
/// `QuizCategoryScreen`) vì app chưa có khái niệm "lesson" độc lập khớp icon
/// mockup — dùng thẳng dữ liệu quiz đã có thay vì bịa 1 khái niệm mới không
/// dữ liệu thật. Mọi route con khác (VD `/vocabulary`, `/lessons/:id`...)
/// vẫn là route cấp cao qua `context.push`, tự động che toàn màn hình và ẩn
/// thanh nav này — đúng hành vi `showNav=false` của mockup cho các màn học/
/// luyện tập chi tiết. Tab "Premium" bị bỏ khỏi thanh nav theo đúng 7 tab
/// mockup — vẫn có thể vào qua mục "Nâng cấp Premium" trong Hồ sơ.
class MainTabShell extends StatefulWidget {
  const MainTabShell({super.key});

  @override
  State<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends State<MainTabShell> {
  int _index = 0;

  /// Chỉ số các tab đã từng mở — mỗi tab chỉ thực sự build (và bắt đầu
  /// watch provider của nó) khi được mở lần đầu, thay vì cả 7 tab cùng build
  /// ngay khi vào app. Nhiều tab có provider khá nặng (JLPT progress đọc
  /// tuần tự cả 5 cấp độ, danh sách Kanji/Grammar theo cấp độ...) — build
  /// cùng lúc làm mọi provider (kể cả currentUserProvider phụ thuộc, VD lúc
  /// đăng xuất) phải chạy lại đồng thời, làm chậm hẳn phản hồi UI dù không
  /// tab nào đang hiển thị.
  final Set<int> _visited = {0};

  static const _tabs = [
    (icon: Icons.home_outlined, label: 'Home'),
    (icon: Icons.menu_book_outlined, label: 'Lesson'),
    (icon: Icons.description_outlined, label: 'Grammar'),
    (icon: Icons.edit_outlined, label: 'Kanji'),
    (icon: Icons.chat_bubble_outline, label: 'Kaiwa'),
    (icon: Icons.monitor_heart_outlined, label: 'Review'),
    (icon: Icons.person_outline, label: 'Hồ sơ'),
  ];

  static const _tabBuilders = <WidgetBuilder>[
    _buildHome,
    _buildLesson,
    _buildGrammar,
    _buildKanji,
    _buildKaiwa,
    _buildReview,
    _buildProfile,
  ];

  static Widget _buildHome(BuildContext context) => const HomeScreen();
  static Widget _buildLesson(BuildContext context) =>
      const QuizCategoryScreen();
  static Widget _buildGrammar(BuildContext context) =>
      const GrammarHomeScreen();
  static Widget _buildKanji(BuildContext context) => const KanjiHomeScreen();
  static Widget _buildKaiwa(BuildContext context) => const KaiwaHomeScreen();
  static Widget _buildReview(BuildContext context) => const ReviewScreen();
  static Widget _buildProfile(BuildContext context) => const ProfileScreen();

  void _selectTab(int i) {
    setState(() {
      _index = i;
      _visited.add(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < _tabBuilders.length; i++)
            _visited.contains(i)
                ? _tabBuilders[i](context)
                : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: _NavTabButton(
                    icon: _tabs[i].icon,
                    label: _tabs[i].label,
                    active: i == _index,
                    onTap: () => _selectTab(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTabButton extends StatelessWidget {
  const _NavTabButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.inkFaint;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
