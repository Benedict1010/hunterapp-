import 'package:flutter/widgets.dart';

import '../features/resume/presentation/resume_controller.dart';

class ResumeScope extends InheritedNotifier<ResumeController> {
  const ResumeScope({
    required ResumeController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static ResumeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ResumeScope>();
    assert(scope != null, 'No ResumeScope found in context');
    return scope!.notifier!;
  }

  static ResumeController? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ResumeScope>();
    return scope?.notifier;
  }
}
