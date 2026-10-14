import 'package:flutter/widgets.dart';

import '../features/applications/presentation/application_controller.dart';

class ApplicationScope extends InheritedNotifier<ApplicationController> {
  const ApplicationScope({
    required ApplicationController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static ApplicationController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ApplicationScope>();
    assert(scope != null, 'No ApplicationScope found in context');
    return scope!.notifier!;
  }

  static ApplicationController? maybeOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ApplicationScope>();
    return scope?.notifier;
  }
}
