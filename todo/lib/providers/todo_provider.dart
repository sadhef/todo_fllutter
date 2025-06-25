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
    } catch (e) {
      _setError('Failed to add todo: $e');
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
      }
    } catch (e) {
      _setError('Failed to update todo: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Toggle todo completion
  Future<void> toggleTodo(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      final wasCompleted = _todos[index].isCompleted;
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
    }

    try {
      await _todoService.toggleTodo(id);
      await loadStats();
    } catch (e) {
      // Revert optimistic update on error
      if (index != -1) {
        _todos[index] = _todos[index].copyWith(
          isCompleted: !_todos[index].isCompleted,
        );
        _applyFilters();
        notifyListeners();
      }
      _setError('Failed to toggle todo: $e');
    }
  }

  // Delete todo
  Future<void> deleteTodo(String id) async {
    Todo? deletedTodo;
    int? deletedIndex;

    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      deletedTodo = _todos[index];
      deletedIndex = index;
      _todos.removeAt(index);

      // Cancel all notifications for this todo
      await _notificationService.cancelAllNotificationsForTodo(id);

      _applyFilters();
      notifyListeners();
    }

    try {
      await _todoService.deleteTodo(id);
      await loadStats();
    } catch (e) {
      if (deletedTodo != null && deletedIndex != null) {
        _todos.insert(deletedIndex, deletedTodo);
        _applyFilters();
        notifyListeners();
      }
      _setError('Failed to delete todo: $e');
    }
  }

  // FIXED: Enhanced search functionality with better performance and accuracy
  Future<void> searchTodos(String query) async {
    _searchQuery = query.trim(); // Remove leading/trailing whitespace
    _applyFilters();
    notifyListeners();
  }

  // Filter methods
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

  // Bulk operations
  Future<void> deleteMultipleTodos(List<String> ids) async {
    try {
      await _todoService.deleteMultipleTodos(ids);

      // Cancel notifications for deleted todos
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

  // Private helper methods
  void _applyFilters() {
    _filteredTodos = _todos.where((todo) {
      // FIXED: Enhanced search filter with better matching
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final titleMatch = todo.title.toLowerCase().contains(query);
        final descriptionMatch = todo.description.toLowerCase().contains(query);
        final priorityMatch = todo.priority.toLowerCase().contains(query);

        // FIXED: Check voice note duration properly using existing getter
        bool voiceNoteMatch = false;
        if (todo.hasVoiceNote && todo.voiceNoteDuration != null) {
          final minutes = todo.voiceNoteDuration!.inMinutes;
          final seconds = todo.voiceNoteDuration!.inSeconds % 60;
          final formattedDuration =
              '${minutes}:${seconds.toString().padLeft(2, '0')}';
          voiceNoteMatch = formattedDuration.contains(query);
        }

        // Match any of the fields
        if (!titleMatch &&
            !descriptionMatch &&
            !priorityMatch &&
            !voiceNoteMatch) {
          return false;
        }
      }

      // Status filter
      if (_filterStatus == 'completed' && !todo.isCompleted) return false;
      if (_filterStatus == 'pending' && todo.isCompleted) return false;

      // Priority filter
      if (_filterPriority != 'all' && todo.priority != _filterPriority)
        return false;

      return true;
    }).toList();

    // Sort by creation date (newest first), but completed todos at bottom
    _filteredTodos.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  double _calculateAverageCompletionTime() {
    final completedTodos = _todos
        .where((todo) => todo.isCompleted && todo.updatedAt != null)
        .toList();

    if (completedTodos.isEmpty) return 0.0;

    final totalHours = completedTodos.fold<double>(0, (sum, todo) {
      final duration = todo.updatedAt!.difference(todo.createdAt);
      return sum + duration.inHours;
    });

    return totalHours / completedTodos.length;
  }

  int _getMostProductiveHour() {
    final hourCounts = <int, int>{};

    for (final todo in _todos.where(
      (t) => t.isCompleted && t.updatedAt != null,
    )) {
      final hour = todo.updatedAt!.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    if (hourCounts.isEmpty) return 9; // Default to 9 AM

    return hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  int _calculateStreakDays() {
    if (_todos.isEmpty) return 0;

    final now = DateTime.now();
    var currentDate = DateTime(now.year, now.month, now.day);
    var streakDays = 0;

    for (int i = 0; i < 30; i++) {
      final hasCompletedTodo = _todos.any((todo) =>
          todo.isCompleted &&
          todo.updatedAt != null &&
          todo.updatedAt!.year == currentDate.year &&
          todo.updatedAt!.month == currentDate.month &&
          todo.updatedAt!.day == currentDate.day);

      if (hasCompletedTodo) {
        streakDays++;
      } else if (i > 0) {
        // Break streak if no completed todos found (except for today)
        break;
      }

      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return streakDays;
  }

  // Utility methods
  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _clearError() {
    _error = null;
  }

  void _setError(String error) {
    _error = error;
    print('TodoProvider Error: $error');
  }
}
