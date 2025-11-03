import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'exam_service.dart';

class ExamProvider with ChangeNotifier {
  List<Map<String, dynamic>> _questions = [];
  final ExamService _examService = ExamService();

  List<Map<String, dynamic>> get questions => _questions;

  /// 📌 โหลดข้อสอบ
  Future<void> loadExamQuestions(String userId) async {
    _questions.clear();
    try {
      _questions = await _examService.fetchUserScoresAndLoadQuestions(userId);
      notifyListeners();
    } catch (e) {
      print("Error loading questions: $e");
    }
  }

  Map<int, bool> _answeredQuestions = {};
  Duration _duration = Duration.zero;
  Map<String, dynamic> _submittedAnswers = {};

  Map<String, dynamic> get submittedAnswers => _submittedAnswers;
  Duration get duration => _duration;
  Map<int, bool> get answeredQuestions => _answeredQuestions;

  int? _userScore;
  int? get userScore => _userScore;

  void updateAnswers(Map<String, dynamic> answers) {
    _submittedAnswers = answers;
    notifyListeners();
  }

  void updateAnsweredQuestions(Map<int, bool> answers) {
    _answeredQuestions = answers;
    notifyListeners();
  }

  void updateDuration(Duration newDuration) {
    _duration = newDuration;
    notifyListeners();
  }

  Future<void> fetchUserScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final scoreDoc = await FirebaseFirestore.instance
        .collection('scores')
        .doc(user.uid)
        .get();

    if (scoreDoc.exists) {
      _userScore = scoreDoc.data()?['scores'] as int?;
    } else {
      _userScore = null; // ยังไม่มีคะแนน
    }

    notifyListeners();
  }

  int? getUserScore() {
    return _userScore;
  }
  int currentQuestionNumber = 0;

void setCurrentQuestionNumber(int number) {
  currentQuestionNumber = number;
  notifyListeners();
}
void resetExamData() {
  _questions.clear();
  _submittedAnswers.clear();
  _answeredQuestions.clear();
  _duration = Duration.zero;
  _userScore = null;
  currentQuestionNumber = 0;
  notifyListeners();
}
}
