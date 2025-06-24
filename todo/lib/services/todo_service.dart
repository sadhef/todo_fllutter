import 'dart:convert';
import '../models/todo.dart';

// This simulates localStorage/sessionStorage from web development
// In a real app, you'd use SharedPreferences or SQLite
class TodoService {
  static final TodoService _instance = TodoService._internal();
  factory TodoService() => _instance;
  TodoService._internal();

  // In-memory storage (similar to a simple state store)
  final List<Todo> _todos = [];

  // Simulated async operations (like API calls)
  static const Duration _delay = Duration(milliseconds: 300);

  // Get all todos (GET /api/todos)
  Future<List<Todo>> getAllTodos() async {
    await Future.delayed(_delay); // Simulate network delay
    return List.from(_todos);
  }

  // Get todos by filter (GET /api/todos?filter=...)
  Future<List<Todo>> getTodosByFilter({
    bool? isCompleted,
    String? priority,
  }) async {
    await Future.delayed(_delay);

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

    final newTodo = todo.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
    );

    _todos.add(newTodo);
    return newTodo;
  }

  // Update todo (PUT /api/todos/:id)
  Future<Todo> updateTodo(String id, Todo updatedTodo) async {
    await Future.delayed(_delay);

    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) {
      throw Exception('Todo not found');
    }

    final updated = updatedTodo.copyWith(id: id, updatedAt: DateTime.now());

    _todos[index] = updated;
    return updated;
  }

  // Toggle todo completion (PATCH /api/todos/:id/toggle)
  Future<Todo> toggleTodo(String id) async {
    await Future.delayed(_delay);

    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) {
      throw Exception('Todo not found');
    }

    final updated = _todos[index].copyWith(
      isCompleted: !_todos[index].isCompleted,
      updatedAt: DateTime.now(),
    );

    _todos[index] = updated;
    return updated;
  }

  // Delete todo (DELETE /api/todos/:id)
  Future<void> deleteTodo(String id) async {
    await Future.delayed(_delay);

    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) {
      throw Exception('Todo not found');
    }

    _todos.removeAt(index);
  }

  // Bulk operations
  Future<void> deleteMultipleTodos(List<String> ids) async {
    await Future.delayed(_delay);
    _todos.removeWhere((todo) => ids.contains(todo.id));
  }

  Future<void> toggleMultipleTodos(List<String> ids, bool isCompleted) async {
    await Future.delayed(_delay);

    for (int i = 0; i < _todos.length; i++) {
      if (ids.contains(_todos[i].id)) {
        _todos[i] = _todos[i].copyWith(
          isCompleted: isCompleted,
          updatedAt: DateTime.now(),
        );
      }
    }
  }

  // Search todos (GET /api/todos/search?q=...)
  Future<List<Todo>> searchTodos(String query) async {
    await Future.delayed(_delay);

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

  // Initialize with sample data (empty by default)
  Future<void> initializeSampleData() async {
    // Start with empty todos - no sample data
    // User will create their own todos
  }
}
