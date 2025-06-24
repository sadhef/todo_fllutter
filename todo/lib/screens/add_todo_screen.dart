import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../widgets/voice_note_widget.dart';
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
        title: Text(widget.todoToEdit != null ? 'Edit Todo' : 'Add Todo'),
        actions: [
          if (widget.todoToEdit != null)
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteTodo),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.lightPink, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title field
                _buildTextField(
                  controller: _titleController,
                  label: 'Title *',
                  hint: 'Enter todo title',
                  icon: Icons.title,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    if (value.trim().length < 3) {
                      return 'Title must be at least 3 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Description field
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Enter todo description (optional)',
                  icon: Icons.description,
                  maxLines: 3,
                  isRequired: false,
                ),

                const SizedBox(height: 24),

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

                const SizedBox(height: 24),

                // Priority selection
                _buildSectionCard(
                  title: 'Priority',
                  icon: Icons.flag,
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

                const SizedBox(height: 24),

                // Due date selection
                _buildSectionCard(
                  title: 'Due Date',
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
                                  : 'Set due date (optional)',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_selectedDueDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              color: AppTheme.primaryColor,
                              onPressed: () {
                                setState(() {
                                  _selectedDueDate = null;
                                });
                              },
                            )
                          else
                            Icon(
                              Icons.chevron_right,
                              color: AppTheme.primaryColor,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveTodo,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                widget.todoToEdit != null
                                    ? 'Update Todo'
                                    : 'Add Todo',
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool isRequired = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: AppTheme.softPink),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
      maxLines: maxLines,
      textInputAction: maxLines > 1
          ? TextInputAction.newline
          : TextInputAction.next,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.lightPink,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(
    String priority,
    String label,
    Color color,
    IconData icon,
  ) {
    final isSelected = _selectedPriority == priority;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPriority = priority;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
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
        initialTime: TimeOfDay.now(),
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

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            const Text('Delete Todo'),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this todo? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage([String? message]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ??
              (widget.todoToEdit != null
                  ? 'Todo updated successfully!'
                  : 'Todo added successfully!'),
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
