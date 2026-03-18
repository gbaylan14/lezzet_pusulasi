import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'loading_screen.dart'; // Pusula ekranını çağırıyoruz

class AIWizardScreen extends StatefulWidget {
  const AIWizardScreen({super.key});

  @override
  State<AIWizardScreen> createState() => _AIWizardScreenState();
}

class _AIWizardScreenState extends State<AIWizardScreen> {
  final List<String> _selectedIngredients = [];
  final TextEditingController _ingredientController = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  // YENİ: KATEGORİ SEÇENEKLERİ
  String? _secilenKategori = "Farketmez (Bana Bırak)";
  final List<String> _anaKategoriler = [
    "Farketmez (Bana Bırak)",
    "Kahvaltı", "Çorbalar", "Ana Yemekler", "Salatalar", 
    "Mezeler", "Atıştırmalıklar", "Makarna & Pilav", 
    "Tatlılar", "İçecekler", "Fast Food", 
    "Sağlıklı & Diyet", "Pratik Tarifler"
  ];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _ingredientController.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  final List<String> _commonIngredients = [
    "Domates", "Tavuk", "Yumurta", "Patates", "Soğan", 
    "Sarımsak", "Peynir", "Kıyma", "Makarna", "Yoğurt", "Ispanak"
  ];

  void _generate() {
    if (_selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen en az bir malzeme seçin veya ekleyin!")),
      );
      return;
    }

    // Seçilen malzemelerin bir kopyasını oluşturuyoruz
    List<String> promptListesi = List.from(_selectedIngredients);

    // Eğer kullanıcı özel bir kategori seçtiyse, bunu yapay zekaya bir kural olarak ekliyoruz
    if (_secilenKategori != null && _secilenKategori != "Farketmez (Bana Bırak)") {
      // Listenin en başına "Kategori: Tatlılar" şeklinde ekliyoruz
      promptListesi.insert(0, "Kategori: $_secilenKategori");
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoadingScreen(ingredients: promptListesi),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        title: const Text("Buzdolabı Sihirbazı"), 
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // YENİ: KATEGORİ SEÇİM ALANI
            const Text("🍽️ Ne Tür Bir Tarif İstiyorsun?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A5D4E))),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.shade200, width: 2)
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _secilenKategori,
                  icon: const Icon(Icons.arrow_drop_down_circle, color: Colors.orange),
                  items: _anaKategoriler.map((String kat) {
                    return DropdownMenuItem<String>(
                      value: kat,
                      child: Text(kat, style: const TextStyle(fontWeight: FontWeight.w500)),
                    );
                  }).toList(),
                  onChanged: (String? yeniDeger) {
                    setState(() {
                      _secilenKategori = yeniDeger;
                    });
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 30),

            // MALZEME SEÇİM ALANI
            const Text("🧊 Buzdolabında neler var?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4A5D4E))),
            const SizedBox(height: 5),
            const Text("Seçtiğin her tarif ana sayfada paylaşılacaktır.", style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 15),
            
            Wrap(
              spacing: 8, runSpacing: 4,
              children: _commonIngredients.map((ingredient) {
                final isSelected = _selectedIngredients.contains(ingredient);
                return FilterChip(
                  label: Text(ingredient),
                  selected: isSelected,
                  selectedColor: Colors.orange.withOpacity(0.2),
                  onSelected: (bool selected) {
                    setState(() {
                      selected ? _selectedIngredients.add(ingredient) : _selectedIngredients.remove(ingredient);
                    });
                  },
                );
              }).toList(),
            ),
            
            const Divider(height: 30),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)]),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none, color: _isListening ? Colors.red : Colors.orange),
                    onPressed: _listen,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ingredientController,
                      onChanged: (text) => setState(() {}),
                      decoration: const InputDecoration(hintText: "Söyle veya yaz...", border: InputBorder.none),
                    ),
                  ),
                  if (_ingredientController.text.isNotEmpty)
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _selectedIngredients.add(_ingredientController.text.trim());
                        _ingredientController.clear();
                      }),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text("Ekle"),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            Wrap(
              spacing: 8,
              children: _selectedIngredients.map((item) => Chip(
                label: Text(item, style: const TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: Colors.orange.shade50,
                side: BorderSide(color: Colors.orange.shade200),
                onDeleted: () => setState(() => _selectedIngredients.remove(item)),
                deleteIcon: const Icon(Icons.close, size: 16),
              )).toList(),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton.icon(
                onPressed: _generate,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2725B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                label: const Text("Tarifi Hazırla ve Paylaş!", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}