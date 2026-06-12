// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_courses/app/app.dart';

void main() {
  testWidgets('App boots to dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const StudentAIApp());
    await tester.pumpAndSettle();

    // Basic smoke assertion for dashboard greeting text.
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Text) return false;
        final value = widget.data ?? '';
        return value.startsWith('Good ');
      }),
      findsAtLeastNWidgets(1),
    );
  });
}
