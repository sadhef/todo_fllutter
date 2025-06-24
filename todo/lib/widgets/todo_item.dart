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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
            gradient: _getCardGradient(isDarkMode),
            border: todo.isCompleted
                ? null
                : Border.all(
                    color: AppTheme.getPriorityColor(
                      todo.priority,
                    ).withOpacity(0.3),
                    width: 1.5,
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
                    _buildCheckbox(context),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(todo.title, style: _getTitleStyle(context)),
                    ),
                    _buildPriorityChip(context),
                    const SizedBox(width: 8),
                    _buildMenuButton(context),
                  ],
                ),

                // Description
                if (todo.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    todo.description,
                    style: _getDescriptionStyle(context),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Due date and voice note info
                if (todo.dueDate != null || todo.voiceNotePath != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Due date
                      if (todo.dueDate != null) ...[
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: _getDueDateColor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDueDate(todo.dueDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getDueDateColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],

                      // Spacer
                      if (todo.dueDate != null && todo.voiceNotePath != null)
                        const SizedBox(width: 16),

                      // Voice note indicator
                      if (todo.voiceNotePath != null) ...[
                        Icon(Icons.mic, size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(todo.voiceNoteDuration),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Creation date
                      Text(
                        _formatCreationDate(todo.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: todo.isCompleted ? AppTheme.successColor : Colors.transparent,
          border: Border.all(
            color: todo.isCompleted
                ? AppTheme.successColor
                : AppTheme.getPriorityColor(todo.priority),
            width: 2,
          ),
        ),
        child: todo.isCompleted
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _buildPriorityChip(BuildContext context) {
    final priorityColor = AppTheme.getPriorityColor(todo.priority);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priorityColor.withOpacity(isDarkMode ? 0.3 : 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: priorityColor.withOpacity(0.5), width: 1),
      ),
      child: Text(
        todo.priority.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? priorityColor.withOpacity(0.9) : priorityColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
        size: 20,
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 18),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'toggle',
          child: Row(
            children: [
              Icon(
                todo.isCompleted ? Icons.undo : Icons.check_circle,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(todo.isCompleted ? 'Mark Pending' : 'Mark Complete'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
            break;
          case 'toggle':
            onToggle();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
    );
  }

  Gradient _getCardGradient(bool isDarkMode) {
    if (todo.isCompleted) {
      return LinearGradient(
        colors: isDarkMode
            ? [const Color(0xFF2A2A2A), const Color(0xFF1E1E1E)]
            : [Colors.grey[100]!, Colors.grey[50]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return LinearGradient(
        colors: isDarkMode
            ? [const Color(0xFF2A2A2A), const Color(0xFF1E1E1E)]
            : [Colors.white, AppTheme.lightPink.withOpacity(0.3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  TextStyle _getTitleStyle(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextStyle(
      decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
      color: todo.isCompleted
          ? (isDarkMode ? Colors.grey[500] : Colors.grey[600])
          : (isDarkMode ? const Color(0xFFE1E1E1) : AppTheme.darkText),
      fontWeight: FontWeight.w600,
      fontSize: 16,
    );
  }

  TextStyle _getDescriptionStyle(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return TextStyle(
      color: todo.isCompleted
          ? (isDarkMode ? Colors.grey[600] : Colors.grey[500])
          : (isDarkMode ? const Color(0xFFB0B0B0) : AppTheme.mediumText),
      fontSize: 14,
      height: 1.3,
    );
  }

  Color _getDueDateColor(BuildContext context) {
    if (todo.dueDate == null)
      return Theme.of(context).textTheme.bodySmall!.color!;

    final now = DateTime.now();
    final dueDate = todo.dueDate!;
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return AppTheme.errorColor; // Overdue
    } else if (difference <= 1) {
      return AppTheme.warningColor; // Due soon
    } else {
      return AppTheme.successColor; // Normal
    }
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return 'Overdue';
    } else if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else if (difference <= 7) {
      return 'Due in $difference days';
    } else {
      return '${dueDate.day}/${dueDate.month}/${dueDate.year}';
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';

    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatCreationDate(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference <= 7) {
      return '$difference days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }
}
