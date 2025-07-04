import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GPT-4o Chat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const ChatScreen(),
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
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  Future<void> _sendMessage(String userInput) async {
    if (_isLoading || userInput.trim().isEmpty) return;

    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      _addMessage('assistant', '❌ API key পাওয়া যায়নি। .env ফাইলটি চেক করুন।');
      return;
    }

    _addMessage('user', userInput);
    setState(() => _isLoading = true);

    try {
      final messagesForAPI = [
        {
          'role': 'system',
          'content': '''
You are an empathetic, warm, and helpful AI. 
Speak naturally, mix Bengali and English as needed. Be human-like, kind, and respectful.
Respond in a way that makes the user feel emotionally supported and understood.
          '''
        },
        ..._messages.map((m) => {
              'role': m['role']!,
              'content': m['text']!,
            }),
        {
          'role': 'user',
          'content': userInput,
        }
      ];

      final response = await http.post(
        Uri.parse("https://api.openai.com/v1/chat/completions"),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4o',
          'messages': messagesForAPI,
          'temperature': 0.7,
          'max_tokens': 2048,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final reply = data['choices'][0]['message']['content'].trim();
        _addMessage('assistant', reply);
      } else {
        _addMessage('assistant', '❌ ত্রুটি: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      _addMessage('assistant', '❌ ত্রুটি: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addMessage(String role, String text) {
    setState(() {
      _messages.add({'role': role, 'text': text});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🤖 GPT-4o Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (_, index) {
                final m = _messages[index];
                final isUser = m['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(ClipboardData(text: m['text'] ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✅ কপি করা হয়েছে!')),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 300),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFF1E3A8A) : Colors.grey[800],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SelectableText(
                        m['text'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'NotoSansBengali',
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 6,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: (_) {},
                      decoration: const InputDecoration(
                        hintText: 'আপনার প্রশ্ন লিখুন...',
                        hintStyle: TextStyle(color: Colors.white70),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      _sendMessage(_controller.text);
                      _controller.clear();
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
