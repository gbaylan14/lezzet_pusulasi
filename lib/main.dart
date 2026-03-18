import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart'; // SPLASH EKRANINI İÇERİ ALDIK

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await Hive.openBox('favoriler');

  runApp(const LezzetPusulasi());
}

class LezzetPusulasi extends StatelessWidget {
  const LezzetPusulasi({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lezzet Pusulası',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      // Artık herkes doğrudan Ana Sayfaya girecek!
      home: const SplashScreen(),
    );
  }
}