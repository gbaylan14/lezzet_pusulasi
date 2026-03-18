import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // TARİF SİLME FONKSİYONU
  void _deleteRecipe(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Tarifi Sil"),
        content: const Text("Bu tarifi tamamen silmek istediğine emin misin? Geri dönüşü yoktur."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('tarifler').doc(docId).delete();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tarif başarıyla silindi. 🗑️")));
              }
            },
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        title: const Text("Profilim", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        actions: [
          // ÇIKIŞ YAP BUTONU ARTIK BURADA!
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // Çıkış yapınca ana sayfadaki her şeyi sıfırlayıp giriş ekranına atıyoruz
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
            }
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          // KULLANICI AVATARI VE BİLGİLERİ
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.orange.shade100,
            child: Text(
              user?.displayName?.isNotEmpty == true ? user!.displayName![0].toUpperCase() : (user?.email?[0].toUpperCase() ?? "A"),
              style: const TextStyle(fontSize: 40, color: Colors.orange, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 15),
          Text(user?.displayName ?? "Lezzet Şefi", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(user?.email ?? "", style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          
          // LİSTE BAŞLIĞI
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Colors.orange.shade50,
            child: const Text("🍳 Paylaştığım Tarifler", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
          ),

          // KULLANICININ KENDİ TARİFLERİ
          Expanded(
            child: StreamBuilder(
              // SADECE BENİM ID'ME SAHİP OLAN TARİFLERİ GETİR
              stream: FirebaseFirestore.instance.collection('tarifler').where('paylasan_uid', isEqualTo: user?.uid).snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.orange));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Henüz hiç tarif paylaşmadın.\nHadi sihirbazı kullan! ✨", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)));
                }

                // Veritabanında index hatası almamak için sıralamayı telefonun içinde (lokalde) yapıyoruz
                var docs = snapshot.data!.docs;
                docs.sort((a, b) {
                  Timestamp? tA = (a.data() as Map)['tarih'];
                  Timestamp? tB = (b.data() as Map)['tarih'];
                  if (tA == null || tB == null) return 0;
                  return tB.compareTo(tA);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var ds = docs[index];
                    var data = ds.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(data['resim_url'] ?? '', width: 60, height: 60, fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Container(width: 60, height: 60, color: Colors.grey[300], child: const Icon(Icons.fastfood, color: Colors.grey)),
                          ),
                        ),
                        title: Text(data['baslik'] ?? "İsimsiz Tarif", style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text("❤️ ${data['begenenler']?.length ?? 0} Beğeni   💬 ${data['yorum_sayisi'] ?? 0} Yorum"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteRecipe(context, ds.id), // Silme butonuna basınca fonksiyon çalışır
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}