import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hunter/app/app.dart';

void main() {
  testWidgets('landing starts the supplied onboarding flow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const AiJobHunterApp());
    expect(find.text('Your AI Job Search,'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Get Started'), 300);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Resume Verified'), findsOneWidget);
  });
}
