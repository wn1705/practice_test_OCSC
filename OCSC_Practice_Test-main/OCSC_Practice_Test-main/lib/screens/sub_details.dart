import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectDetails extends StatefulWidget {
  @override
  _SubjectDetailsState createState() => _SubjectDetailsState();
}

class _SubjectDetailsState extends State<SubjectDetails> {
  final List<Map<String, dynamic>> subjectScores = [
    {
      "subject": "วิชาความสามารถในการคิดวิเคราะห์",
      "topics": [
        {"topic": "อนุกรม", "fullScore": 5, "score": 0},
        {"topic": "คณิตศาสตร์ทั่วไป", "fullScore": 5, "score": 0},
        {"topic": "ตารางข้อมูล", "fullScore": 5, "score": 0},
        {"topic": "เงื่อนไขสัญลักษณ์", "fullScore": 10, "score": 0},
        {"topic": "เงื่อนไขภาษา", "fullScore": 5, "score": 0},
        {"topic": "อุปมาอุปไมย", "fullScore": 5, "score": 0},
        {"topic": "เรียงประโยค", "fullScore": 5, "score": 0},
        {"topic": "บทความ", "fullScore": 10, "score": 0},
      ],
    },
    {
      "subject": "วิชาภาษาอังกฤษ",
      "topics": [
        {"topic": "บทสนทนา", "fullScore": 5, "score": 0},
        {"topic": "ไวยากรณ์", "fullScore": 5, "score": 0},
        {"topic": "คำศัพท์", "fullScore": 5, "score": 0},
        {"topic": "การอ่าน", "fullScore": 10, "score": 0},
      ],
    },
    {
      "subject": "วิชาความรู้และลักษณะการเป็นข้าราชการที่ดี",
      "topics": [
        {
          "topic": "พ.ร.บ.ระเบียบบริหาราชการแผ่นดิน",
          "fullScore": 6,
          "score": 0
        },
        {
          "topic": "พ.ร.ก.ว่าด้วยหลักเกณฑ์และการบริหารกิจการบ้านเมืองที่ดี",
          "fullScore": 6,
          "score": 0
        },
        {
          "topic": "พ.ร.บ.วิธีปฏิบัติราชการทางปกครอง",
          "fullScore": 6,
          "score": 0
        },
        {
          "topic": "ประมวลกฎหมายอาญาความผิดต่อตำแหน่งหน้าที่ราชการ",
          "fullScore": 2,
          "score": 0
        },
        {"topic": "พ.ร.บ.มาตรฐานทางจริยธรรม", "fullScore": 3, "score": 0},
        {
          "topic": "พ.ร.บ.ความรับผิดทางละเมิดของเจ้าหน้าที่",
          "fullScore": 2,
          "score": 0
        },
      ],
    },
  ];

  Map<String, dynamic> fetchedScores = {};
  Map<String, dynamic>? selectedSubject; // ใช้ selectedSubject เป็น nullable

  //math_thai variable
  int article_score = 0;
  int analogy_score = 0;
  int dtable_score = 0;
  int ling_score = 0;
  int gmath_score = 0;
  int sentrear_score = 0;
  int series_score = 0;
  int symbol_score = 0;

  //english variable
  int speaking_score = 0;
  int grammar_score = 0;
  int reading_score = 0;
  int vocab_score = 0;

  //laws variable
  int admin_procedure = 0;
  int criminal_code = 0;
  int ethics = 0;
  int good_govern = 0;
  int state_admin = 0;
  int tortious = 0;
  String? examId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?; // รับ args
    if (args != null && args['exam_id'] != null) {
      examId = args['exam_id'];

      // ตรวจสอบว่า args['subject'] เป็น String หรือไม่
      final subjectName = args['subject'];
      if (subjectName is String) {
        // ตรวจสอบว่าเป็น String
        selectedSubject = subjectScores.firstWhere(
          (subject) => subject['subject'] == subjectName,
          orElse: () => {},
        );

        if (selectedSubject != null && selectedSubject!.isNotEmpty) {
          // ใช้ selectedSubject ต่อได้เลย เช่นเก็บไว้ใน state เพื่อแสดงผล
          print('รับ subject แล้ว: ${selectedSubject!['subject']}');
        }
      } else {
        print('subject ไม่ใช่ String');
      }

      fetchScores(examId!);
    }
  }

  Future<void> fetchScores(String examId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('scores')
          .where('exam_id', isEqualTo: examId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final subjectScoresData = doc.data()['subject_scores'];
        if (subjectScoresData != null) {
          setState(() {
            fetchedScores = Map<String, dynamic>.from(subjectScoresData);
          });
          updateSubjectScores();
        }
      }
    } catch (e) {
      print('Error fetching scores: $e');
    }
  }

  void updateSubjectScores() {
    setState(() {
      // วิชาความสามารถในการคิดวิเคราะห์
      analogy_score =
          fetchedScores['math_thai']?['analogy']?['ttotal_scores'] ?? 0;
      article_score =
          fetchedScores['math_thai']?['article']?['ttotal_scores'] ?? 0;
      dtable_score =
          fetchedScores['math_thai']?['dtable']?['ttotal_scores'] ?? 0;
      gmath_score = fetchedScores['math_thai']?['gmath']?['ttotal_scores'] ?? 0;
      ling_score =
          fetchedScores['math_thai']?['ling_condition']?['ttotal_scores'] ?? 0;
      sentrear_score =
          fetchedScores['math_thai']?['sent_rearrange']?['ttotal_scores'] ?? 0;
      series_score =
          fetchedScores['math_thai']?['series']?['ttotal_scores'] ?? 0;
      symbol_score =
          fetchedScores['math_thai']?['symb_condition']?['ttotal_scores'] ?? 0;

      // วิชาภาษาอังกฤษ
      speaking_score =
          fetchedScores['english']?['conver']?['ttotal_scores'] ?? 0;
      grammar_score =
          fetchedScores['english']?['grammar']?['ttotal_scores'] ?? 0;
      reading_score =
          fetchedScores['english']?['reading']?['ttotal_scores'] ?? 0;
      vocab_score = fetchedScores['english']?['vocab']?['ttotal_scores'] ?? 0;

      // วิชาความรู้ความสามารถในการเป็นข้าราชการที่ดี
      admin_procedure =
          fetchedScores['laws']?['admin_procedure']?['ttotal_scores'] ?? 0;
      criminal_code =
          fetchedScores['laws']?['criminal_code']?['ttotal_scores'] ?? 0;
      ethics = fetchedScores['laws']?['ethics']?['ttotal_scores'] ?? 0;
      good_govern =
          fetchedScores['laws']?['good_govern']?['ttotal_scores'] ?? 0;
      state_admin =
          fetchedScores['laws']?['state_admin']?['ttotal_scores'] ?? 0;
      tortious = fetchedScores['laws']?['tortious']?['ttotal_scores'] ?? 0;

      // อัพเดตข้อมูลใน subjectScores
      subjectScores[0]['topics'] = [
        {"topic": "อนุกรม", "fullScore": 5, "score": series_score},
        {"topic": "บทความ", "fullScore": 10, "score": article_score},
        {"topic": "ตารางข้อมูล", "fullScore": 5, "score": dtable_score},
        {"topic": "คณิตศาสตร์ทั่วไป", "fullScore": 5, "score": gmath_score},
        {"topic": "เงื่อนไขภาษา", "fullScore": 5, "score": ling_score},
        {"topic": "เรียงประโยค", "fullScore": 5, "score": sentrear_score},
        {"topic": "อุปมาอุปไมย", "fullScore": 5, "score": analogy_score},
        {"topic": "เงื่อนไขสัญลักษณ์", "fullScore": 10, "score": symbol_score},
      ];
      subjectScores[1]['topics'] = [
        {"topic": "บทสนทนา", "fullScore": 5, "score": speaking_score},
        {"topic": "ไวยากรณ์", "fullScore": 5, "score": grammar_score},
        {"topic": "การอ่าน", "fullScore": 10, "score": reading_score},
        {"topic": "คำศัพท์", "fullScore": 5, "score": vocab_score},
      ];
      subjectScores[2]['topics'] = [
        {
          "topic": "พ.ร.บ.ระเบียบบริหาราชการแผ่นดิน",
          "fullScore": 6,
          "score": state_admin
        },
        {
          "topic": "พ.ร.ก.ว่าด้วยหลักเกณฑ์และการบริหารกิจการบ้านเมืองที่ดี",
          "fullScore": 6,
          "score": good_govern
        },
        {
          "topic": "พ.ร.บ.วิธีปฏิบัติราชการทางปกครอง",
          "fullScore": 6,
          "score": admin_procedure
        },
        {
          "topic": "ประมวลกฎหมายอาญาความผิดต่อตำแหน่งหน้าที่ราชการ",
          "fullScore": 2,
          "score": criminal_code
        },
        {"topic": "พ.ร.บ.มาตรฐานทางจริยธรรม", "fullScore": 3, "score": ethics},
        {
          "topic": "พ.ร.บ.ความรับผิดทางละเมิดของเจ้าหน้าที่",
          "fullScore": 2,
          "score": tortious
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final int topicCount = selectedSubject?['topics']?.length ?? 0;
    final double chartHeight = 200 + (topicCount * 8);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade200,
        title: const Text('คะแนนตามสัดส่วน'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            if (selectedSubject != null) ...[
              Text(
                selectedSubject!['subject'],
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Column(
                children:
                    (selectedSubject!['topics'] as List).map<Widget>((topic) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.6,
                          child: Text(
                            '${topic['topic']}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Text(
                          '${topic['score']} / ${topic['fullScore']}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'ข้อ',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 2),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                height: chartHeight,
                child: RadarChart(
                  RadarChartData(
                    radarShape: RadarShape.polygon,
                    titlePositionPercentageOffset: 0.25,
                    dataSets: [
                      if (selectedSubject != null)
                        RadarDataSet(
                          fillColor: Colors.green.withOpacity(0.3),
                          borderColor: Colors.green,
                          entryRadius: 2,
                          dataEntries: (selectedSubject!['topics'] as List)
                              .map<RadarEntry>((topic) {
                            final score = topic['score'] ?? 0;
                            final fullScore = topic['fullScore'] ?? 1;
                            final percentage =
                                fullScore == 0 ? 0.0 : score / fullScore;
                            return RadarEntry(value: percentage.toDouble());
                          }).toList(),
                        ),
                    ],
                    radarBackgroundColor: Colors.transparent,
                    borderData: FlBorderData(show: false),
                    radarBorderData: BorderSide(color: Colors.grey.shade300),
                    titleTextStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                    getTitle: (index, angle) {
                      if (selectedSubject != null) {
                        final topics = selectedSubject!['topics'] as List;
                        if (index < topics.length) {
                          final name = topics[index]['topic'];
                          return RadarChartTitle(
                              text: name.length > 10
                                  ? name.substring(0, 10) + '…'
                                  : name);
                        }
                      }
                      return const RadarChartTitle(text: '');
                    },
                    tickCount: 5,
                    tickBorderData:
                        const BorderSide(color: Colors.grey, width: 1),
                    ticksTextStyle:
                        const TextStyle(fontSize: 12, color: Colors.black54),
                    gridBorderData:
                        BorderSide(color: Colors.grey.shade400, width: 1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
