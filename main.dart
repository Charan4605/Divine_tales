import 'package:flutter/material.dart';
import 'chat_page.dart';
void main() {
  runApp(const DivineTalesApp());
}

class DivineTalesApp extends StatelessWidget {
  const DivineTalesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Divine Tales',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home:   ChatPage(),
      debugShowCheckedModeBanner: false,  // ✅ Removes debug banner
// Directly show ChatPage
    );
  }
}
