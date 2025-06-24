import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/todo.dart';
import '../providers/todo_provider.dart';
import '../widgets/todo_item.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_chips.dart';
import '../widgets/stats_card.dart';
import 'add_todo_screen.dart';

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
        title: const Text('Re-Todo'),
        actions: [
          IconButton(
            icon: Icon(_showStats ? Icons.list : Icons.analytics),
            onPressed: () {
              setState(() {
                _showStats = !_showStats;
              });
            },
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
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.list)),
            Tab(text: 'Pending', icon: Icon(Icons.radio_button_unchecked)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
            Tab(text: 'Search', icon: Icon(Icons.search)),
          ],
        ),
      ),
      body: Consumer<TodoProvider>(
        builder: (context, todoProvider, child) {
          if (todoProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (todoProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${todoProvider.error}',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => todoProvider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              if (_showStats) const StatsCard(),
              const FilterChips(),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTodo,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTodoList(TodoProvider todoProvider, String filter) {
    // Apply filter
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
    IconData icon;

    switch (filter) {
      case 'pending':
        message = 'No pending todos!\nYou\'re all caught up! 🎉';
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
        message = 'No completed todos yet.\nStart checking off your tasks!';
        icon = Icons.assignment_turned_in_outlined;
        break;
      default:
        message = 'No todos yet.\nTap + to create your first todo!';
        icon = Icons.assignment_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (filter == 'all') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addNewTodo,
              icon: const Icon(Icons.add),
              label: const Text('Add Todo'),
            ),
          ],
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    final todoProvider = context.read<TodoProvider>();

    switch (action) {
      case 'refresh':
        todoProvider.refresh();
        break;
      case 'clear_filters':
        todoProvider.clearFilters();
        break;
    }
  }

  void _addNewTodo() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddTodoScreen()));
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
        title: const Text('Delete Todo'),
        content: const Text('Are you sure you want to delete this todo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TodoProvider>().deleteTodo(todoId);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
