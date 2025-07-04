import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:chatgpt_ai/chatgpt_ai.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final ChatGPT chatGPT = ChatGPT(apiKey: dotenv.env['OPENAI_API_KEY']!);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatGPT AI Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ChatPage(chatGPT: chatGPT),
    );
  }
}

class ChatPage extends StatefulWidget {
  final ChatGPT chatGPT;
  ChatPage({required this.chatGPT});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  String _response = '';
  bool _isLoading = false;

  Future<void> sendMessage(String message) async {
    setState(() {
      _isLoading = true;
      _response = '';
    });

    try {
      final res = await widget.chatGPT.sendMessage(
        message,
        model: Model.gptTurbo,
      );

      setState(() {
        _response = res.choices.first.message.content;
      });
    } catch (e) {
      setState(() {
        _response = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ChatGPT AI Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(hintText: 'Type your message here'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : () => sendMessage(_controller.text),
              child: Text('Send'),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(child: SingleChildScrollView(child: Text(_response))),
          ],
        ),
      ),
    );
  }
}
