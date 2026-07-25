import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  /// Đăng ký: email thật. Đăng nhập: email HOẶC tên đăng nhập (identifier).
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _isSignUp = false;

  static final _usernamePattern = RegExp(r'^[a-zA-Z0-9_\.]{3,20}$');

  @override
  void dispose() {
    _email.dispose();
    _username.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ctrl = ref.read(authControllerProvider.notifier);
    if (_isSignUp) {
      await ctrl.signUpWithEmail(
        _email.text.trim(),
        _password.text,
        _name.text.trim(),
        _username.text.trim(),
      );
    } else {
      await ctrl.signInWithIdentifier(_email.text.trim(), _password.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final loading = state.isLoading;

    ref.listen(authControllerProvider, (_, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Lỗi: ${next.error}')));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _HeroTitle(),
                    const SizedBox(height: 28),
                    _AuthTabs(
                      isSignUp: _isSignUp,
                      onChanged:
                          loading ? null : (v) => setState(() => _isSignUp = v),
                    ),
                    const SizedBox(height: 22),
                    if (_isSignUp) ...[
                      _LabeledField(
                        label: 'Tên hiển thị',
                        child: TextFormField(
                          controller: _name,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                          ),
                          decoration:
                              const InputDecoration(hintText: 'Tên của bạn'),
                          textInputAction: TextInputAction.next,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Nhập tên hiển thị'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: 'Tên đăng nhập',
                        child: TextFormField(
                          controller: _username,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                          ),
                          decoration:
                              const InputDecoration(hintText: 'ten_dang_nhap'),
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return 'Nhập tên đăng nhập';
                            if (!_usernamePattern.hasMatch(value)) {
                              return '3-20 ký tự, chỉ chữ/số/dấu gạch dưới';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _LabeledField(
                      label: _isSignUp ? 'Email' : 'Email hoặc tên đăng nhập',
                      child: TextFormField(
                        controller: _email,
                        style:
                            const TextStyle(color: AppColors.ink, fontSize: 15),
                        keyboardType: _isSignUp
                            ? TextInputType.emailAddress
                            : TextInputType.text,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: _isSignUp
                              ? 'ban@email.com'
                              : 'ban@email.com hoặc tên đăng nhập',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return _isSignUp
                                ? 'Email không hợp lệ'
                                : 'Nhập email hoặc tên đăng nhập';
                          }
                          if (_isSignUp && !v.contains('@')) {
                            return 'Email không hợp lệ';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    _LabeledField(
                      label: 'Mật khẩu',
                      child: TextFormField(
                        controller: _password,
                        style:
                            const TextStyle(color: AppColors.ink, fontSize: 15),
                        obscureText: true,
                        decoration: const InputDecoration(hintText: '••••••••'),
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) => (v == null || v.length < 6)
                            ? 'Tối thiểu 6 ký tự'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: loading ? null : _submit,
                      child: loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_isSignUp ? 'Đăng ký' : 'Đăng nhập'),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'hoặc',
                            style: TextStyle(
                              color: AppColors.inkFaint,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.border)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: loading
                          ? null
                          : () => ref
                              .read(authControllerProvider.notifier)
                              .signInWithGoogle(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: const BorderSide(
                          color: AppColors.border,
                          width: 1.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        foregroundColor: AppColors.ink,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _GoogleMark(),
                          SizedBox(width: 10),
                          Text(
                            'Tiếp tục với Google',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            color: AppColors.inkSoft,
                            fontSize: 13.5,
                          ),
                          children: [
                            TextSpan(
                              text: _isSignUp
                                  ? 'Đã có tài khoản? '
                                  : 'Chưa có tài khoản? ',
                            ),
                            TextSpan(
                              text: _isSignUp ? 'Đăng nhập' : 'Đăng ký ngay',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = loading
                                    ? null
                                    : () =>
                                        setState(() => _isSignUp = !_isSignUp),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        height: 148,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -30,
              right: -36,
              child: Text(
                '語',
                style: AppFonts.zenMaruGothic(
                  fontSize: 190,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentSoft,
                ),
              ),
            ),
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '日本語',
                    textAlign: TextAlign.center,
                    style: AppFonts.zenMaruGothic(
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Chinh phục JLPT theo lộ trình\ncủa riêng bạn',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.inkSoft,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({required this.isSignUp, required this.onChanged});

  final bool isSignUp;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.chip,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _AuthTab(
              label: 'Đăng nhập',
              selected: !isSignUp,
              onTap: () => onChanged?.call(false),
            ),
          ),
          Expanded(
            child: _AuthTab(
              label: 'Đăng ký',
              selected: isSignUp,
              onTap: () => onChanged?.call(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTab extends StatelessWidget {
  const _AuthTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 14,
            color: selected ? AppColors.ink : AppColors.inkFaint,
          ),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration:
          const BoxDecoration(color: AppColors.indigo, shape: BoxShape.circle),
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
