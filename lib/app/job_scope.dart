import 'package:flutter/widgets.dart';

import '../features/jobs/presentation/job_controller.dart';

class JobScope extends InheritedNotifier<JobController> {
  const JobScope({
    required JobController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static JobController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<JobScope>();
    assert(scope != null, 'No JobScope found in context');
    return scope!.notifier!;
  }

  static JobController? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<JobScope>();
    return scope?.notifier;
  }
}
