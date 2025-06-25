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

  // NEW: Add the missing hasActiveFilters getter
  bool get hasActiveFilters {
    return _filterStatus != 'all' ||
        _filterPriority != 'all' ||
        _searchQuery.isNotEmpty;
  }

  // Computed getters
  int get totalTodos => _todos.length;
  int get completedTodos => _todos.where((todo) => todo.isCompleted).length;
  int get pendingTodos => _todos.where((todo) => !todo.isCompleted).length;
  double get completionRate =>
      totalTodos > 0 ? completedTodos / totalTodos : 0.0;

  List<String> get priorities => ['low', 'medium', 'high'];

  // Todos with voice notes
  List<Todo> get todosWithVoiceNotes =>
      _todos.where((todo) => todo.hasVoiceNote).toList();

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

  // Initialize provider
  Future<void> initialize() async {
    await _notificationService.initialize();
    await _todoService.initializeSampleData();
    await loadTodos();
    await loadStats();

    // Schedule daily productivity summary
    await _notificationService.scheduleDailyProductivitySummary();
  }

  // FIXED: Added refresh method
  Future<void> refresh() async {
    await loadTodos();
    await loadStats();
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
    } finally {
      _setLoading(false);
    }
  }

  // Add todo - FIXED: Use existing notification methods
  Future<void> addTodo(Todo todo) async {
    _setLoading(true);
    _clearError();

    try {
      final newTodo = await _todoService.addTodo(todo);
      _todos.add(newTodo);

      // FIXED: Use existing scheduleReminderNotification method
      if (newTodo.dueDate != null && !newTodo.isCompleted) {
        await _notificationService.scheduleReminderNotification(newTodo);
      }

      _applyFilters();
      await loadStats();
      notifyListeners();
    } catch (e) {
      _setError('Failed to add todo: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update todo - FIXED: Use existing notification methods
  Future<void> updateTodo(String id, Todo updatedTodo) async {
    try {
      final updated = await _todoService.updateTodo(id, updatedTodo);
      final index = _todos.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        _todos[index] = updated;

        // FIXED: Use existing updateReminderNotification method
        await _notificationService.updateReminderNotification(updated);

        _applyFilters();
        await loadStats();
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update todo: $e');
    }
  }

  // Toggle todo completion - FIXED: Use existing notification methods
  Future<void> toggleTodo(String id) async {
    try {
      final index = _todos.indexWhere((todo) => todo.id == id);
      if (index == -1) return;

      final todo = _todos[index];
      final updatedTodo = todo.copyWith(
        isCompleted: !todo.isCompleted,
        updatedAt: DateTime.now(),
      );

      await _todoService.updateTodo(id, updatedTodo);
      _todos[index] = updatedTodo;

      // FIXED: Use existing notification methods
      if (updatedTodo.isCompleted) {
        // Cancel reminders and show completion celebration
        await _notificationService.cancelReminderNotification(id);
        await _notificationService.scheduleCompletionNotification(updatedTodo);
      } else if (updatedTodo.dueDate != null) {
        // Reschedule reminders for uncompleted todo
        await _notificationService.scheduleReminderNotification(updatedTodo);
      }

      _applyFilters();
      await loadStats();
      notifyListeners();
    } catch (e) {
      _setError('Failed to toggle todo: $e');
    }
  }

  // Delete todo - FIXED: Use existing notification methods
  Future<void> deleteTodo(String id) async {
    // Optimistically remove from UI
    Todo? deletedTodo;
    int? deletedIndex;

    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      deletedTodo = _todos[index];
      deletedIndex = index;
      _todos.removeAt(index);

      // FIXED: Use existing cancelAllNotificationsForTodo method
      await _notificationService.cancelAllNotificationsForTodo(id);

      _applyFilters();
      notifyListeners();
    }

    try {
      await _todoService.deleteTodo(id);
      await loadStats();
    } catch (e) {
      // Rollback on error
      if (deletedTodo != null && deletedIndex != null) {
        _todos.insert(deletedIndex, deletedTodo);
        _applyFilters();
        notifyListeners();
      }
      _setError('Failed to delete todo: $e');
    }
  }

  // NEW: Search functionality
  Future<void> searchTodos(String query) async {
    _searchQuery = query.trim();
    _applyFilters();
    notifyListeners();
  }

  // NEW: Filter methods
  void setStatusFilter(String status) {
    _filterStatus = status;
    _applyFilters();
    notifyListeners();
  }

  void setPriorityFilter(String priority) {
    _filterPriority = priority;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterStatus = 'all';
    _filterPriority = 'all';
    _applyFilters();
    notifyListeners();
  }

  // Bulk operations - FIXED: Use existing notification methods
  Future<void> deleteMultipleTodos(List<String> ids) async {
    try {
      await _todoService.deleteMultipleTodos(ids);

      // FIXED: Cancel notifications for deleted todos using existing method
      for (final id in ids) {
        await _notificationService.cancelAllNotificationsForTodo(id);
      }

      _todos.removeWhere((todo) => ids.contains(todo.id));
      _applyFilters();
      await loadStats();
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete todos: $e');
    }
  }

  Future<void> toggleMultipleTodos(List<String> ids, bool isCompleted) async {
    try {
      await _todoService.toggleMultipleTodos(ids, isCompleted);

      for (int i = 0; i < _todos.length; i++) {
        if (ids.contains(_todos[i].id)) {
          _todos[i] = _todos[i].copyWith(
            isCompleted: isCompleted,
            updatedAt: DateTime.now(),
          );
        }
      }

      _applyFilters();
      await loadStats();
      notifyListeners();
    } catch (e) {
      _setError('Failed to update todos: $e');
    }
  }

  // Load statistics
  Future<void> loadStats() async {
    try {
      _stats = await _todoService.getStats();

      // Add additional statistics
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisWeek = now.subtract(Duration(days: now.weekday - 1));

      final todayTodos = _todos.where((todo) =>
          todo.createdAt.isAfter(today) ||
          (todo.updatedAt != null && todo.updatedAt!.isAfter(today)));

      final completedToday =
          todayTodos.where((todo) => todo.isCompleted).length;
      final completedThisWeek = _todos
          .where((todo) =>
              todo.isCompleted &&
              todo.updatedAt != null &&
              todo.updatedAt!.isAfter(thisWeek))
          .length;

      final averageCompletionTime = _calculateAverageCompletionTime();
      final mostProductiveHour = _getMostProductiveHour();

      _stats.addAll({
        'completedToday': completedToday,
        'completedThisWeek': completedThisWeek,
        'averageCompletionTime': averageCompletionTime,
        'mostProductiveHour': mostProductiveHour,
        'streakDays': _calculateStreakDays(),
      });
    } catch (e) {
      print('Failed to load stats: $e');
    }
  }

  // NEW: Apply filters method
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
        final titleMatch = todo.title.toLowerCase().contains(query);
        final descriptionMatch = todo.description.toLowerCase().contains(query);
        final priorityMatch = todo.priority.toLowerCase().contains(query);

        return titleMatch || descriptionMatch || priorityMatch;
      }).toList();
    }

    _filteredTodos = filtered;
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  double _calculateAverageCompletionTime() {
    final completedTodos = _todos
        .where((todo) => todo.isCompleted && todo.updatedAt != null)
        .toList();

    if (completedTodos.isEmpty) return 0.0;

    double totalHours = 0;
    for (final todo in completedTodos) {
      final completionTime = todo.updatedAt!.difference(todo.createdAt).inHours;
      totalHours += completionTime;
    }

    return totalHours / completedTodos.length;
  }

  int _getMostProductiveHour() {
    final completedTodos = _todos
        .where((todo) => todo.isCompleted && todo.updatedAt != null)
        .toList();

    if (completedTodos.isEmpty) return 9; // Default to 9 AM

    final hourCounts = <int, int>{};

    for (final todo in completedTodos) {
      final hour = todo.updatedAt!.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    int mostProductiveHour = 9;
    int maxCount = 0;

    hourCounts.forEach((hour, count) {
      if (count > maxCount) {
        maxCount = count;
        mostProductiveHour = hour;
      }
    });

    return mostProductiveHour;
  }

  int _calculateStreakDays() {
    final now = DateTime.now();
    final completedTodos = _todos
        .where((todo) => todo.isCompleted && todo.updatedAt != null)
        .toList();

    if (completedTodos.isEmpty) return 0;

    // Sort by completion date (most recent first)
    completedTodos.sort((a, b) => b.updatedAt!.compareTo(a.updatedAt!));

    int streak = 0;
    DateTime currentDate = DateTime(now.year, now.month, now.day);

    for (final todo in completedTodos) {
      final todoDate = DateTime(
          todo.updatedAt!.year, todo.updatedAt!.month, todo.updatedAt!.day);

      if (todoDate == currentDate) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else if (todoDate.isBefore(currentDate)) {
        break;
      }
    }

    return streak;
  }
}
