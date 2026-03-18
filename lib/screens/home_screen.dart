import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:share_plus/share_plus.dart'; 
import 'ai_wizard_screen.dart';
import 'login_screen.dart';
import 'comments_sheet.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  String searchQuery = "";
  String secilenKategori = "Tümü";
  
  final List<String> kategoriler = [
    "Tümü", "Kahvaltı", "Çorbalar", "Ana Yemekler", "Salatalar", 
    "Mezeler", "Atıştırmalıklar", "Makarna & Pilav", "Tatlılar", 
    "İçecekler", "Fast Food", "Sağlıklı & Diyet", "Pratik Tarifler"
  ];

  // --- SENİN FONKSİYONLARIN (HEPSİ KORUNDU) ---

  void _checkAuth(Function action) {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bu işlem için giriş yapmalısınız! 🚀")));
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    } else {
      action();
    }
  }

  Future<void> _toggleLike(String docId, List begenenler) async {
    final uid = currentUser?.uid;
    if (uid == null) return;
    final docRef = FirebaseFirestore.instance.collection('tarifler').doc(docId);
    if (begenenler.contains(uid)) {
      await docRef.update({'begenenler': FieldValue.arrayRemove([uid])});
    } else {
      await docRef.update({'begenenler': FieldValue.arrayUnion([uid])});
    }
  }

  void _showRatingDialog(String recipeId) {
    int secilenPuan = 0;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Tarife Puan Ver", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Bu tarifi ne kadar beğendin?", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(index < secilenPuan ? Icons.star : Icons.star_border, color: Colors.amber, size: 40),
                        onPressed: () => setState(() => secilenPuan = index + 1),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE2725B)),
                  onPressed: () async {
                    if (secilenPuan == 0) return;
                    // --- BURADA KÜÇÜK BİR DÜZELTME: update kullanarak verileri koruyoruz ---
                    await FirebaseFirestore.instance.collection('tarifler').doc(recipeId).update({
                      'puan_verenler.${currentUser!.uid}': secilenPuan
                    });
                    if (context.mounted) {
                       Navigator.pop(context);
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Puanın kaydedildi! 🌟")));
                    }
                  },
                  child: const Text("Gönder", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          }
        );
      }
    );
  }

  Future<void> _uploadPhoto(String recipeId) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Fotoğraf yükleniyor, lütfen bekleyin... ⏳"), duration: Duration(seconds: 3)),
    );

    try {
      final bytes = await image.readAsBytes();
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('deneyenler')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putData(bytes);
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('tarifler')
          .doc(recipeId)
          .collection('deneyenler')
          .add({
        'foto_url': downloadUrl,
        'paylasan_ad': currentUser?.displayName ?? currentUser?.email?.split('@')[0] ?? 'Anonim Şef',
        'tarih': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Harika! Yaptığın yemeğin fotoğrafı başarıyla eklendi! 📸✨")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Yükleme hatası: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      // --- DRAWER (YAN MENÜ) ---
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFFE2725B)),
              accountName: Text(currentUser?.displayName ?? "Lezzet Şefi", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Text(currentUser?.email ?? "Misafir Kullanıcı"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  currentUser?.displayName?.isNotEmpty == true ? currentUser!.displayName![0].toUpperCase() : (currentUser?.email?[0].toUpperCase() ?? "M"),
                  style: const TextStyle(fontSize: 24, color: Color(0xFFE2725B), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.orange),
              title: const Text("Ana Sayfa", style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pop(context), 
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: Colors.orange),
              title: const Text("Yapay Zeka ile Tarif Üret"),
              onTap: () {
                Navigator.pop(context);
                _checkAuth(() => Navigator.push(context, MaterialPageRoute(builder: (context) => const AIWizardScreen())));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.orange),
              title: const Text("Profilim"),
              onTap: () {
                Navigator.pop(context);
                _checkAuth(() => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())));
              },
            ),
            const Divider(),
            currentUser == null
            ? ListTile(
                leading: const Icon(Icons.login, color: Colors.green),
                title: const Text("Giriş Yap / Kayıt Ol", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
              )
            : ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Çıkış Yap", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                },
              ),
          ],
        ),
      ),
      // --- APPBAR (MARKANI BURAYA EKLEDİM) ---
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', height: 30), // SENİN LOGON
            const SizedBox(width: 8),
            const Text("Lezzet Pusulası", style: TextStyle(color: Color(0xFFE2725B), fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          currentUser == null 
          ? TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())), 
              icon: const Icon(Icons.login, color: Colors.orange),
              label: const Text("Giriş Yap", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            )
          : IconButton(
              icon: const Icon(Icons.person, color: Colors.orange, size: 28), 
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
              }
            )
        ],
      ),
      body: Column(
        children: [
          // ARAMA CUBUĞU
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, top: 15, bottom: 10),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: "Tarif veya malzeme ara...",
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide(color: Colors.orange.shade200, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: const BorderSide(color: Colors.orange, width: 2)),
              ),
            ),
          ),

          // KATEGORİLER
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: kategoriler.length,
              itemBuilder: (context, index) {
                bool isSelected = secilenKategori == kategoriler[index];
                return GestureDetector(
                  onTap: () => setState(() => secilenKategori = kategoriler[index]),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE2725B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? const Color(0xFFE2725B) : Colors.orange.shade200),
                    ),
                    child: Center(
                      child: Text(
                        kategoriler[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // TARİF LİSTESİ (STREAM)
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('tarifler').orderBy('tarih', descending: true).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.orange));
                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Henüz hiç tarif yok.\nİlk paylaşan sen ol! 🍳", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)));
                }

                var docs = snapshot.data!.docs;
                
                // --- FİLTRELEME MANTIGI (SENİN KODUN) ---
                docs = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var baslik = (data['baslik'] ?? '').toString().toLowerCase();
                  var icerik = (data['icerik'] ?? '').toString().toLowerCase();
                  
                  bool kategoriUygun = true;
                  if (secilenKategori != "Tümü") {
                    kategoriUygun = baslik.contains(secilenKategori.toLowerCase()) || icerik.contains(secilenKategori.toLowerCase());
                  }

                  bool aramaUygun = true;
                  if (searchQuery.isNotEmpty) {
                    aramaUygun = baslik.contains(searchQuery);
                  }

                  return kategoriUygun && aramaUygun;
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("Bu kategoriye veya aramaya uygun tarif bulunamadı 🧐", style: TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var ds = docs[index];
                    var data = ds.data() as Map<String, dynamic>;
                    
                    List begenenler = data.containsKey('begenenler') ? data['begenenler'] : [];
                    bool isLiked = currentUser != null && begenenler.contains(currentUser!.uid);

                    Map<String, dynamic> puanVerenler = data.containsKey('puan_verenler') ? data['puan_verenler'] : {};
                    double ortalamaPuan = 0;
                    if (puanVerenler.isNotEmpty) {
                      double toplam = 0;
                      puanVerenler.forEach((key, value) => toplam += value);
                      ortalamaPuan = toplam / puanVerenler.length;
                    }

                    // --- TARİF KARTI (SENİN TASARIMIN) ---
                    return Card(
                      margin: const EdgeInsets.only(bottom: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            child: Image.network(
                              data['resim_url'] ?? '', 
                              height: 220, width: double.infinity, fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(height: 220, color: Colors.grey[300], child: const Icon(Icons.fastfood, size: 50, color: Colors.grey)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, 
                              children: [
                                Text(data['baslik'] ?? 'İsimsiz Tarif', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                Text("👨‍🍳 Hazırlayan: ${data['paylasan_ad'] ?? 'Anonim'}", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w500)),
                                
                                const Divider(height: 20, thickness: 1),
                                
                                // ETKİLEŞİM SATIRI
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        // BEGENİ
                                        InkWell(
                                          onTap: () => _checkAuth(() => _toggleLike(ds.id, begenenler)),
                                          child: Row(
                                            children: [
                                              Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.grey, size: 26),
                                              const SizedBox(width: 4),
                                              Text("${begenenler.length}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        // YORUM
                                        InkWell(
                                          onTap: () => _checkAuth(() {
                                            showModalBottomSheet(
                                              context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                                              builder: (context) => CommentsSheet(recipeId: ds.id),
                                            );
                                          }),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 24),
                                              const SizedBox(width: 4),
                                              Text("${data['yorum_sayisi'] ?? 0}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                        // PAYLAŞ
                                        InkWell(
                                          onTap: () {
                                            final baslik = data['baslik'] ?? 'Nefis Tarif';
                                            final icerik = data['icerik'] ?? '';
                                            final paylasimMetni = "🍽️ Bak 'Lezzet Pusulası'nda ne buldum!\n\n👨‍🍳 $baslik\n\nTarif Detayı:\n$icerik";
                                            Share.share(paylasimMetni);
                                          },
                                          child: const Icon(Icons.share, color: Colors.grey, size: 24),
                                        ),
                                      ],
                                    ),
                                    
                                    // PUAN VE "YAPTIM" BUTONU
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () => _checkAuth(() => _showRatingDialog(ds.id)),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.star, color: Colors.amber, size: 26),
                                              const SizedBox(width: 4),
                                              Text(ortalamaPuan > 0 ? ortalamaPuan.toStringAsFixed(1) : "Oy", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        InkWell(
                                          onTap: () => _checkAuth(() => _uploadPhoto(ds.id)),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.orange.shade200)),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.camera_alt, color: Colors.orange, size: 20),
                                                SizedBox(width: 4),
                                                Text("Yaptım", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 13)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                // DENEYENLER (FOTOĞRAFLAR)
                                StreamBuilder(
                                  stream: FirebaseFirestore.instance.collection('tarifler').doc(ds.id).collection('deneyenler').orderBy('tarih', descending: true).snapshots(),
                                  builder: (context, AsyncSnapshot<QuerySnapshot> fotoSnapshot) {
                                    if (!fotoSnapshot.hasData || fotoSnapshot.data!.docs.isEmpty) return const SizedBox.shrink();
                                    
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 15),
                                        const Text("📸 Deneyenlerin Kareleri", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          height: 60,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: fotoSnapshot.data!.docs.length,
                                            itemBuilder: (context, i) {
                                              var fotoVerisi = fotoSnapshot.data!.docs[i];
                                              return InkWell(
                                                onTap: () {
                                                  showDialog(
                                                    context: context, 
                                                    builder: (_) => Dialog(
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                                      child: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          ClipRRect(
                                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                                            child: Image.network(fotoVerisi['foto_url'], fit: BoxFit.cover),
                                                          ),
                                                          Padding(
                                                            padding: const EdgeInsets.all(15.0),
                                                            child: Text("👨‍🍳 ${fotoVerisi['paylasan_ad']} bu tarifi denedi!", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                          )
                                                        ],
                                                      )
                                                    )
                                                  );
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets.only(right: 10),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(10),
                                                    child: Image.network(fotoVerisi['foto_url'], width: 60, height: 60, fit: BoxFit.cover),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                )
                              ]
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // --- FLOATING ACTION BUTTON (SENİN KODUN) ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _checkAuth(() {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AIWizardScreen()));
        }),
        label: const Text("Tarif Üret", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        backgroundColor: const Color(0xFFE2725B),
      ),
    );
  }
}