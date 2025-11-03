import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // เพิ่ม FirebaseAuth
import 'package:google_sign_in/google_sign_in.dart';

class HeartManager with WidgetsBindingObserver {
  final int maxHearts;
  final int regenMinutes;
  
  int currentHearts = 5;
  int _secondsLeft = 0;
  Timer? _timer;
  VoidCallback? onUpdate;

  HeartManager({
    required this.maxHearts,
    required this.regenMinutes,
    this.onUpdate,
  });

  Future<void> init() async {
    print("🔥 HeartManager.init() ถูกเรียก");

    WidgetsBinding.instance.addObserver(this);
    final prefs = await SharedPreferences.getInstance();
    currentHearts = prefs.getInt('currentHearts') ?? maxHearts;

    // เมื่อเปิดแอปครั้งแรก
    await _handleResume();
    // ✅ ส่งค่าหัวใจไปยัง Firestore ตอนเปิดแอป
    await _updateHeartInFirestore();

    onUpdate?.call();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
  }

  int get secondsLeft => _secondsLeft;

  int get hearts => currentHearts;

  bool get isFull => currentHearts >= maxHearts;

  void useHeart() async {
    if (currentHearts > 0) {
      currentHearts--;
      await _saveData();
      if (_timer == null || !_timer!.isActive) {
        _startRegenTimer(regenMinutes * 60);
        print("$regenMinutes");
      }
      onUpdate?.call();
      await _updateHeartInFirestore(); // อัปเดตข้อมูลหัวใจใน Firestore
    }
  }

  void increaseHeart() async {
    if (currentHearts < maxHearts) {
      currentHearts++;
      await _saveData();
      onUpdate?.call();
      await _updateHeartInFirestore(); // อัปเดตข้อมูลหัวใจใน Firestore
    }
  }

  void _startRegenTimer(int seconds) {
    _secondsLeft = seconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      _secondsLeft--;
      if (_secondsLeft <= 0) {
        if (currentHearts < maxHearts) {
          currentHearts++;
          await _saveData();

          if (currentHearts < maxHearts) {
            _secondsLeft = regenMinutes * 60;
          } else {
            _timer?.cancel();
          }
          onUpdate?.call();
          await _updateHeartInFirestore(); // อัปเดตข้อมูลหัวใจใน Firestore
        }
      }
    });
  }

  Future<void> _handleResume() async {
     print("🔁 _handleResume เริ่มทำงาน");
    final prefs = await SharedPreferences.getInstance();
    final lastUsedTimestamp = prefs.getInt('lastUsedTime');
    
    if (lastUsedTimestamp == null) {
    print("🕒 ยังไม่มี lastUsedTime -> สร้างใหม่");
    await prefs.setInt('lastUsedTime', DateTime.now().millisecondsSinceEpoch);
    return;
  }

    final lastUsed = DateTime.fromMillisecondsSinceEpoch(lastUsedTimestamp);
    final now = DateTime.now();
    final elapsedMinutes = now.difference(lastUsed).inMinutes;

    final regenCount = (elapsedMinutes / regenMinutes).floor();
    currentHearts = (currentHearts + regenCount).clamp(0, maxHearts);

    if (currentHearts < maxHearts) {
      final nextRegen = lastUsed.add(Duration(minutes: regenMinutes * (regenCount + 1)));
      final secondsLeft = nextRegen.difference(now).inSeconds;
      _startRegenTimer(secondsLeft);
    }
    // ถ้าหัวใจเพิ่มขึ้นจากการรีเจน หรือข้อมูลถูกเปลี่ยนแปลง ให้บันทึกข้อมูลใหม่
    if (regenCount > 0 || currentHearts != prefs.getInt('currentHearts')) {
      await _saveData();
      onUpdate?.call();  // เรียก onUpdate ทันทีหลังจากรีเฟรชข้อมูล
      await _updateHeartInFirestore(); // อัปเดตข้อมูลหัวใจใน Firestore
    }

    // await _saveData();
    // onUpdate?.call();  // เรียก onUpdate ทันทีหลังจากรีเฟรชข้อมูล
    // await _updateHeartInFirestore(); // อัปเดตข้อมูลหัวใจใน Firestore
  }


  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentHearts', currentHearts); // เซฟ currentHearts ใหม่
    await prefs.setInt('lastUsedTime', DateTime.now().millisecondsSinceEpoch);
    print("✅ Saved time: ${DateTime.now()}");

    // await prefs.setInt('lastUsedTime', DateTime.now().millisecondsSinceEpoch); // เซฟเวลา
    // print("🚀 Last used time saved: ${DateTime.now()}");
  }


  // ฟังก์ชันที่จะอัปเดตข้อมูลหัวใจใน Firestore
  Future<void> _updateHeartInFirestore() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    User? user = FirebaseAuth.instance.currentUser;
    
    // if (user != null) {
    //   String userId = user.uid;
    if (user != null) {
      String email = user.email ?? "";

      // ค้นหา doc ที่มี field user_id == userId
      // QuerySnapshot snapshot = await firestore
          // .collection('user_management')
          // .where('user_id', isEqualTo: userId)
          // .limit(1)
          // .get();

      try {
        // ค้นหา doc ที่ email ตรงกับของผู้ใช้
        QuerySnapshot querySnapshot = await firestore
            .collection('user_management')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

      // if (snapshot.docs.isNotEmpty) {
      //   String docId = snapshot.docs.first.id;
        if (querySnapshot.docs.isNotEmpty) {
          DocumentSnapshot doc = querySnapshot.docs.first;
          String docId = doc.id;


          // อัปเดต currentHearts ไปยัง doc นั้น
        await firestore.collection('user_management').doc(docId).set({
          'currentHearts': currentHearts,
          'lastUpdated': Timestamp.now(),
        }, SetOptions(merge: true));
          print("อัปเดต currentHearts สำเร็จ");
      } else {
        print("ไม่พบ email ตรงกับ ${user.email} ใน user_management");
      }
    } catch (e) {
        print("เกิดข้อผิดพลาดในการอัปเดต currentHearts: $e");
      }
    } else {
      print("ผู้ใช้ยังไม่ได้ลงชื่อเข้าใช้");
    }
  }


  // Handle app resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveData(); // ✅ เซฟเวลาจริงตอนแอปกำลังจะปิด
    }
    if (state == AppLifecycleState.resumed) {
      _handleResume(); // รีเฟรชข้อมูลเมื่อแอปเปิดขึ้นมาใหม่
    }
  }
}
