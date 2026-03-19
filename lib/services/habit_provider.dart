import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/habit.dart';
import 'habit_storage_service.dart';
import 'notification_service.dart';

class HabitProvider extends ChangeNotifier {
  HabitProvider(this._storageService);

  final HabitStorageService _storageService;

  final List<Habit> _habits = <Habit>[];
  bool _isLoading = false;
  DateTime? _lastOpened;

  List<Habit> get habits => List<Habit>.unmodifiable(_habits);
  bool get isLoading => _isLoading;
  DateTime? get lastOpened => _lastOpened;

  int _notificationIdForHabit(Habit habit) => habit.id.hashCode & 0x7FFFFFFF;

  Day _dayFromWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return Day.monday;
      case DateTime.tuesday:
        return Day.tuesday;
      case DateTime.wednesday:
        return Day.wednesday;
      case DateTime.thursday:
        return Day.thursday;
      case DateTime.friday:
        return Day.friday;
      case DateTime.saturday:
        return Day.saturday;
      case DateTime.sunday:
      default:
        return Day.sunday;
    }
  }

  Future<void> _scheduleReminderForHabit(Habit habit) async {
    if (!habit.hasReminder || habit.reminderTimeOfDay == null) {
      await NotificationService.instance.cancelNotification(
        _notificationIdForHabit(habit),
      );
      return;
    }

    final time = habit.reminderTimeOfDay!;
    if (habit.frequency == HabitFrequency.daily) {
      await NotificationService.instance.scheduleDailyNotification(
        id: _notificationIdForHabit(habit),
        title: 'Habit reminder',
        body: 'Time to complete "${habit.name}"',
        hour: time.hour,
        minute: time.minute,
      );
    } else {
      await NotificationService.instance.scheduleWeeklyNotification(
        id: _notificationIdForHabit(habit),
        title: 'Habit reminder',
        body: 'Time to complete "${habit.name}"',
        day: _dayFromWeekday(DateTime.now().weekday),
        hour: time.hour,
        minute: time.minute,
      );
    }
  }

  Future<void> _scheduleAllReminders() async {
    for (final habit in _habits) {
      await _scheduleReminderForHabit(habit);
    }
  }

  Future<void> loadHabits() async {
    _isLoading = true;
    notifyListeners();

    _lastOpened = await _storageService.loadLastOpened();
    final loaded = await _storageService.loadHabits();
    _habits
      ..clear()
      ..addAll(loaded);

    await _scheduleAllReminders();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addHabit({
    required String name,
    required String description,
    required HabitFrequency frequency,
    bool reminderEnabled = false,
    String? reminderTime,
  }) async {
    final now = DateTime.now();
    final newHabit = Habit(
      id: now.microsecondsSinceEpoch.toString(),
      name: name,
      description: description,
      frequency: frequency,
      createdAt: now,
      reminderEnabled: reminderEnabled,
      reminderTime: reminderTime,
    );

    _habits.insert(0, newHabit);
    await _persistAndNotify();
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    final index = _habits.indexWhere(
      (Habit habit) => habit.id == updatedHabit.id,
    );
    if (index == -1) {
      return;
    }

    _habits[index] = updatedHabit;
    await _persistAndNotify();
  }

  Future<void> deleteHabit(String id) async {
    _habits.removeWhere((Habit habit) => habit.id == id);
    await _persistAndNotify();
  }

  Future<void> toggleHabitForToday(String id, bool isCompleted) async {
    final index = _habits.indexWhere((Habit habit) => habit.id == id);
    if (index == -1) {
      return;
    }

    _habits[index] = _habits[index].toggleCompletion(
      DateTime.now(),
      isCompleted,
    );
    await _persistAndNotify();
  }

  Future<void> toggleHabitForDate(
    String id,
    DateTime date,
    bool isCompleted,
  ) async {
    final index = _habits.indexWhere((Habit habit) => habit.id == id);
    if (index == -1) {
      return;
    }

    _habits[index] = _habits[index].toggleCompletion(date, isCompleted);
    await _persistAndNotify();
  }

  Future<void> _persistAndNotify() async {
    await _storageService.saveHabits(_habits);
    await _scheduleAllReminders();
    notifyListeners();
  }
}
