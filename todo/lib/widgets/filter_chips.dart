import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/todo_provider.dart';
import '../theme/app_theme.dart';

class FilterChips extends StatelessWidget {
  const FilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TodoProvider>(
      builder: (context, todoProvider, child) {
        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Status filters
                _buildFilterChip(
                  context,
                  label: 'All',
                  isSelected: todoProvider.filterStatus == 'all',
                  onSelected: () => todoProvider.setStatusFilter('all'),
                  icon: Icons.list_alt,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Pending',
                  isSelected: todoProvider.filterStatus == 'pending',
                  onSelected: () => todoProvider.setStatusFilter('pending'),
                  icon: Icons.radio_button_unchecked,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Completed',
                  isSelected: todoProvider.filterStatus == 'completed',
                  onSelected: () => todoProvider.setStatusFilter('completed'),
                  icon: Icons.check_circle,
                  color: AppTheme.successColor,
                ),

                const SizedBox(width: 16),
                Container(
                  width: 1,
                  height: 30,
                  color: AppTheme.softPink.withOpacity(0.5),
                ),
                const SizedBox(width: 16),

                // Priority filters
                _buildFilterChip(
                  context,
                  label: 'High Priority',
                  isSelected: todoProvider.filterPriority == 'high',
                  onSelected: () => todoProvider.setPriorityFilter('high'),
                  color: AppTheme.highPriority,
                  icon: Icons.priority_high,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Medium Priority',
                  isSelected: todoProvider.filterPriority == 'medium',
                  onSelected: () => todoProvider.setPriorityFilter('medium'),
                  color: AppTheme.mediumPriority,
                  icon: Icons.remove,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Low Priority',
                  isSelected: todoProvider.filterPriority == 'low',
                  onSelected: () => todoProvider.setPriorityFilter('low'),
                  color: AppTheme.lowPriority,
                  icon: Icons.keyboard_arrow_down,
                ),

                const SizedBox(width: 16),
                Container(
                  width: 1,
                  height: 30,
                  color: AppTheme.softPink.withOpacity(0.5),
                ),
                const SizedBox(width: 16),

                // Special filters
                _buildFilterChip(
                  context,
                  label: 'With Voice Notes',
                  isSelected: false, // You can add this filter to the provider
                  onSelected: () {
                    // Filter todos with voice notes
                    // This would require adding this filter to TodoProvider
                  },
                  icon: Icons.mic,
                  color: AppTheme.accentColor,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Overdue',
                  isSelected: false,
                  onSelected: () {
                    // Filter overdue todos
                    // This would require adding this filter to TodoProvider
                  },
                  icon: Icons.warning,
                  color: AppTheme.errorColor,
                ),

                const SizedBox(width: 16),

                // Clear filters button
                if (todoProvider.filterStatus != 'all' ||
                    todoProvider.filterPriority != 'all' ||
                    todoProvider.searchQuery.isNotEmpty)
                  _buildClearFiltersButton(context, todoProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    IconData? icon,
    Color? color,
  }) {
    final chipColor = color ?? AppTheme.primaryColor;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : chipColor,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : chipColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        backgroundColor: chipColor.withOpacity(0.1),
        selectedColor: chipColor,
        checkmarkColor: Colors.white,
        side: BorderSide(color: chipColor, width: isSelected ? 2 : 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: isSelected ? 3 : 1,
        shadowColor: chipColor.withOpacity(0.3),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildClearFiltersButton(
    BuildContext context,
    TodoProvider todoProvider,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ActionChip(
        avatar: const Icon(Icons.clear_all, size: 14),
        label: const Text(
          'Clear All',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        onPressed: () {
          todoProvider.clearFilters();

          // Show feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text('Filters cleared'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        backgroundColor: AppTheme.lightPink,
        side: BorderSide(color: AppTheme.softPink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
        shadowColor: AppTheme.primaryColor.withOpacity(0.2),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
