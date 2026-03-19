import 'package:flutter/material.dart';

enum HabitFrequency { daily, weekly }

extension HabitFrequencyX on HabitFrequency {
  String get value {
    switch (this) {
      case HabitFrequency.daily:
        return 'daily';
      case HabitFrequency.weekly:
        return 'weekly';
    }
  }

  String get label {
    switch (this) {
      case HabitFrequency.daily:
        return 'Daily';
      case HabitFrequency.weekly:
        return 'Weekly';
    }
  }

  static HabitFrequency fromString(String value) {
    switch (value.toLowerCase()) {
      case 'weekly':
        return HabitFrequency.weekly;
      case 'daily':
      default:
        return HabitFrequency.daily;
    }
  }
}

class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.description,
    required this.frequency,
    required this.createdAt,
    Set<String>? completionDates,
    this.reminderEnabled = false,
    this.reminderTime,
  }) : completionDates = completionDates ?? <String>{};

  final String id;
  final String name;
  final String description;
  final HabitFrequency frequency;
  final DateTime createdAt;
  final Set<String> completionDates;
  final bool reminderEnabled;
  final String? reminderTime; // HH:mm

  Habit copyWith({
    String? id,
    String? name,
    String? description,
    HabitFrequency? frequency,
    DateTime? createdAt,
    Set<String>? completionDates,
    bool? reminderEnabled,
    String? reminderTime,
  }) {
    return Habit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      frequency: frequency ?? this.frequency,
      createdAt: createdAt ?? this.createdAt,
      completionDates:
          completionDates ?? Set<String>.from(this.completionDates),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'frequency': frequency.value,
      'createdAt': createdAt.toIso8601String(),
      'completionDates': completionDates.toList(),
      'reminderEnabled': reminderEnabled,
      'reminderTime': reminderTime,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) {
    final rawDates = (json['completionDates'] as List<dynamic>? ?? <dynamic>[])
        .map((dynamic e) => e.toString())
        .toSet();

    return Habit(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      frequency: HabitFrequencyX.fromString(
        (json['frequency'] as String?) ?? 'daily',
      ),
      createdAt:
          DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime.now(),
      completionDates: rawDates,
      reminderEnabled: (json['reminderEnabled'] as bool?) ?? false,
      reminderTime: (json['reminderTime'] as String?),
    );
  }

  bool isCompletedOn(DateTime date) {
    if (frequency == HabitFrequency.daily) {
      return completionDates.contains(_dateKey(date));
    }

    final weekStart = _startOfWeek(date);
    return completionDates.any((String key) {
      final parsed = DateTime.tryParse(key);
      if (parsed == null) {
        return false;
      }
      return _startOfWeek(parsed) == weekStart;
    });
  }

  Habit toggleCompletion(DateTime date, bool isCompleted) {
    final updatedDates = Set<String>.from(completionDates);

    if (frequency == HabitFrequency.daily) {
      final key = _dateKey(date);
      if (isCompleted) {
        updatedDates.add(key);
      } else {
        updatedDates.remove(key);
      }
      return copyWith(completionDates: updatedDates);
    }

    final weekStart = _startOfWeek(date);
    if (isCompleted) {
      updatedDates.removeWhere((String key) {
        final parsed = DateTime.tryParse(key);
        if (parsed == null) {
          return false;
        }
        return _startOfWeek(parsed) == weekStart;
      });
      updatedDates.add(_dateKey(date));
    } else {
      updatedDates.removeWhere((String key) {
        final parsed = DateTime.tryParse(key);
        if (parsed == null) {
          return false;
        }
        return _startOfWeek(parsed) == weekStart;
      });
    }

    return copyWith(completionDates: updatedDates);
  }

  double get completionPercentage {
    if (frequency == HabitFrequency.daily) {
      const daysToTrack = 30;
      var done = 0;
      final now = _normalizeDate(DateTime.now());

      for (var i = 0; i < daysToTrack; i++) {
        final day = now.subtract(Duration(days: i));
        if (isCompletedOn(day)) {
          done++;
        }
      }
      return (done / daysToTrack) * 100;
    }

    const weeksToTrack = 12;
    var done = 0;
    final now = _normalizeDate(DateTime.now());

    for (var i = 0; i < weeksToTrack; i++) {
      final day = now.subtract(Duration(days: i * 7));
      if (isCompletedOn(day)) {
        done++;
      }
    }
    return (done / weeksToTrack) * 100;
  }

  int get currentStreak {
    var streak = 0;
    final now = _normalizeDate(DateTime.now());

    if (frequency == HabitFrequency.daily) {
      var cursor = now;
      while (isCompletedOn(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
      return streak;
    }

    var cursor = _startOfWeek(now);
    while (isCompletedOn(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 7));
    }
    return streak;
  }

  bool get hasReminder => reminderEnabled && reminderTime != null;

  TimeOfDay? get reminderTimeOfDay {
    if (reminderTime == null) return null;
    final parts = reminderTime!.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  int get longestStreak {
    if (completionDates.isEmpty) {
      return 0;
    }

    final normalizedDays = completionDates
        .map((String key) => DateTime.tryParse(key))
        .whereType<DateTime>()
        .map(_normalizeDate)
        .toSet();

    if (normalizedDays.isEmpty) {
      return 0;
    }

    final List<DateTime> sorted = normalizedDays.toList()
      ..sort((a, b) => a.compareTo(b));

    var longest = 1;
    var current = 1;
    for (var i = 1; i < sorted.length; i++) {
      final previous = sorted[i - 1];
      final currentDate = sorted[i];

      final expected = frequency == HabitFrequency.daily
          ? previous.add(const Duration(days: 1))
          : _startOfWeek(previous.add(const Duration(days: 7)));

      if (frequency == HabitFrequency.daily
          ? currentDate == expected
          : _startOfWeek(currentDate) == expected) {
        current++;
      } else {
        longest = longest > current ? longest : current;
        current = 1;
      }
    }

    longest = longest > current ? longest : current;
    return longest;
  }
}

DateTime _normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime _startOfWeek(DateTime date) {
  final normalized = _normalizeDate(date);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

String _dateKey(DateTime date) {
  final normalized = _normalizeDate(date);
  final year = normalized.year.toString().padLeft(4, '0');
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
