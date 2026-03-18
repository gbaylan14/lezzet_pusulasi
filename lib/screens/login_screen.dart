import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  // --- HİBRİT GOOGLE GİRİŞ FONKSİYONU (google_sign_in 7.x uyumlu) ---
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        // WEB İÇİN POPUP KULLANIMI
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        // ANDROID İÇİN - google_sign_in 7.x
        // authenticate() metodu; signIn() artık yok!
        final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

        // authentication artık senkron (await yok)
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      // --- Firestore Kayıt Kısmı ---
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

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on GoogleSignInException catch (e) {
      // 7.x: message değil description kullanılıyor!
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Giriş Hatası: ${e.code} - ${e.description}")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Giriş Hatası: $e")),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  // --- NORMAL E-POSTA İLE GİRİŞ / KAYIT ---
  void _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen e-posta ve şifre giriniz!")),
      );
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
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const VerifyEmailScreen()),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Şifreler uyuşmuyor!")),
          );
          setState(() => _isLoading = false);
          return;
        }

        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (userCredential.user != null) {
          await userCredential.user!.updateDisplayName(_fullNameController.text.trim());

          await FirebaseFirestore.instance
              .collection('kullanicilar')
              .doc(userCredential.user!.uid)
              .set({
            'ad_soyad': _fullNameController.text.trim(),
            'kullanici_adi': _usernameController.text.trim(),
            'cinsiyet': _selectedGender,
            'eposta': _emailController.text.trim(),
            'kayit_tarihi': FieldValue.serverTimestamp(),
          });

          await userCredential.user!.sendEmailVerification();

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const VerifyEmailScreen()),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: ${e.toString()}")),
        );
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
              const Center(
                child: Icon(Icons.explore_rounded, size: 100, color: Color(0xFFE2725B)),
              ),
              const SizedBox(height: 20),
              Text(
                _isLoginMode ? "Hoş Geldin! 👋" : "Aramıza Katıl! 🚀",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFE2725B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _signInWithGoogle,
                icon: Image.network("https://cdn-icons-png.flaticon.com/512/2991/2991148.png", height: 24),
                label: const Text("Google ile Giriş Yap", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: null,
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
                  Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("VEYA", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                  Expanded(child: Divider(color: Colors.grey, thickness: 1)),
                ],
              ),
              const SizedBox(height: 25),
              if (!_isLoginMode) ...[
                _buildTextField(_fullNameController, "Ad Soyad", Icons.badge),
                const SizedBox(height: 15),
                _buildTextField(_usernameController, "Kullanıcı Adı", Icons.person),
                const SizedBox(height: 15),
                _buildGenderSelector(),
                const SizedBox(height: 15),
              ],
              _buildTextField(_emailController, "E-posta adresi", Icons.email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 15),
              _buildTextField(_passwordController, "Şifre", Icons.lock, obscureText: true),
              if (!_isLoginMode) ...[
                const SizedBox(height: 15),
                _buildTextField(_confirmPasswordController, "Şifre Tekrar", Icons.lock_outline, obscureText: true),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE2725B),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_isLoginMode ? "Giriş Yap" : "Kaydol", style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                child: Text(
                  _isLoginMode ? "Hesabın yok mu? Kaydol" : "Zaten hesabın var mı? Giriş Yap",
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscureText = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          const Text(" Cinsiyet:", style: TextStyle(color: Colors.grey, fontSize: 16)),
          Expanded(
            child: RadioListTile<String>(
              title: const Text("Kadın", style: TextStyle(fontSize: 14)),
              value: 'Kadın',
              groupValue: _selectedGender,
              activeColor: Colors.orange,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) => setState(() => _selectedGender = value!),
            ),
          ),
          Expanded(
            child: RadioListTile<String>(
              title: const Text("Erkek", style: TextStyle(fontSize: 14)),
              value: 'Erkek',
              groupValue: _selectedGender,
              activeColor: Colors.orange,
              contentPadding: EdgeInsets.zero,
              onChanged: (value) => setState(() => _selectedGender = value!),
            ),
          ),
        ],
      ),
    );
  }
}
