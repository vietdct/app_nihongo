import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Bản nháp Chính sách bảo mật — soạn theo dữ liệu THẬT app đang thu thập
/// (Supabase Auth/DB/Storage, Anthropic Claude cho AI Kaiwa). Đây là bản
/// nháp do AI soạn theo yêu cầu người dùng, cần người dùng rà soát/chỉnh
/// sửa (đặc biệt phần pháp lý) trước khi coi là chính thức.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: const Text('Chính sách bảo mật'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: const [
          _UpdatedAt(),
          SizedBox(height: 16),
          _Section(
            title: '1. Dữ liệu chúng tôi thu thập',
            body:
                '• Email và mật khẩu (qua Supabase Authentication) để tạo và '
                'đăng nhập tài khoản.\n'
                '• Thông tin hồ sơ bạn tự nhập: tên hiển thị, quốc gia, ảnh '
                'đại diện.\n'
                '• Dữ liệu học tập: từ vựng/Kanji/ngữ pháp đã học, kết quả '
                'quiz và thi thử JLPT, chuỗi ngày học, điểm kinh nghiệm (XP).\n'
                '• Nội dung hội thoại khi bạn dùng tính năng AI Kaiwa (văn '
                'bản bạn nhập/nói và phản hồi của AI).',
          ),
          _Section(
            title: '2. Mục đích sử dụng',
            body:
                'Dữ liệu trên được dùng để: vận hành tài khoản và đồng bộ '
                'tiến độ học tập giữa các thiết bị, cá nhân hoá nội dung ôn '
                'tập (Smart Review, AI Insights), và tạo phản hồi hội thoại '
                'trong tính năng AI Kaiwa. Chúng tôi không dùng dữ liệu của '
                'bạn cho quảng cáo và không bán dữ liệu cho bên thứ ba.',
          ),
          _Section(
            title: '3. Chia sẻ với bên thứ ba',
            body:
                '• Supabase: lưu trữ tài khoản, dữ liệu học tập và ảnh đại '
                'diện (cơ sở dữ liệu + storage).\n'
                '• Anthropic (Claude API): xử lý nội dung hội thoại khi bạn '
                'chủ động dùng tính năng AI Kaiwa, nhằm tạo phản hồi trò '
                'chuyện.\n'
                'Chúng tôi không chia sẻ dữ liệu cho bên thứ ba nào khác '
                'ngoài hai đơn vị trên để vận hành các tính năng nêu trên.',
          ),
          _Section(
            title: '4. Bảo mật',
            body:
                'Mật khẩu được Supabase Authentication mã hoá, không được '
                'app lưu trữ ở dạng văn bản thuần. Dữ liệu học tập và ảnh '
                'đại diện chỉ chủ tài khoản mới có quyền đọc/ghi (row-level '
                'security).',
          ),
          _Section(
            title: '5. Quyền của bạn',
            body:
                'Bạn có thể sửa hoặc xoá thông tin hồ sơ (tên, quốc gia, '
                'ảnh đại diện) trực tiếp trong app. Để yêu cầu xoá toàn bộ '
                'tài khoản và dữ liệu liên quan, hoặc có thắc mắc về quyền '
                'riêng tư, vui lòng liên hệ email hỗ trợ ở mục Tài khoản → '
                'Hỗ trợ.',
          ),
          _Section(
            title: '6. Thay đổi chính sách',
            body:
                'Chính sách này có thể được cập nhật khi app bổ sung tính '
                'năng mới liên quan đến dữ liệu người dùng. Ngày cập nhật '
                'gần nhất luôn hiển thị ở đầu trang.',
          ),
        ],
      ),
    );
  }
}

class _UpdatedAt extends StatelessWidget {
  const _UpdatedAt();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Cập nhật lần cuối: 07/08/2026',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.inkFaint,
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}
