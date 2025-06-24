import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';
import '../services/notification_service.dart';

class TodoProvider with ChangeNotifier {
  final TodoService _todoService = TodoService();
  final NotificationService _notificationService = NotificationService();

  // State variables
  List<Todo> _todos = [];
  List<Todo> _filteredTodos = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'completed', 'pending'
  String _filterPriority = 'all';
  Map<String, dynamic> _stats = {};

  // Getters
  List<Todo> get todos => _filteredTodos;
  List<Todo> get allTodos => _todos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get filterStatus => _filterStatus;
  String get filterPriority => _filterPriority;
  Map<String, dynamic> get stats => _stats;

  // Computed getters
  int get totalTodos => _todos.length;
  int get completedTodos => _todos.where((todo) => todo.isCompleted).length;
  int get pendingTodos => _todos.where((todo) => !todo.isCompleted).length;
  double get completionRate =>
      totalTodos > 0 ? completedTodos / totalTodos : 0.0;

  List<String> get priorities => ['low', 'medium', 'high'];

  // Todos with voice notes
  List<Todo> get todosWithVoiceNotes => _todos
      .where((todo) =>
          todo.voiceNotePath != null && todo.voiceNotePath!.isNotEmpty)
      .toList();

  // Overdue todos
  List<Todo> get overdueTodos {
    final now = DateTime.now();
    return _todos
        .where(
          (todo) =>
              !todo.isCompleted &&
              todo.dueDate != null &&
              todo.dueDate!.isBefore(now),
        )
        .toList();
  }

  // Today's todos
  List<Todo> get todaysTodos {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _todos.where((todo) {
      if (todo.dueDate == null) return false;
      final dueDate = DateTime(
        todo.dueDate!.year,
        todo.dueDate!.month,
        todo.dueDate!.day,
      );
      return dueDate.isAtSameMomentAs(today) ||
          (dueDate.isAfter(today) && dueDate.isBefore(tomorrow));
    }).toList();
  }

  // Upcoming todos (next 7 days)
  List<Todo> get upcomingTodos {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    return _todos.where((todo) {
      if (todo.dueDate == null || todo.isCompleted) return false;
      return todo.dueDate!.isAfter(now) && todo.dueDate!.isBefore(nextWeek);
    }).toList();
  }

  // High priority todos
  List<Todo> get highPriorityTodos => _todos
      .where((todo) => todo.priority == 'high' && !todo.isCompleted)
      .toList();

  // Initialize provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _notificationService.initialize();
      await _todoService.initialize(); // Initialize SharedPreferences
      await loadTodos();
      await loadStats();

      // Schedule daily productivity summary
      await _notificationService.scheduleDailyProductivitySummary();
    } catch (e) {
      _setError('Failed to initialize: $e');
      if (kDebugMode) {
        print('TodoProvider initialization error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Load todos
  Future<void> loadTodos() async {
    _setLoading(true);
    _clearError();

    try {
      _todos = await _todoService.getAllTodos();
      _applyFilters();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load todos: $e');
      if (kDebugMode) {
        print('Load todos error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Add todo
  Future<void> addTodo(Todo todo) async {
    _setLoading(true);
    _clearError();

    try {
      final newTodo = await _todoService.addTodo(todo);
      _todos.add(newTodo);

      // Schedule notification if todo has due date
      if (newTodo.dueDate != null && !newTodo.isCompleted) {
        await _notificationService.scheduleReminderNotification(newTodo);
      }

      _applyFilters();
      await loadStats();
      notifyListeners();

      if (kDebugMode) {
        print('Todo added successfully: ${newTodo.title}');
      }
    } catch (e) {
      _setError('Failed to add todo: $e');
      if (kDebugMode) {
        print('Add todo error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Update todo
  Future<void> updateTodo(String id, Todo updatedTodo) async {
    _setLoading(true);
    _clearError();

    try {
      final updated = await _todoService.updateTodo(id, updatedTodo);
      final index = _todos.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        _todos[index] = updated;

        // Update notification
        await _notificationService.updateReminderNotification(updated);

        _applyFilters();
        await loadStats();
        notifyListeners();

        if (kDebugMode) {
          print('Todo updated successfully: ${updated.title}');
        }
      }
    } catch (e) {
      _setError('Failed to update todo: $e');
      if (kDebugMode) {
        print('Update todo error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Toggle todo completion
  Future<void> toggleTodo(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final wasCompleted = _todos[index].isCompleted;

      // Optimistic update
      _todos[index] = _todos[index].copyWith(
        isCompleted: !_todos[index].isCompleted,
        updatedAt: DateTime.now(),
      );

      // Show completion celebration if newly completed
      if (!wasCompleted && _todos[index].isCompleted) {
        await _notificationService.scheduleCompletionNotification(
          _todos[index],
        );
        await _notificationService.cancelReminderNotification(_todos[index].id);
      } else if (wasCompleted && !_todos[index].isCompleted) {
        // Reschedule reminder if uncompleted and has due date
        if (_todos[index].dueDate != null) {
          await _notificationService.scheduleReminderNotification(
            _todos[index],
          );
        }
      }

      _applyFilters();
      notifyListeners();

      try {
        await _todoService.toggleTodo(id);
        await loadStats();

        if (kDebugMode) {
          print('Todo toggled successfully: ${_todos[index].title}');
        }
      } catch (e) {
        // Revert optimistic update on error
        _todos[index] = _todos[index].copyWith(
          isCompleted: !_todos[index].isCompleted,
        );
        _applyFilters();
        notifyListeners();
        _setError('Failed to toggle todo: $e');

        if (kDebugMode) {
          print('Toggle todo error: $e');
        }
      }
    }
  }

  // Delete todo
  Future<void> deleteTodo(String id) async {
    Todo? deletedTodo;
    int? deletedIndex;

    // Optimistic delete
    try {
      deletedIndex = _todos.indexWhere((todo) => todo.id == id);
      if (deletedIndex != -1) {
        deletedTodo = _todos[deletedIndex];
        _todos.removeAt(deletedIndex);

        // Cancel any pending notifications
        await _notificationService.cancelReminderNotification(id);

        _applyFilters();
        notifyListeners();
      }

      await _todoService.deleteTodo(id);
      await loadStats();

      if (kDebugMode) {
        print('Todo deleted successfully: ${deletedTodo?.title}');
      }
    } catch (e) {
      // Revert optimistic delete on error
      if (deletedTodo != null && deletedIndex != null) {
        _todos.insert(deletedIndex, deletedTodo);
        _applyFilters();
        notifyListeners();
      }
      _setError('Failed to delete todo: $e');

      if (kDebugMode) {
        print('Delete todo error: $e');
      }
    }
  }

  // Bulk delete todos
  Future<void> deleteMultipleTodos(List<String> ids) async {
    _setLoading(true);
    _clearError();

    final List<Todo> deletedTodos = [];
    final List<int> deletedIndices = [];

    try {
      // Optimistic delete
      for (final id in ids) {
        final index = _todos.indexWhere((todo) => todo.id == id);
        if (index != -1) {
          deletedTodos.add(_todos[index]);
          deletedIndices.add(index);
        }
      }

      // Remove in reverse order to maintain indices
      deletedIndices.sort((a, b) => b.compareTo(a));
      for (final index in deletedIndices) {
        _todos.removeAt(index);
      }

      // Cancel notifications
      for (final id in ids) {
        await _notificationService.cancelReminderNotification(id);
      }

      _applyFilters();
      notifyListeners();

      await _todoService.deleteMultipleTodos(ids);
      await loadStats();

      if (kDebugMode) {
        print('Multiple todos deleted successfully: ${ids.length} items');
      }
    } catch (e) {
      // Revert optimistic deletes on error
      for (int i = 0; i < deletedTodos.length; i++) {
        _todos.insert(deletedIndices[i], deletedTodos[i]);
      }
      _applyFilters();
      notifyListeners();
      _setError('Failed to delete todos: $e');

      if (kDebugMode) {
        print('Bulk delete error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Bulk toggle todos
  Future<void> toggleMultipleTodos(List<String> ids, bool isCompleted) async {
    _setLoading(true);
    _clearError();

    final Map<String, bool> originalStates = {};

    try {
      // Store original states for potential revert
      for (final id in ids) {
        final todo = _todos.firstWhere((t) => t.id == id);
        originalStates[id] = todo.isCompleted;
      }

      // Optimistic update
      for (int i = 0; i < _todos.length; i++) {
        if (ids.contains(_todos[i].id)) {
          _todos[i] = _todos[i].copyWith(
            isCompleted: isCompleted,
            updatedAt: DateTime.now(),
          );

          // Handle notifications
          if (isCompleted) {
            await _notificationService.cancelReminderNotification(_todos[i].id);
          } else if (_todos[i].dueDate != null) {
            await _notificationService.scheduleReminderNotification(_todos[i]);
          }
        }
      }

      _applyFilters();
      notifyListeners();

      await _todoService.toggleMultipleTodos(ids, isCompleted);
      await loadStats();

      if (kDebugMode) {
        print('Multiple todos toggled successfully: ${ids.length} items');
      }
    } catch (e) {
      // Revert optimistic updates on error
      for (int i = 0; i < _todos.length; i++) {
        if (ids.contains(_todos[i].id)) {
          final originalState = originalStates[_todos[i].id];
          if (originalState != null) {
            _todos[i] = _todos[i].copyWith(isCompleted: originalState);
          }
        }
      }
      _applyFilters();
      notifyListeners();
      _setError('Failed to toggle todos: $e');

      if (kDebugMode) {
        print('Bulk toggle error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Search todos
  Future<void> searchTodos(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _applyFilters();
    } else {
      _setLoading(true);
      _clearError();

      try {
        final searchResults = await _todoService.searchTodos(query);
        _filteredTodos = searchResults;
        notifyListeners();

        if (kDebugMode) {
          print(
              'Search completed: ${searchResults.length} results for "$query"');
        }
      } catch (e) {
        _setError('Failed to search todos: $e');

        if (kDebugMode) {
          print('Search error: $e');
        }
      } finally {
        _setLoading(false);
      }
    }
  }

  // Set filters - Updated method names to match home_screen.dart
  void setFilter({String? status, String? priority}) {
    if (status != null) _filterStatus = status;
    if (priority != null) _filterPriority = priority;
    _applyFilters();

    if (kDebugMode) {
      print(
          'Filters applied: status=$_filterStatus, priority=$_filterPriority');
    }
  }

  // Individual filter methods for backward compatibility
  void setStatusFilter(String status) {
    setFilter(status: status);
  }

  void setPriorityFilter(String priority) {
    setFilter(priority: priority);
  }

  // Clear filters
  void clearFilters() {
    _filterStatus = 'all';
    _filterPriority = 'all';
    _searchQuery = '';
    _applyFilters();

    if (kDebugMode) {
      print('All filters cleared');
    }
  }

  // Load statistics
  Future<void> loadStats() async {
    try {
      _stats = await _todoService.getStats();
      notifyListeners();

      if (kDebugMode) {
        print('Stats loaded: ${_stats.toString()}');
      }
    } catch (e) {
      _setError('Failed to load statistics: $e');

      if (kDebugMode) {
        print('Load stats error: $e');
      }
    }
  }

  // Refresh data
  Future<void> refresh() async {
    _clearError();
    await loadTodos();
    await loadStats();

    if (kDebugMode) {
      print('Data refreshed successfully');
    }
  }

  // Clear all data (for testing or reset)
  Future<void> clearAllData() async {
    _setLoading(true);
    _clearError();

    try {
      await _todoService.clearAllData();
      _todos.clear();
      _filteredTodos.clear();
      _stats.clear();

      // Cancel all notifications
      for (final todo in _todos) {
        await _notificationService.cancelReminderNotification(todo.id);
      }

      notifyListeners();

      if (kDebugMode) {
        print('All data cleared successfully');
      }
    } catch (e) {
      _setError('Failed to clear data: $e');

      if (kDebugMode) {
        print('Clear data error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Export todos (for backup)
  List<Map<String, dynamic>> exportTodos() {
    try {
      final exportData = _todos.map((todo) => todo.toMap()).toList();

      if (kDebugMode) {
        print('Exported ${exportData.length} todos');
      }

      return exportData;
    } catch (e) {
      _setError('Failed to export todos: $e');

      if (kDebugMode) {
        print('Export error: $e');
      }

      return [];
    }
  }

  // Import todos (for restore)
  Future<void> importTodos(List<Map<String, dynamic>> todosData) async {
    _setLoading(true);
    _clearError();

    try {
      // Clear existing data
      await clearAllData();

      // Import new data
      for (final todoMap in todosData) {
        final todo = Todo.fromMap(todoMap);
        await _todoService.addTodo(todo);
      }

      await loadTodos();
      await loadStats();

      if (kDebugMode) {
        print('Imported ${todosData.length} todos successfully');
      }
    } catch (e) {
      _setError('Failed to import todos: $e');

      if (kDebugMode) {
        print('Import error: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Get productivity insights
  Map<String, dynamic> getProductivityInsights() {
    if (_todos.isEmpty) {
      return {
        'totalTasks': 0,
        'completionRate': 0.0,
        'averageTasksPerDay': 0.0,
        'mostProductiveDay': 'N/A',
        'priorityDistribution': {},
        'overdueTasks': 0,
      };
    }

    final now = DateTime.now();
    final last7Days = now.subtract(const Duration(days: 7));
    final recentTodos =
        _todos.where((todo) => todo.createdAt.isAfter(last7Days)).toList();

    // Calculate priority distribution
    final priorityCount = <String, int>{};
    for (final todo in _todos) {
      priorityCount[todo.priority] = (priorityCount[todo.priority] ?? 0) + 1;
    }

    // Calculate average tasks per day
    final daysSinceFirstTodo = _todos.isEmpty
        ? 1
        : now
            .difference(_todos
                .map((t) => t.createdAt)
                .reduce((a, b) => a.isBefore(b) ? a : b))
            .inDays
            .clamp(1, double.infinity);

    final averageTasksPerDay = _todos.length / daysSinceFirstTodo;

    return {
      'totalTasks': _todos.length,
      'completionRate': completionRate,
      'averageTasksPerDay': averageTasksPerDay,
      'recentTasks': recentTodos.length,
      'priorityDistribution': priorityCount,
      'overdueTasks': overdueTodos.length,
      'todaysTasks': todaysTodos.length,
      'upcomingTasks': upcomingTodos.length,
      'highPriorityTasks': highPriorityTodos.length,
    };
  }

  // Private helper methods
  void _applyFilters() {
    List<Todo> filtered = List.from(_todos);

    // Apply status filter
    if (_filterStatus != 'all') {
      if (_filterStatus == 'completed') {
        filtered = filtered.where((todo) => todo.isCompleted).toList();
      } else if (_filterStatus == 'pending') {
        filtered = filtered.where((todo) => !todo.isCompleted).toList();
      }
    }

    // Apply priority filter
    if (_filterPriority != 'all') {
      filtered =
          filtered.where((todo) => todo.priority == _filterPriority).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((todo) {
        return todo.title.toLowerCase().contains(query) ||
            todo.description.toLowerCase().contains(query);
      }).toList();
    }

    // Sort by priority and creation date
    filtered.sort((a, b) {
      // First sort by completion status (pending first)
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }

      // Then by priority (high, medium, low)
      final priorityOrder = ['high', 'medium', 'low'];
      final aPriorityIndex = priorityOrder.indexOf(a.priority);
      final bPriorityIndex = priorityOrder.indexOf(b.priority);

      if (aPriorityIndex != bPriorityIndex) {
        return aPriorityIndex.compareTo(bPriorityIndex);
      }

      // Then by due date (earliest first)
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1; // a has due date, b doesn't
      } else if (b.dueDate != null) {
        return 1; // b has due date, a doesn't
      }

      // Finally by creation date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });

    _filteredTodos = filtered;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    if (kDebugMode) {
      print('TodoProvider disposed');
    }
    super.dispose();
  }
}
