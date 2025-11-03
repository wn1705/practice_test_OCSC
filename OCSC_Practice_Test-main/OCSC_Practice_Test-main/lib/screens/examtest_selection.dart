import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/exam_service.dart';
import 'examtest.dart';
import 'package:ocsc_practice_test/services/exam_provider.dart';

class ExamTestSelection extends StatelessWidget {
  final int index; // รับค่า index จาก constructor

  ExamTestSelection({required this.index});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('รูปแบบการสอบ', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 30),
              Text(
                'เลือกรูปแบบการสอบ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 20),
              _buildOptionButton(context, 'จับเวลา', Colors.blue, true),
              SizedBox(height: 15),
              _buildOptionButton(context, 'ไม่จับเวลา', Colors.green, false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(
      BuildContext context, String title, Color color, bool isTimed) {
    return Container(
      width: 200,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 40),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          Provider.of<ExamProvider>(context, listen: false).resetExamData();
          // final examProvider = Provider.of<ExamProvider>(context, listen: false);
          // examProvider.resetExamData(); // ✅ เคลียร์ข้อมูลเก่าก่อนเริ่มชุดใหม่

          final examService = ExamService();
          final userId = FirebaseAuth.instance.currentUser!.uid;

          final questions =
              await examService.fetchQuestionsBasedOnIndex(index, userId);
          print("🍏 Now at index ${index}");

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuizPage(
                isTimedMode: isTimed,
                examId: 'exam_id',
                questionNumber: 0,
                no: 0,
                index: index,
                questions: questions,
              ),
            ),
          );
        },
        child: Text(
          title,
          style: TextStyle(
              fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
