const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * 同時起動インスタンス制限（爆発防止）
 */
setGlobalOptions({
  maxInstances: 5,
});

/**
 * 問題投稿API
 */
exports.createProblem = onCall(
  {
    enforceAppCheck: true, // App Check 必須
  },
  async (request) => {
    const db = admin.firestore();

    // ===== 1. App Check トークン取得（端末識別用） =====
    const appId = request.app?.appId;
    if (!appId) {
      throw new HttpsError("failed-precondition", "App Check required");
    }

    // ===== 2. データサイズ制限（200KBまで許可） =====
    const rawSize = Buffer.byteLength(
      JSON.stringify(request.data),
      "utf8"
    );

    const MAX_SIZE = 200 * 1024; // 200KB
    if (rawSize > MAX_SIZE) {
      throw new HttpsError(
        "invalid-argument",
        "Payload too large"
      );
    }

    // ===== 3. 1日10件制限（端末単位） =====
    const today = new Date().toISOString().split("T")[0];

    const snapshot = await db
      .collection("problems")
      .where("appId", "==", appId)
      .where("date", "==", today)
      .get();

    if (snapshot.size >= 10) {
      throw new HttpsError(
        "resource-exhausted",
        "Daily limit reached"
      );
    }

    // ===== 4. 保存 =====
    await db.collection("problems").add({
      title: request.data.title || "",
      content: request.data.content || "",
      appId: appId,
      date: today,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  }
);