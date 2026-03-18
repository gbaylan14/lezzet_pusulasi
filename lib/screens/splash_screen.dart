import 'package:flutter/material.dart';
import 'home_screen.dart'; // Birkaç saniye sonra buraya geçecek

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // 1. Logoyu yavaşça büyütüp küçülten animasyon ayarı
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // 2 saniye sürecek
      vsync: this,
    )..repeat(reverse: true); // Sürekli kalp gibi atsın

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    // 2. 3 saniye sonra otomatik olarak Ana Sayfaya geçiş
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0), // Uygulamamızın o tatlı krem rengi
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // BÜYÜYÜP KÜÇÜLEN LOGO
            ScaleTransition(
              scale: _animation,
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)
                  ]
                ),
                child: const Icon(Icons.restaurant_menu, size: 80, color: Color(0xFFE2725B)), // Şık restoran ikonu
              ),
            ),
            
            const SizedBox(height: 40),
            
            // UYGULAMA İSMİ
            const Text(
              "Lezzet Keşfi",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE2725B),
                letterSpacing: 2, // Harflerin arası biraz açık olsun
              ),
            ),
            
            const SizedBox(height: 10),
            
            // ALT BAŞLIK
            const Text(
              "Yapay Zeka Mutfak Asistanın",
              style: TextStyle(fontSize: 16, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}