// lib/widgets/reminder_time_picker.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ReminderTimePicker extends StatefulWidget {
  final List<Duration>? initialReminderTimes;
  final bool enableDefaultReminders;
  final ValueChanged<List<Duration>?> onReminderTimesChanged;
  final ValueChanged<bool> onEnableDefaultRemindersChanged;

  const ReminderTimePicker({
    super.key,
    this.initialReminderTimes,
    this.enableDefaultReminders = true,
    required this.onReminderTimesChanged,
    required this.onEnableDefaultRemindersChanged,
  });

  @override
  State<ReminderTimePicker> createState() => _ReminderTimePickerState();
}

class _ReminderTimePickerState extends State<ReminderTimePicker> {
  List<Duration> _customReminderTimes = [];
  bool _useDefaultReminders = true;
  bool _useCustomReminders = false;

  // Predefined quick reminder options
  final List<Duration> _quickOptions = [
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
    Duration(hours: 6),
    Duration(hours: 12),
    Duration(hours: 24),
    Duration(days: 2),
    Duration(days: 7),
  ];

  @override
  void initState() {
    super.initState();
    _useDefaultReminders = widget.enableDefaultReminders;
    _customReminderTimes = widget.initialReminderTimes?.toList() ?? [];
    _useCustomReminders = _customReminderTimes.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Reminder Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Default reminders option
            _buildReminderOption(
              title: 'Use Default Reminders',
              subtitle: '1 day, 2 hours, 15 minutes before due date',
              value: _useDefaultReminders && !_useCustomReminders,
              onChanged: (value) {
                setState(() {
                  _useDefaultReminders = value ?? false;
                  if (value == true) {
                    _useCustomReminders = false;
                    _updateCallbacks();
                  }
                });
              },
            ),

            const SizedBox(height: 8),

            // Custom reminders option
            _buildReminderOption(
              title: 'Set Custom Reminders',
              subtitle: _useCustomReminders
                  ? _formatCustomReminders()
                  : 'Choose your own reminder times',
              value: _useCustomReminders,
              onChanged: (value) {
                setState(() {
                  _useCustomReminders = value ?? false;
                  if (value == true) {
                    _useDefaultReminders = false;
                    if (_customReminderTimes.isEmpty) {
                      _customReminderTimes.add(Duration(hours: 2));
                    }
                  } else {
                    _customReminderTimes.clear();
                  }
                  _updateCallbacks();
                });
              },
            ),

            // Custom reminder configuration
            if (_useCustomReminders) ...[
              const SizedBox(height: 16),
              _buildCustomReminderSection(),
            ],

            const SizedBox(height: 8),

            // No reminders option
            _buildReminderOption(
              title: 'No Reminders',
              subtitle: 'Don\'t send any reminder notifications',
              value: !_useDefaultReminders && !_useCustomReminders,
              onChanged: (value) {
                setState(() {
                  _useDefaultReminders = false;
                  _useCustomReminders = false;
                  _customReminderTimes.clear();
                  _updateCallbacks();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: value ? AppTheme.lightPink : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? AppTheme.primaryColor : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: RadioListTile<bool>(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: value ? AppTheme.primaryColor : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: value
                ? AppTheme.primaryColor.withOpacity(0.8)
                : Colors.grey[600],
          ),
        ),
        value: true,
        groupValue: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildCustomReminderSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightPink.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.softPink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Quick Options:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _showCustomTimeDialog,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Custom'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Quick option chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: _quickOptions.map((duration) {
              final isSelected = _customReminderTimes.contains(duration);
              return FilterChip(
                label: Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      if (!_customReminderTimes.contains(duration)) {
                        _customReminderTimes.add(duration);
                        _customReminderTimes.sort((a, b) => b.compareTo(a));
                      }
                    } else {
                      _customReminderTimes.remove(duration);
                    }
                    _updateCallbacks();
                  });
                },
                selectedColor: AppTheme.primaryColor,
                checkmarkColor: Colors.white,
                backgroundColor: AppTheme.lightPink,
                side: BorderSide(color: AppTheme.softPink),
              );
            }).toList(),
          ),

          // Selected reminders list
          if (_customReminderTimes.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Selected Reminders:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            ..._customReminderTimes.map((duration) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.alarm,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatDuration(duration)} before due date',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        setState(() {
                          _customReminderTimes.remove(duration);
                          _updateCallbacks();
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  void _showCustomTimeDialog() {
    int selectedDays = 0;
    int selectedHours = 0;
    int selectedMinutes = 30;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Custom Reminder Time'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Remind me before due date:'),
                  const SizedBox(height: 16),

                  // Days picker
                  Row(
                    children: [
                      const Expanded(child: Text('Days:')),
                      DropdownButton<int>(
                        value: selectedDays,
                        items: List.generate(30, (i) => i).map((days) {
                          return DropdownMenuItem(
                            value: days,
                            child: Text('$days'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedDays = value ?? 0;
                          });
                        },
                      ),
                    ],
                  ),

                  // Hours picker
                  Row(
                    children: [
                      const Expanded(child: Text('Hours:')),
                      DropdownButton<int>(
                        value: selectedHours,
                        items: List.generate(24, (i) => i).map((hours) {
                          return DropdownMenuItem(
                            value: hours,
                            child: Text('$hours'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedHours = value ?? 0;
                          });
                        },
                      ),
                    ],
                  ),

                  // Minutes picker
                  Row(
                    children: [
                      const Expanded(child: Text('Minutes:')),
                      DropdownButton<int>(
                        value: selectedMinutes,
                        items: [0, 5, 10, 15, 30, 45].map((minutes) {
                          return DropdownMenuItem(
                            value: minutes,
                            child: Text('$minutes'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedMinutes = value ?? 0;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final customDuration = Duration(
                      days: selectedDays,
                      hours: selectedHours,
                      minutes: selectedMinutes,
                    );

                    if (customDuration.inMinutes > 0) {
                      setState(() {
                        if (!_customReminderTimes.contains(customDuration)) {
                          _customReminderTimes.add(customDuration);
                          _customReminderTimes.sort((a, b) => b.compareTo(a));
                        }
                        _updateCallbacks();
                      });
                    }

                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      if (duration.inHours % 24 == 0) {
        return '${duration.inDays}d';
      } else {
        return '${duration.inDays}d ${duration.inHours % 24}h';
      }
    } else if (duration.inHours > 0) {
      if (duration.inMinutes % 60 == 0) {
        return '${duration.inHours}h';
      } else {
        return '${duration.inHours}h ${duration.inMinutes % 60}m';
      }
    } else {
      return '${duration.inMinutes}m';
    }
  }

  String _formatCustomReminders() {
    if (_customReminderTimes.isEmpty) return 'No custom reminders set';

    final sorted = List<Duration>.from(_customReminderTimes)
      ..sort((a, b) => b.compareTo(a));

    if (sorted.length == 1) {
      return _formatDuration(sorted.first);
    } else if (sorted.length <= 3) {
      return sorted.map(_formatDuration).join(', ');
    } else {
      return '${sorted.take(2).map(_formatDuration).join(', ')} +${sorted.length - 2} more';
    }
  }

  void _updateCallbacks() {
    if (_useCustomReminders && _customReminderTimes.isNotEmpty) {
      widget.onReminderTimesChanged(_customReminderTimes);
      widget.onEnableDefaultRemindersChanged(false);
    } else if (_useDefaultReminders) {
      widget.onReminderTimesChanged(null);
      widget.onEnableDefaultRemindersChanged(true);
    } else {
      widget.onReminderTimesChanged(null);
      widget.onEnableDefaultRemindersChanged(false);
    }
  }
}
