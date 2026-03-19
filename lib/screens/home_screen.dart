import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_provider.dart';
import '../services/theme_provider.dart';
import '../widgets/habit_card.dart';
import 'add_edit_habit_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _HabitFilter { all, completed, pending, daily, weekly }

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _HabitFilter _activeFilter = _HabitFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _greetingByHour(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  List<Habit> _filteredHabits(List<Habit> habits, DateTime today) {
    final normalizedQuery = _searchQuery.trim().toLowerCase();

    return habits
        .where((Habit habit) {
          final matchesSearch =
              normalizedQuery.isEmpty ||
              habit.name.toLowerCase().contains(normalizedQuery) ||
              habit.description.toLowerCase().contains(normalizedQuery);

          if (!matchesSearch) return false;

          switch (_activeFilter) {
            case _HabitFilter.all:
              return true;
            case _HabitFilter.completed:
              return habit.isCompletedOn(today);
            case _HabitFilter.pending:
              return !habit.isCompletedOn(today);
            case _HabitFilter.daily:
              return habit.frequency == HabitFrequency.daily;
            case _HabitFilter.weekly:
              return habit.frequency == HabitFrequency.weekly;
          }
        })
        .toList(growable: false);
  }

  bool get _hasActiveConditions =>
      _searchQuery.trim().isNotEmpty || _activeFilter != _HabitFilter.all;

  String _filterLabel(_HabitFilter filter) {
    switch (filter) {
      case _HabitFilter.all:
        return 'All';
      case _HabitFilter.completed:
        return 'Completed';
      case _HabitFilter.pending:
        return 'Pending';
      case _HabitFilter.daily:
        return 'Daily';
      case _HabitFilter.weekly:
        return 'Weekly';
    }
  }

  void _clearConditions() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _activeFilter = _HabitFilter.all;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<HabitProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final today = DateTime.now();
    final lastOpened = provider.lastOpened;

    final total = provider.habits.length;
    final completed = provider.habits
        .where((habit) => habit.isCompletedOn(today))
        .length;

    final completion = total == 0 ? 0.0 : completed / total;
    final visibleHabits = _filteredHabits(provider.habits, today);
    final isSearchingOrFiltering = _hasActiveConditions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Tracker'),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nights_stay,
            ),
            onPressed: themeProvider.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.query_stats_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StatisticsScreen()),
              );
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: provider.loadHabits,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                    sliver: SliverToBoxAdapter(
                      child: _HomeHeader(
                        greeting: _greetingByHour(today.hour),
                        lastOpened: lastOpened,
                        total: total,
                        completed: completed,
                        completion: completion,
                        onStatisticsTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const StatisticsScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    sliver: SliverToBoxAdapter(
                      child: _HomeControls(
                        controller: _searchController,
                        activeFilter: _activeFilter,
                        onSearchChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        onFilterChanged: (filter) {
                          setState(() => _activeFilter = filter);
                        },
                        onClear: isSearchingOrFiltering
                            ? _clearConditions
                            : null,
                        filterLabelBuilder: _filterLabel,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Text(
                            isSearchingOrFiltering
                                ? 'Showing ${visibleHabits.length} habits'
                                : 'Today\'s habits',
                          ),
                          const Spacer(),
                          Text('$completed/$total done'),
                        ],
                      ),
                    ),
                  ),
                  if (provider.habits.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No habits yet')),
                    )
                  else if (visibleHabits.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        title: 'No matching habits',
                        subtitle: 'Try another keyword',
                        actionLabel: 'Clear filters',
                        onActionTap: _clearConditions,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 120),
                      sliver: SliverList.builder(
                        itemCount: visibleHabits.length,
                        itemBuilder: (_, index) {
                          final habit = visibleHabits[index];
                          return HabitCard(
                            habit: habit,
                            isCompletedToday: habit.isCompletedOn(today),
                            onChanged: (value) =>
                                provider.toggleHabitForToday(habit.id, value),
                            onEdit: () => _goToAddOrEdit(context, habit: habit),
                            onDelete: () =>
                                _confirmDelete(context, habit, provider),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToAddOrEdit(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _goToAddOrEdit(BuildContext context, {Habit? habit}) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AddEditHabitScreen(habit: habit)));
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Habit habit,
    HabitProvider provider,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete habit'),
        content: Text('Delete "${habit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await provider.deleteHabit(habit.id);
    }
  }
}
