import 'package:flutter/material.dart';
import 'services/firebaseConf.dart'; // นำเข้าไฟล์ที่มี initializeFirebase()

import 'screens/login.dart';
import 'screens/examtest_selection.dart';
import 'screens/examtest.dart';
import 'screens/exam_result.dart';
import 'screens/sub_details.dart';
import 'screens/review_answer.dart';
import 'package:provider/provider.dart';
import 'services/exam_provider.dart';
import '../widgets/navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseConfig.initializeFirebase();

  // runApp(MyApp());
  runApp(
    ChangeNotifierProvider(
      create: (context) => ExamProvider()..fetchUserScore(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Login App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
      routes: {
        '/dashboard': (context) => NavigationExample(),
        '/examtestselection': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          int index = args?['index'] ?? 0; // รับค่า index จาก arguments
          return ExamTestSelection(index: index); // ส่งไปยัง ExamTestSelection
        },
        '/examtest': (context) {
          // สมมุติว่าเราส่งค่า arguments ไปที่ QuizPage
          final arguments = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;

          final examId = arguments['examId']; // examId ที่ส่งไป
          final questionNumber =
              arguments['questionNumber']; // questionNumber ที่ส่งไป
          final no = arguments['no']; // no ที่ส่งไป
          final questions = arguments['questions']; // questions ที่ส่งไป
          final index = arguments['index'];

          return QuizPage(
            examId: examId,
            questionNumber: questionNumber,
            no: no,
            questions: questions,
            index: index,
          );
        },
        '/sub_details': (context) => SubjectDetails(),
        '/review_answer': (context) => ReviewAnswerPage(),
        '/exam_result': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>? ??
              {};
          return ExamResult(
            exam_id: args['exam_id'] ?? 'N/A',
          );
        },
      },
    );
  }
}
