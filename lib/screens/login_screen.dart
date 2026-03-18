import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'verify_email_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoginMode = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  
  String _selectedGender = 'Kadın'; 
  bool _isLoading = false;

  // --- GOOGLE İLE GİRİŞ FONKSİYONU ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      UserCredential userCredential = 
          await FirebaseAuth.instance.signInWithPopup(googleProvider);

      final userDoc = await FirebaseFirestore.instance
          .collection('kullanicilar')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance
            .collection('kullanicilar')
            .doc(userCredential.user!.uid)
            .set({
          'ad_soyad': userCredential.user!.displayName ?? "Google Kullanıcısı",
          'kullanici_adi': userCredential.user!.email?.split('@')[0] ?? "user",
          'cinsiyet': "Belirtilmedi",
          'eposta': userCredential.user!.email,
          'kayit_tarihi': FieldValue.serverTimestamp(),
        });
      }

      if (context.mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Google Giriş Hatası: $e")));
      }
    }
    setState(() => _isLoading = false);
  }

  // --- NORMAL E-POSTA İLE GİRİŞ / KAYIT ---
  void _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen e-posta ve şifre giriniz!")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLoginMode) {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential.user != null && !userCredential.user!.emailVerified) {
          if (context.mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const VerifyEmailScreen()));
          }
          setState(() => _isLoading = false);
          return;
        }
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifreler uyuşmuyor!")));
          setState(() => _isLoading = false);
          return;
        }

        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential.user != null) {
          await userCredential.user!.updateDisplayName(_fullNameController.text.trim());

          await FirebaseFirestore.instance.collection('kullanicilar').doc(userCredential.user!.uid).set({
            'ad_soyad': _fullNameController.text.trim(),
            'kullanici_adi': _usernameController.text.trim(),
            'cinsiyet': _selectedGender,
            'eposta': _emailController.text.trim(),
            'kayit_tarihi': FieldValue.serverTimestamp(),
          });

          await userCredential.user!.sendEmailVerification();
          
          if (context.mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const VerifyEmailScreen()));
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      if (context.mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: ${e.toString()}")));
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- EFSANEVİ LOGO BURADA ---
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 150, // İdeal boyut
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),

              // BAŞLIK
              Text(
                _isLoginMode ? "Hoş Geldin! 👋" : "Aramıza Katıl! 🚀",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE2725B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // GOOGLE BUTONU
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: Image.network("https://cdn-icons-png.flaticon.com/512/2991/2991148.png", height: 24),
                label: const Text("Google ile Giriş Yap", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              
              // FACEBOOK BUTONU
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Facebook Girişi yakında eklenecek!")));
                },
                icon: const Icon(Icons.facebook, color: Colors.white, size: 28),
                label: const Text("Facebook ile Giriş Yap", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1877F2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              
              const SizedBox(height: 25),
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey, thickness: 1)),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("VEYA", style: TextStyle(color: Colors.grey))),
                  Expanded(child: Divider(color: Colors.grey, thickness: 1)),
                ],
              ),
              const SizedBox(height: 25),

              if (!_isLoginMode) ...[
                TextField(
                  controller: _fullNameController,
                  decoration: InputDecoration(labelText: "Ad Soyad", prefixIcon: const Icon(Icons.badge, color: Colors.orange), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(labelText: "Kullanıcı Adı", prefixIcon: const Icon(Icons.person, color: Colors.orange), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 15),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                  child: Row(
                    children: [
                      const Text(" Cinsiyet:", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text("Kadın"),
                          value: 'Kadın',
                          groupValue: _selectedGender,
                          activeColor: Colors.orange,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) => setState(() => _selectedGender = value!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text("Erkek"),
                          value: 'Erkek',
                          groupValue: _selectedGender,
                          activeColor: Colors.orange,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (value) => setState(() => _selectedGender = value!),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
              ],

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: "E-posta adresi", prefixIcon: const Icon(Icons.email, color: Colors.orange), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Şifre", prefixIcon: const Icon(Icons.lock, color: Colors.orange), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
              ),
              
              if (!_isLoginMode) ...[
                const SizedBox(height: 15),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(labelText: "Şifrenizi Tekrar Giriniz", prefixIcon: const Icon(Icons.lock_outline, color: Colors.orange), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                ),
              ],

              const SizedBox(height: 25),

              if (!_isLoginMode)
                const Padding(
                  padding: EdgeInsets.only(bottom: 15),
                  child: Text(
                    "Kaydolarak, kullanım koşulları ve gizlilik politikamızı kabul etmiş olursunuz.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2725B), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isLoginMode ? "Giriş Yap" : "Kaydol", style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              
              const SizedBox(height: 15),

              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoginMode = !_isLoginMode;
                  });
                },
                child: Text(
                  _isLoginMode ? "Hesabın yok mu? Kaydol" : "Zaten hesabın var mı? Giriş Yap",
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}