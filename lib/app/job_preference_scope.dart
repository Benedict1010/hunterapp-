import 'package:flutter/widgets.dart';

import '../features/preferences/presentation/job_preference_controller.dart';

class JobPreferenceScope extends InheritedNotifier<JobPreferenceController> {
  const JobPreferenceScope({
    required JobPreferenceController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static JobPreferenceController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<JobPreferenceScope>();
    assert(scope != null, 'No JobPreferenceScope found in context');
    return scope!.notifier!;
  }

  static JobPreferenceController? maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<JobPreferenceScope>();
    return scope?.notifier;
  }
}
