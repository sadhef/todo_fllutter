import 'package:flutter/foundation.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';

// This is similar to React Context + useReducer or Redux
class TodoProvider with ChangeNotifier {
  final TodoService _todoService = TodoService();

  // State variables (similar to useState in React)
  List<Todo> _todos = [];
  List<Todo> _filteredTodos = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'completed', 'pending'
  String _filterCategory = 'all';
  String _filterPriority = 'all';
  Map<String, dynamic> _stats = {};

  // Getters (similar to computed properties in Vue or selectors in Redux)
  List<Todo> get todos => _filteredTodos;
  List<Todo> get allTodos => _todos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get filterStatus => _filterStatus;
  String get filterCategory => _filterCategory;
  String get filterPriority => _filterPriority;
  Map<String, dynamic> get stats => _stats;

  // Computed getters
  int get totalTodos => _todos.length;
  int get completedTodos => _todos.where((todo) => todo.isCompleted).length;
  int get pendingTodos => _todos.where((todo) => !todo.isCompleted).length;
  double get completionRate =>
      totalTodos > 0 ? completedTodos / totalTodos : 0.0;

  List<String> get categories =>
      _todos.map((todo) => todo.category).toSet().toList();
  List<String> get priorities => ['low', 'medium', 'high'];

  // Initialize provider (similar to useEffect with empty dependency)
  Future<void> initialize() async {
    await _todoService.initializeSampleData();
    await loadTodos();
    await loadStats();
  }

  // Load todos (GET request)
  Future<void> loadTodos() async {
    _setLoading(true);
    _clearError();

    try {
      _todos = await _todoService.getAllTodos();
      _applyFilters();
      notifyListeners(); // Similar to setState in React
    } catch (e) {
      _setError('Failed to load todos: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Add todo (POST request)
  Future<void> addTodo(Todo todo) async {
    _setLoading(true);
    _clearError();

    try {
      final newTodo = await _todoService.addTodo(todo);
      _todos.add(newTodo);
      _applyFilters();
      await loadStats();
      notifyListeners();
    } catch (e) {
      _setError('Failed to add todo: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update todo (PUT request)
  Future<void> updateTodo(String id, Todo updatedTodo) async {
    _setLoading(true);
    _clearError();

    try {
      final updated = await _todoService.updateTodo(id, updatedTodo);
      final index = _todos.indexWhere((todo) => todo.id == id);
      if (index != -1) {
        _todos[index] = updated;
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

  // Toggle todo completion (PATCH request)
  Future<void> toggleTodo(String id) async {
    // Optimistic update (update UI immediately, like in modern web apps)
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(
        isCompleted: !_todos[index].isCompleted,
      );
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

  // Delete todo (DELETE request)
  Future<void> deleteTodo(String id) async {
    // Store reference for potential rollback
    Todo? deletedTodo;
    int? deletedIndex;

    // Optimistic delete
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      deletedTodo = _todos[index];
      deletedIndex = index;
      _todos.removeAt(index);
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

  // Search todos
  Future<void> searchTodos(String query) async {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Filter methods (similar to reducer actions)
  void setStatusFilter(String status) {
    _filterStatus = status;
    _applyFilters();
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _filterCategory = category;
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
    _filterCategory = 'all';
    _filterPriority = 'all';
    _applyFilters();
    notifyListeners();
  }

  // Bulk operations
  Future<void> deleteMultipleTodos(List<String> ids) async {
    try {
      await _todoService.deleteMultipleTodos(ids);
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
          _todos[i] = _todos[i].copyWith(isCompleted: isCompleted);
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
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load stats: $e');
    }
  }

  // Private helper methods
  void _applyFilters() {
    _filteredTodos = _todos.where((todo) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!todo.title.toLowerCase().contains(query) &&
            !todo.description.toLowerCase().contains(query) &&
            !todo.category.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Status filter
      if (_filterStatus == 'completed' && !todo.isCompleted) return false;
      if (_filterStatus == 'pending' && todo.isCompleted) return false;

      // Category filter
      if (_filterCategory != 'all' && todo.category != _filterCategory)
        return false;

      // Priority filter
      if (_filterPriority != 'all' && todo.priority != _filterPriority)
        return false;

      return true;
    }).toList();

    // Sort by creation date (newest first)
    _filteredTodos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  // Refresh data (similar to pull-to-refresh)
  Future<void> refresh() async {
    await loadTodos();
    await loadStats();
  }
}
