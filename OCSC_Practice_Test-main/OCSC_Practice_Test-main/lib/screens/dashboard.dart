import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:ocsc_practice_test/services/exam_provider.dart';
import 'examtest_selection.dart';
import '../services/heart_manager.dart';

class Dashboard extends StatefulWidget {
  final String exam_id;//เพิ่มฟังก์ชันการคำนวณ 16/4/25
  const Dashboard({Key? key, required this.exam_id}) : super(key: key);//เพิ่มฟังก์ชันการคำนวณ 16/4/25
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String? userId; // ตัวแปรเก็บ userId
  late HeartManager heartManager;


  @override
  void fetchUserId() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid; // เซ็ตค่า userId
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not logged in!")),
      );
    }
  }

  // Timer? timer;
  // int heartTimer = 0;
  List<ui.Image>? leafImages;
  int frogIndex = 0;
  List<Offset> leafPositions = [];
  int favoriteCount = 5; // Default number of favorite icons
  List<bool> favoriteStates = List.generate(
      5, (index) => true); // Track the state of each favorite icon

  void initState() {
    super.initState();
    fetchUserId(); // โหลด userId
    print("🚀 App started! Fetching score...");
    loadLeafImages();

    heartManager = HeartManager(
      maxHearts: 5,
      regenMinutes: 240,
      onUpdate: _onHeartsUpdated,
    );
    heartManager.init().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          // Force UI to update after heartManager.init() completes
        });

      });
    });

    // timer = Timer.periodic(Duration(seconds: 1), (_) {
    //   if (mounted) {
    //     HeartRefill();
    //   }
    // });

    loadFrogPosition().then((loadedIndex) {
      if (mounted) {
        setState(() {
          frogIndex = loadedIndex;
          // frogIndex = 12;
        });
      }
    });
    loadFavoriteCount();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      //fetchLatestScoreAndMoveFrog();
    });
    handleDashboardExamResult(); //เพิ่มฟังก์ชันการคำนวณ 16/4/25
  }

  void _onHeartsUpdated() {
    setState(() {
      favoriteStates = List.generate(5, (index) => index < heartManager.hearts).reversed.toList();
    });
  }

  void updateFavoriteStates() {
    setState(() {
      favoriteCount = heartManager.currentHearts;
      favoriteStates = List.generate(5, (index) => index < favoriteCount).reversed.toList();
    });
  }


  Future<void> resetGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 🧹 ล้างค่าทั้งหมดที่บันทึกไว้ใน SharedPreferences

    setState(() {
      frogIndex = 0; // รีเซ็ตตำแหน่งกบ
      favoriteCount = 5; // รีเซ็ตหัวใจกลับไป 5
      favoriteStates = List.generate(5, (index) => true); // หัวใจเป็น ❤️ เต็ม
    });

    print("🔄 เกมถูกรีเซ็ตเรียบร้อย!");
  }

  @override
  void dispose() {
    heartManager.dispose();
    super.dispose();
    saveFrogPosition(frogIndex); // บันทึกตำแหน่งของกบก่อนปิดแอป
    // timer?.cancel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    //fetchLatestScoreAndMoveFrog(); 
  }

  Future<void> loadFavoriteCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      favoriteCount = prefs.getInt('favoriteCount') ??
          5; // ❌ ไม่รีเซ็ตเป็น 5 เสมอ แต่ใช้ค่าที่บันทึกไว้
      favoriteStates =
          List.generate(5, (index) => index < favoriteCount).reversed.toList();
    });
  }

  Future<void> saveFavoriteCount() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('favoriteCount', favoriteCount);
  }

  Future<void> saveFrogPosition(int frogIndex) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('frogIndex', frogIndex);
  }

  Future<int> loadFrogPosition() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt('frogIndex') ??
        0; // ถ้าไม่มีข้อมูลจะคืนค่าเริ่มต้นเป็น 0
  }

  // Method to load leaf images
  Future<void> loadLeafImages() async {
    final leafAssetPaths = [
      'assets/images/bw_leaf1.png',
      'assets/images/bw_leaf2.png',
      'assets/images/color_leaf1.png',
      'assets/images/color_leaf2.png',
    ];

    List<ui.Image> images = [];
    for (var path in leafAssetPaths) {
      final image = await loadImage(AssetImage(path));
      images.add(image);
    }

    setState(() {
      leafImages = images;
      generateLeafPositions();
    });
  }

  // Method to load image
  Future<ui.Image> loadImage(AssetImage assetImage) async {
    final completer = Completer<ui.Image>();
    try {
      final imageStream = assetImage.resolve(ImageConfiguration());
      imageStream.addListener(
        ImageStreamListener((ImageInfo image, bool synchronousCall) {
          completer.complete(image.image);
        }),
      );
      return completer.future;
    } catch (e) {
      print("❌ Error loading image: $e");
      throw Exception("Failed to load image");
    }
  }


  // Method to generate leaf positions
  void generateLeafPositions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      final verticalSpacing = screenHeight / 14;
      final topMargin = 50.0;

      setState(() {
        leafPositions = List.generate(13, (index) {
          final x = (index % 2 == 0) ? screenWidth * 0.4 : screenWidth * 0.6;
          final y = verticalSpacing * (index + 1) + topMargin;
          return Offset(x, y);
        });
      });
    });
  }
//เพิ่มฟังก์ชันการคำนวณ 16/4/25
  //Future<void> fetchLatestScoreAndMoveFrog() async {
    //var user = FirebaseAuth.instance.currentUser;
    //if (user == null) {
     // ScaffoldMessenger.of(context).showSnackBar(
     //   SnackBar(content: Text("User not logged in!")),
    //  );
    //  return;
   // }
   // print("🔍 Current userId: ${user.uid}");

    // ✅ ดึงเฉพาะคะแนนของ user นี้
   // var snapshot = await FirebaseFirestore.instance
    //    .collection('scores')
    //    .where('user_id', isEqualTo: user.uid) // 👉 กรองตาม user_id
    //    .where('created_at', isNotEqualTo: null)
     //   .orderBy('created_at', descending: true)
     //   .limit(1)
     //   .get();

    //if (snapshot.docs.isNotEmpty) {
     // var doc = snapshot.docs.first;
     // int latestScore = doc['total_scores'];
     // Timestamp timestamp = doc['created_at'];
     // DateTime scoreTime = timestamp.toDate();

     // print("✅ คะแนนล่าสุดของผู้ใช้: $latestScore");
     // updateFrogPosition(latestScore, scoreTime); // 🐸 อัปเดตกบ
   // } else {
   //   print("⚠️ ไม่มีข้อมูลคะแนนของผู้ใช้นี้ใน Firestore");
   // }
  //}


  Future<void> updateFrogPosition(int latestScore, DateTime scoreTime, {bool passed = false}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  if (frogIndex >= 12 || frogIndex < 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("The frog cannot move beyond index 12!")),
    );
    return;
  }

  if (heartManager.currentHearts == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("No hearts left! Wait for recovery.")),
    );
    return;
  }

  if (passed && latestScore >= 90) {
    heartManager.increaseHeart();
    setState(() => frogIndex++);
  } else if (passed && latestScore >= 60) {
    heartManager.useHeart();
    setState(() => frogIndex++);
  } else {
    heartManager.useHeart();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Score too low to move!")),
    );
  }

  saveFrogPosition(frogIndex);
  updateFavoriteStates(); // 🔁 อัปเดต UI หัวใจ
}




  //ฟังก์ชันใหม่ 4/16/2025
  Future<void> handleDashboardExamResult() async {
  try {
    print("📌 เรียกใช้งาน handleDashboardExamResult ด้วยคะแนนล่าสุดของผู้ใช้");

    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ User is not logged in!");
      return;
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('scores')
        .where('user_id', isEqualTo: user.uid)
        .where('created_at', isNotEqualTo: null)
        .orderBy('created_at', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      print("❌ No score data found for user_id: ${user.uid}");
      return;
    }

    final data = querySnapshot.docs.first.data();
    final subjectScoresMap = data['subject_scores'] as Map<String, dynamic>?;

    if (subjectScoresMap == null) {
      print("❌ Subject scores data is missing or invalid.");
      return;
    }

    final mathScore = subjectScoresMap['math_thai']?['stotal_scores'] ?? 0;
    final lawScore = subjectScoresMap['laws']?['stotal_scores'] ?? 0;
    final engScore = subjectScoresMap['english']?['stotal_scores'] ?? 0;
    final totalScore = mathScore + lawScore + engScore;

    final createdAt = data['created_at'];
    DateTime scoreTime;
    if (createdAt is Timestamp) {
      scoreTime = createdAt.toDate();
    } else {
      print("❌ Invalid timestamp format");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int lastTimestamp = prefs.getInt('lastScoreTimestamp') ?? 0;
    if (scoreTime.millisecondsSinceEpoch <= lastTimestamp) {
      print("⛔ คะแนนนี้เคยใช้แล้ว ไม่กระโดด/เปลี่ยนหัวใจ");
      return;
    }
    await prefs.setInt('lastScoreTimestamp', scoreTime.millisecondsSinceEpoch);

    final isMathPassed = ((mathScore * 2) / 100) >= 0.6;
    final isLawPassed = ((lawScore * 2) / 50) >= 0.6;
    final isEngPassed = ((engScore * 2) / 50) >= 0.5;

    final examPassed = isMathPassed && isLawPassed && isEngPassed;

    if (examPassed) {
      if (totalScore >= 90) {
        print("🏆 ได้มากกว่า 90 และผ่านทุกวิชา -> กระโดด + ❤️ เพิ่ม");
        updateFrogPosition(totalScore, scoreTime, passed: true);
      } else if (totalScore >= 60) {
        print("✅ ได้ 60-89 และผ่านทุกวิชา -> กระโดด + ❤️ ลด");
        updateFrogPosition(totalScore, scoreTime, passed: true);
      } else {
        print("❌ ผ่านวิชาทุกตัวแต่คะแนนรวมไม่ถึง 60 -> ไม่กระโดด");
        updateFrogPosition(totalScore, scoreTime, passed: false);
      }
    } else {
      print("❌ ไม่ผ่านครบ 3 วิชา -> ไม่กระโดด");
      updateFrogPosition(totalScore, scoreTime, passed: false);
    }
  } catch (e) {
    print("❌ Error loading latest score for dashboard: $e");
  }
}


  void navigateToExamTest(int index) {
    if (favoriteCount == 0) {
      // แสดง SnackBar แจ้งเตือนว่าหัวใจหมด
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No hearts left! Wait for recovery.")),
      );
      return;
    }

    if (index == frogIndex) {
      final examProvider = Provider.of<ExamProvider>(context, listen: false);
      examProvider.resetExamData();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => ExamTestSelection(index: index)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  favoriteStates[index]
                      ? Icons.favorite
                      : Icons.favorite_border,
                  size: 30,
                  color: favoriteStates[index]
                      ? Colors.pink.shade300
                      : Colors.grey,
                ),
              );
            }),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final size = MediaQuery.of(context).size;

          return SingleChildScrollView(
            child: SizedBox(
              height: size.height * 1.1,
              child: Stack(
                children: [
                  // Background image
                  Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/bg_dashboard.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (leafPositions.isNotEmpty && leafImages != null)
                    Positioned.fill(
                      child: CustomPaint(
                        painter:
                        PathPainter(leafImages!, frogIndex, leafPositions),
                      ),
                    ),
                  if (leafPositions.isNotEmpty &&
                      frogIndex < leafPositions.length)
                    Positioned(
                      top: leafPositions[frogIndex].dy - 70,
                      left: leafPositions[frogIndex].dx - 40,
                      child: GestureDetector(
                        onTap: () => navigateToExamTest(frogIndex),
                        child: Image.asset(
                          'assets/images/frog.png',
                          width: 80,
                          height: 80,
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 40,
                    right: 20,
                    child: ElevatedButton(
                      onPressed: () {
                        resetGame();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text("Reset Game",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          )),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// CustomPainter for drawing paths
class PathPainter extends CustomPainter {
  final List<ui.Image> leafImages;
  final int frogIndex;
  final List<Offset> leafPositions;

  PathPainter(this.leafImages, this.frogIndex, this.leafPositions);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < leafPositions.length; i++) {
      final isFrogLeaf = i == frogIndex;
      final isPastLeaf = i < frogIndex;

      // Determine the appropriate image index
      final imageIndex = i % 4 == 0
          ? (isFrogLeaf || isPastLeaf ? 2 : 0) // Use bw_leaf1 or color_leaf1
          : (isFrogLeaf || isPastLeaf ? 3 : 1); // Use bw_leaf2 or color_leaf2

      final leafImage = leafImages[imageIndex];
      final imageSize = (imageIndex == 0 || imageIndex == 2) ? 50.0 : 30.0;

      canvas.drawImageRect(
        leafImage,
        Rect.fromLTWH(
            0, 0, leafImage.width.toDouble(), leafImage.height.toDouble()),
        Rect.fromCircle(center: leafPositions[i], radius: imageSize),
        Paint(),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}