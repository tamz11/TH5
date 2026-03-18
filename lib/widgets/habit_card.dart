import 'package:flutter/material.dart';

import '../models/habit.dart';

class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.isCompletedToday,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final Habit habit;
  final bool isCompletedToday;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isCompletedToday
        ? (isDark ? const Color(0xFF1E2A24) : const Color(0xFFF4F8F5))
        : theme.colorScheme.surface;
    final titleColor = isCompletedToday
        ? (isDark ? const Color(0xFFAABAB2) : const Color(0xFF73827D))
        : theme.textTheme.titleMedium?.color;

    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          decoration: isCompletedToday ? TextDecoration.lineThrough : null,
          color: titleColor,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: isDark
                ? const Color(0x33000000)
                : const Color(0x120A2019),
            blurRadius: isDark ? 10 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _HabitToggle(
              isDone: isCompletedToday,
              onTap: () => onChanged(!isCompletedToday),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(habit.name, style: titleStyle),
                  if (habit.description.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      habit.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: <Widget>[
                      _MetaPill(
                        icon: Icons.repeat_rounded,
                        label: habit.frequency.label,
                      ),
                      _MetaPill(
                        icon: Icons.local_fire_department_rounded,
                        label: '${habit.currentStreak} day streak',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (String action) {
                if (action == 'edit') {
                  onEdit();
                } else if (action == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitToggle extends StatelessWidget {
  const _HabitToggle({required this.isDone, required this.onTap});

  final bool isDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDone
                ? const Color(0xFF1E5B4F)
                : (isDark
                    ? const Color(0xFF6C8178)
                    : const Color(0xFFB5C4BC)),
            width: 1.6,
          ),
          color: isDone ? const Color(0xFF1E5B4F) : Colors.transparent,
        ),
        child: isDone
            ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
            : null,
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foregroundColor = isDark
        ? const Color(0xFFD5E3DB)
        : const Color(0xFF36524A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF223029) : const Color(0xFFE9F0EB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
