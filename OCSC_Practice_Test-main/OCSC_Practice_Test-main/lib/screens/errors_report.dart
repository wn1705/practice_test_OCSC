import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'examtest.dart';

class ErrorReportService{
  static Future<void> reportError({
    
    required int questionNumber,
    required String testName,
    required String subject,
    required String topic,
    required String errorMessage,
    required int no,
    required String examId,
  }) async{

  
    try{
      
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('error_reports').get();
      int caseId = snapshot.docs.length +1 ;
      await FirebaseFirestore.instance.collection('error_reports').add({
          'questionNumber': questionNumber,
          'caseId': caseId,
          'test_name': testName,
          'subject': subject,
          'topic': topic,
          'timestamp': FieldValue.serverTimestamp(),
          'errorMessage':errorMessage,
          'no':no,
          'read':false,

      });
    }catch(e){
       print("❌ เกิดข้อผิดพลาดในการส่งรายงาน: $e");
    }
  }
}


void reportErrorDialog(BuildContext context, Map<String, dynamic> question) {

  TextEditingController errorController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('รายงานข้อผิดพลาด'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text('ข้อสอบชุดที่: ${question["exam_id"].substring(0, 5)}'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('ข้อที่: ${question["questionNumber"]+1}'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: errorController,
              decoration: const InputDecoration(
                hintText: 'โปรดอธิบายปัญหาที่พบ',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () async {
              if (errorController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณากรอกรายละเอียดปัญหาก่อนส่ง'),
                  ),
                );
                return;
              }

              await ErrorReportService.reportError(
                 
                questionNumber: question["questionNumber"],
                testName: question["test_name"] ?? "ไม่พบข้อมูล",
                subject: question["subject"],
                topic: question["topic"],
                errorMessage: errorController.text.trim(),
                no: question["no"],
                examId: question["exam_id"],
              );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ขอบคุณสำหรับการแจ้งปัญหา!')),
              );
            },
            child: const Text('ส่งรายงาน'),
          ),
        ],
      );
    },
  );
}
