import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_tokens.dart';

class ToggleRow extends StatelessWidget {
  const ToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
    super.key,
    this.subtitle,
    this.leading,
  });
  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool value;
  final ValueChanged<bool>? onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (leading case final value?) ...[
        value,
        const SizedBox(width: AppSpacing.sm),
      ],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle case final value?)
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
      Switch(value: value, onChanged: onChanged),
    ],
  );
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.trailing,
  });
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hintText,
      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
      suffixIcon: trailing,
    ),
  );
}
