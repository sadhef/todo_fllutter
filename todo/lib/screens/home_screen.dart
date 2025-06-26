import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_item.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/stats_card.dart';
import '../screens/add_todo_screen.dart';
import '../screens/timeline_screen.dart';
import '../screens/chatbot_screen.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Re-Todo'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showStats ? Icons.visibility_off : Icons.analytics),
            onPressed: () {
              setState(() {
                _showStats = !_showStats;
              });
            },
            tooltip: _showStats ? 'Hide Stats' : 'Show Stats',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_filters',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Filters'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'timeline',
                child: Row(
                  children: [
                    Icon(Icons.timeline),
                    SizedBox(width: 8),
                    Text('Timeline'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'All'),
            Tab(icon: Icon(Icons.radio_button_unchecked), text: 'Pending'),
            Tab(icon: Icon(Icons.check_circle), text: 'Completed'),
            Tab(icon: Icon(Icons.search), text: 'Search'),
          ],
        ),
      ),
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          if (todoProvider.isLoading && todoProvider.todos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading your todos...',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          if (todoProvider.error != null) {
            return _buildErrorState(todoProvider);
          }

          return Column(
            children: [
              if (_showStats) const StatsCard(),
              _buildFilterChips(todoProvider),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTodoList(todoProvider, 'all'),
                    _buildTodoList(todoProvider, 'pending'),
                    _buildTodoList(todoProvider, 'completed'),
                    _buildSearchTab(todoProvider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildErrorState(TodoProvider todoProvider) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.errorColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              todoProvider.error ?? 'Unknown error occurred',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => todoProvider.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(TodoProvider todoProvider) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Status filters
            _buildFilterChip(
              'All',
              todoProvider.filterStatus == 'all',
              () => todoProvider.setStatusFilter('all'),
              icon: Icons.list_alt,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Pending',
              todoProvider.filterStatus == 'pending',
              () => todoProvider.setStatusFilter('pending'),
              icon: Icons.radio_button_unchecked,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Completed',
              todoProvider.filterStatus == 'completed',
              () => todoProvider.setStatusFilter('completed'),
              icon: Icons.check_circle,
            ),

            const SizedBox(width: 16),
            Container(width: 1, height: 30, color: AppTheme.softPink),
            const SizedBox(width: 16),

            // Priority filters
            _buildFilterChip(
              'High Priority',
              todoProvider.filterPriority == 'high',
              () => todoProvider.setPriorityFilter('high'),
              icon: Icons.priority_high,
              color: AppTheme.errorColor,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Medium Priority',
              todoProvider.filterPriority == 'medium',
              () => todoProvider.setPriorityFilter('medium'),
              icon: Icons.remove,
              color: AppTheme.warningColor,
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              'Low Priority',
              todoProvider.filterPriority == 'low',
              () => todoProvider.setPriorityFilter('low'),
              icon: Icons.low_priority,
              color: AppTheme.successColor,
            ),

            const SizedBox(width: 16),
            if (todoProvider.hasActiveFilters) ...[
              Container(width: 1, height: 30, color: AppTheme.softPink),
              const SizedBox(width: 16),
              _buildClearFiltersButton(todoProvider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onSelected, {
    IconData? icon,
    Color? color,
  }) {
    final chipColor = color ?? AppTheme.primaryColor;

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

  Widget _buildClearFiltersButton(TodoProvider todoProvider) {
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
      backgroundColor: AppTheme.lightPink,
      side: BorderSide(color: AppTheme.softPink),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildTodoList(TodoProvider todoProvider, String filter) {
    List<Todo> todos;
    switch (filter) {
      case 'pending':
        todos = todoProvider.todos.where((todo) => !todo.isCompleted).toList();
        break;
      case 'completed':
        todos = todoProvider.todos.where((todo) => todo.isCompleted).toList();
        break;
      default:
        todos = todoProvider.todos;
    }

    if (todos.isEmpty) {
      return _buildEmptyState(filter);
    }

    return RefreshIndicator(
      onRefresh: todoProvider.refresh,
      color: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: todos.length,
        itemBuilder: (context, index) {
          final todo = todos[index];
          return TodoItem(
            todo: todo,
            onToggle: () => todoProvider.toggleTodo(todo.id),
            onDelete: () => _deleteTodo(todo.id),
            onEdit: () => _editTodo(todo),
          );
        },
      ),
    );
  }

  Widget _buildSearchTab(TodoProvider todoProvider) {
    return Column(
      children: [
        const SearchBarWidget(),
        Expanded(child: _buildTodoList(todoProvider, 'all')),
      ],
    );
  }

  Widget _buildEmptyState(String filter) {
    String message;
    String submessage;
    IconData icon;
    Color iconColor;

    switch (filter) {
      case 'pending':
        message = 'All caught up!';
        submessage = 'You have no pending tasks. Great job!';
        icon = Icons.celebration;
        iconColor = AppTheme.successColor;
        break;
      case 'completed':
        message = 'No completed tasks yet';
        submessage = 'Start completing some tasks to see them here!';
        icon = Icons.assignment_turned_in;
        iconColor = AppTheme.primaryColor;
        break;
      default:
        message = 'No todos yet';
        submessage = 'Create your first todo to get started on your productivity journey!';
        icon = Icons.add_task;
        iconColor = AppTheme.accentColor;
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: iconColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              submessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (filter == 'all') ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _addNewTodo,
                icon: const Icon(Icons.add),
                label: const Text('Create Todo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: "chatbot_fab",
          mini: true,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ChatBotScreen()),
            );
          },
          backgroundColor: Colors.orange,
          child: const Text('🍪', style: TextStyle(fontSize: 16)),
          tooltip: 'Chat with Cookie 🎀',
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: "add_todo_fab",
          onPressed: _addNewTodo,
          icon: const Icon(Icons.add),
          label: const Text('Add Todo'),
          backgroundColor: AppTheme.accentColor,
          foregroundColor: Colors.white,
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    final todoProvider = context.read<TodoProvider>();

    switch (action) {
      case 'refresh':
        todoProvider.refresh();
        _showSnackBar('Refreshing todos...', AppTheme.primaryColor);
        break;
      case 'clear_filters':
        todoProvider.clearFilters();
        _showSnackBar('Filters cleared', AppTheme.successColor);
        break;
      case 'timeline':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const TimelineScreen()),
        );
        break;
    }
  }

  void _addNewTodo() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddTodoScreen()),
    );
  }

  void _editTodo(Todo todo) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddTodoScreen(todoToEdit: todo)),
    );
  }

  void _deleteTodo(String todoId) {
    showDialog(
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TodoProvider>().deleteTodo(todoId);
              Navigator.of(context).pop();
              _showSnackBar('Todo deleted', AppTheme.errorColor);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}