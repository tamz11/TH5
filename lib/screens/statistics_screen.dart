import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_provider.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
    final longestStreak = habits.isEmpty
        ? 0
        : habits
              .map((Habit habit) => habit.longestStreak)
              .reduce((int a, int b) => a > b ? a : b);
    final today = DateTime.now();
    final completedToday = habits
        .where((Habit habit) => habit.isCompletedOn(today))
        .length;
    final activeCount = habits.length;

    // 7-day completion timeline for chart
    final dateLabels = List<DateTime>.generate(
      7,
      (index) => DateTime.now().subtract(Duration(days: 6 - index)),
    );
    final timeline = dateLabels.map((DateTime day) {
      final doneCount = habits
          .where((Habit habit) => habit.isCompletedOn(day))
          .length;
      return doneCount / (habits.isEmpty ? 1 : habits.length);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: habits.isEmpty
          ? const Center(
              child: Text('No habits found. Add habits to view statistics.'),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: <Widget>[
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 64) / 2,
                      child: _StatTile(
                        title: 'Overall',
                        value: '${overall.toStringAsFixed(1)}%',
                        icon: Icons.track_changes_rounded,
                      ),
                    ),
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 64) / 2,
                      child: _StatTile(
                        title: 'Best streak',
                        value: '$bestStreak days',
                        icon: Icons.local_fire_department_rounded,
                      ),
                    ),
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 64) / 2,
                      child: _StatTile(
                        title: 'Longest streak',
                        value: '$longestStreak days',
                        icon: Icons.emoji_events_rounded,
                      ),
                    ),
                    SizedBox(
                      width: (MediaQuery.of(context).size.width - 64) / 2,
                      child: _StatTile(
                        title: 'Today',
                        value: '$completedToday / $activeCount',
                        icon: Icons.today_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Last 7 days',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Completion rate',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${(timeline.last * 100).toStringAsFixed(0)}%',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 140,
                          child: Row(
                            children: List<Widget>.generate(7, (index) {
                              final rate = timeline[index];
                              return Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          width: 18,
                                          height: 120 * rate,
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${dateLabels[index].day}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).dividerColor),
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
                                  backgroundColor: isDark
                                      ? const Color(0xFF2C3A34)
                                      : const Color(0xFFD5DFD8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.labelLarge
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
                              avatar: Icon(
                                Icons.repeat_rounded,
                                size: 16,
                                color: isDark
                                    ? const Color(0xFFD5E3DB)
                                    : const Color(0xFF345047),
                              ),
                              label: Text(habit.frequency.label),
                            ),
                            Chip(
                              avatar: Icon(
                                Icons.whatshot_rounded,
                                size: 16,
                                color: isDark
                                    ? const Color(0xFFD5E3DB)
                                    : const Color(0xFF345047),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF223029) : const Color(0xFFE8EFEA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            size: 18,
            color: isDark ? const Color(0xFFD5E3DB) : const Color(0xFF27443C),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
