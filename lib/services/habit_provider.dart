import 'package:flutter/foundation.dart';

import '../models/habit.dart';
import 'habit_storage_service.dart';

class HabitProvider extends ChangeNotifier {
  HabitProvider(this._storageService);

  final HabitStorageService _storageService;

  final List<Habit> _habits = <Habit>[];
  bool _isLoading = false;

  List<Habit> get habits => List<Habit>.unmodifiable(_habits);
  bool get isLoading => _isLoading;

  Future<void> loadHabits() async {
    _isLoading = true;
    notifyListeners();

    final loaded = await _storageService.loadHabits();
    _habits
      ..clear()
      ..addAll(loaded);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addHabit({
    required String name,
    required String description,
    required HabitFrequency frequency,
  }) async {
    final now = DateTime.now();
    final newHabit = Habit(
      id: now.microsecondsSinceEpoch.toString(),
      name: name,
      description: description,
      frequency: frequency,
      createdAt: now,
    );

    _habits.insert(0, newHabit);
    await _persistAndNotify();
  }

  Future<void> updateHabit(Habit updatedHabit) async {
    final index = _habits.indexWhere((Habit habit) => habit.id == updatedHabit.id);
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

    _habits[index] = _habits[index].toggleCompletion(DateTime.now(), isCompleted);
    await _persistAndNotify();
  }

  Future<void> _persistAndNotify() async {
    await _storageService.saveHabits(_habits);
    notifyListeners();
  }
}
