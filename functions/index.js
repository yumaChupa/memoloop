const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({
  maxInstances: 5,
});

function isValidUuid(uuid) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(uuid);
}

/**
 * 問題投稿API - UUID ベース 1日10件制限
 */
exports.createProblem = onCall(
  { enforceAppCheck: true },
  async (request) => {
    const db = admin.firestore();

    const { uuid } = request.data;
    if (!uuid || !isValidUuid(uuid)) {
      throw new HttpsError("invalid-argument", "Valid UUID required");
    }

    const rawSize = Buffer.byteLength(JSON.stringify(request.data), "utf8");
    if (rawSize > 200 * 1024) {
      throw new HttpsError("invalid-argument", "Payload too large");
    }

    const today = new Date().toISOString().split("T")[0];
    const snapshot = await db
      .collection("problems")
      .where("uuid", "==", uuid)
      .where("date", "==", today)
      .get();

    if (snapshot.size >= 10) {
      throw new HttpsError("resource-exhausted", "Daily limit reached");
    }

    await db.collection("problems").add({
      title: request.data.title || "",
      content: request.data.content || "",
      uuid: uuid,
      date: today,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  }
);

/**
 * 問題セットアップロードAPI - UUID ベースレート制限（20秒）
 * 戻り値: { remaining: null } = 成功, { remaining: N } = N秒後に再試行, { remaining: -1 } = 問題数超過
 */
const MAX_QUESTIONS = 310;
const UPLOAD_COOLDOWN_SECONDS = 20;

exports.uploadProblemSet = onCall(
  { enforceAppCheck: true },
  async (request) => {
    const db = admin.firestore();
    const { uuid, title, filename, tags, questions } = request.data;

    if (!uuid || !isValidUuid(uuid)) {
      throw new HttpsError("invalid-argument", "Valid UUID required");
    }
    if (!title || typeof title !== "string" || !filename || typeof filename !== "string") {
      throw new HttpsError("invalid-argument", "title and filename required");
    }
    if (!Array.isArray(questions)) {
      throw new HttpsError("invalid-argument", "questions must be an array");
    }
    if (questions.length > MAX_QUESTIONS) {
      return { remaining: -1 };
    }

    // UUID ごとのレート制限チェック
    const rateLimitRef = db.collection("uploadRateLimits").doc(uuid);
    const rateLimitDoc = await rateLimitRef.get();
    if (rateLimitDoc.exists) {
      const lastUpload = rateLimitDoc.data().lastUploadAt?.toDate();
      if (lastUpload) {
        const elapsedSeconds = (Date.now() - lastUpload.getTime()) / 1000;
        if (elapsedSeconds < UPLOAD_COOLDOWN_SECONDS) {
          return { remaining: Math.ceil(UPLOAD_COOLDOWN_SECONDS - elapsedSeconds) };
        }
      }
    }

    const setRef = db.collection("sets").doc(filename);
    const questionsRef = setRef.collection("questions");

    // 既存 downloadCount を保持
    const existingDoc = await setRef.get();
    const currentDownloads = existingDoc.exists ? (existingDoc.data().downloadCount ?? 0) : 0;

    // 既存 questions を削除
    const existingQuestions = await questionsRef.get();
    if (!existingQuestions.empty) {
      const batchDelete = db.batch();
      existingQuestions.docs.forEach((doc) => batchDelete.delete(doc.reference));
      await batchDelete.commit();
    }

    // sets ドキュメント更新
    await setRef.set({
      title,
      filename,
      updatedAt: new Date().toISOString(),
      tags: Array.isArray(tags) ? tags : [],
      downloadCount: currentDownloads,
      questionCount: questions.length,
    });

    // questions 再アップロード（good/bad はローカル専用のため除外）
    const batchUpload = db.batch();
    questions.forEach((q) => {
      const cleaned = { ...q };
      delete cleaned.good;
      delete cleaned.bad;
      batchUpload.set(questionsRef.doc(String(cleaned.index)), cleaned);
    });
    await batchUpload.commit();

    // レート制限タイムスタンプ更新
    await rateLimitRef.set(
      { lastUploadAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );

    return { remaining: null };
  }
);

/**
 * ダウンロード数インクリメントAPI
 */
exports.incrementDownload = onCall(
  { enforceAppCheck: true },
  async (request) => {
    const db = admin.firestore();
    const { filename } = request.data;

    if (!filename || typeof filename !== "string") {
      throw new HttpsError("invalid-argument", "filename required");
    }

    const setRef = db.collection("sets").doc(filename);
    const doc = await setRef.get();
    if (!doc.exists) {
      throw new HttpsError("not-found", "Problem set not found");
    }

    await setRef.update({
      downloadCount: admin.firestore.FieldValue.increment(1),
    });

    return { success: true };
  }
);
