const { setGlobalOptions } = require("firebase-functions/v2");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

setGlobalOptions({
  maxInstances: 5,
});

// ===== レート制限定数 =====
const DAILY_CALL_LIMIT = 1000;       // 1日あたりの最大アクセス回数
const DAILY_BYTES_LIMIT = 1048576;   // 1日あたりの最大データ転送量（1MB）

// ===== 内部ヘルパー =====

/** 今日の日付文字列（YYYY-MM-DD）を返す */
function todayStr() {
  return new Date().toISOString().split("T")[0];
}

/** デバイス使用量ドキュメントの参照を返す */
function usageDocRef(db, deviceUuid) {
  return db.collection("deviceUsage").doc(`${deviceUuid}_${todayStr()}`);
}

/** deviceUuid の形式バリデーション */
function validateDeviceUuid(deviceUuid) {
  if (
    !deviceUuid ||
    typeof deviceUuid !== "string" ||
    deviceUuid.length > 36 ||
    !/^[0-9a-f-]+$/i.test(deviceUuid)
  ) {
    throw new HttpsError("invalid-argument", "無効なデバイスIDです");
  }
}

/**
 * 1アクセス分を記録し、上限チェックをトランザクションで行う。
 * 上限超過時は HttpsError("resource-exhausted") をスロー。
 */
async function checkAndIncrementCalls(db, deviceUuid) {
  validateDeviceUuid(deviceUuid);
  const docRef = usageDocRef(db, deviceUuid);

  await db.runTransaction(async (tx) => {
    const doc = await tx.get(docRef);
    const data = doc.exists ? doc.data() : {};
    const callCount = data.callCount || 0;
    const bytesUsed = data.bytesUsed || 0;

    if (callCount >= DAILY_CALL_LIMIT) {
      throw new HttpsError(
        "resource-exhausted",
        "1日のアクセス上限（1000回）に達しました"
      );
    }
    if (bytesUsed >= DAILY_BYTES_LIMIT) {
      throw new HttpsError(
        "resource-exhausted",
        "1日のデータ転送上限（1MB）に達しました"
      );
    }

    tx.set(
      docRef,
      {
        deviceUuid,
        date: todayStr(),
        callCount: callCount + 1,
        bytesUsed,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });
}

/**
 * レスポンスデータのバイト数を非同期で記録する（非クリティカル）
 */
async function recordBytes(db, deviceUuid, payload) {
  const bytes = Buffer.byteLength(JSON.stringify(payload), "utf8");
  if (bytes <= 0) return;
  const docRef = usageDocRef(db, deviceUuid);
  try {
    await docRef.update({
      bytesUsed: admin.firestore.FieldValue.increment(bytes),
    });
  } catch (_) {
    // ドキュメントが存在しない場合は無視
  }
}

// ===== 既存関数（互換維持） =====

/**
 * 問題投稿API - deviceUuid ベース 1日10件制限
 */
exports.createProblem = onCall(
  { enforceAppCheck: true },
  async (request) => {
    const db = admin.firestore();

    const { deviceUuid } = request.data;
    validateDeviceUuid(deviceUuid);

    const rawSize = Buffer.byteLength(JSON.stringify(request.data), "utf8");
    if (rawSize > 200 * 1024) {
      throw new HttpsError("invalid-argument", "Payload too large");
    }

    const today = todayStr();
    const snapshot = await db
      .collection("problems")
      .where("deviceUuid", "==", deviceUuid)
      .where("date", "==", today)
      .get();

    if (snapshot.size >= 10) {
      throw new HttpsError("resource-exhausted", "Daily limit reached");
    }

    await db.collection("problems").add({
      title: request.data.title || "",
      content: request.data.content || "",
      deviceUuid,
      date: today,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  }
);

// ===== 新規関数（UUIDベースのレート制限付き） =====

/**
 * 公開されている問題セット一覧を取得
 */
exports.getSetsList = onCall({ enforceAppCheck: true }, async (request) => {
  const db = admin.firestore();
  const { deviceUuid } = request.data;

  await checkAndIncrementCalls(db, deviceUuid);

  const snapshot = await db.collection("sets").get();
  const sets = snapshot.docs.map((doc) => doc.data());

  // バイト数を非同期で記録（エラーは無視）
  recordBytes(db, deviceUuid, sets).catch(() => {});

  return { sets };
});

/**
 * 特定の問題セットの問題一覧を取得
 */
exports.getProblemSet = onCall({ enforceAppCheck: true }, async (request) => {
  const db = admin.firestore();
  const { deviceUuid, filename } = request.data;

  if (!filename || typeof filename !== "string") {
    throw new HttpsError("invalid-argument", "filename が必要です");
  }

  await checkAndIncrementCalls(db, deviceUuid);

  const snapshot = await db
    .collection("sets")
    .doc(filename)
    .collection("questions")
    .get();
  const questions = snapshot.docs.map((doc) => doc.data());

  recordBytes(db, deviceUuid, questions).catch(() => {});

  return { questions };
});

/**
 * ダウンロード数をインクリメント
 */
exports.incrementDownload = onCall({ enforceAppCheck: true }, async (request) => {
  const db = admin.firestore();
  const { deviceUuid, filename } = request.data;

  if (!filename || typeof filename !== "string") {
    throw new HttpsError("invalid-argument", "filename が必要です");
  }

  await checkAndIncrementCalls(db, deviceUuid);

  await db.collection("sets").doc(filename).update({
    downloadCount: admin.firestore.FieldValue.increment(1),
  });

  return { success: true };
});

/**
 * 問題セットをアップロード（新規 or 更新）
 */
exports.uploadProblemSet = onCall({ enforceAppCheck: true }, async (request) => {
  const db = admin.firestore();
  const { deviceUuid, title, filename, tags, questions } = request.data;

  if (!title || !filename || !Array.isArray(questions)) {
    throw new HttpsError(
      "invalid-argument",
      "title, filename, questions が必要です"
    );
  }
  if (questions.length > 310) {
    throw new HttpsError(
      "invalid-argument",
      "問題数が上限（310問）を超えています"
    );
  }

  await checkAndIncrementCalls(db, deviceUuid);

  const setRef = db.collection("sets").doc(filename);
  const questionsRef = setRef.collection("questions");

  // 既存 questions を削除
  const existing = await questionsRef.get();
  const batchDelete = db.batch();
  existing.forEach((doc) => batchDelete.delete(doc.ref));
  await batchDelete.commit();

  // 既存の downloadCount を保持
  const existingDoc = await setRef.get();
  const currentDownloads = existingDoc.data()?.downloadCount || 0;
  const now = new Date().toISOString();

  // sets ドキュメントを更新
  await setRef.set({
    title,
    filename,
    updatedAt: now,
    tags: tags || [],
    downloadCount: currentDownloads,
    questionCount: questions.length,
  });

  // questions をバッチアップロード（Firestore 500件制限対応）
  const BATCH_SIZE = 400;
  for (let i = 0; i < questions.length; i += BATCH_SIZE) {
    const chunk = questions.slice(i, i + BATCH_SIZE);
    const batchUpload = db.batch();
    chunk.forEach((q) => {
      const cleaned = { ...q };
      delete cleaned.good;
      delete cleaned.bad;
      batchUpload.set(questionsRef.doc(String(q.index)), cleaned);
    });
    await batchUpload.commit();
  }

  // リクエストサイズをバイト数として記録
  recordBytes(db, deviceUuid, request.data).catch(() => {});

  return { success: true };
});

