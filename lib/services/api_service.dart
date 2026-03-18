import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  static Future<String> generateAndSaveRecipe(List<String> ingredients) async {
    final user = FirebaseAuth.instance.currentUser;

    // Sanki yapay zeka düşünüyormuş gibi 2 saniye bekletelim (Pusula dönecek!)
    await Future.delayed(const Duration(seconds: 2));

    final anaMalzeme = ingredients.isNotEmpty ? ingredients.first : "Lezzet";
    final title = "Nefis $anaMalzeme Şöleni";
    
    final recipe = '''
# $title

Seçtiğin malzemeler: ${ingredients.join(', ')}.

Bu malzemelerle hazırlayabileceğin harika bir tarif! 
(Not: Bu tarif API limitlerine takılmamak için otomatik oluşturuldu.)

🍳 Yapılışı:
1. Malzemeleri güzelce yıka ve hazırla.
2. Kısık ateşte sevgiyle pişir.
3. Sıcak servis yap, afiyet olsun!
''';

    try {
      if (user != null) {
        await FirebaseFirestore.instance.collection('tarifler').add({
          'baslik': title,
          'icerik': recipe,
          'paylasan_ad': user.displayName ?? user.email?.split('@')[0] ?? "Usta Şef",
          'paylasan_uid': user.uid, // Profil ekranı için silme yetkisi!
          'tarih': FieldValue.serverTimestamp(),
          'resim_url': "https://loremflickr.com/800/600/food,cooking/all?lock=${DateTime.now().millisecondsSinceEpoch}",
          'begenenler': [], 
          'puan_verenler': {}, 
          'yorum_sayisi': 0, 
        });
      }
      return recipe;
    } catch (e) {
      throw Exception("Tarif veritabanına kaydedilemedi.");
    }
  }
}