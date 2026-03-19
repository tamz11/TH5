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
    if (hour < 12) {
      return 'Good morning';
    }
    if (hour < 18) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  List<Habit> _filteredHabits(List<Habit> habits, DateTime today) {
    final normalizedQuery = _searchQuery.trim().toLowerCase();

    return habits.where((Habit habit) {
      final matchesSearch = normalizedQuery.isEmpty ||
          habit.name.toLowerCase().contains(normalizedQuery) ||
          habit.description.toLowerCase().contains(normalizedQuery);

      if (!matchesSearch) {
        return false;
      }

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
    }).toList(growable: false);
  }

  bool get _hasActiveConditions {
    return _searchQuery.trim().isNotEmpty || _activeFilter != _HabitFilter.all;
  }

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
    final isDark = theme.brightness == Brightness.dark;

    final provider = context.watch<HabitProvider>();
    final today = DateTime.now();
    final total = provider.habits.length;
    final completed = provider.habits
        .where((Habit habit) => habit.isCompletedOn(today))
        .length;
    final completion = total == 0 ? 0.0 : completed / total;
    final visibleHabits = _filteredHabits(provider.habits, today);
    final isSearchingOrFiltering = _hasActiveConditions;

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
          : RefreshIndicator(
              onRefresh: provider.loadHabits,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
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
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    sliver: SliverToBoxAdapter(
                      child: _HomeControls(
                        controller: _searchController,
                        activeFilter: _activeFilter,
                        onSearchChanged: (String value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        onFilterChanged: (_HabitFilter filter) {
                          setState(() {
                            _activeFilter = filter;
                          });
                        },
                        onClear: isSearchingOrFiltering ? _clearConditions : null,
                        filterLabelBuilder: _filterLabel,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: <Widget>[
                          Text(
                            isSearchingOrFiltering
                                ? 'Showing ${visibleHabits.length} habits'
                                : 'Today\'s habits',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Text(
                            '$completed/$total done',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (provider.habits.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        title: 'No habits yet',
                        subtitle:
                            'Tap + to build your first routine and track your streak every day.',
                      ),
                    )
                  else if (visibleHabits.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        title: 'No matching habits',
                        subtitle:
                            'Try another keyword or clear filters to see more habits.',
                        actionLabel: 'Clear filters',
                        onActionTap: _clearConditions,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 2, 20, 120),
                      sliver: SliverList.builder(
                        itemCount: visibleHabits.length,
                        itemBuilder: (BuildContext context, int index) {
                          final habit = visibleHabits[index];
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

class _HomeControls extends StatelessWidget {
  const _HomeControls({
    required this.controller,
    required this.activeFilter,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onClear,
    required this.filterLabelBuilder,
  });

  final TextEditingController controller;
  final _HabitFilter activeFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_HabitFilter> onFilterChanged;
  final VoidCallback? onClear;
  final String Function(_HabitFilter filter) filterLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: controller,
          onChanged: onSearchChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search habits...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      controller.clear();
                      onSearchChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Clear search',
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _HabitFilter.values.map((filter) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filterLabelBuilder(filter)),
                  selected: activeFilter == filter,
                  onSelected: (_) => onFilterChanged(filter),
                ),
              );
            }).toList(growable: false),
          ),
        ),
        if (onClear != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset search & filter'),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE7EEE8),
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
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (actionLabel != null && onActionTap != null) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: onActionTap,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
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
