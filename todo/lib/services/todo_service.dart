import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';

class TodoService {
  static final TodoService _instance = TodoService._internal();
  factory TodoService() => _instance;
  TodoService._internal();

  // FIXED: Added persistent storage
  SharedPreferences? _prefs;
  List<Todo> _todos = [];
  static const String _todosKey = 'todos_data';
  static const Duration _delay = Duration(milliseconds: 300);

  // Initialize SharedPreferences
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // FIXED: Load todos from persistent storage
  Future<void> _loadTodosFromStorage() async {
    await _initPrefs();
    try {
      final String? todosJson = _prefs!.getString(_todosKey);
      if (todosJson != null) {
        final List<dynamic> todosList = json.decode(todosJson);
        _todos = todosList.map((todoMap) => Todo.fromJson(todoMap)).toList();
        print('Loaded ${_todos.length} todos from storage');
      } else {
        print('No todos found in storage, starting with empty list');
        _todos = [];
      }
    } catch (e) {
      print('Error loading todos from storage: $e');
      _todos = [];
    }
  }

  // FIXED: Save todos to persistent storage
  Future<void> _saveTodosToStorage() async {
    await _initPrefs();
    try {
      final List<Map<String, dynamic>> todosJson =
          _todos.map((todo) => todo.toJson()).toList();
      final String encodedTodos = json.encode(todosJson);
      await _prefs!.setString(_todosKey, encodedTodos);
      print('Saved ${_todos.length} todos to storage');
    } catch (e) {
      print('Error saving todos to storage: $e');
    }
  }

  // Get all todos (GET /api/todos)
  Future<List<Todo>> getAllTodos() async {
    await Future.delayed(_delay); // Simulate network delay

    // FIXED: Load from storage if _todos is empty (first time or after restart)
    if (_todos.isEmpty) {
      await _loadTodosFromStorage();
    }

    return List.from(_todos);
  }

  // Get todos by filter (GET /api/todos?filter=...)
  Future<List<Todo>> getTodosByFilter({
    bool? isCompleted,
    String? priority,
  }) async {
    await Future.delayed(_delay);

    // FIXED: Ensure todos are loaded
    if (_todos.isEmpty) {
      await _loadTodosFromStorage();
    }

    return _todos.where((todo) {
      if (isCompleted != null && todo.isCompleted != isCompleted) {
        return false;
      }
      if (priority != null && todo.priority != priority) {
        return false;
      }
      return true;
    }).toList();
  }

  // Add new todo (POST /api/todos)
  Future<Todo> addTodo(Todo todo) async {
    await Future.delayed(_delay);

    // FIXED: Ensure todos are loaded
    if (_todos.isEmpty) {
      await _loadTodosFromStorage();
    }

    final newTodo = todo.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
    );

    _todos.add(newTodo);

    // FIXED: Save to persistent storage
    await _saveTodosToStorage();

    return newTodo;
  }

  // Update todo (PUT /api/todos/:id)
  Future<Todo> updateTodo(String id, Todo updatedTodo) async {
    await Future.delayed(_delay);

    // FIXED: Ensure todos are loaded
    if (_todos.isEmpty) {
      await _loadTodosFromStorage();
    }

    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) {
      throw Exception('Todo not found');
    }

    final updated = updatedTodo.copyWith(id: id, updatedAt: DateTime.now());

    _todos[index] = updated;

    // FIXED: Save to persistent storage
    await _saveTodosToStorage();

    return updated;
  }

  // Toggle todo completion (PATCH /api/todos/:id/toggle)
  Future<Todo> toggleTodo(String id) async {
    await Future.delayed(_delay);

    // FIXED: Ensure todos are loaded
    if (_todos.isEmpty) {
      await _loadTodosFromStorage();
    }

    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) {
      throw Exception('Todo not found');
    }

    final updated = _todos[index].copyWith(
      isCompleted: !_todos[index].isCompleted,
      updatedAt: DateTime.now(),
    );

    _todos[index] = updated;

    // FIXED: Save to persistent storage
    await _saveTodosToStorage();

    return updated;
  }

  // Delete todo (DELETE /api/todos/:id)
  Future<void> deleteTodo(String id) async {
    await Future.delayed(_delay);

    // FIXED: Ensure todos are loaded
    if (_todos.isEmpty) {
      await _loadTodosFromStorage();
    }

    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) {
      throw Exception('Todo not found');
    }

    _todos.removeAt(index);

    // FIXED: Save to persistent storage
    await _saveTodosToStorage();
  }

  // Bulk operations
  Future<void> deleteMultipleTodos(List<String> ids) async {
    await Future.delayed(_delay);

    // FIXED: Ensure todos are loaded
    if (_todos.isEmpty) {
      await _loadTodosFromStorage();
    }

    _todos.removeWhere((todo) => ids.contains(todo.id));

    // FIXED: Save to persistent storage
    await _saveTodosToStorage();
  }

  Future<void> toggleMultipleTodos(List<String> ids, bool isCompleted) async {
    await Future.delayed(_delay);

    // FIXED: Ensure todos are loaded
    if (_todos.isEmpty) {
      await _loadTodosFromStorage();
    }

    for (int i = 0; i < _todos.length; i++) {
      if (ids.contains(_todos[i].id)) {
        _todos[i] = _todos[i].copyWith(
          isCompleted: isCompleted,
          updatedAt: DateTime.now(),
        );
      }
    }

    // FIXED: Save to persistent storage
    await _saveTodosToStorage();
  }

  // Search todos (GET /api/todos/search?q=...)
  Future<List<Todo>> searchTodos(String query) async {
    await Future.delayed(_delay);

    // FIXED: Ensure todos are loaded
    if (_todos.isEmpty) {
      await _loadTodosFromStorage();
    }

    if (query.isEmpty) return List.from(_todos);

    final lowerQuery = query.toLowerCase();
    return _todos.where((todo) {
      return todo.title.toLowerCase().contains(lowerQuery) ||
          todo.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Get statistics
  Future<Map<String, dynamic>> getStats() async {
    await Future.delayed(_delay);

    // FIXED: Ensure todos are loaded
    if (_todos.isEmpty) {
      await _loadTodosFromStorage();
    }

    final total = _todos.length;
    final completed = _todos.where((todo) => todo.isCompleted).length;
    final pending = total - completed;

    final byPriority = <String, int>{};

    for (final todo in _todos) {
      byPriority[todo.priority] = (byPriority[todo.priority] ?? 0) + 1;
    }

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'completionRate': total > 0 ? completed / total : 0.0,
      'byPriority': byPriority,
    };
  }

  // FIXED: Initialize with sample data only if storage is empty
  Future<void> initializeSampleData() async {
    await _initPrefs();
    await _loadTodosFromStorage();

    // Only create sample data if no todos exist in storage
    if (_todos.isEmpty) {
      print('No existing todos found, creating sample data...');

      final sampleTodos = [
        Todo(
          id: '1',
          title: 'Welcome to Re-Todo! 🎉',
          description:
              'This is your first sample todo. You can edit, complete, or delete it.',
          isCompleted: false,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          priority: 'medium',
          dueDate: DateTime.now().add(const Duration(days: 2)),
        ),
      ];

      _todos.addAll(sampleTodos);
      await _saveTodosToStorage();
      print('Sample data created and saved');
    } else {
      print('Existing todos found, skipping sample data creation');
    }
  }

  // FIXED: Add method to clear all data (useful for testing/debugging)
  Future<void> clearAllData() async {
    await _initPrefs();
    await _prefs!.remove(_todosKey);
    _todos.clear();
    print('All todo data cleared from storage');
  }

  // FIXED: Add method to export data (useful for backup)
  Future<String> exportData() async {
    if (_todos.isEmpty) {
      await _loadTodosFromStorage();
    }

    final Map<String, dynamic> exportData = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'todosCount': _todos.length,
      'todos': _todos.map((todo) => todo.toJson()).toList(),
    };

    return json.encode(exportData);
  }

  // FIXED: Add method to import data (useful for restore)
  Future<bool> importData(String jsonData) async {
    try {
      final Map<String, dynamic> importData = json.decode(jsonData);

      if (importData['todos'] != null) {
        final List<dynamic> todosList = importData['todos'];
        final List<Todo> importedTodos =
            todosList.map((todoMap) => Todo.fromJson(todoMap)).toList();

        _todos = importedTodos;
        await _saveTodosToStorage();

        print('Successfully imported ${_todos.length} todos');
        return true;
      }

      return false;
    } catch (e) {
      print('Error importing data: $e');
      return false;
    }
  }

  // FIXED: Add method to get storage info (useful for debugging)
  Future<Map<String, dynamic>> getStorageInfo() async {
    await _initPrefs();

    final String? todosJson = _prefs!.getString(_todosKey);
    final int storageSize = todosJson?.length ?? 0;

    return {
      'hasData': todosJson != null,
      'storageSize': storageSize,
      'todosInMemory': _todos.length,
      'lastModified': todosJson != null ? 'Available' : 'No data',
    };
  }
}
