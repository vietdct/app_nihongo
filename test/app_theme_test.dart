import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihongo/core/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('light theme dùng Material 3 và đúng độ sáng', () {
      final theme = AppTheme.light();
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('dark theme dùng Material 3 và đúng độ sáng', () {
      final theme = AppTheme.dark();
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('màu cam đất được gán vào primary (CTA chính)', () {
      final theme = AppTheme.light();
      expect(theme.colorScheme.primary, AppColors.accent);
    });
  });
}
