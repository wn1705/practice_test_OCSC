import 'package:flutter/material.dart';
import 'login.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _usernameError;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  void _register() async {
    setState(() {
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    // เช็กช่องว่าง
    if (_usernameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty || _confirmPasswordController.text.isEmpty) {
      setState(() {
        _usernameError = _usernameController.text.isEmpty ? 'กรุณากรอกชื่อผู้ใช้' : null;
        _emailError = _emailController.text.isEmpty ? 'กรุณากรอกอีเมล' : null;
        _passwordError = _passwordController.text.isEmpty ? 'กรุณากรอกรหัสผ่าน' : null;
        _confirmPasswordError = _confirmPasswordController.text.isEmpty ? 'กรุณายืนยันรหัสผ่าน' : null;
      });
      return;
    }

    // เช็กรหัสผ่านไม่ตรงกัน
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _confirmPasswordError = 'รหัสผ่านไม่ตรงกัน';
      });
      return;
    }

    // ตรวจสอบว่า username ซ้ำหรือไม่
    QuerySnapshot existingUser = await _firestore
        .collection("user_management")
        .where("username", isEqualTo: _usernameController.text)
        .get();

    if (existingUser.docs.isNotEmpty) {
      setState(() {
        _usernameError = 'ชื่อผู้ใช้นี้มีอยู่แล้ว';
      });
      return;
    }

    // สมัครผู้ใช้ใหม่
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      await _firestore.collection("user_management").doc(userCredential.user!.uid).set({
        'username': _usernameController.text,
        'email': _emailController.text,
        'user_id': userCredential.user!.uid,
        'created_at': FieldValue.serverTimestamp(),
        'channel': 'false',
        'role': 'user',
        'status': 'active',
        'progress': 0,
        'read': false,
      });

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        setState(() {
          _emailError = 'อีเมลนี้มีอยู่ในระบบแล้ว';
        });
      } else {
        setState(() {
          _passwordError = 'ต้องมีตัวพิมพ์ใหญ่ พิมพ์เล็ก และตัวเลข อย่างน้อย 6 ตัวอักษร';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('ลงทะเบียน', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 40),
              _buildTextField('Username', controller: _usernameController, errorText: _usernameError),
              SizedBox(height: 16),
              _buildTextField('Email', controller: _emailController, errorText: _emailError),
              SizedBox(height: 16),
              _buildTextField('Password', obscureText: true, controller: _passwordController, errorText: _passwordError),
              SizedBox(height: 16),
              _buildTextField('Confirm Password', obscureText: true, controller: _confirmPasswordController, errorText: _confirmPasswordError),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Register', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, {bool obscureText = false, TextEditingController? controller, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey[200],
        //     errorText: errorText,
        //     errorStyle: TextStyle(fontSize: 12.5,overflow: TextOverflow.visible, ),
        //   ),
        // ),
          ),
        ),
        if (errorText != null) // แสดงข้อความ error ด้านล่าง
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Text(
              errorText,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.red,
              ),
            ),
          ),
        SizedBox(height: 4),
      ],
    );
  }
}

