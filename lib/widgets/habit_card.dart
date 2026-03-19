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
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          decoration: isCompletedToday ? TextDecoration.lineThrough : null,
          color: isCompletedToday
              ? const Color(0xFF73827D)
              : const Color(0xFF1E2925),
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isCompletedToday ? const Color(0xFFF4F8F5) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCE5DF)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120A2019),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _HabitCheckIn(
              isDone: isCompletedToday,
              onChanged: onChanged,
            ),
            const SizedBox(width: 8),
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
                        icon: isCompletedToday
                            ? Icons.task_alt_rounded
                            : Icons.pending_actions_rounded,
                        label: isCompletedToday ? 'Checked in' : 'Not checked in',
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

class _HabitCheckIn extends StatelessWidget {
  const _HabitCheckIn({required this.isDone, required this.onChanged});

  final bool isDone;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isDone ? 'Mark as not done' : 'Check in today',
      child: Transform.translate(
        offset: const Offset(0, -2),
        child: Checkbox(
          value: isDone,
          onChanged: (bool? value) {
            onChanged(value ?? false);
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F0EB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: const Color(0xFF36524A)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF36524A),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
