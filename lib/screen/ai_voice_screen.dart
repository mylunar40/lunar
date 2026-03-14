import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AiVoiceScreen extends StatefulWidget {
  const AiVoiceScreen({super.key});

  @override
  State<AiVoiceScreen> createState() => _AiVoiceScreenState();
}

class _AiVoiceScreenState extends State<AiVoiceScreen> {
  final TextEditingController messageController = TextEditingController();

  List<Map<String, dynamic>> messages = [];

  /// SEND TEXT MESSAGE
  void sendMessage() {
    String text = messageController.text.trim();

    if (text.isEmpty) return;

    setState(() {
      messages.add({
        "text": text,
        "isUser": true,
      });
    });

    messageController.clear();

    /// Fake AI reply
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        messages.add({
          "text": "I understand. Tell me more about how you feel.",
          "isUser": false,
        });
      });
    });
  }

  /// IMAGE PICKER
  Future pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        messages.add({
          "image": image.path,
          "isUser": true,
        });
      });
    }
  }

  /// DELETE CHAT
  void deleteChat() {
    setState(() {
      messages.clear();
    });
  }

  /// SAVE CHAT (demo)
  void saveChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Chat Saved")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lunar Voice AI"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveChat,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: deleteChat,
          ),
        ],
      ),
      body: Column(
        children: [
          /// CHAT AREA
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                bool isUser = messages[index]["isUser"] ?? false;

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.purple : Colors.grey[800],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: messages[index]["image"] != null
                        ? Image.file(
                            File(messages[index]["image"]),
                            width: 180,
                          )
                        : Text(
                            messages[index]["text"] ?? "",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),

          /// INPUT AREA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                /// IMAGE BUTTON
                IconButton(
                  icon: const Icon(Icons.add, size: 30),
                  onPressed: pickImage,
                ),

                /// TEXT FIELD
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: "Ask Lunar AI...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                /// MIC BUTTON (structure ready)
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () {
                    print("Mic pressed");
                  },
                ),

                /// SEND BUTTON
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
