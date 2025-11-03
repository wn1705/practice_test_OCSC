import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'exam_result.dart'; // Import ExamResult page
import 'package:intl/intl.dart';

class ExamHistory extends StatelessWidget {
  final String userId; // รับ userId มาจากหน้าก่อนหน้า

  const ExamHistory({super.key, required this.userId});

  Future<List<Map<String, dynamic>>> fetchExamData() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('scores')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true) // เรียงจากใหม่ไปเก่า
        .get();

    // ตรวจสอบว่า querySnapshot มีข้อมูลหรือไม่
    if (querySnapshot.docs.isEmpty) {
      print('ไม่มีข้อมูล');
      return []; // ถ้าไม่มีข้อมูลจะคืนค่าเป็น list ว่าง
    }

    return querySnapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;

      // แปลง created_at จาก Timestamp เป็น DateTime
      DateTime? createdAt;
      if (data["created_at"] != null) {
        createdAt = (data["created_at"] as Timestamp).toDate(); // ใช้ .toDate() แทนการใช้ seconds
      }

      // ดึงคะแนนแต่ละวิชา
      final subjectScores = data['subject_scores'] ?? {};
      final mt_score = subjectScores['math_thai']?['stotal_scores'] ?? 0;
      final law_score = subjectScores['laws']?['stotal_scores'] ?? 0;
      final eng_score = subjectScores['english']?['stotal_scores'] ?? 0;

      // ตรวจสอบว่าผ่านแต่ละวิชาหรือไม่
      final isMathPassed = ((mt_score * 2) / 100) >= 0.6;
      final isLawPassed  = ((law_score * 2) / 50) >= 0.6;
      final isEngPassed  = ((eng_score * 2) / 50) >= 0.5;

      final passed = (isMathPassed && isLawPassed && isEngPassed) ? "ผ่าน" : "ไม่ผ่าน";

      return {
        "id": data["exam_id"] ?? "N/A",
        "date": createdAt != null ? DateFormat("dd/MM/yyyy").format(createdAt) : "N/A",
        "duration": createdAt != null
            ? "${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')} น."
            : "N/A",
        "result": passed,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // ปิดปุ่มย้อนกลับ
        title: const Text('ประวัติการทำข้อสอบ',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade200,
      ),

      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchExamData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("ไม่มีประวัติการสอบ"));
            }
            final examData = snapshot.data!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // หัวตาราง
                Row(
                  children: const [
                    Expanded(flex: 2,
                        child: Text('ข้อสอบ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center)),
                    Expanded(flex: 3,
                        child: Text('วันที่สอบ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center)),
                    Expanded(flex: 3,
                        child: Text('เวลาที่สอบ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center)),
                    Expanded(flex: 3,
                        child: Text('ผลการสอบ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center)),
                    Expanded(flex: 3, child: SizedBox()), // ปุ่ม "ดูคะแนน"
                  ],
                ),
                const Divider(),

                // รายการผลสอบ
                Expanded(
                  child: ListView.builder(
                    itemCount: examData.length,
                    itemBuilder: (context, index) {
                      final exam = examData[index];
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "${exam["id"].substring(0, 5)}",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                    exam["date"], textAlign: TextAlign.center, style: TextStyle(fontSize: 13)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(exam["duration"],
                                    textAlign: TextAlign.center),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  exam["result"],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: exam["result"] == "ผ่าน" ? Colors
                                        .green : Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/exam_result',
                                      arguments: {
                                        "exam_id": exam["id"],
                                      },
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                  ),
                                  child: const Text('ดูคะแนน'),
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }}