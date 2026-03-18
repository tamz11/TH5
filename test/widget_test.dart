import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:th5/main.dart';

void main() {
  testWidgets('Habit tracker home screen is rendered', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const HabitTrackerApp());
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Habit Tracker'), findsOneWidget);
  });
}
