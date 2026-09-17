import 'package:flutter/material.dart';

class JobMetric {
  const JobMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
    this.trendLabel,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;
  final String? trendLabel;
}
