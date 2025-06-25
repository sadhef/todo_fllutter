import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/todo.dart';
import '../services/todo_service.dart';

class ChatBotService {
  static final ChatBotService _instance = ChatBotService._internal();
  factory ChatBotService() => _instance;
  ChatBotService._internal();

  static const String _geminiApiKey = 'AIzaSyDlbDag0db5FTrAhUvrWfRV33McIddr1q0';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  final TodoService _todoService = TodoService();

  Future<String> sendMessage(String userMessage) async {
    try {
      // Get current todos for context
      final todos = await _todoService.getAllTodos();
      final contextPrompt = _buildEnhancedContextPrompt(userMessage, todos);

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': contextPrompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048, // Increased for longer responses
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        } else {
          return "I'm sorry, I couldn't generate a response. Please try again.";
        }
      } else {
        print('Gemini API Error: ${response.statusCode} - ${response.body}');
        return "I'm experiencing some technical difficulties. Please try again later.";
      }
    } catch (e) {
      print('ChatBot Service Error: $e');
      return "I'm sorry, something went wrong. Please check your internet connection and try again.";
    }
  }

  String _buildEnhancedContextPrompt(String userMessage, List<Todo> todos) {
    final todoStats = _getTodoStats(todos);
    final recentTodos = todos
        .take(5)
        .map((t) =>
            '- ${t.title} (${t.isCompleted ? "completed" : "pending"}, Priority: ${t.priority})')
        .join('\n');
    final overdueTodos = todos
        .where((t) =>
            !t.isCompleted &&
            t.dueDate != null &&
            t.dueDate!.isBefore(DateTime.now()))
        .toList();

    // Detect if this is a task-related query or general conversation
    final isTaskRelated = _isTaskRelatedQuery(userMessage);

    return """
You are Cookie 🍪, a versatile AI assistant that combines the capabilities of ChatGPT with specialized task management features for a todo app called "Re-Todo".

DUAL PERSONALITY:
1. **General AI Assistant**: Answer any questions, have conversations, help with coding, explain concepts, provide advice, be creative, solve problems, etc. - just like ChatGPT.
2. **Task Manager Helper**: When users ask about their todos, productivity, or task management, provide specialized assistance using their current task data.

Current User's Task Context (use ONLY when relevant to their query):
- Total todos: ${todoStats['total']}
- Completed: ${todoStats['completed']}
- Pending: ${todoStats['pending']}
- Completion rate: ${(todoStats['completionRate'] * 100).toStringAsFixed(1)}%
- Overdue tasks: ${overdueTodos.length}

Recent todos:
$recentTodos

${overdueTodos.isNotEmpty ? 'OVERDUE TASKS:\n${overdueTodos.map((t) => '⚠️ ${t.title} (due ${_formatDate(t.dueDate!)})').join('\n')}\n' : ''}

User message: "$userMessage"

RESPONSE GUIDELINES:

**For Task/Productivity Related Queries:**
- Reference their actual todo data
- Provide specific, actionable advice
- Suggest task prioritization
- Offer productivity tips
- Mention overdue tasks if relevant
- Be encouraging about their progress

**For General Queries:**
- Act like ChatGPT - knowledgeable, helpful, conversational
- Answer questions on any topic (science, coding, history, etc.)
- Help with creative tasks, explanations, problem-solving
- Provide detailed, informative responses
- Don't mention todos unless specifically asked

**Always:**
- Be friendly, warm, and personable
- Use emojis appropriately to enhance communication
- Keep responses engaging and helpful
- Adapt your tone to match the user's query
- If unsure whether it's task-related, ask for clarification

Query Classification: ${isTaskRelated ? "TASK-RELATED" : "GENERAL"}

Respond as Cookie:
""";
  }

  bool _isTaskRelatedQuery(String message) {
    final taskKeywords = [
      'todo',
      'todos',
      'task',
      'tasks',
      'productivity',
      'complete',
      'completed',
      'pending',
      'overdue',
      'due',
      'priority',
      'progress',
      'work',
      'schedule',
      'organize',
      'plan',
      'focus',
      'motivation',
      'deadline',
      'reminder',
      'manage',
      'management',
      'efficient',
      'goals',
      'achievement',
      'finish',
      'assignment',
      'project',
      'checklist',
      'routine',
      'habit',
      'busy',
      'procrastination',
      'time management',
      'next task',
      'what should i',
      'help me with',
      'suggest',
      'recommend'
    ];

    final lowercaseMessage = message.toLowerCase();
    return taskKeywords.any((keyword) => lowercaseMessage.contains(keyword));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'today';
    if (difference == 1) return 'yesterday';
    if (difference > 1) return '$difference days ago';

    final future = date.difference(now).inDays;
    if (future == 0) return 'today';
    if (future == 1) return 'tomorrow';
    return 'in $future days';
  }

  Map<String, dynamic> _getTodoStats(List<Todo> todos) {
    final total = todos.length;
    final completed = todos.where((todo) => todo.isCompleted).length;
    final pending = total - completed;

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'completionRate': total > 0 ? completed / total : 0.0,
    };
  }

  // Enhanced helper methods for different types of requests
  Future<String> getGeneralHelp() async {
    return """
Hi! I'm Cookie 🍪 - your versatile AI assistant! I can help you with:

**📝 Task Management:**
• Analyze your todos and provide productivity advice
• Suggest which tasks to prioritize
• Help you stay motivated and organized
• Track your progress and celebrate achievements

**🤖 General AI Assistant:**
• Answer questions on any topic
• Help with coding and technical problems
• Explain complex concepts
• Provide creative ideas and solutions
• Have casual conversations
• Help with learning and research

**🚀 Quick Actions:**
• "What should I work on next?" - Get task suggestions
• "How am I doing?" - Check your progress
• "Explain quantum physics" - Get explanations
• "Help me write code" - Programming assistance
• "Tell me a joke" - Light conversation

What would you like help with today?
""";
  }

  Future<String> getTaskSuggestion() async {
    final todos = await _todoService.getAllTodos();
    final pendingTodos = todos.where((t) => !t.isCompleted).toList();

    if (pendingTodos.isEmpty) {
      return "🎉 Amazing! You've completed all your tasks! How about:\n\n• Planning something new for tomorrow\n• Taking a well-deserved break\n• Reviewing your accomplishments\n• Setting new goals\n\nYou're doing fantastic! 🌟";
    }

    // Check for overdue tasks first
    final overdueTodos = pendingTodos
        .where((t) => t.dueDate != null && t.dueDate!.isBefore(DateTime.now()))
        .toList();
    if (overdueTodos.isNotEmpty) {
      return "⚠️ **URGENT**: You have ${overdueTodos.length} overdue task(s)!\n\nI'd strongly recommend tackling this first:\n\n🔥 **${overdueTodos.first.title}**\n• Priority: ${overdueTodos.first.priority}\n• Was due: ${_formatDate(overdueTodos.first.dueDate!)}\n\nLet's get this done to get back on track! 💪";
    }

    // Suggest based on priority and due dates
    final highPriority =
        pendingTodos.where((t) => t.priority == 'high').toList();
    if (highPriority.isNotEmpty) {
      return "🎯 **Perfect timing!** I recommend focusing on this high-priority task:\n\n🔥 **${highPriority.first.title}**\n• Priority: High\n• ${highPriority.first.dueDate != null ? 'Due: ${_formatDate(highPriority.first.dueDate!)}' : 'No deadline set'}\n\nHigh-priority tasks deserve your immediate attention. You've got this! 🚀";
    }

    // Sort by due date for medium/low priority
    pendingTodos.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    return "💡 **Here's my suggestion:**\n\n✨ **${pendingTodos.first.title}**\n• Priority: ${pendingTodos.first.priority}\n• ${pendingTodos.first.dueDate != null ? 'Due: ${_formatDate(pendingTodos.first.dueDate!)}' : 'No deadline'}\n\nThis looks like a great task to build momentum! Starting with manageable tasks often leads to completing more. 🌟";
  }

  Future<String> getMotivationalMessage() async {
    final todos = await _todoService.getAllTodos();
    final stats = _getTodoStats(todos);
    final completionRate = stats['completionRate'] as double;

    final motivationalQuotes = [
      "The secret to getting ahead is getting started. 🚀",
      "Progress, not perfection, is the goal. ⭐",
      "Small steps daily lead to big changes yearly. 🌱",
      "You're capable of amazing things! 💪",
      "Focus on progress, celebrate every win! 🎉",
      "Consistency beats perfection every time. ⚡",
    ];

    final randomQuote = motivationalQuotes[
        DateTime.now().millisecond % motivationalQuotes.length];

    if (completionRate >= 0.8) {
      return "🌟 **You're absolutely crushing it!** \n\n📊 ${(completionRate * 100).toStringAsFixed(1)}% completion rate is fantastic!\n\n✨ You've completed ${stats['completed']} out of ${stats['total']} tasks. Your dedication and consistency are truly inspiring!\n\n💡 *$randomQuote*\n\nKeep up this amazing momentum! 🚀";
    } else if (completionRate >= 0.5) {
      return "👍 **You're making excellent progress!** \n\n📈 You're more than halfway there with ${(completionRate * 100).toStringAsFixed(1)}% completion!\n\n🎯 ${stats['completed']} tasks done, ${stats['pending']} to go. You're building great momentum!\n\n💡 *$randomQuote*\n\nStay focused - you're doing great! 💪";
    } else if (stats['completed'] > 0) {
      return "🚀 **Every journey starts with a single step!** \n\n🎉 You've got ${stats['completed']} task(s) completed - that's something to be proud of!\n\n💪 ${stats['pending']} tasks remaining means ${stats['pending']} opportunities to feel accomplished!\n\n💡 *$randomQuote*\n\nRemember: Progress is progress, no matter how small! ✨";
    } else {
      return "🌟 **Fresh start, endless possibilities!** \n\n✨ You have ${stats['total']} tasks ready to be conquered!\n\n🎯 Every expert was once a beginner. Every pro was once an amateur. The key is just starting!\n\n💡 *$randomQuote*\n\nLet's turn that first task into your first victory! 🚀";
    }
  }

  Future<String> getProductivityTips() async {
    final tips = [
      "🍅 **Pomodoro Technique**: Work for 25 minutes, then take a 5-minute break. Repeat 4 times, then take a longer break.",
      "🎯 **2-Minute Rule**: If something takes less than 2 minutes, do it immediately instead of adding it to your todo list.",
      "🧠 **Eat the Frog**: Tackle your most challenging or important task first thing in the morning when your energy is highest.",
      "📋 **Priority Matrix**: Use Urgent vs Important to categorize tasks. Focus on Important but Not Urgent tasks to prevent crises.",
      "⚡ **Time Blocking**: Assign specific time slots to different types of tasks. This helps maintain focus and prevents multitasking.",
      "🔄 **Batch Similar Tasks**: Group similar activities together (emails, calls, errands) to maintain flow and reduce context switching.",
      "📱 **Digital Minimalism**: Turn off non-essential notifications during focus time. Your phone should work for you, not against you.",
      "🎊 **Celebrate Small Wins**: Acknowledge every completed task. Positive reinforcement builds momentum and motivation.",
    ];

    final randomTip = tips[DateTime.now().millisecond % tips.length];

    return "💡 **Productivity Tip of the Moment:**\n\n$randomTip\n\n🌟 **Remember**: The best productivity system is the one you actually use consistently. Start small, build habits, and adjust as you learn what works for you!\n\nWant more personalized advice? Ask me about your specific tasks! 🍪";
  }
}
