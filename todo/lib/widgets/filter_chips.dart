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
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Pending',
                  isSelected: todoProvider.filterStatus == 'pending',
                  onSelected: () => todoProvider.setStatusFilter('pending'),
                  icon: Icons.radio_button_unchecked,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Completed',
                  isSelected: todoProvider.filterStatus == 'completed',
                  onSelected: () => todoProvider.setStatusFilter('completed'),
                  icon: Icons.check_circle,
                ),

                const SizedBox(width: 16),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                const SizedBox(width: 16),

                // Priority filters
                _buildFilterChip(
                  context,
                  label: 'High Priority',
                  isSelected: todoProvider.filterPriority == 'high',
                  onSelected: () => todoProvider.setPriorityFilter('high'),
                  color: AppTheme.highPriority,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Medium Priority',
                  isSelected: todoProvider.filterPriority == 'medium',
                  onSelected: () => todoProvider.setPriorityFilter('medium'),
                  color: AppTheme.mediumPriority,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  context,
                  label: 'Low Priority',
                  isSelected: todoProvider.filterPriority == 'low',
                  onSelected: () => todoProvider.setPriorityFilter('low'),
                  color: AppTheme.lowPriority,
                ),

                const SizedBox(width: 16),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                const SizedBox(width: 16),

                // Category filters
                ...todoProvider.categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(
                      context,
                      label: category,
                      isSelected: todoProvider.filterCategory == category,
                      onSelected: () =>
                          todoProvider.setCategoryFilter(category),
                      color: AppTheme.getCategoryColor(category),
                    ),
                  );
                }).toList(),

                const SizedBox(width: 16),

                // Clear filters button
                if (todoProvider.filterStatus != 'all' ||
                    todoProvider.filterCategory != 'all' ||
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
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: isSelected ? Colors.white : chipColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : chipColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: chipColor.withOpacity(0.1),
      selectedColor: chipColor,
      checkmarkColor: Colors.white,
      side: BorderSide(color: chipColor, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildClearFiltersButton(
    BuildContext context,
    TodoProvider todoProvider,
  ) {
    return ActionChip(
      label: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.clear_all, size: 16),
          SizedBox(width: 4),
          Text('Clear Filters', style: TextStyle(fontSize: 12)),
        ],
      ),
      onPressed: todoProvider.clearFilters,
      backgroundColor: Colors.grey[200],
      side: BorderSide(color: Colors.grey[400]!),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
