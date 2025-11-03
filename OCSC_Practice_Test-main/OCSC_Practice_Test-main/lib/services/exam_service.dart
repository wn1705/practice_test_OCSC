import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class ExamService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchQuestionsBasedOnIndex(
      int index, String userId) async {
    if (index == 12) {
      print("🍏 index 12: fetchQuestionsBasedOnIndex");
      return await loadPostTest(); // ถ้า index คือ 12 ให้ใช้ข้อสอบ post_test
    } else {
      return await fetchUserScoresAndLoadQuestions(userId);
    }
  }

  Future<List<Map<String, dynamic>>> loadPreTest() async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('data')
        .where('test_name', isEqualTo: 'pre_test')
        .orderBy('no')
        .limit(100) // ปรับจำนวนที่ต้องการ
        .get();

    List<Map<String, dynamic>> preTestData = querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      // ตรวจสอบว่าฟิลด์ 'no' เป็นตัวเลข
      int no =
          data['no'] is int ? data['no'] : 0; // กรณีไม่ใช่ตัวเลขจะตั้งเป็น 0

      return {
        "question_id": doc.id,
        "question": data["question"] ?? "ไม่มีคำถาม",
        "options": [
          data["option_a"],
          data["option_b"],
          data["option_c"],
          data["option_d"]
        ],
        "answer": data["answer"],
        "explanation": data["explanation"],
        "subject": data["subject"] ?? "ไม่มีวิชา",
        "topic": data["topic"] ?? "ไม่มีหัวข้อ",
        "test_name": data["test_name"] ?? "ไม่มีชุดข้อสอบ",
        "no": no,
      };
    }).toList();

    return preTestData;
  }

  Future<List<Map<String, dynamic>>> loadPostTest() async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('data')
        .where('test_name', isEqualTo: 'post_test')
        .orderBy('no')
        .limit(100) // คุณอาจปรับจำนวนตามที่ต้องการ
        .get();
    print("🍏 index 12: loadPostTest");

    List<Map<String, dynamic>> postTestData = querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        "question_id": doc.id,
        "question": data["question"] ?? "ไม่มีคำถาม",
        "options": [
          data["option_a"],
          data["option_b"],
          data["option_c"],
          data["option_d"]
        ],
        "answer": data["answer"],
        "explanation": data["explanation"],
        "subject": data["subject"] ?? "ไม่มีวิชา",
        "topic": data["topic"] ?? "ไม่มีหัวข้อ",
        "test_name": data["test_name"] ?? "ไม่มีชุดข้อสอบ",
        "no": data["no"] ?? "ไม่มีข้อ",
      };
    }).toList();
    print("🍏 Loaded post test questions: $postTestData");
    return postTestData;
  }

  Future<List<Map<String, dynamic>>> fetchUserScoresAndLoadQuestions(
      String userId) async {
    try {
      // ค้นหาคะแนนล่าสุดของผู้ใช้
      QuerySnapshot scoreSnapshot = await _firestore
          .collection('scores')
          .where('user_id', isEqualTo: userId)
          .where('pretest_done', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .limit(100)
          .get();
      print(scoreSnapshot.docs.first.data());

      if (scoreSnapshot.docs.isNotEmpty) {
        Map<String, dynamic> scoreData =
            scoreSnapshot.docs.first.data() as Map<String, dynamic>;
        print("🔥 ข้อมูลจาก Firestore: ${scoreData}");

        // 🔹 ถ้ามี pretest_done อยู่แล้ว ไปโหลดข้อสอบที่เหมาะกับคะแนน
        return await fetchQuestionsBasedOnScores(scoreData);
      }

      // ถ้ายังไม่เคยทำ Pre-test
      print("🆕 ผู้ใช้ยังไม่เคยทำ Pre-test");
      List<Map<String, dynamic>> preTestQuestions = await loadPreTest();

      print("✅ บันทึก pretest_done สำเร็จ");
      return preTestQuestions;
    } catch (e, stacktrace) {
      print("❌ Error fetching user scores or questions: $e");
      print(stacktrace);
      return await loadPreTest();
    }
  }

  // กำหนด topicLimits เป็นค่าคงที่
  final Map<String, int> topicLimits = {
    'series': 5,
    'article': 10,
    'symb_condition': 10,
    'analogy': 5,
    'dtable': 5,
    'gmath': 5,
    'ling_condition': 5,
    'sent_rearrange': 5,
    'reading': 10,
    'conver': 5,
    'grammar': 5,
    'vocab': 5,
    'state_admin': 6,
    'good_govern': 6,
    'admin_procedure': 6,
    'criminal_code': 2,
    'tortious': 2,
    'ethics': 3,
  };
  //จุดที่แก้
  String calculateDifficulty(double percentage, String topic) {
  if (percentage < 50) {
    return "easy";
  } else if (percentage < 70) {
    return "medium";
  } else {
    return "hard";
  }
}

  Future<List<Map<String, dynamic>>> fetchQuestionsBasedOnScores(
      Map<String, dynamic> scoreData) async {
    try {
      if (scoreData == null) {
        throw Exception("scoreData is null");
      }

      Map<String, dynamic> subjects = scoreData['subject_scores'] ?? {};
      print("subjects: $subjects");

      // กำหนดลำดับที่ต้องการของ subject
      List<String> subjectOrder = ['math_thai', 'english', 'laws'];

      // เรียง subjects ตาม subjectOrder
      List<String> sortedSubjects = [];
      subjectOrder.forEach((subject) {
        if (subjects.containsKey(subject)) {
          sortedSubjects.add(subject);
        }
      });

      List<Future<List<Map<String, dynamic>>>> questionFutures = [];

      // ตรวจสอบข้อมูลในแต่ละ subject และ topic
      sortedSubjects.forEach((subject) {
        print("กำลังประมวลผล subject: $subject");

        var subjectData = subjects[subject];
        if (subjectData is Map<String, dynamic>) {
          subjectData.forEach((topic, topicData) {
            print("กำลังคำนวณหัวข้อ: $topic");

            if (topicData is Map<String, dynamic>) {
              var stotalScores = topicData['stotal_scores'] ?? 0;
              var stotalQuestions =
                  topicData['stotal_questions'] ?? 1; // ป้องกันหาร 0

              double percentage = (stotalScores / stotalQuestions) * 100;
              print("คำนวณคะแนนสำหรับ $topic: $percentage%");

              // ใช้ topicLimits ในการคำนวณ difficulty และจำกัดจำนวนคำถาม
              String difficulty = calculateDifficulty(percentage, topic);
              print("difficulty สำหรับ $topic: $difficulty");

              int limit = topicLimits[topic] ??
                  5; // ใช้ค่า default 5 ถ้าไม่มีค่าใน topicLimits

              questionFutures.add(
                  fetchQuestionsByTopicAndDifficulty(topic, difficulty, limit));
            }
          });
        }
      });

      List<List<Map<String, dynamic>>> allQuestions =
          await Future.wait(questionFutures);

      if (allQuestions.isEmpty) {
        throw Exception("No questions found");
      }

      return allQuestions.expand((q) => q).toList();
    } catch (e) {
      print("❌ Error fetching questions based on scores: $e");
      return await loadPreTest();
    }
  }
  //จุดที่แก้
  Future<List<Map<String, dynamic>>> fetchQuestionsByTopicAndDifficulty(
    String topic, String difficulty, int limit) async {
  QuerySnapshot querySnapshot = await _firestore
      .collection('data')
      .where('topic', isEqualTo: topic)
      .where('difficulty', isEqualTo: difficulty)
      .limit(limit)
      .get();

  List<Map<String, dynamic>> result = querySnapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return {
      "question_id": doc.id,
      "question": data["question"] ?? "ไม่มีคำถาม",
      "options": [
        data["option_a"],
        data["option_b"],
        data["option_c"],
        data["option_d"]
      ],
      "answer": data["answer"],
      "explanation": data["explanation"],
      "subject": data["subject"] ?? "ไม่มีวิชา",
      "topic": data["topic"] ?? "ไม่มีหัวข้อ",
      "test_name": data["test_name"] ?? "ไม่มีชุดข้อสอบ",
      "no": data["no"] ?? "ไม่มีข้อ",
    };
  }).toList();

  // 🔁 ถ้าไม่เจอคำถามเลย ลองโหลด difficulty ที่ง่ายกว่า
  if (result.isEmpty && difficulty != 'easy') {
    print("⚠️ ไม่เจอคำถามสำหรับ $topic ที่ระดับ $difficulty → ลอง easy แทน");
    return await fetchQuestionsByTopicAndDifficulty(topic, 'easy', limit);
  }

  result.shuffle();
  return result.take(limit).toList();
    // return result;
}
}
