import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isSending = false;

  // Kullanıcının e-postayı onaylayıp onaylamadığını kontrol eden fonksiyon
  Future<void> _checkVerification() async {
    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload(); // Firebase'den güncel durumu çek

    if (user != null && user.emailVerified) {
      // Eğer onayladıysa Ana Sayfaya gönder
      if (context.mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } else {
      // Hala onaylamadıysa uyar
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("E-posta henüz doğrulanmamış. Lütfen e-posta kutunuzu (ve Spam klasörünü) kontrol edip tekrar deneyin. 📩")));
      }
    }
  }

  // Doğrulama mailini tekrar gönderen fonksiyon
  Future<void> _resendEmail() async {
    setState(() => _isSending = true);
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Doğrulama e-postası yeniden gönderildi! 🚀")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: ${e.toString()}")));
      }
    }
    setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        title: const Text("E-posta Doğrulama"),
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false, // Geri butonunu kaldırıyoruz ki doğrulama bitmeden kaçamasın
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            
            // İSTEDİĞİN O ÖZEL METİN
            Text(
              "Lezzet Pusulası'nın tüm özelliklerine erişebilmek için e-posta adresini doğrulaman gerekiyor.\n\n${user?.email ?? ''} adresine bir doğrulama mesajı gönderdik. Lütfen e-posta kutunu kontrol et.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 30),
            
            // KONTROL BUTONU
            ElevatedButton(
              onPressed: _checkVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2725B), 
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
              ),
              child: const Text("E-postamı Doğruladım, Devam Et", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),
            
            // YENİDEN GÖNDER BUTONU
            TextButton(
              onPressed: _isSending ? null : _resendEmail,
              child: _isSending 
                  ? const CircularProgressIndicator(color: Colors.orange) 
                  : const Text("Doğrulama postasını yeniden gönder", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            
            const SizedBox(height: 20),
            const Divider(),
            
            // ÇIKIŞ YAP (Yanlış e-posta girdiyse düzeltmek için)
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                }
              },
              child: const Text("Farklı bir hesapla giriş yap", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}