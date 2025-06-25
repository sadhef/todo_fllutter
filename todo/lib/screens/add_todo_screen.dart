// lib/screens/add_todo_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../widgets/voice_note_widget.dart';
import '../widgets/reminder_time_picker.dart';
import '../theme/app_theme.dart';

class AddTodoScreen extends StatefulWidget {
  final Todo? todoToEdit;

  const AddTodoScreen({super.key, this.todoToEdit});

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedPriority = 'medium';
  DateTime? _selectedDueDate;
  String? _voiceNotePath;
  Duration? _voiceNoteDuration;
  bool _isLoading = false;

  // NEW: Reminder settings
  List<Duration>? _customReminderTimes;
  bool _enableDefaultReminders = true;

  @override
  void initState() {
    super.initState();
    if (widget.todoToEdit != null) {
      _initializeWithExistingTodo();
    }
  }

  void _initializeWithExistingTodo() {
    final todo = widget.todoToEdit!;
    _titleController.text = todo.title;
    _descriptionController.text = todo.description;
    _selectedPriority = todo.priority;
    _selectedDueDate = todo.dueDate;
    _voiceNotePath = todo.voiceNotePath;
    _voiceNoteDuration = todo.voiceNoteDuration;
    _customReminderTimes = todo.customReminderTimes;
    _enableDefaultReminders = todo.enableDefaultReminders;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.todoToEdit != null ? 'Edit Todo' : 'Add New Todo',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.todoToEdit != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTodo,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.1),
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title input
              _buildSectionCard(
                title: 'Task Details',
                icon: Icons.task_alt,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Task Title',
                        hintText: 'What needs to be done?',
                        prefixIcon:
                            Icon(Icons.title, color: AppTheme.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AppTheme.primaryColor, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a task title';
                        }
                        return null;
                      },
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Add more details...',
                        prefixIcon: Icon(Icons.description,
                            color: AppTheme.primaryColor),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AppTheme.primaryColor, width: 2),
                        ),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Voice note section
              _buildSectionCard(
                title: 'Voice Note',
                icon: Icons.mic,
                child: VoiceNoteWidget(
                  voiceNotePath: _voiceNotePath,
                  voiceNoteDuration: _voiceNoteDuration,
                  isRecordingMode: true,
                  onVoiceNoteChanged: (path, duration) {
                    setState(() {
                      _voiceNotePath = path;
                      _voiceNoteDuration = duration;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Priority selection
              _buildSectionCard(
                title: 'Priority',
                icon: Icons.flag,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildPriorityChip(
                          'low',
                          'Low',
                          AppTheme.lowPriority,
                          Icons.flag_outlined,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPriorityChip(
                          'medium',
                          'Medium',
                          AppTheme.mediumPriority,
                          Icons.flag,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildPriorityChip(
                          'high',
                          'High',
                          AppTheme.highPriority,
                          Icons.outlined_flag,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Due date selection
              _buildSectionCard(
                title: 'Due Date & Time',
                icon: Icons.calendar_today,
                child: InkWell(
                  onTap: _selectDueDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightPink,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.softPink, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedDueDate != null
                                ? 'Due: ${_formatDateTime(_selectedDueDate!)}'
                                : 'Set due date and time',
                            style: TextStyle(
                              color: _selectedDueDate != null
                                  ? AppTheme.primaryColor
                                  : Colors.grey[600],
                              fontWeight: _selectedDueDate != null
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (_selectedDueDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedDueDate = null;
                                _customReminderTimes = null;
                                _enableDefaultReminders = true;
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
                  ),
                ),
              ),

              // Reminder settings (only show if due date is set)
              if (_selectedDueDate != null) ...[
                const SizedBox(height: 16),
                ReminderTimePicker(
                  initialReminderTimes: _customReminderTimes,
                  enableDefaultReminders: _enableDefaultReminders,
                  onReminderTimesChanged: (times) {
                    setState(() {
                      _customReminderTimes = times;
                    });
                  },
                  onEnableDefaultRemindersChanged: (enabled) {
                    setState(() {
                      _enableDefaultReminders = enabled;
                    });
                  },
                ),
              ],

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveTodo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.todoToEdit != null
                              ? 'Update Todo'
                              : 'Add Todo',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.primaryColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    final isSelected = _selectedPriority == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriority = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedDueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.primaryColor,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: AppTheme.primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedDueDate != null
            ? TimeOfDay.fromDateTime(_selectedDueDate!)
            : TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppTheme.primaryColor,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppTheme.primaryColor,
                  ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedDueDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      } else {
        setState(() {
          _selectedDueDate = date;
        });
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateOnly = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (dateOnly == today) {
      dateStr = 'Today';
    } else if (dateOnly == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final timeStr =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }

  Future<void> _saveTodo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final todoProvider = context.read<TodoProvider>();

      if (widget.todoToEdit != null) {
        // Update existing todo
        final updatedTodo = widget.todoToEdit!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _selectedPriority,
          dueDate: _selectedDueDate,
          voiceNotePath: _voiceNotePath,
          voiceNoteDuration: _voiceNoteDuration,
          customReminderTimes: _customReminderTimes,
          enableDefaultReminders: _enableDefaultReminders,
          updatedAt: DateTime.now(),
        );

        await todoProvider.updateTodo(widget.todoToEdit!.id, updatedTodo);
      } else {
        // Create new todo
        final newTodo = Todo(
          id: '', // Will be generated by service
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          priority: _selectedPriority,
          dueDate: _selectedDueDate,
          voiceNotePath: _voiceNotePath,
          voiceNoteDuration: _voiceNoteDuration,
          customReminderTimes: _customReminderTimes,
          enableDefaultReminders: _enableDefaultReminders,
          createdAt: DateTime.now(),
        );

        await todoProvider.addTodo(newTodo);
      }

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessMessage();
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteTodo() async {
    if (widget.todoToEdit == null) return;

    final confirmed = await _showDeleteConfirmation();
    if (confirmed != true) return;

    try {
      await context.read<TodoProvider>().deleteTodo(widget.todoToEdit!.id);
      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessMessage('Todo deleted successfully!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Error deleting todo: $e');
      }
    }
  }

  Future<bool?> _showDeleteConfirmation() async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Todo'),
          content: const Text(
              'Are you sure you want to delete this todo? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessMessage([String? message]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Todo saved successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
