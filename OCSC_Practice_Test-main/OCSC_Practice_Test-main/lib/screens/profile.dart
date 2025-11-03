import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  User? user; // ตัวแปรเก็บข้อมูลผู้ใช้
  String username = "Loading..."; // ชื่อผู้ใช้ที่จะแสดง
  String email = "Loading..."; // อีเมลที่จะแสดง

  @override
  void initState() {
    super.initState();
    // ดึงข้อมูลผู้ใช้ที่ล็อกอิน
    user = FirebaseAuth.instance.currentUser;

    // เรียกฟังก์ชันเพื่อดึงข้อมูลชื่อจาก Firestore
    if (user != null) {
      // _getUserData(user!.uid); // เรียกข้อมูลผู้ใช้จาก Firestore
      _getUserDataByEmail(user!.email!);
    }
  }

  Future<void> _getUserDataByEmail(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('user_management')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        setState(() {
          username = data['username'] ?? "No Name";
          this.email = email; // จาก FirebaseAuth
        });
      } else {
        setState(() {
          username = "No Name";
          this.email = email;
        });
      }
    } catch (e) {
      print("Error fetching user data by email: $e");
      setState(() {
        username = "No Name";
        this.email = email;
      });
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut(); // ออกจากระบบ Firebase
      await googleSignIn.signOut(); // ออกจากระบบ Google
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => LoginScreen()), // เปลี่ยนไปที่หน้าล็อกอิน
      );
    } catch (e) {
      print("Sign-out Error: $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("ไม่สามารถออกจากระบบได้")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // ปิดปุ่มย้อนกลับ
        title: const Text('บัญชีของฉัน',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade200,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ข้อมูลส่วนตัว',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 28, color: Colors.amber),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ชื่อผู้ใช้',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          username,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Icon(Icons.email, size: 28, color: Colors.amber),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'อีเมล',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          email,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
