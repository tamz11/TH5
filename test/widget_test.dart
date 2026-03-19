import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:th5/main.dart';

void main() {
  testWidgets('Habit tracker home screen is rendered', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const HabitTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Today\'s Focus'), findsOneWidget);
    expect(find.text('Search habits...'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
