import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'dart:math';
import 'package:intl/intl.dart';

import '../widgets/navigation.dart';

class ExamResult extends StatefulWidget {
  final String exam_id;

  const ExamResult({super.key, required this.exam_id});

  @override
  _ExamResultState createState() => _ExamResultState();
}

class _ExamResultState extends State<ExamResult> {
  int currentPageIndex = 0;
  int score = 0;
  int mt_score = 0, law_score = 0, eng_score = 0;
  String result = 'ไม่ระบุ';
  String examDate = 'ไม่มี';
  String examTime = 'ไม่มี';
  String duration = 'ไม่ระบุ';
  String date = 'ไม่ระบุ';
  bool isLoading = true;

  List<Map<String, dynamic>> subjectScores = [];

  @override
  void initState() {
    super.initState();
    fetchExamResult();
  }

  Future<void> fetchExamResult() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('scores')
          .where('exam_id', isEqualTo: widget.exam_id)
          .get();

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      querySnapshot.docs.forEach((doc) {
        // print('Document ID: ${doc.id}');
        // print('Document Data: ${doc.data()}'); // แสดงข้อมูลทั้งหมดในเอกสาร
        print('created_at value: ${data['created_at']}');
        // print('subject value: ${data['subject_scores']}');
      });
      final subjectScoresMap = data['subject_scores'] as Map<String, dynamic>?;
      final created_at = data['created_at'];
      print('created_value value: $created_at');


      setState(() {
        score = data['total_scores'] ?? 0;
        mt_score = subjectScoresMap?['math_thai']?['stotal_scores'] ?? 0;
        law_score = subjectScoresMap?['laws']?['stotal_scores'] ?? 0;
        eng_score = subjectScoresMap?['english']?['stotal_scores'] ?? 0;

        // ตรวจสอบว่าผ่านแต่ละวิชาหรือไม่ โดยใช้ mt_score แทน mathScore
        final isMathPassed = ((mt_score * 2) / 100) >= 0.6;
        final isLawPassed  = ((law_score * 2) / 50) >= 0.6;
        final isEngPassed  = ((eng_score * 2) / 50) >= 0.5;



        subjectScores = [
          {
            "subject": "วิชาความสามารถในการคิดวิเคราะห์",
            "criteria": "เกณฑ์การสอบผ่านต้องได้คะแนนไม่ต่ำกว่าร้อยละ 60",
            "fullScore": 100,
            "score": mt_score
          },
          {
            "subject": "วิชาความรู้และลักษณะการเป็นข้าราชการที่ดี",
            "criteria": "เกณฑ์การสอบผ่านต้องได้คะแนนไม่ต่ำกว่าร้อยละ 60",
            "fullScore": 50,
            "score": law_score
          },
          {"subject": "วิชาภาษาอังกฤษ",
            "criteria": "เกณฑ์การสอบผ่านต้องได้คะแนนไม่ต่ำกว่าร้อยละ 50",
            "fullScore": 50,
            "score": eng_score},
        ];

        // result = examPassed ? "ผ่าน" : "ไม่ผ่าน";
        result = (isMathPassed && isLawPassed && isEngPassed) ? "ผ่าน" : "ไม่ผ่าน";
        duration = data['time_taken'] ?? 'ไม่ระบุ';

        final created_at = data['created_at'];
        if (created_at is Timestamp) {
          final datetime = created_at.toDate();
          examDate = DateFormat('dd/MM/yyyy').format(datetime);
          examTime = DateFormat('HH:mm').format(datetime);
        } else {
          examDate = 'ไม่สามารถโหลดเวลาได้';
          examTime = '-';
        }
        isLoading = false; // เปลี่ยนค่า isLoading เมื่อโหลดเสร็จแล้ว
      });
    } catch (e) {
      print('Error fetching exam result: $e');
      setState(() => isLoading = false); // ในกรณีที่เกิด error
    }
  }

  void onTabTapped(int index) {
    setState(() {
      currentPageIndex = index;
    });

    // ใช้ Navigator.pop() เพื่อกลับไปที่หน้า NavigationExample
    // กลับไปหน้าก่อนหน้า

    // ใช้ Navigator.pushReplacementNamed เพื่อให้ไม่ซ้อนกัน
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const NavigationExample(initialIndex: 0)),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const NavigationExample(initialIndex: 1)),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => const NavigationExample(initialIndex: 2)),
        );
        break;
    }
  }

  Widget buildSubjectScores() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('คะแนนตามรายวิชา',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subjectScores.length,
          itemBuilder: (context, index) {
            final subject = subjectScores[index];
            // final criteria = subjectScores[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subject['subject'],
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subject['criteria'],
                      style: const TextStyle(
                          fontSize: 12, color: Colors.redAccent)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                          child: Text('คะแนนเต็ม: ${subject['fullScore']}',
                              style: const TextStyle(fontSize: 16))),
                      Expanded(
                          child: Text('คะแนนที่ได้: ${subject['score']*2}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/sub_details',
                        arguments: {
                          'exam_id': widget.exam_id,
                          'subject': subject['subject'],
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                    ),
                    child: const Center(
                      child: Text('ดูคะแนนตามสัดส่วน',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green.shade200,
          title: const Text('ผลการสอบ'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    double percentage = min((score)/ 100, 1.0);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.green.shade200,
        title: const Text('ผลการสอบ'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ข้อสอบชุดที่ ${widget.exam_id.substring(0, 5)}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildRichText("วันที่สอบ: ", examDate)),
                Expanded(child: _buildRichText("เวลาที่สอบ: ", '$examTime')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildRichText("คุณทำได้: ", '$score/100 ข้อ')),
                Expanded(child: _buildRichText("เวลาที่ใช้ไป: ", duration)),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: CircularPercentIndicator(
                radius: 70.0,
                lineWidth: 15.0,
                animation: true,
                percent: percentage,
                center: Text(
                  '${score.floor()}/100',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                    color: Colors.green,
                  ),
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: Colors.green.shade400,
                backgroundColor: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                result,
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: result == "ผ่าน" ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 30),
            buildSubjectScores(),
          ],
        ),
      ),
      bottomNavigationBar: MyBottomNavigationBar(
        currentIndex: currentPageIndex,
        onTap: onTabTapped,
      ),
    );
  }

  Widget _buildRichText(String label, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
              text: label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          TextSpan(text: value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
