import 'package:divine_tales/const.dart';
import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<ChatMessage> _messages = [];
  final List<Map<String, dynamic>> _chatHistory = [];
  bool _isLoading = false;
  bool _isTyping = false;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  int? _editingIndex;

  final ChatUser _currentUser = ChatUser(
    id: "1",
    firstName: "Charan",
  );

  final ChatUser _gptUser = ChatUser(
    id: "2",
    firstName: "SageBot",
  );

  Future<void> _sendMessage(ChatMessage message) async {
    setState(() {
      _messages.add(message);
      _chatHistory.add({
        "role": "USER",
        "message": message.text,
        "timestamp": DateTime.now().toIso8601String()
      });
      _isLoading = true;
      _isTyping = true;
    });

    _controller.clear();

    // 👇 Add this logic for basic greetings
    final lowerText = message.text.toLowerCase().trim();
    if (['hi', 'hello', 'hey', 'namaste', 'yo'].contains(lowerText)) {
      final greetingReply = ChatMessage(
        text: "Namaste, Charan 🙏 How can I help you today?",
        user: _gptUser,
        createdAt: DateTime.now(),
      );

      setState(() {
        _messages.add(greetingReply);
        _chatHistory.add({
          "role": "CHATBOT",
          "message": greetingReply.text,
          "timestamp": DateTime.now().toIso8601String()
        });
        _isLoading = false;
        _isTyping = false;
      });
      return; // ⛔ Don't call the API
    }

    // Call API only if not a basic greeting
    await _receiveMessage(message.text);
  }

  Future<void> _receiveMessage(String message) async {
    try {
      const apiUrl = 'https://api.cohere.com/v1/chat';

      final Map<String, dynamic> requestBody = {
        "message": message,
        "model": "02ebdbfb-f807-493a-b523-c9beb73726b8-ft",
        "chat_history": _chatHistory.map((msg) => {
          "role": msg["role"],
          "message": msg["message"]
        }).toList(),
        "temperature": 0.7,
        "max_tokens": 700,
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $COHERE_API_KEY",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final botResponse = responseData['text'] ?? "No response";

        final botMessage = ChatMessage(
          text: botResponse,
          user: _gptUser,
          createdAt: DateTime.now(),
        );

        setState(() {
          _messages.add(botMessage);
          _chatHistory.add({
            "role": "CHATBOT",
            "message": botResponse,
            "timestamp": DateTime.now().toIso8601String()
          });
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: "Error: ${response.body}",
            user: _gptUser,
            createdAt: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Error: $e",
          user: _gptUser,
          createdAt: DateTime.now(),
        ));
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isTyping = false;
      });
    }
  }

  // ✅ Summarize chat functionality
  Future<void> _summarizeChat() async {
    if (_chatHistory.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      const apiUrl = 'https://api.cohere.com/v1/chat';

      final Map<String, dynamic> requestBody = {
        "message": "Summarize this conversation concisely.",
        "model": "02ebdbfb-f807-493a-b523-c9beb73726b8-ft",
        "chat_history": _chatHistory.map((msg) => {
          "role": msg["role"],
          "message": msg["message"]
        }).toList(),
        "temperature": 0.5,
        "max_tokens": 500,
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $COHERE_API_KEY",
          "Content-Type": "application/json",
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final summary = responseData['text'] ?? "No summary available";

        setState(() {
          _messages.add(ChatMessage(
            text: "📊 Summary:\n$summary",
            user: _gptUser,
            createdAt: DateTime.now(),
          ));
        });
      } else {
        setState(() {
          _messages.add(ChatMessage(
            text: "Failed to generate summary: ${response.body}",
            user: _gptUser,
            createdAt: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Error summarizing chat: $e",
          user: _gptUser,
          createdAt: DateTime.now(),
        ));
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    return DateFormat('MMM d, hh:mm a').format(dateTime);
  }

  void _editMessage(int index) {
    setState(() {
      _editingIndex = index;
      _editController.text = _messages[index].text;
    });
  }

  void _saveEditedMessage() {
    if (_editingIndex != null && _editController.text.isNotEmpty) {
      final editedMessage = _editController.text;

      setState(() {
        _messages[_editingIndex!] = ChatMessage(
          text: editedMessage,
          user: _messages[_editingIndex!].user,
          createdAt: _messages[_editingIndex!].createdAt,
        );

        _chatHistory[_editingIndex!] = {
          "role": "USER",
          "message": editedMessage,
          "timestamp": DateTime.now().toIso8601String(),
        };

        _editingIndex = null;
        _isTyping = true;
      });

      _receiveMessage(editedMessage);
    }
  }

  void _cancelEdit() {
    setState(() => _editingIndex = null);
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background1.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Column(
              children: [
                // ✅ Summarize Chat Button
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: _summarizeChat,
                    icon: const Icon(Icons.summarize, color: Colors.white),
                    label: const Text("Summarize Chat"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message.user.id == _currentUser.id;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 12),
                        child: Column(
                          crossAxisAlignment: isUser
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Colors.cyan[300]
                                    : Colors.purple[200],
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Text(message.text),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // ✅ Message Input Field
                _buildMessageInput(),
                // ✅ Disclaimer Text below input field
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "⚠️ Not for general use. Discuss your problems only.",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _editingIndex != null ? _editController : _controller,
              decoration: InputDecoration(
                hintText: _editingIndex != null ? "Edit message..." : "Type a message...",
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send, color: Colors.cyan[400]),
            onPressed: () {
              if (_editingIndex != null) {
                _saveEditedMessage();
              } else {
                if (_controller.text.isNotEmpty) {
                  final message = ChatMessage(
                    text: _controller.text,
                    user: _currentUser,
                    createdAt: DateTime.now(),
                  );
                  _sendMessage(message);
                }
              }
            },
          ),
        ],
      ),
    );
  }

}
