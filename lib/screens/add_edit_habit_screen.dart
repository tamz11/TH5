import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../services/habit_provider.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const int _kNameMaxLength = 50;
const int _kNameMinLength = 2;
const int _kDescMaxLength = 200;

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
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
  bool _isSaving = false;

  bool get _isEditMode => widget.habit != null;

  // Track whether the user has made any changes (for navigation guard)
  bool get _isDirty {
    final nameChanged =
        _nameController.text.trim() != (widget.habit?.name ?? '').trim();
    final descChanged = _descriptionController.text.trim() !=
        (widget.habit?.description ?? '').trim();
    final freqChanged =
        _frequency != (widget.habit?.frequency ?? HabitFrequency.daily);
    final reminderChanged =
        _reminderEnabled != (widget.habit?.reminderEnabled ?? false);
    final timeChanged = _reminderTime != widget.habit?.reminderTimeOfDay;
    return nameChanged || descChanged || freqChanged || reminderChanged || timeChanged;
  }

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

  // ---------------------------------------------------------------------------
  // Navigation guard – warn when leaving with unsaved changes
  // ---------------------------------------------------------------------------
  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text(
            'You have unsaved changes. Are you sure you want to leave?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
    return shouldLeave ?? false;
  }

  // ---------------------------------------------------------------------------
  // Save logic
  // ---------------------------------------------------------------------------
  Future<void> _saveHabit() async {
    FocusScope.of(context).unfocus();

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    // Extra guard: reminder is on but no time chosen
    if (_reminderEnabled && _reminderTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a reminder time.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final provider = context.read<HabitProvider>();
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();

      final reminderTimeString = _reminderTime != null
          ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:'
              '${_reminderTime!.minute.toString().padLeft(2, '0')}'
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

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Habit updated successfully'
                : 'Habit created successfully',
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Reminder time picker
  // ---------------------------------------------------------------------------
  Future<void> _pickReminderTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 20, minute: 0),
      helpText: 'Choose reminder time',
    );
    if (selected != null && mounted) {
      setState(() => _reminderTime = selected);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, _) async {
        if (didPop) return;
        final canLeave = await _onWillPop();
        if (canLeave && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? 'Edit Habit' : 'Create Habit'),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Close',
            onPressed: () async {
              final canLeave = await _onWillPop();
              if (canLeave && mounted) Navigator.of(context).pop();
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Header
                Text(
                  _isEditMode ? 'Tune your habit' : 'Build a new routine',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Keep it specific and measurable to stay consistent.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),

                // Form card
                _FormCard(
                  children: <Widget>[
                    // ── Name ─────────────────────────────────────────────
                    _SectionLabel('Habit name'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      maxLength: _kNameMaxLength,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Read 20 pages',
                        counterText: '', // hide default counter
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (String? value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'Habit name is required.';
                        }
                        if (trimmed.length < _kNameMinLength) {
                          return 'Name must be at least $_kNameMinLength characters.';
                        }
                        return null;
                      },
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${_nameController.text.length}/$_kNameMaxLength',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                _nameController.text.length >= _kNameMaxLength
                                    ? Colors.red
                                    : null,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Description ──────────────────────────────────────
                    _SectionLabel('Description (optional)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      maxLength: _kDescMaxLength,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        hintText: 'Optional note for this routine',
                        counterText: '',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${_descriptionController.text.length}/$_kDescMaxLength',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _descriptionController.text.length >=
                                    _kDescMaxLength
                                ? Colors.red
                                : null,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Frequency ─────────────────────────────────────────
                    _SectionLabel('Frequency'),
                    const SizedBox(height: 10),
                    _FrequencySelector(
                      selected: _frequency,
                      onChanged: (HabitFrequency value) =>
                          setState(() => _frequency = value),
                    ),

                    const SizedBox(height: 20),

                    // ── Reminder ──────────────────────────────────────────
                    _ReminderSection(
                      enabled: _reminderEnabled,
                      time: _reminderTime,
                      onToggle: (bool value) {
                        setState(() {
                          _reminderEnabled = value;
                          if (!value) _reminderTime = null;
                        });
                      },
                      onPickTime: _pickReminderTime,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Save button
                _SaveButton(
                  isEditMode: _isEditMode,
                  isSaving: _isSaving,
                  onPressed: _isSaving ? null : _saveHabit,
                ),

                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            final canLeave = await _onWillPop();
                            if (canLeave && mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleMedium);
}

// ---------------------------------------------------------------------------
// Frequency selector – SegmentedButton (Material 3)
// ---------------------------------------------------------------------------
class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector({required this.selected, required this.onChanged});

  final HabitFrequency selected;
  final ValueChanged<HabitFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<HabitFrequency>(
      segments: const <ButtonSegment<HabitFrequency>>[
        ButtonSegment<HabitFrequency>(
          value: HabitFrequency.daily,
          label: Text('Daily'),
          icon: Icon(Icons.today_rounded),
        ),
        ButtonSegment<HabitFrequency>(
          value: HabitFrequency.weekly,
          label: Text('Weekly'),
          icon: Icon(Icons.date_range_rounded),
        ),
      ],
      selected: <HabitFrequency>{selected},
      onSelectionChanged: (Set<HabitFrequency> newSelection) {
        if (newSelection.isNotEmpty) onChanged(newSelection.first);
      },
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: const Color(0xFF1E5B4F),
        selectedForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reminder section with animated reveal
// ---------------------------------------------------------------------------
class _ReminderSection extends StatelessWidget {
  const _ReminderSection({
    required this.enabled,
    required this.time,
    required this.onToggle,
    required this.onPickTime,
  });

  final bool enabled;
  final TimeOfDay? time;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.notifications_active_rounded),
          title: const Text('Reminder'),
          subtitle: const Text('Receive daily/weekly reminders'),
          value: enabled,
          onChanged: onToggle,
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState:
              enabled ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: InkWell(
              onTap: onPickTime,
              borderRadius: BorderRadius.circular(16),
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
                      time != null
                          ? 'Reminder at ${time!.format(context)}'
                          : 'Tap to choose reminder time',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: time == null ? theme.hintColor : null,
                      ),
                    ),
                    Icon(Icons.access_time_rounded,
                        color: theme.iconTheme.color),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Save button with loading spinner
// ---------------------------------------------------------------------------
class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isEditMode,
    required this.isSaving,
    required this.onPressed,
  });

  final bool isEditMode;
  final bool isSaving;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_rounded),
        label: Text(
          isSaving
              ? 'Saving...'
              : isEditMode
                  ? 'Save Changes'
                  : 'Create Habit',
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
