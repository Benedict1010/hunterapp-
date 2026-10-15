import 'package:flutter/widgets.dart';

import '../features/job_sources/presentation/job_source_controller.dart';

class JobSourceScope extends InheritedNotifier<JobSourceController> {
  const JobSourceScope({
    required JobSourceController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static JobSourceController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<JobSourceScope>();
    assert(scope != null, 'No JobSourceScope found in context');
    return scope!.notifier!;
  }

  static JobSourceController? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<JobSourceScope>();
    return scope?.notifier;
  }
}
