import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommentsSheet extends StatefulWidget {
  final String recipeId;
  const CommentsSheet({super.key, required this.recipeId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final commentText = _commentController.text.trim();
    _commentController.clear();

    // 1. Yorumu ekle
    await FirebaseFirestore.instance
        .collection('tarifler')
        .doc(widget.recipeId)
        .collection('yorumlar')
        .add({
      'yazan_ad': currentUser?.displayName ?? "Anonim Gurme",
      'yazan_id': currentUser?.uid,
      'yorum': commentText,
      'tarih': FieldValue.serverTimestamp(),
    });

    // 2. Ana tarif dökümanındaki yorum sayısını 1 artır
    await FirebaseFirestore.instance
        .collection('tarifler')
        .doc(widget.recipeId)
        .update({'yorum_sayisi': FieldValue.increment(1)});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFFFDF7F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // TUTAMAC (Handle)
          const SizedBox(height: 12),
          Container(height: 5, width: 40, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("Yorumlar & Lezzet Fikirleri 💭", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE2725B))),
          ),
          const Divider(height: 0),

          // YORUM LİSTESİ
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('tarifler')
                  .doc(widget.recipeId)
                  .collection('yorumlar')
                  .orderBy('tarih', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.orange));
                if (snapshot.data!.docs.isEmpty) return _buildEmptyComments();

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return _buildCommentBubble(data);
                  },
                );
              },
            ),
          ),

          // YORUM YAZMA ALANI
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentBubble(Map<String, dynamic> data) {
    String ilkHarf = data['yazan_ad'] != null ? data['yazan_ad'][0].toUpperCase() : "G";
    return Padding(
     
    padding: const EdgeInsets.only(bottom: 15), // Doğru kullanım bu      child: Row(

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE2725B).withOpacity(0.1),
            child: Text(ilkHarf, style: const TextStyle(color: Color(0xFFE2725B), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['yazan_ad'] ?? "Anonim", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(data['yorum'] ?? "", style: const TextStyle(color: Colors.black87, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(left: 15, right: 15, top: 10, bottom: MediaQuery.of(context).viewInsets.bottom + 15),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: InputDecoration(
                hintText: "Bir şeyler yaz...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFFDF7F0),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendComment,
            child: const CircleAvatar(
              backgroundColor: Color(0xFFE2725B),
              child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyComments() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text("Henüz yorum yok.\nİlk tadına bakan sen ol! 🥣", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}