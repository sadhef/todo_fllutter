import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  String _selectedPeriod = 'week'; // 'week', 'month', 'year'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productivity Timeline'),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
              const PopupMenuItem(value: 'year', child: Text('This Year')),
            ],
          ),
        ],
      ),
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          final timelineData = _getTimelineData(todoProvider.allTodos);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.lightPink, Colors.white],
              ),
            ),
            child: Column(
              children: [
                _buildStatsHeader(timelineData),
                _buildPeriodSelector(),
                Expanded(child: _buildTimeline(timelineData)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(Map<String, dynamic> data) {
    final completedToday = data['completedToday'] ?? 0;
    final totalToday = data['totalToday'] ?? 0;
    final streak = data['streak'] ?? 0;
    final weeklyAverage = data['weeklyAverage'] ?? 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.pinkGradientDecoration,
      child: Column(
        children: [
          Text(
            'Productivity Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Today',
                  '$completedToday/$totalToday',
                  Icons.today,
                  Colors.white,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Streak',
                  '$streak days',
                  Icons.local_fire_department,
                  Colors.white,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Weekly Avg',
                  '${weeklyAverage.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.9), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildPeriodChip('week', 'Week'),
          const SizedBox(width: 8),
          _buildPeriodChip('month', 'Month'),
          const SizedBox(width: 8),
          _buildPeriodChip('year', 'Year'),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _selectedPeriod == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPeriod = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: AppTheme.primaryColor, width: 1),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline(Map<String, dynamic> data) {
    final timelineItems = data['timelineItems'] as List<TimelineItem>? ?? [];

    if (timelineItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: AppTheme.softPink),
            const SizedBox(height: 16),
            Text(
              'No activity found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete some todos to see your timeline!',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.softPink),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: timelineItems.length,
      itemBuilder: (context, index) {
        final item = timelineItems[index];
        final isLast = index == timelineItems.length - 1;

        return _buildTimelineItem(item, isLast);
      },
    );
  }

  Widget _buildTimelineItem(TimelineItem item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getTimelineColor(item.type),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppTheme.softPink.withOpacity(0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Timeline content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getTimelineIcon(item.type),
                        color: _getTimelineColor(item.type),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                        ),
                      ),
                      Text(
                        _formatTimelineDate(item.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.softPink,
                        ),
                      ),
                    ],
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item.description,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                  if (item.metadata.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: item.metadata.entries.map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightPink,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${entry.key}: ${entry.value}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTimelineColor(TimelineItemType type) {
    switch (type) {
      case TimelineItemType.completed:
        return AppTheme.successColor;
      case TimelineItemType.created:
        return AppTheme.primaryColor;
      case TimelineItemType.milestone:
        return AppTheme.warningColor;
      case TimelineItemType.achievement:
        return AppTheme.accentColor;
    }
  }

  IconData _getTimelineIcon(TimelineItemType type) {
    switch (type) {
      case TimelineItemType.completed:
        return Icons.check_circle;
      case TimelineItemType.created:
        return Icons.add_circle;
      case TimelineItemType.milestone:
        return Icons.flag;
      case TimelineItemType.achievement:
        return Icons.emoji_events;
    }
  }

  String _formatTimelineDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Map<String, dynamic> _getTimelineData(List<Todo> todos) {
    final now = DateTime.now();
    final timelineItems = <TimelineItem>[];

    // Get date range based on selected period
    DateTime startDate;
    switch (_selectedPeriod) {
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    // Filter todos by date range
    final filteredTodos = todos
        .where(
          (todo) =>
              todo.createdAt.isAfter(startDate) ||
              (todo.updatedAt != null && todo.updatedAt!.isAfter(startDate)),
        )
        .toList();

    // Create timeline items
    for (final todo in filteredTodos) {
      // Add creation event
      timelineItems.add(
        TimelineItem(
          type: TimelineItemType.created,
          title: 'Created: ${todo.title}',
          description: todo.description,
          timestamp: todo.createdAt,
          metadata: {
            'Priority': todo.priority,
            if (todo.dueDate != null) 'Due': _formatDate(todo.dueDate!),
          },
        ),
      );

      // Add completion event if completed
      if (todo.isCompleted &&
          todo.updatedAt != null &&
          todo.updatedAt!.isAfter(startDate)) {
        timelineItems.add(
          TimelineItem(
            type: TimelineItemType.completed,
            title: 'Completed: ${todo.title}',
            description: 'Task completed successfully!',
            timestamp: todo.updatedAt!,
            metadata: {
              'Priority': todo.priority,
              'Duration': _calculateDuration(todo.createdAt, todo.updatedAt!),
            },
          ),
        );
      }
    }

    // Add milestones and achievements
    _addMilestones(timelineItems, filteredTodos, startDate);

    // Sort by timestamp (newest first)
    timelineItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Calculate stats
    final completedToday = todos
        .where(
          (todo) =>
              todo.isCompleted &&
              todo.updatedAt != null &&
              _isSameDay(todo.updatedAt!, now),
        )
        .length;

    final totalToday = todos
        .where((todo) => _isSameDay(todo.createdAt, now))
        .length;

    final streak = _calculateStreak(todos);
    final weeklyAverage = _calculateWeeklyAverage(todos);

    return {
      'timelineItems': timelineItems,
      'completedToday': completedToday,
      'totalToday': totalToday,
      'streak': streak,
      'weeklyAverage': weeklyAverage,
    };
  }

  void _addMilestones(
    List<TimelineItem> items,
    List<Todo> todos,
    DateTime startDate,
  ) {
    final completedTodos = todos.where((todo) => todo.isCompleted).length;

    // Check for completion milestones
    if (completedTodos >= 10 && completedTodos % 10 == 0) {
      items.add(
        TimelineItem(
          type: TimelineItemType.milestone,
          title: '🎉 ${completedTodos} Todos Completed!',
          description:
              'You\'ve reached a major milestone! Keep up the great work!',
          timestamp: DateTime.now(),
          metadata: {'Achievement': 'Milestone'},
        ),
      );
    }

    // Check for streak achievements
    final streak = _calculateStreak(todos);
    if (streak >= 7 && streak % 7 == 0) {
      items.add(
        TimelineItem(
          type: TimelineItemType.achievement,
          title: '🔥 ${streak} Day Streak!',
          description: 'Amazing consistency! You\'re on fire!',
          timestamp: DateTime.now(),
          metadata: {'Type': 'Streak Achievement'},
        ),
      );
    }
  }

  int _calculateStreak(List<Todo> todos) {
    final now = DateTime.now();
    int streak = 0;

    for (int i = 0; i < 30; i++) {
      final checkDate = now.subtract(Duration(days: i));
      final hasCompletedTodo = todos.any(
        (todo) =>
            todo.isCompleted &&
            todo.updatedAt != null &&
            _isSameDay(todo.updatedAt!, checkDate),
      );

      if (hasCompletedTodo) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }

    return streak;
  }

  double _calculateWeeklyAverage(List<Todo> todos) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final weekTodos = todos
        .where((todo) => todo.createdAt.isAfter(startOfWeek))
        .toList();

    if (weekTodos.isEmpty) return 0.0;

    final completed = weekTodos.where((todo) => todo.isCompleted).length;
    return (completed / weekTodos.length) * 100;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _calculateDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    if (duration.inDays > 0) {
      return '${duration.inDays}d';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

// Timeline item model
class TimelineItem {
  final TimelineItemType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, String> metadata;

  TimelineItem({
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.metadata = const {},
  });
}

enum TimelineItemType { created, completed, milestone, achievement }
