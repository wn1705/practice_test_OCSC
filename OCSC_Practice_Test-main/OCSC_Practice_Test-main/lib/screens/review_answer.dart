import 'package:flutter/material.dart';
import 'examtest.dart';
import '../services/exam_provider.dart';
import 'package:provider/provider.dart';

class ReviewAnswerPage extends StatefulWidget {
  ReviewAnswerPage({Key? key}) : super(key: key);

  @override
  _ReviewAnswerPageState createState() => _ReviewAnswerPageState();
}

class _ReviewAnswerPageState extends State<ReviewAnswerPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late String examId; // รับ exam_id จากภายนอก
  Map<int, bool> answeredQuestions = {};
  Duration _duration = Duration.zero; // Define _duration with an initial value

  @override
  void initState() {
    super.initState();
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
    // โหลดข้อมูลที่บันทึกไว้จาก Provider เมื่อเริ่มต้นหน้านี้
    final examProvider = Provider.of<ExamProvider>(context, listen: false);

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    examId = args['examId'] as String;

    // โหลดค่าใหม่เสมอ จาก Provider
    answeredQuestions = Map<int, bool>.from(examProvider.answeredQuestions);

    // ถ้า provider ยังว่าง ให้ fallback ไปใช้ค่าจาก arguments
    if (answeredQuestions.isEmpty && args['answeredQuestions'] != null) {
      answeredQuestions = Map<int, bool>.from(args['answeredQuestions'] as Map);
    }

    if (_duration == Duration.zero) {
      _duration = examProvider.duration;
    }
  }

  // ฟังก์ชันสำหรับเปลี่ยนสถานะการทำคำตอบ
  void _toggleAnswerStatus(int index) {
    setState(() {
      // answeredQuestions[index] = answeredQuestions[index] ?? false;
      answeredQuestions[index] = !(answeredQuestions[index] ?? false);
    });
    // อัปเดตค่า answeredQuestions ใน Provider
    final examProvider = Provider.of<ExamProvider>(context, listen: false);
    examProvider.updateAnsweredQuestions(answeredQuestions);
  }

  int get _completedQuestions {
    return answeredQuestions.values.where((answered) => answered).length;
  }

  // ฟังก์ชันสำหรับคำนวณเปอร์เซ็นต์ข้อที่ทำแล้ว
  double get _completionPercentage {
    return (_completedQuestions / 100) * 100;
  }

// ฟังก์ชันสำหรับไปยังข้อสอบที่เลือก
  void _navigateToQuestion(int questionNumber) async {
    // อัพเดตข้อมูลที่จำเป็นก่อนที่จะไปยังคำถามที่เลือก
    final examProvider = Provider.of<ExamProvider>(context, listen: false);
    examProvider.updateAnsweredQuestions(answeredQuestions);
    examProvider.updateDuration(_duration);
    examProvider.setCurrentQuestionNumber(questionNumber);

    // ส่งข้อมูลกลับไปยังหน้าก่อนหน้า (อัปเดต answeredQuestions และ remainingTime)
    Navigator.pop(context, {
      'answeredQuestions': answeredQuestions,
      'remainingTime': _duration,
    });

    await Future.delayed(Duration(milliseconds: 100));

    

    // ✅ โหลดค่าล่าสุดกลับมาหลังจากตอบเสร็จ
    if (mounted) {
      setState(() {
        answeredQuestions = Map<int, bool>.from(examProvider.answeredQuestions);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showExitDialog = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final _showExitConfirmationDialog = showExitDialog?['showExitDialog'];

    debugPrint(
        'Answered Questions: $answeredQuestions'); // ตรวจสอบค่า answeredQuestions
    return Scaffold(
      appBar: AppBar(
          automaticallyImplyLeading: false, // ปิดปุ่มย้อนกลับ
          backgroundColor: Colors.green.shade200,
          title: Text(
            'ทวนคำตอบ',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          centerTitle: true), // Title for review page

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // แสดง exam_id ที่ด้านบน
            Text(
              // "Exam ID: ${examId}",
              "Exam ID: ${examId.substring(0, 5)}", // show only 5 letters for UI
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // จัดข้อความให้ห่างกัน
              children: [
                Text(
                  "ทำไปแล้ว ${_completionPercentage.toStringAsFixed(2)}%",
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  "${_completedQuestions}/100",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),

            SizedBox(height: 8),

            // แสดง Progress Bar
            LinearProgressIndicator(
              key: ValueKey(_completionPercentage),
              value: _completionPercentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            SizedBox(height: 16),

            // GridView to display numbers in circles, 5 per row
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, // 5 items per row
                  crossAxisSpacing: 8.0, // Horizontal space between items
                  mainAxisSpacing: 8.0, // Vertical space between items
                ),
                itemCount: 100,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      _navigateToQuestion(index); // Navigate to question
                    },
                    onLongPress: () {
                      _toggleAnswerStatus(index); // Toggle answer status
                    },
                    child: CircleAvatar(
                      backgroundColor: answeredQuestions[index] == true
                          ? Colors.green
                          : Colors
                              .grey, // ใช้สีเขียวถ้าทำแล้ว, lightgrey ถ้ายังไม่ทำ
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            // Back button to return to the exam test
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                //ฟังก์ชันส่งข้อสอบ
                onPressed: () {
                  _showExitConfirmationDialog();

                },
                child: Text("ส่งข้อสอบ",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
