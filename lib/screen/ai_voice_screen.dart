 import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AiVoiceScreen extends StatefulWidget {
  const AiVoiceScreen({super.key});

  @override
  State<AiVoiceScreen> createState() => _AiVoiceScreenState();
}

class _AiVoiceScreenState extends State<AiVoiceScreen> {

  TextEditingController messageController = TextEditingController();

  stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;

  List<Map<String, String>> messages = [];

  String status = "Hello, I am Lunar AI. How can I help you?";

  void startListening() async {

    bool available = await speech.initialize();

    if (available) {
      setState(() {
        isListening = true;
      });

      speech.listen(
        onResult: (result) {
          setState(() {
            messageController.text = result.recognizedWords;
          });
        },
      );
    }
  }

  Future<String> askAI(String message) async {

    final response = await http.post(
      Uri.parse("https://api.openai.com/v1/chat/completions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer YOUR_OPENAI_API_KEY"
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {"role": "user", "content": message}
        ]
      }),
    );

    final data = jsonDecode(response.body);

    return data["choices"][0]["message"]["content"];
  }

  void sendMessage() async {

    String userMessage = messageController.text;

    if (userMessage.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": userMessage});
      status = "Thinking...";
    });

    messageController.clear();

    String reply = await askAI(userMessage);

    setState(() {
      messages.add({"role": "ai", "text": reply});
      status = reply;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Lunar Voice AI"),
      ),

      body: Column(
        children: [

          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {

                bool isUser = messages[index]["role"] == "user";

                return Container(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,

                  padding: const EdgeInsets.all(10),

                  child: Container(
                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.purple
                          : Colors.grey.shade300,

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Text(
                      messages[index]["text"] ?? "",
                      style: TextStyle(
                        color:
                            isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(10),

            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: messageController,

                    decoration: const InputDecoration(
                      hintText: "Ask Lunar AI...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: startListening,
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}