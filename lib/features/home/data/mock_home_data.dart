import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/job_metric.dart';

const homeMetrics = [
  JobMetric(
    label: 'Jobs Scanned',
    value: '1,284',
    icon: Icons.search_rounded,
    accentColor: AppColors.primary,
    trendLabel: '+12%',
  ),
  JobMetric(
    label: 'New Matches',
    value: '42',
    icon: Icons.auto_awesome_outlined,
    accentColor: Color(0xFF9A6BD6),
    trendLabel: 'Hot',
  ),
  JobMetric(
    label: 'Strong Matches',
    value: '18',
    icon: Icons.track_changes_outlined,
    accentColor: AppColors.success,
    trendLabel: '95%+',
  ),
  JobMetric(
    label: 'Applications',
    value: '08',
    icon: Icons.assignment_outlined,
    accentColor: AppColors.warning,
  ),
];
