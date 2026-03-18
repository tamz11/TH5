import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_provider.dart';

class AddEditHabitScreen extends StatefulWidget {
  const AddEditHabitScreen({super.key, this.habit});

  final Habit? habit;

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late HabitFrequency _frequency;
  bool _reminderEnabled = false;
  TimeOfDay? _reminderTime;

  bool get _isEditMode => widget.habit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.habit?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.habit?.description ?? '',
    );
    _frequency = widget.habit?.frequency ?? HabitFrequency.daily;
    _reminderEnabled = widget.habit?.reminderEnabled ?? false;
    _reminderTime = widget.habit?.reminderTimeOfDay;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final provider = context.read<HabitProvider>();
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    final reminderTimeString = _reminderTime != null
        ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
        : null;

    if (_isEditMode) {
      final updated = widget.habit!.copyWith(
        name: name,
        description: description,
        frequency: _frequency,
        reminderEnabled: _reminderEnabled,
        reminderTime: reminderTimeString,
      );
      await provider.updateHabit(updated);
    } else {
      await provider.addHabit(
        name: name,
        description: description,
        frequency: _frequency,
        reminderEnabled: _reminderEnabled,
        reminderTime: reminderTimeString,
      );
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Habit' : 'Create Habit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _isEditMode ? 'Tune your habit' : 'Build a new routine',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Keep it specific and measurable to stay consistent.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Habit name',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Read 20 pages',
                      ),
                      validator: (String? value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter habit name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Optional note for this routine',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Frequency',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: HabitFrequency.values.map((
                        HabitFrequency value,
                      ) {
                        final isSelected = _frequency == value;
                        return ChoiceChip(
                          label: Text(value.label),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _frequency = value;
                            });
                          },
                          selectedColor: const Color(0xFF1E5B4F),
                          labelStyle: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? const Color(0xFFD5E3DB)
                                        : const Color(0xFF2B3C36)),
                                fontWeight: FontWeight.w700,
                              ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reminder'),
                      subtitle: const Text('Receive daily/weekly reminders'),
                      value: _reminderEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _reminderEnabled = value;
                        });
                      },
                      secondary: const Icon(Icons.notifications_active_rounded),
                    ),
                    if (_reminderEnabled) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final selected = await showTimePicker(
                            context: context,
                            initialTime:
                                _reminderTime ??
                                const TimeOfDay(hour: 20, minute: 0),
                          );
                          if (selected != null) {
                            setState(() {
                              _reminderTime = selected;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                _reminderTime != null
                                    ? 'Reminder time: ${_reminderTime!.format(context)}'
                                    : 'Choose reminder time',
                                style: theme.textTheme.bodyLarge,
                              ),
                              const Icon(Icons.access_time),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saveHabit,
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        _isEditMode ? 'Save Changes' : 'Create Habit',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
