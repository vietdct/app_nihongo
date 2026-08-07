import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Bản nháp Điều khoản dịch vụ — soạn theo yêu cầu người dùng, cần rà
/// soát/chỉnh sửa (đặc biệt phần pháp lý) trước khi coi là chính thức.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        title: const Text('Điều khoản dịch vụ'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: const [
          _UpdatedAt(),
          SizedBox(height: 16),
          _Section(
            title: '1. Chấp nhận điều khoản',
            body:
                'Bằng việc tạo tài khoản và sử dụng Nihongo, bạn đồng ý với '
                'các điều khoản dưới đây và với Chính sách bảo mật của app.',
          ),
          _Section(
            title: '2. Tài khoản',
            body:
                'Bạn chịu trách nhiệm bảo mật mật khẩu và mọi hoạt động '
                'diễn ra dưới tài khoản của mình. Mỗi người dùng chỉ nên tạo '
                'một tài khoản cho mục đích học tập cá nhân.',
          ),
          _Section(
            title: '3. Nội dung học tập',
            body:
                'Nội dung từ vựng, Kanji, ngữ pháp và đề thi thử trong app '
                'được biên soạn/tổng hợp phục vụ mục đích học tập, không '
                'phải tài liệu thi chính thức của JLPT hay Japan Foundation. '
                'App không đảm bảo kết quả thi thật sẽ giống hệt đề mô '
                'phỏng.',
          ),
          _Section(
            title: '4. Tính năng AI (Kaiwa, AI Insights)',
            body:
                'Các phản hồi do AI (Anthropic Claude) tạo ra chỉ mang tính '
                'hỗ trợ luyện tập, có thể chứa sai sót. Bạn không nên nhập '
                'thông tin cá nhân nhạy cảm (số CMND/CCCD, số thẻ ngân '
                'hàng...) khi trò chuyện với AI Kaiwa.',
          ),
          _Section(
            title: '5. Premium',
            body:
                'Các gói Premium (nếu có) mở khoá thêm tính năng theo mô tả '
                'tại thời điểm mua. Điều khoản thanh toán cụ thể sẽ được '
                'hiển thị tại màn hình nâng cấp trước khi bạn xác nhận mua.',
          ),
          _Section(
            title: '6. Hành vi bị cấm',
            body:
                'Không sử dụng app để: phát tán nội dung vi phạm pháp luật, '
                'tấn công/khai thác lỗ hổng hệ thống, hoặc thu thập dữ liệu '
                'của người dùng khác trái phép.',
          ),
          _Section(
            title: '7. Giới hạn trách nhiệm',
            body:
                'App được cung cấp "nguyên trạng", không đảm bảo hoạt động '
                'không gián đoạn hay không lỗi. Chúng tôi không chịu trách '
                'nhiệm cho thiệt hại gián tiếp phát sinh từ việc sử dụng '
                'app.',
          ),
          _Section(
            title: '8. Thay đổi điều khoản',
            body:
                'Điều khoản có thể được cập nhật khi app thay đổi tính '
                'năng. Ngày cập nhật gần nhất luôn hiển thị ở đầu trang. '
                'Nếu có thắc mắc, liên hệ email hỗ trợ ở mục Tài khoản → '
                'Hỗ trợ.',
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
