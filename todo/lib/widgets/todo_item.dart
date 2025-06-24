import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../widgets/voice_note_widget.dart';
import '../theme/app_theme.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TodoItem({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: AppTheme.primaryColor.withOpacity(0.1),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: todo.isCompleted
                ? LinearGradient(
                    colors: [Colors.grey[100]!, Colors.grey[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [Colors.white, AppTheme.lightPink.withOpacity(0.3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with checkbox, title, and priority
                Row(
                  children: [
                    _buildCheckbox(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        todo.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              decoration: todo.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: todo.isCompleted
                                  ? Colors.grey[600]
                                  : AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    _buildPriorityChip(),
                    _buildMenuButton(),
                  ],
                ),

                // Description
                if (todo.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    todo.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: todo.isCompleted
                          ? Colors.grey[500]
                          : Colors.grey[700],
                    ),
                  ),
                ],

                // Voice note section
                if (todo.hasVoiceNote) ...[
                  const SizedBox(height: 12),
                  VoiceNoteWidget(
                    voiceNotePath: todo.voiceNotePath,
                    voiceNoteDuration: todo.voiceNoteDuration,
                    isRecordingMode: false,
                  ),
                ],

                const SizedBox(height: 12),

                // Footer with due date and timestamps
                Row(
                  children: [
                    if (todo.dueDate != null) ...[
                      _buildDueDateChip(),
                      const Spacer(),
                    ] else
                      const Spacer(),
                    _buildTimestampInfo(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: todo.isCompleted ? AppTheme.successColor : Colors.transparent,
          border: Border.all(
            color: todo.isCompleted ? AppTheme.successColor : AppTheme.softPink,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: todo.isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : null,
      ),
    );
  }

  Widget _buildPriorityChip() {
    final color = AppTheme.getPriorityColor(todo.priority);
    IconData icon;

    switch (todo.priority) {
      case 'high':
        icon = Icons.priority_high;
        break;
      case 'medium':
        icon = Icons.remove;
        break;
      case 'low':
        icon = Icons.keyboard_arrow_down;
        break;
      default:
        icon = Icons.remove;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            todo.priority.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<String>(
      onSelected: _handleMenuAction,
      icon: Icon(Icons.more_vert, color: AppTheme.softPink, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              const Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy, color: AppTheme.primaryColor, size: 18),
              const SizedBox(width: 8),
              const Text('Duplicate'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: AppTheme.errorColor, size: 18),
              const SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDueDateChip() {
    final now = DateTime.now();
    final dueDate = todo.dueDate!;
    final isOverdue = dueDate.isBefore(now) && !todo.isCompleted;
    final isDueToday = _isSameDay(dueDate, now);
    final isDueTomorrow = _isSameDay(dueDate, now.add(const Duration(days: 1)));

    Color color;
    IconData icon;
    String text;

    if (isOverdue) {
      color = AppTheme.errorColor;
      icon = Icons.warning;
      final daysPast = now.difference(dueDate).inDays;
      text = daysPast == 0 ? 'Overdue' : '${daysPast}d overdue';
    } else if (isDueToday) {
      color = AppTheme.warningColor;
      icon = Icons.today;
      text = 'Due today';
    } else if (isDueTomorrow) {
      color = AppTheme.primaryColor;
      icon = Icons.event;
      text = 'Due tomorrow';
    } else {
      color = AppTheme.softPink;
      icon = Icons.schedule;
      final daysLeft = dueDate.difference(now).inDays;
      text = daysLeft < 7 ? '${daysLeft}d left' : _formatDate(dueDate);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_circle_outline, size: 10, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              _formatTimestamp(todo.createdAt),
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          ],
        ),
        if (todo.updatedAt != null) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit, size: 10, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                _formatTimestamp(todo.updatedAt!),
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
            ],
          ),
        ],
      ],
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        onEdit();
        break;
      case 'duplicate':
        // Handle duplication - you can implement this in the parent widget
        break;
      case 'delete':
        onDelete();
        break;
    }
  }
}
