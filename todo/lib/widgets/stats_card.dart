import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        final stats = todoProvider.stats;

        if (stats.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Statistics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Overall stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Total',
                        stats['total']?.toString() ?? '0',
                        Icons.list,
                        AppTheme.primaryColor,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Completed',
                        stats['completed']?.toString() ?? '0',
                        Icons.check_circle,
                        AppTheme.successColor,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Pending',
                        stats['pending']?.toString() ?? '0',
                        Icons.radio_button_unchecked,
                        AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Completion rate
                _buildProgressBar(
                  context,
                  'Completion Rate',
                  stats['completionRate']?.toDouble() ?? 0.0,
                ),

                const SizedBox(height: 16),

                // Priority breakdown
                if (stats['byPriority'] != null) ...[
                  Text(
                    'By Priority',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPriorityItem(
                          context,
                          'High',
                          stats['byPriority']['high']?.toString() ?? '0',
                          AppTheme.highPriority,
                        ),
                      ),
                      Expanded(
                        child: _buildPriorityItem(
                          context,
                          'Medium',
                          stats['byPriority']['medium']?.toString() ?? '0',
                          AppTheme.mediumPriority,
                        ),
                      ),
                      Expanded(
                        child: _buildPriorityItem(
                          context,
                          'Low',
                          stats['byPriority']['low']?.toString() ?? '0',
                          AppTheme.lowPriority,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Additional stats
                if (stats['todosWithVoiceNotes'] != null) ...[
                  Text(
                    'Additional Stats',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          context,
                          'Voice Notes',
                          stats['todosWithVoiceNotes']?.toString() ?? '0',
                          Icons.mic,
                          AppTheme.accentColor,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          context,
                          'Overdue',
                          stats['overdueTodos']?.toString() ?? '0',
                          Icons.warning,
                          AppTheme.errorColor,
                        ),
                      ),
                      const Expanded(
                        child: SizedBox(),
                      ), // Empty space for alignment
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    BuildContext context,
    String label,
    double progress,
  ) {
    final percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '$percentage%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            progress >= 0.8
                ? AppTheme.successColor
                : progress >= 0.5
                ? AppTheme.warningColor
                : AppTheme.errorColor,
          ),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildPriorityItem(
    BuildContext context,
    String priority,
    String count,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            priority,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
