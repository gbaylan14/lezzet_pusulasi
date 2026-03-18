import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

class AIWizardScreen extends StatefulWidget {
  const AIWizardScreen({super.key});

  @override
  State<AIWizardScreen> createState() => _AIWizardScreenState();
}

class _AIWizardScreenState extends State<AIWizardScreen> {
  final TextEditingController _ingredientsController = TextEditingController();
  bool _isLoading = false;
  String _generatedRecipe = "";

  // 🔥 GEMINI API ANAHTARIN (Buraya kendi anahtarını yapıştır!)
  final String _apiKey = "AIzaSyBCijOcoYUsAIoHgxfjqu7d9NYuWSAcIeU";

  Future<void> _generateRecipe() async {
    if (_ingredientsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen elindeki malzemeleri yaz! 🧐")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedRecipe = "";
    });

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
      
      // Şık ve profesyonel bir komut (Prompt)
      final prompt = """
      Sen 'Lezzet Pusulası' uygulamasının uzman şefisin. 
      Kullanıcının elindeki şu malzemelerle: ${_ingredientsController.text} 
      yaratıcı, lezzetli ve pratik bir tarif üret. 
      Tarifi şu formatta ver:
      1. Tarife havalı bir isim ver.
      2. Hazırlanma süresini belirt.
      3. Malzemeleri liste halinde yaz.
      4. Hazırlanış aşamalarını madde madde anlat.
      5. En sona şefin özel bir ipucunu ekle.
      Dili samimi ve iştah açıcı olsun. Markdown formatını kullan.
      """;

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      setState(() {
        _generatedRecipe = response.text ?? "Üzgünüm, pusula bir hata yaptı. Tekrar dener misin?";
      });
    } catch (e) {
      setState(() {
        _generatedRecipe = "Hata oluştu: $e\nLütfen API anahtarını kontrol et!";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFE2725B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "AI Tarif Sihirbazı 🪄",
          style: TextStyle(color: Color(0xFFE2725B), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. GİRİŞ KARTI
            _buildInputCard(),
            const SizedBox(height: 25),

            // 2. YÜKLENİYOR VEYA SONUÇ EKRANI
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFFE2725B)),
                    SizedBox(height: 15),
                    Text("Pusula lezzetleri tarıyor... 🧭✨", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else if (_generatedRecipe.isNotEmpty)
              _buildResultCard()
            else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        children: [
          const Text(
            "Dolapta neler var? 🧐",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _ingredientsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Örn: Tavuk, krema, mantar, soğan...",
              filled: true,
              fillColor: const Color(0xFFFDF7F0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : _generateRecipe,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE2725B),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("Tarif Üret 🚀", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE2725B).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Pusulanın Tarifi ✨", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE2725B))),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Colors.grey),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generatedRecipe));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tarif kopyalandı! 📋")));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.grey),
                    onPressed: () => Share.share("Lezzet Pusulası AI'dan harika bir tarif!\n\n$_generatedRecipe"),
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          MarkdownBody(
            data: _generatedRecipe,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
              h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFE2725B)),
              h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
              listBullet: const TextStyle(color: Color(0xFFE2725B), fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 50),
        Icon(Icons.restaurant_menu_rounded, size: 80, color: Colors.orange.withOpacity(0.2)),
        const SizedBox(height: 15),
        const Text(
          "Eldeki malzemeleri yukarı yaz,\nsihirli dokunuşu bekle! ✨",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ],
    );
  }
}