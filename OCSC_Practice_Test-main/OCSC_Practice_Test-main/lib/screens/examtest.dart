import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:uuid/uuid.dart';

import 'errors_report.dart';
import 'package:ocsc_practice_test/widgets/quiz_navigation.dart';
import 'package:ocsc_practice_test/services/exam_provider.dart';
import 'package:ocsc_practice_test/services/exam_service.dart';

class QuizPage extends StatefulWidget {
  final String examId; // เพิ่มตัวแปร examId
  final int questionNumber; // เพิ่มตัวแปร questionNumber
  final int no;
  final int index;
  final List<Map<String, dynamic>> questions;

  final bool isTimedMode; //////รับค่าตัวแปรมาจากก่อนหน้านี้examtest_selection
  QuizPage({
    required this.examId,
    required this.questionNumber,
    this.isTimedMode = true,
    required this.no,
    // required List<Map<String, dynamic>> questions,
    required this.index,
    required this.questions,
  });

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage>
    with AutomaticKeepAliveClientMixin {
  @override
  final ExamService _examService = ExamService();
  bool get wantKeepAlive => true;
  ////////////////////////////////////////////
  late bool isTimed;
  late Timer _timer;
  Duration _duration = Duration.zero;
  Duration _initialDuration = Duration(hours: 3); // 3 hours
  Duration? _maxDuration; //  non-timed mode ไม่จำกัดเวลา
  String timerDisplay = '00:00:00';
  ////////////ฟังก์ชันจับเวลา////////////////////////
  late Map<int, bool> answeredQuestions; // ประกาศตัวแปร answeredQuestions

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? user_id;
  String? examId;
  Map<int, String?> selectedAnswers = {}; // Store selected options
  Map<int, bool> submittedAnswers = {}; // Store if answer was submitted

  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  int score = 0;
  String? selectedOption;
  bool showAnswer = false;
  bool isAnswerSubmitted = false;

  int selectedNavIndex = 1; // Start at "Review" by default

  @override
  void initState() {
    super.initState();
    _getuser_id(); // Fetch user id on initialization
    examId = Uuid().v4();

    // ตรวจสอบสถานะของคำตอบและเวลาเมื่อเริ่มต้น
    final examProvider = Provider.of<ExamProvider>(context, listen: false);


    // ตรวจสอบสถานะของคำตอบและเวลาเมื่อเริ่มต้น
    answeredQuestions = examProvider.answeredQuestions;
    _duration = examProvider.duration;

    currentQuestionIndex = widget.questionNumber;

    fetchQuestions();

    /////////////ฟังก์ชันจับเวลา//////////////////////
    isTimed = widget.isTimedMode;
    // Set this to true or false based on your app's logic
    if (isTimed) {
      _duration = _initialDuration; // หากจับเวลา เริ่มที่ 3 ชั่วโมง
    } else {
      _duration = Duration.zero; // ถ้าไม่จับเวลา เริ่มที่ 0
    }
    timerDisplay = _formatDuration(_duration);
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final examProvider = Provider.of<ExamProvider>(context, listen: false);

    setState(() {
      currentQuestionIndex = examProvider.currentQuestionNumber;
    });
  }

  Map<String, Map<String, dynamic>> structuredScores = {
    "math_thai": {},
    "english": {},
    "laws": {}
  };

  /// ✅ โหลดคะแนนและข้อสอบ
  Future<void> fetchUserScoresAndLoadQuestions() async {
    // await _getuser_id(); // โหลด user_id ก่อน
    if (user_id != null) {
      questions = await _examService.fetchUserScoresAndLoadQuestions(user_id!);
      setState(() {}); // รีเฟรช UI
    } else {
      print("❌ ไม่พบ user_id");
    }
  }

///////////ฟังก์ชันจับเวลา//////////////////////
  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (isTimed) {
          // โหมดจับเวลา: นับถอยหลัง
          if (_duration.inSeconds > 0) {
            _duration = _duration - Duration(seconds: 1);
            timerDisplay = _formatDuration(_duration);
          } else {
            // หมดเวลา
            _timer.cancel();
            _showTimeUpDialog();
          }
        } else {
          // โหมดไม่จับเวลา: นับขึ้น
          _duration = _duration + Duration(seconds: 1);
          timerDisplay = _formatDuration(_duration);
        }
      });
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  ///////ฟังก์ชันจับเวลา/////////////////////////////////////
  // Fetch the user ID from Firebase Authentication
  Future<void> _getuser_id() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        user_id = user.uid;
        await _checkUserInUserManagement(
            user_id); // เชื่อมต่อกับ user_management
      } else {
        print("❌ User is not logged in.");
      }
    } catch (e) {
      print("❌ Error fetching user ID: $e");
    }
  }

  Future<void> _checkUserInUserManagement(String? user_id) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user_management')
          .doc(user_id)
          .get();
      if (!userDoc.exists) {
        // ถ้า user ไม่เคยมีข้อมูลใน user_management ให้สร้างข้อมูลใหม่
        await FirebaseFirestore.instance
            .collection('user_management')
            .doc(user_id)
            .set({
          'createdAt': Timestamp.now(),
          // ข้อมูลอื่น ๆ ที่คุณต้องการเก็บ
        });
      }
    } catch (e) {
      print("❌ Error checking user in user_management: $e");
    }
  }

  void fetchQuestions() async {
    if (user_id != null) {
      // เรียกฟังก์ชัน fetchQuestionsBasedOnIndex ที่มีอยู่ใน ExamService
      final fetchedQuestions = await _examService.fetchQuestionsBasedOnIndex(
        widget.index, // ใช้ index ที่ส่งมาจาก ExamTestSelection
        user_id!,
      );

      print('🍎 Fetched Questions: $fetchedQuestions');

      // รีเฟรชข้อมูลข้อสอบ
      setState(() {
        questions = fetchedQuestions;
      });
    }
  }

  //เปลี่ยนส่วนนี้เรื่องการคำนวณ คือปัญหา การคำนวณ ได้19/100 แต่ในresultได้ 15/100 แล้วคะแนนรายtopicได้15 ไปเช็คในfirrebaseก็ได้15 แต่คะแนนรวม100 ได้19
  Future<void> saveUserScoreToFirestore({
    required int totalQuestions,
    required String timeTaken,
    required Map<String, dynamic> subjectScores,
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint("❌ User is not logged in, cannot save score!");
        return;
      }

      String userId = user.uid;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      int correctAnswers = 0; //

      Map<String, Map<String, dynamic>> structuredScores = {
        "math_thai": {"stotal_scores": 0, "stotal_questions": 0},
        "english": {"stotal_scores": 0, "stotal_questions": 0},
        "laws": {"stotal_scores": 0, "stotal_questions": 0},
      };

      for (var i = 0; i < questions.length; i++) {
        String subject = questions[i]["subject"] ?? "";
        String topic = questions[i]["topic"] ?? "";

        // bool isCorrect = selectedAnswers[i] == questions[i]["answer"];

        if (!structuredScores.containsKey(subject)) {
          structuredScores[subject] = {
            "stotal_scores": 0,
            "stotal_questions": 0
          };
        }

        if (!structuredScores[subject]!.containsKey(topic)) {
          structuredScores[subject]![topic] = {
            "ttotal_scores": 0,
            "ttotal_questions": 0
          };
        }

        structuredScores[subject]!["stotal_questions"] += 1;
        structuredScores[subject]![topic]["ttotal_questions"] += 1;

        // ✅ เฉพาะข้อที่ตอบ และถูกต้อง ค่อยเพิ่ม score
        if (selectedAnswers[i] != null) {
        bool isCorrect = selectedAnswers[i] == questions[i]["answer"];
        if (isCorrect) {
          structuredScores[subject]!["stotal_scores"] += 1;
          structuredScores[subject]![topic]["ttotal_scores"] += 1;
          correctAnswers += 1; //
        }
        }
      }

      // ✅ บันทึกลง Firestore
      await firestore.collection('scores').add({
        'user_id': userId,
        'exam_id': examId,
        'total_questions': totalQuestions,
        'total_scores': correctAnswers, //
        'time_taken': timeTaken,
        'subject_scores': structuredScores,
        'created_at': FieldValue.serverTimestamp(),
        'pretest_done': true,
        'index': widget.index,
      });

      // ✅ เก็บผลลัพธ์ของแต่ละข้อใน exam_set
      List<Map<String, dynamic>> questionResults = [];
      for (int i = 0; i < questions.length; i++) {
        questionResults.add({
          "data_no": questions[i]["no"],
          "result": selectedAnswers[i] == questions[i]["answer"],
          "test_name": questions[i]["test_name"],
          "topic": questions[i]["topic"],
        });
      }

      await firestore.collection('exam_set').add({
        "index": widget.index,
        "exam_id": examId,
        "user_id": userId,
        "question_results": questionResults,
        "created_at": FieldValue.serverTimestamp(),
      });

      await updateProgress(
        index: widget.index,
        userId: userId,
        structuredScores: structuredScores,
      );

      debugPrint("✅ Exam score saved successfully for user: $userId");
      Provider.of<ExamProvider>(context, listen: false).resetExamData();

    } catch (e) {
      debugPrint("❌ Error saving score: $e");
    }
  }

  // ฟังก์ชันเพื่อแสดง dialog ยืนยันการออกจากห้องสอบ
  Future<void> _showExitConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // ปิดการ dismiss dialog เมื่อคลิกข้างนอก
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('คุณต้องการออกจากห้องสอบ?'),
          content: Text('ระบบจะบันทึกคะแนนและออกจากห้องสอบ'),
          actions: <Widget>[
            TextButton(
              child: Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop(); // ปิด dialog
              },
            ),
            TextButton(
              child: Text('จบการทดสอบ'),
              onPressed: () {
                // เพิ่มฟังก์ชันจบการทดสอบ เช่น ส่งคะแนน หรือบันทึกผล
                Navigator.of(context).pop(); // ปิด dialog
                _submitExam(); // เรียกฟังก์ชันสำหรับส่งคะแนน
              },
            ),
          ],
        );
      },
    );
  }

  //โหลดดีเลย์ข้อมูลหลังจากสอบเสร็จก่อนส่งไปหน้า result
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: const [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('กำลังรวบรวมข้อมูล...')),
          ],
        ),
      ),
    );
  }

//////////////submutexamฟังก์ขันจับเวลา///////////////
  Future<void> _submitExam() async {
    _timer?.cancel();
    // ตรวจสอบค่า isTimed ก่อนคำนวณเวลา
    Duration timeTaken = isTimed
        ? _initialDuration - _duration // ถ้าจับเวลา ให้ลบจากค่าเริ่มต้น
        : _duration; // ถ้าไม่จับเวลา ใช้ค่าปัจจุบันตรง ๆ

    String duration = _formatDuration(timeTaken);

    _showLoadingDialog(); // 👈 แสดง loading

    // Implement the logic to submit the exam
    await saveUserScoreToFirestore(
      totalQuestions: questions.length,
      // totalScore: score, // Removed as it is not defined in the method
      timeTaken: duration,
      // timerDisplay
      subjectScores: structuredScores,
    );
    print("Exam submitted");


    await Future.delayed(const Duration(seconds: 3));
    // 👈 ปิด loading dialog
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/exam_result',
      (route) => false,
      arguments: {
        'exam_id': examId,
      },
    );
    context.read<ExamProvider>().resetExamData();
  }

  //////////////submutexamฟังก์ขันจับเวลา///////////////

  void submitAnswer() {
    if (selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกคำตอบก่อนกดยืนยัน')),
      );
      return;
    }

    final examProvider = Provider.of<ExamProvider>(context, listen: false);
    Map<String, dynamic> updatedAnswers = examProvider.submittedAnswers;
    updatedAnswers[currentQuestionIndex.toString()] = selectedOption;

    examProvider.updateAnswers(updatedAnswers);
    // ✅ เพิ่มส่วนนี้เพื่อบันทึกว่าข้อนี้ตอบแล้ว
    examProvider.answeredQuestions[currentQuestionIndex] = true;
    examProvider.updateAnsweredQuestions(examProvider.answeredQuestions);

    setState(() {
      submittedAnswers[currentQuestionIndex] =
          true; // Mark the question as answered
      selectedAnswers[currentQuestionIndex] = selectedOption; // Save answer
      showAnswer = true;
    });

    if (selectedOption == questions[currentQuestionIndex]["answer"]) {
      score++;
    }
  }

  Future<void> updateProgress({
    required int index,
    required String userId,
    required Map<String, dynamic> structuredScores,
  }) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final progressDocRef = firestore.collection('progress').doc(userId);
    final progressSnapshot = await progressDocRef.get();

    // รวมคะแนนของแต่ละวิชา
    int englishScore = structuredScores["english"]?["stotal_scores"] ?? 0;
    int lawsScore = structuredScores["laws"]?["stotal_scores"] ?? 0;
    int mathThaiScore = structuredScores["math_thai"]?["stotal_scores"] ?? 0;
    int totalProgressScore = englishScore + lawsScore + mathThaiScore;

    bool isPreTest = index == 0;
    bool isPostTest = index == 12;

    try {
      if (isPreTest) {
        if (!progressSnapshot.exists ||
            !(progressSnapshot.data()?.containsKey('pre_test') ?? false)) {
          // บันทึก pre-test ครั้งแรก
          await progressDocRef.set({
            'tpre_scores': totalProgressScore,
            'pre_test': {
              'english': englishScore,
              'laws': lawsScore,
              'math_thai': mathThaiScore,
            }
          }, SetOptions(merge: true));
          debugPrint("✅ Pre-test saved (first time)");
        } else {
          debugPrint("⏩ Pre-test already exists, skipping update");
        }
      } else if (isPostTest) {
        // บันทึก post-test ทุกครั้ง (ล่าสุด)
        await progressDocRef.set({
          'tpost_scores': totalProgressScore,
          'post_test': {
            'english': englishScore,
            'laws': lawsScore,
            'math_thai': mathThaiScore,
          }
        }, SetOptions(merge: true));
        debugPrint("✅ Post-test updated (latest)");
      }
    } catch (e) {
      debugPrint("❌ Error updating progress: $e");
    }
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.alarm_off,
              color: Colors.black,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'หมดเวลา',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.redAccent,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitExam();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'ส่งข้อสอบ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

//=================================== Widget build =================================== //
  @override
  Widget build(BuildContext context) {
    print("🍏 Questions in QuizPage: $questions");
    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    //
    final currentQuestion = questions[currentQuestionIndex];
    final examProvider = Provider.of<ExamProvider>(context);
    selectedOption = selectedAnswers[currentQuestionIndex] ??
        examProvider.submittedAnswers[currentQuestionIndex.toString()];

    isAnswerSubmitted = examProvider.submittedAnswers
        .containsKey(currentQuestionIndex.toString());
    showAnswer = isAnswerSubmitted;

    return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // ปิดปุ่มย้อนกลับ
          backgroundColor: Colors.green.shade200,
          title: Center(
            child: Text(
              isTimed
                  ? 'เวลาที่เหลือ: $timerDisplay' // "Time remaining" for timed mode
                  : 'เวลาที่ใช้: $timerDisplay', // "Time used" for non-timed mode
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isTimed && _duration.inMinutes < 10
                    ? Colors.red
                    : Colors.black, // Red text when < 10 min remaining
              ),
            ),
          ),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.exit_to_app),
              onPressed: () {
                // แสดง dialog ยืนยันการออกจากห้องสอบ
                _showExitConfirmationDialog();
              },
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: ListView(
            children: [
              Text('คำถาม ${currentQuestionIndex + 1}/${questions.length}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GptMarkdown(
                currentQuestion["question"].replaceAll(r"\n", "\n"),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ...currentQuestion["options"].map<Widget>((option) {
                bool isCorrect = option == currentQuestion["answer"];
                bool isSelected = option == selectedOption;
                bool isWrong = isSelected && !isCorrect && isAnswerSubmitted;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: isAnswerSubmitted
                        ? (option == currentQuestion["answer"]
                            ? Colors.green.withOpacity(0.3)
                            // : (option == selectedOption
                            : (isWrong ? Colors.red.withOpacity(0.3) : null))
                        : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: RadioListTile<String>(
                    value: option.toString(),
                    groupValue: selectedOption,
                    title: GptMarkdown(
                      // Render LaTeX inside Radio Button
                      option.toString().replaceAll(r"\n", "\n"),
                      style: const TextStyle(fontSize: 16),
                    ),
                    onChanged: isAnswerSubmitted
                        ? null
                        : (value) {
                            setState(() {
                              selectedOption = value;
                              selectedAnswers[currentQuestionIndex] = value;
                            });
                          },
                    activeColor: Colors.blue,
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    examProvider.setCurrentQuestionNumber(currentQuestionIndex);
                    submitAnswer();
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(150, 50),
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'ยืนยันคำตอบ',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    onPressed: () {
                      if (currentQuestion != null) {
                        reportErrorDialog(context, {
                          "questionNumber": currentQuestionIndex,
                          "question": currentQuestion["question"] ?? "N/A",
                          "test_name": currentQuestion["test_name"] ?? "N/A",
                          "subject": currentQuestion["subject"] ?? "N/A",
                          "topic": currentQuestion["topic"] ?? "N/A",
                          "no": currentQuestion["no"] ?? "N/A",
                          "exam_id": examId,
                        });
                      } else {
                        print("⚠️ currentQuestion เป็น null!");
                      }
                    },
                    child: const Text(
                      'รายงานความผิดพลาด',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (showAnswer) ...[
                GptMarkdown(
                  'คำตอบที่ถูกต้อง: \n${currentQuestion["answer"]}'
                      .replaceAll(r"\n", "\n"),
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 8),
                GptMarkdown(
                  'คำอธิบาย: \n${currentQuestion["explanation"]}'
                      .replaceAll(r"\n", "\n"),
                  style: TextStyle(color: Colors.blue[900]),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        bottomNavigationBar: ExamNavigation(
            selectedIndex: selectedNavIndex,
            onItemTapped: (int index) async {
              // ✅ เปลี่ยนให้เป็น async function
              if (index == 1) {
                // ตรวจสอบว่าเป็นการกดปุ่มไปหน้า Review Answer
                final result = await Navigator.pushNamed(
                  context,
                  '/review_answer',
                  arguments: {
                    'examId': examId, // ส่ง examId
                    'answeredQuestions':
                        submittedAnswers, // ส่ง answeredQuestions
                    'remainingTime': _duration,
                    'showExitDialog': _showExitConfirmationDialog,
                  },
                );

                // 🔹 ถ้ากลับมาพร้อมข้อมูล answeredQuestions ที่อัปเดตแล้ว
                if (result != null && result is Map<int, bool>) {
                  setState(() {
                    submittedAnswers = result; // ✅ อัปเดตค่าคำตอบที่ส่งกลับมา
                    selectedAnswers = result.map((key, value) =>
                        MapEntry(int.parse(key as String), value.toString()));
                  });
                }
              } else {
                setState(() async {
                  selectedNavIndex = index;

                  if (index == 0 && currentQuestionIndex > 0) {
                    currentQuestionIndex--;
                  } else if (index == 2) {
                    if (currentQuestionIndex < questions.length - 1) {
                      currentQuestionIndex++;
                      // selectedOption = null;
                      selectedOption = selectedAnswers[currentQuestionIndex] ??
                          examProvider.submittedAnswers[
                              currentQuestionIndex.toString()];
                    } else {
                      await _showExitConfirmationDialog();
                    }
                  }
                });
              }
            }));
  }
}
