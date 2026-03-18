import 'package:flutter/material.dart';
import 'recipe_detail_screen.dart';
import '../services/api_service.dart';

class LoadingScreen extends StatefulWidget {
  final List<String> ingredients;

  const LoadingScreen({super.key, required this.ingredients});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _getAiRecipe();
  }

  void _getAiRecipe() async {
    try {
      // Metot adı düzeltildi: generateRecipe → generateAndSaveRecipe
      final String recipe =
          await ApiService.generateAndSaveRecipe(widget.ingredients);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(
              recipeTitle: "Senin İçin Hazırlanan Tarif",
              recipeContent: recipe,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Tarif alınırken bir hata oluştu: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _controller,
              child: const Icon(
                Icons.restaurant_menu,
                size: 100,
                color: Color(0xFFE2725B),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Lezzet Pusulası dönüyor...",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A5D4E),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "${widget.ingredients.join(', ')} ile en harika tarifler hazırlanıyor. Azıcık sabır!",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 50),
            const SizedBox(
              width: 150,
              child: LinearProgressIndicator(
                color: Color(0xFFE2725B),
                backgroundColor: Color(0xFFE8F0E6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}