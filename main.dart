import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Groq Chat Bot (Direct)',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    // Optional: Start with a system message for better behavior
    {"role": "system", "content": "You are a helpful and friendly assistant."}
  ];
  bool _isLoading = false;

  // ⚠️ PUT YOUR GROQ API KEY HERE (Keep it secret!)
  final String groqApiKey = "gsk_2DqI"; // ← CHANGE THIS

  final String groqUrl = "https://api.groq.com/openai/v1/chat/completions";

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text.trim();
    setState(() {
      _messages.add({"role": "user", "content": userMessage});
      _isLoading = true;
    });
    _controller.clear();

    // Prepare messages in the format Groq expects
    final List<Map<String, String>> messagesForApi = _messages
        .map((m) => {"role": m["role"] as String, "content": m["content"] as String})
        .toList();

    try {
      final response = await http.post(
        Uri.parse(groqUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $groqApiKey",
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant", // or mixtral-8x7b-32768, llama3-8b-8192, etc.
          "messages": messagesForApi,
          "temperature": 0.8,
          "max_tokens": 2048,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final botReply = data["choices"][0]["message"]["content"] as String;

        setState(() {
          _messages.add({"role": "assistant", "content": botReply});
        });
      } else {
        _showError("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      _showError("Network error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      _messages.add({"role": "assistant", "content": "⚠️ $message"});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat Bot "),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                // Skip system message from display
                if (msg["role"] == "system") return const SizedBox.shrink();

                final isUser = msg["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(12.0),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.deepPurple[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["content"] as String,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.deepPurple,
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
