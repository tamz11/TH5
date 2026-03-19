import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/habit.dart';

class HabitStorageService {
  static const String _habitsKey = 'habit_tracker_habits_v1';
  static const String _lastOpenedKey = 'habit_tracker_last_opened_v1';

  Future<List<Habit>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_habitsKey);

    if (data == null || data.isEmpty) {
      return <Habit>[];
    }

    final decoded = jsonDecode(data) as List<dynamic>;
    return decoded
        .map((dynamic item) => Habit.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      habits.map((Habit habit) => habit.toJson()).toList(),
    );
    await prefs.setString(_habitsKey, encoded);
  }

  Future<DateTime?> loadLastOpened() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastOpenedKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  Future<void> saveLastOpened(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastOpenedKey, timestamp.toIso8601String());
  }
}
