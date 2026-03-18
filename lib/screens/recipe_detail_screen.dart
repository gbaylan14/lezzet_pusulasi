import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart'; // Paylaşım paketini ekledik

class RecipeDetailScreen extends StatelessWidget {
  final String recipeTitle;
  final String recipeContent;

  const RecipeDetailScreen({
    super.key,
    required this.recipeTitle,
    required this.recipeContent,
  });

  // Favoriye Ekleme Fonksiyonu
  void _favoriyeEkle(BuildContext context) {
    var box = Hive.box('favoriler');
    box.add({
      'title': recipeTitle,
      'content': recipeContent,
      'time': DateTime.now().toString(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tarif Favorilere Eklendi! 🌟")),
    );
  }

  // PAYLAŞMA FONKSİYONU
  void _tarifiPaylas() {
    // Arkadaşına gidecek mesajın formatı:
    final String mesaj = "🍳 Lezzet Pusulası'ndan Harika Bir Tarif!\n\n"
        "🍴 *${recipeTitle.toUpperCase()}*\n\n"
        "$recipeContent\n\n"
        "--- Bu tarif AI ile hazırlanmıştır ---";

    Share.share(mesaj);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        title: const Text("Tarif Detayı"),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // PAYLAŞ BUTONU
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFFE2725B)),
            onPressed: _tarifiPaylas,
          ),
          // FAVORİ BUTONU
          IconButton(
            icon: const Icon(Icons.star_border, color: Colors.orange),
            onPressed: () => _favoriyeEkle(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: MarkdownBody(
            data: recipeContent,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}