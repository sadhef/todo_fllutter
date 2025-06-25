import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chatbot_provider.dart';
import '../screens/chatbot_screen.dart';
import '../theme/app_theme.dart';

class ChatBotWidget extends StatelessWidget {
  const ChatBotWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatBotProvider>(
      builder: (context, chatProvider, child) {
        return FloatingActionButton(
          heroTag: "chatbot_fab",
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ChatBotScreen()),
            );
          },
          backgroundColor: Colors.orange,
          child: const Text('🍪', style: TextStyle(fontSize: 20)),
        );
      },
    );
  }
}

class ChatBotBadge extends StatelessWidget {
  final Widget child;

  const ChatBotBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatBotProvider>(
      builder: (context, chatProvider, _) {
        // You can add notification badges here if needed
        return child;
      },
    );
  }
}
