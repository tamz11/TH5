import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_provider.dart';
import '../services/theme_provider.dart';
import '../widgets/habit_card.dart';
import 'add_edit_habit_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greetingByHour(int hour) {
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 18) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final provider = context.watch<HabitProvider>();
    final today = DateTime.now();
    final total = provider.habits.length;
    final completed = provider.habits
        .where((Habit habit) => habit.isCompletedOn(today))
        .length;
    final completion = total == 0 ? 0.0 : completed / total;

    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nights_stay,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle theme',
          ),
          IconButton(
            icon: const Icon(Icons.query_stats_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const StatisticsScreen(),
                ),
              );
            },
            tooltip: 'Statistics',
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: <Widget>[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                  sliver: SliverToBoxAdapter(
                    child: _HomeHeader(
                      greeting: _greetingByHour(today.hour),
                      total: total,
                      completed: completed,
                      completion: completion,
                      onStatisticsTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const StatisticsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (provider.habits.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF223029)
                                    : const Color(0xFFE7EEE8),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_motion,
                                size: 36,
                                color: Color(0xFF1E5B4F),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No habits yet',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap + to build your first routine and track your streak every day.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 120),
                    sliver: SliverList.builder(
                      itemCount: provider.habits.length,
                      itemBuilder: (BuildContext context, int index) {
                        final habit = provider.habits[index];
                        final isCompletedToday = habit.isCompletedOn(today);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: HabitCard(
                            habit: habit,
                            isCompletedToday: isCompletedToday,
                            onChanged: (bool value) {
                              provider.toggleHabitForToday(habit.id, value);
                            },
                            onEdit: () {
                              _goToAddOrEdit(context, habit: habit);
                            },
                            onDelete: () {
                              _confirmDelete(context, habit, provider);
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToAddOrEdit(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _goToAddOrEdit(BuildContext context, {Habit? habit}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AddEditHabitScreen(habit: habit)),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Habit habit,
    HabitProvider provider,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete habit'),
          content: Text('Are you sure you want to delete "${habit.name}"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await provider.deleteHabit(habit.id);
    }
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.total,
    required this.completed,
    required this.completion,
    required this.onStatisticsTap,
  });

  final String greeting;
  final int total;
  final int completed;
  final double completion;
  final VoidCallback onStatisticsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final percentage = (completion * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? <Color>[const Color(0xFF1B2823), const Color(0xFF21352E)]
              : <Color>[const Color(0xFFEEF4EF), const Color(0xFFE3ECE6)],
        ),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Today\'s Focus',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onStatisticsTap,
                icon: const Icon(Icons.query_stats_rounded),
                tooltip: 'Statistics',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '$completed of $total habits completed',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF1E5B4F),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: completion,
              backgroundColor: isDark
                  ? const Color(0xFF2C3A34)
                  : const Color(0xFFD2DFD6),
            ),
          ),
        ],
      ),
    );
  }
}
