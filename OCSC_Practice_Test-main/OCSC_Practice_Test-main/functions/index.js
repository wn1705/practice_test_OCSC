/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

//const {onRequest} = require("firebase-functions/v2/https");
//const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

const { onSchedule} = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");
const logger = require("firebase-functions/logger");
const { setGlobalOptions } = require("firebase-functions/v2");


// กำหนด global region สำหรับฟังก์ชันทั้งหมดในไฟล์นี้
setGlobalOptions({ region: "asia-southeast2" });

admin.initializeApp();

// Run once a day at midnight, to update question difficulty
exports.updateMonthlyDifficultyFromExamSet = onSchedule(
  {
    schedule: "1 of month 00:00",
    timeZone: "Asia/Taipei",
  },
  async (event) => {
    logger.log("Running updateMonthlyDifficultyFromExamSet function at midnight...");
    return updateMonthlyDifficultyFromExamSet();
  }
);


async function updateMonthlyDifficultyFromExamSet() {
  const db = admin.firestore();
  const today = new Date();
const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
  const startOfNextMonth = new Date(today.getFullYear(), today.getMonth() + 1, 1);

  const snapshot = await db.collection("exam_set")
    .where("created_at", ">=", admin.firestore.Timestamp.fromDate(startOfMonth))
    .where("created_at", "<", admin.firestore.Timestamp.fromDate(startOfNextMonth))
    .get();

  const questionStats = {};

  snapshot.forEach(doc => {
    const results = doc.data().question_results || [];
    results.forEach(q => {
      const key = `${q.data_no}_${q.test_name}_${q.topic}`;

      if (!questionStats[key]) {
        questionStats[key] = { total: 0, correct: 0 };
      }

      questionStats[key].total += 1;
      if (q.result === true) {
        questionStats[key].correct += 1;
      }
    });
  });

  const batch = db.batch();
  const dataSnapshot = await db.collection("data").get();

  dataSnapshot.forEach(doc => {
    const data = doc.data();
    const key = `${data.no}_${data.test_name}_${data.topic}`;

    if (questionStats[key]) {
      const { total, correct } = questionStats[key];

      // เงื่อนไขใหม่: ต้องมีผู้ทำมากกว่า 10 คน
      if (total > 10) {
        const difficultyPercent = (correct / total) * 100;

        let difficulty = "medium";
        if (difficultyPercent >= 70) difficulty = "easy";
        else if (difficultyPercent < 30) difficulty = "hard";

        batch.update(doc.ref, { difficulty });
      } else {
        logger.log(`🔍 Skipped update for question ${key} — not enough attempts (only ${total})`);
      }
    }
  });


  await batch.commit();
  console.log("✅ Monthly difficulty updated from exam_set successfully.");
}
