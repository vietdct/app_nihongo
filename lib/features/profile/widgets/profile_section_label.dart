import 'package:flutter/material.dart';

class ProfileSectionLabel extends StatelessWidget {
  const ProfileSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).brightness == Brightness.dark
            ? colorScheme.onSurfaceVariant
            : const Color(0xFFB7AE9F),
        letterSpacing: 0.6,
      ),
    );
  }
}
