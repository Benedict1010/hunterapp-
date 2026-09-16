import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.leading,
    this.trailing,
    this.isExpanded = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final bool isExpanded;
  @override
  Widget build(BuildContext context) {
    final child = ElevatedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading case final value?) ...[value, const SizedBox(width: 8)],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (trailing case final value?) ...[const SizedBox(width: 8), value],
        ],
      ),
    );
    return isExpanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class SecondaryOutlinedButton extends StatelessWidget {
  const SecondaryOutlinedButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.leading,
    this.trailing,
    this.isExpanded = true,
  });
  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final Widget? trailing;
  final bool isExpanded;
  @override
  Widget build(BuildContext context) {
    final child = OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (leading case final value?) ...[value, const SizedBox(width: 8)],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (trailing case final value?) ...[const SizedBox(width: 8), value],
        ],
      ),
    );
    return isExpanded ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    super.key,
    this.color,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? color;
  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip,
    icon: Icon(icon, color: color),
  );
}
