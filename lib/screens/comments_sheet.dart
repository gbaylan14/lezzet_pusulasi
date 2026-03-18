import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsSheet extends StatefulWidget {
  final String recipeId; // Hangi tarife yorum yapıldığını bilmemiz lazım

  const CommentsSheet({super.key, required this.recipeId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSending = false;

  // YORUM GÖNDERME FONKSİYONU
  Future<void> _sendComment() async {
    final mesaj = _commentController.text.trim();
    if (mesaj.isEmpty) return;

    setState(() => _isSending = true);

    final user = FirebaseAuth.instance.currentUser;
    final docRef = FirebaseFirestore.instance.collection('tarifler').doc(widget.recipeId);

    try {
      // 1. Yorumu alt koleksiyona (subcollection) kaydet
      await docRef.collection('yorumlar').add({
        'mesaj': mesaj,
        'yazan_ad': user?.displayName ?? user?.email?.split('@')[0] ?? 'Anonim Şef',
        'user_id': user?.uid,
        'tarih': FieldValue.serverTimestamp(),
      });

      // 2. Ana tarifteki yorum sayacını 1 artır
      await docRef.set({'yorum_sayisi': FieldValue.increment(1)}, SetOptions(merge: true));

      _commentController.clear();
    } catch (e) {
      print("Yorum Hatası: $e");
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Klavyenin ekranı kapatmaması için ekran yüksekliğinin %75'ini kaplıyoruz
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ÜST TUTMACA VE BAŞLIK
          const SizedBox(height: 10),
          Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const Padding(
            padding: EdgeInsets.all(15.0),
            child: Text("Yorumlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),

          // YORUMLARIN LİSTELENDİĞİ ALAN
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('tarifler')
                  .doc(widget.recipeId)
                  .collection('yorumlar')
                  .orderBy('tarih', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("İlk yorumu sen yap! 💬", style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var yorum = snapshot.data!.docs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Text(yorum['yazan_ad'][0].toUpperCase(), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(yorum['yazan_ad'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text(yorum['mesaj'], style: const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // YORUM YAZMA KUTUSU
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 10, // Klavye açılınca yukarı kayması için
              left: 15, right: 15, top: 10
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Harika görünüyor...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: const Color(0xFFE2725B),
                  child: IconButton(
                    icon: _isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _isSending ? null : _sendComment,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}