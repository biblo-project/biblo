// lib/notification_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:biblo/main.dart'; // Import your main.dart file to access navigatorKey

class NotificationService {
  WebSocketChannel? _channel;

  // Notice: No BuildContext is passed here anymore! Completely clean.
  void initialize(int userId) {
    final wsUrl = Uri.parse('ws://10.0.2.2:8000/web-socket/notifications/$userId');
    _channel = WebSocketChannel.connect(wsUrl);

    print("Connecting to Notification Web Socket for User $userId...");

    _channel!.stream.listen((message) {
      try {
        final Map<String, dynamic> data = jsonDecode(message);

        if (data['type'] == 'POPUP_NOTIFICATION') {
          // 1. Grab the current global active context safely from the navigation stack
          final currentContext = navigatorKey.currentContext;

          // 2. Explicitly guard check: verify the layout tree is fully alive and mounted
          if (currentContext != null && currentContext.mounted) {
            _showRecommendationDialog(currentContext, data);
          } else {
            print("Skipping dialog: Target layout view is no longer mounted.");
          }
        }
      } catch (e) {
        print("Error reading notification frame: $e");
      }
    }, onError: (error) {
      print("WebSocket error encountered: $error");
    });
  }

  void _showRecommendationDialog(BuildContext context, Map<String, dynamic> data) {
    final String questionText = data['question'];
    final List<dynamic> buttons = data['buttons'];

    final Map<String, dynamic> yesButton = buttons[0];
    final Map<String, dynamic> noButton = buttons[1];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          title: const Text("Recommended For You", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(questionText, style: const TextStyle(fontSize: 16.0)),
          actions: [
            TextButton(
              onPressed: () {
                _channel?.sink.add(jsonEncode({"action": noButton['action']}));
                Navigator.of(dialogContext).pop();
              },
              child: Text(noButton['text'], style: const TextStyle(color: Colors.grey, fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                _channel?.sink.add(jsonEncode({
                  "action": yesButton['action'],
                  "book_id": yesButton['book_id']
                }));
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: Text(yesButton['text'], style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  void disconnect() {
    _channel?.sink.close();
  }
}