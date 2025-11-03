import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // นำเข้าไฟล์ที่ FlutterFire สร้างให้

class DatabaseConfig {
  // สร้าง method เพื่อ initialize Firebase
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform, // ใช้ค่า config อัตโนมัติ
      );
    } catch (e) {
      // แสดงข้อผิดพลาดหากการเชื่อมต่อกับ Firebase ล้มเหลว
      print("Error initializing Firebase: $e");
      rethrow;
    }
  }
}
