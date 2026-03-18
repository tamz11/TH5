import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habits = context.watch<HabitProvider>().habits;
    final overall = habits.isEmpty
        ? 0.0
        : habits
                .map((Habit habit) => habit.completionPercentage)
                .reduce((double a, double b) => a + b) /
            habits.length;
    final bestStreak = habits.isEmpty
        ? 0
        : habits
            .map((Habit habit) => habit.currentStreak)
            .reduce((int a, int b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: habits.isEmpty
          ? const Center(
              child: Text('No habits found. Add habits to view statistics.'),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _StatTile(
                        title: 'Overall',
                        value: '${overall.toStringAsFixed(1)}%',
                        icon: Icons.track_changes_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        title: 'Best streak',
                        value: '$bestStreak days',
                        icon: Icons.local_fire_department_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Per habit',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                ...habits.map((Habit habit) {
                  final percentage = habit.completionPercentage.clamp(0, 100);
                  final progress = (percentage / 100).clamp(0.0, 1.0);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDEE5DF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          habit.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  minHeight: 10,
                                  value: progress,
                                  backgroundColor: const Color(0xFFD5DFD8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: <Widget>[
                            Chip(
                              avatar: const Icon(
                                Icons.repeat_rounded,
                                size: 16,
                                color: Color(0xFF345047),
                              ),
                              label: Text(habit.frequency.label),
                            ),
                            Chip(
                              avatar: const Icon(
                                Icons.whatshot_rounded,
                                size: 16,
                                color: Color(0xFF345047),
                              ),
                              label: Text('Streak: ${habit.currentStreak}'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EFEA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 18, color: const Color(0xFF27443C)),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
