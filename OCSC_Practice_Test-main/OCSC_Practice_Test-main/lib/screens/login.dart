import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ocsc_practice_test/screens/register.dart';
import '../widgets/navigation.dart';
import 'forgot_password.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dashboard.dart';
import '../services/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ValueNotifier<bool> _isPasswordVisible = ValueNotifier<bool>(false);
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore
  bool _isLoading = false;
  String? emailError;
  String? passwordError;
  String? loginErrorMessage;

  void _login() async {
    if (!isValidInputs()) return;
    setState(() {
      _isLoading = true;
      emailError = null;
      passwordError = null;
      loginErrorMessage = null;
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        // ถ้าล็อกอินสำเร็จ ไปที่หน้าหลัก
        User? user = userCredential.user;
        await FirebaseFirestore.instance
            .collection('user_management')
            .doc(user?.uid)
            .set({
          'last_login': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 🔁 โหลดข้อมูลผู้ใช้ใหม่
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('user_management')
            .doc(user?.uid)
            .get();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => NavigationExample(initialIndex: 0)),
        );

        // if (userCredential.user != null) {
        //   // ถ้าล็อกอินสำเร็จ ไปที่หน้าหลัก
        //   Navigator.pushReplacementNamed(context, '/dashboard');
        // }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        loginErrorMessage = "อีเมลหรือรหัสผ่านไม่ถูกต้อง";
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  bool isValidInputs() {
    bool hasError = false;
    setState(() {
      emailError = null;
      passwordError = null;

      if (_emailController.text.isEmpty) {
        emailError = "กรุณากรอกอีเมล";
        hasError = true;
      }
      if (_passwordController.text.isEmpty) {
        passwordError = "กรุณากรอกรหัสผ่าน";
        hasError = true;
      }
    });
    return !hasError;
  }

  Future<void> signInWithGoogle() async {
    try {
      // ⭐ ล้าง session เดิมก่อน
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // ผู้ใช้ยกเลิกการล็อกอิน

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        final docRef = _firestore.collection("user_management").doc(user.uid);
        final docSnapshot = await docRef.get();

        if (!docSnapshot.exists) {
          await docRef.set({
            "channel": true,
            "created_at": FieldValue.serverTimestamp(),
            "email": user.email ?? "No Email",
            "progress": 0,
            "role": "user",
            "status": "active",
            "user_id": user.uid,
            "username": user.displayName ?? "No Name",
            "read": false,
            "last_login": FieldValue.serverTimestamp(),
          });

          // ⭐ เคลียร์ local storage (SharedPreferences)
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.clear();
        } else {
          await docRef.set({
            "last_login": FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      print("Google Sign-In Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to sign in with Google")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // ใช้ MediaQuery เพื่อดึงขนาดของหน้าจอ
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      // appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                    height: screenHeight *
                        0.05), // กำหนดให้มีพื้นที่ว่างขึ้นอยู่กับขนาดหน้าจอ
                Text(
                  'เข้าสู่ระบบ',
                  style: TextStyle(
                      fontSize: screenWidth * 0.08, // ขนาดตัวอักษรตามขนาดหน้าจอ
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                    height: screenHeight * 0.08), // เพิ่มพื้นที่ระหว่างคอนเทนต์
                if (loginErrorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                loginErrorMessage!,
                                style:
                                    TextStyle(color: Colors.red, fontSize: 13),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    errorText: emailError,
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 30),
                ValueListenableBuilder<bool>(
                  valueListenable: _isPasswordVisible,
                  builder: (context, isPasswordVisible, child) {
                    return TextField(
                      controller: _passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        errorText: passwordError,
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            _isPasswordVisible.value =
                                !_isPasswordVisible.value;
                          },
                        ),
                      ),
                    );
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ForgotPassword()));
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.blue, fontSize: 14),
                    ),
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Login', style: TextStyle(fontSize: 16)),
                ),
                SizedBox(height: 40),
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.grey)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Or Login with',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.grey)),
                  ],
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () async {
                    await signInWithGoogle();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/google_ic.jpg',
                        height: 24,
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Google',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.05), // ปรับระยะห่างที่เหมาะสม
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterScreen()),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Text.rich(
                      TextSpan(
                        text: 'Don’t have an account? ',
                        style: TextStyle(fontSize: 14, color: Colors.black),
                        children: [
                          TextSpan(
                            text: 'Register Now',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
