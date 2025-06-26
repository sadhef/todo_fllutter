import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../services/chatbot_service.dart';

class ChatBotProvider with ChangeNotifier {
  final ChatBotService _chatBotService = ChatBotService();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  static const String _messagesKey = 'chat_messages';

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;

  Future<void> initialize() async {
    await _loadMessagesFromStorage();
    if (_messages.isEmpty) {
      _addWelcomeMessage();
    }
  }

  void _addWelcomeMessage() {
    final welcomeMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: """Hi there!  I'm Cookie 🎀, your versatile AI assistant!

I can help you with:
• 📝 **Task Management** - Analyze your todos, suggest priorities, boost productivity
• 🤖 **General Questions** - Answer anything like ChatGPT (coding, explanations, ideas, etc.)
• 💡 **Creative Tasks** - Writing, brainstorming, problem-solving
• 🎯 **Learning** - Explain concepts, help with studies, provide tutorials

**Quick Start:**
• Ask about your tasks: "What should I work on?"
• Ask anything else: "Explain machine learning"
• Use the buttons above for common requests

What would you like help with today? 🚀""",
      type: MessageType.bot,
      timestamp: DateTime.now(),
    );
    _messages.add(welcomeMessage);
    _saveMessagesToStorage();
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      type: MessageType.user,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    _isTyping = true;
    notifyListeners();

    try {
      // Get bot response
      final botResponse = await _chatBotService.sendMessage(content);

      // Add bot message
      final botMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: botResponse,
        type: MessageType.bot,
        timestamp: DateTime.now(),
      );

      _messages.add(botMessage);
      await _saveMessagesToStorage();
    } catch (e) {
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content:
            "I'm sorry, I encountered an error. Please try again. I'm here to help with both your tasks and any other questions you might have! 🍪",
        type: MessageType.bot,
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> sendQuickAction(String action) async {
    String message;
    switch (action) {
      case 'task_suggestion':
        message = "What should I work on next?";
        break;
      case 'motivation':
        message = "I need some motivation to keep going!";
        break;
      case 'productivity_tips':
        message = "Can you give me some productivity tips?";
        break;
      case 'progress_review':
        message = "How am I doing with my tasks today?";
        break;
      case 'general_help':
        message = "How can you help me?";
        break;
      default:
        message = action;
    }
    await sendMessage(message);
  }

  void clearChat() {
    _messages.clear();
    _addWelcomeMessage();
    notifyListeners();
  }

  Future<void> _loadMessagesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString(_messagesKey);
      if (messagesJson != null) {
        final List<dynamic> messagesList = json.decode(messagesJson);
        _messages.clear();
        _messages
            .addAll(messagesList.map((json) => ChatMessage.fromJson(json)));
      }
    } catch (e) {
      print('Error loading chat messages: $e');
    }
  }

  Future<void> _saveMessagesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson =
          json.encode(_messages.map((msg) => msg.toJson()).toList());
      await prefs.setString(_messagesKey, messagesJson);
    } catch (e) {
      print('Error saving chat messages: $e');
    }
  }
}
