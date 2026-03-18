import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Şef Profili", style: TextStyle(color: Color(0xFFE2725B), fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFE2725B)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          // 1. ÜST PROFİL BİLGİSİ
          _buildProfileHeader(),
          
          const SizedBox(height: 20),

          // 2. SEKMELER (TABS)
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFFE2725B),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFE2725B),
            tabs: const [
              Tab(icon: Icon(Icons.restaurant_menu), text: "Tariflerim"),
              Tab(icon: Icon(Icons.camera_alt), text: "Denediklerim"),
            ],
          ),

          // 3. SEKME İÇERİKLERİ
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyRecipes(),
                _buildMyTries(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFE2725B).withOpacity(0.1),
            child: Text(
              currentUser?.displayName?[0].toUpperCase() ?? "L",
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFFE2725B)),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            currentUser?.displayName ?? "Lezzet Şefi",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            currentUser?.email ?? "",
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          // İSTATİSTİKLER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem("Tarif", "12"), // Burası ilerde dinamik olacak
              _buildStatItem("Takipçi", "450"),
              _buildStatItem("Puan", "4.8"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFE2725B))),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }

  Widget _buildMyRecipes() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('tarifler')
          .where('paylasan_id', isEqualTo: currentUser?.uid) // Kendi paylaştıklarını getir
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Henüz bir tarif paylaşmadın. 🍳"));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(data['resim_url'] ?? '', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.fastfood)),
                ),
                title: Text(data['baslik'] ?? 'İsimsiz'),
                subtitle: const Text("Yayında ✨"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyTries() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text("Denediğin tariflerin fotoğrafları burada görünecek!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}