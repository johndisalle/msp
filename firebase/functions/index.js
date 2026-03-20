// Cloud Functions for FaithForge
// Deploy: firebase deploy --only functions
//
// Prerequisites:
//   cd firebase/functions
//   npm init
//   npm install firebase-functions firebase-admin

const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

// ──────────────────────────────────────
// 1. Weekly XP Reset (runs every Monday at 00:00 UTC)
// ──────────────────────────────────────

exports.resetWeeklyXP = functions.pubsub
  .schedule("every monday 00:00")
  .timeZone("UTC")
  .onRun(async () => {
    const usersSnapshot = await db.collection("users").get();
    const batch = db.batch();

    usersSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, { weeklyXP: 0 });
    });

    await batch.commit();
    console.log(`Reset weekly XP for ${usersSnapshot.size} users`);
    return null;
  });

// ──────────────────────────────────────
// 2. Monthly XP Reset (runs 1st of each month at 00:00 UTC)
// ──────────────────────────────────────

exports.resetMonthlyXP = functions.pubsub
  .schedule("1 of month 00:00")
  .timeZone("UTC")
  .onRun(async () => {
    const usersSnapshot = await db.collection("users").get();
    const batch = db.batch();

    usersSnapshot.docs.forEach((doc) => {
      batch.update(doc.ref, { monthlyXP: 0 });
    });

    await batch.commit();
    console.log(`Reset monthly XP for ${usersSnapshot.size} users`);
    return null;
  });

// ──────────────────────────────────────
// 3. Leaderboard Aggregation (runs every hour)
// ──────────────────────────────────────

exports.aggregateLeaderboard = functions.pubsub
  .schedule("every 1 hours")
  .onRun(async () => {
    const periods = [
      { name: "weekly", field: "weeklyXP" },
      { name: "monthly", field: "monthlyXP" },
      { name: "allTime", field: "totalXP" },
    ];

    for (const period of periods) {
      const snapshot = await db
        .collection("users")
        .orderBy(period.field, "desc")
        .limit(100)
        .get();

      const rankings = snapshot.docs.map((doc, index) => {
        const data = doc.data();
        return {
          rank: index + 1,
          userID: doc.id,
          displayName: data.displayName || "Unknown",
          totalXP: data.totalXP || 0,
          weeklyXP: data.weeklyXP || 0,
          monthlyXP: data.monthlyXP || 0,
          currentStreak: data.currentStreak || 0,
          level: data.level || "Novice",
        };
      });

      await db
        .collection("leaderboard")
        .doc(period.name)
        .set({
          rankings,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }

    console.log("Leaderboard aggregated for all periods");
    return null;
  });

// ──────────────────────────────────────
// 4. XP Award (callable function — secure XP updates)
// ──────────────────────────────────────
// Clients call this instead of writing XP directly, preventing spoofing.

exports.awardXP = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Must be signed in to award XP."
    );
  }

  const uid = context.auth.uid;
  const { amount, category, challengeID } = data;

  // Validate
  if (!Number.isInteger(amount) || amount < 1 || amount > 100) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "XP amount must be 1-100."
    );
  }

  const userRef = db.collection("users").doc(uid);

  await db.runTransaction(async (transaction) => {
    const userDoc = await transaction.get(userRef);
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found.");
    }

    const userData = userDoc.data();
    const newTotalXP = (userData.totalXP || 0) + amount;
    const newWeeklyXP = (userData.weeklyXP || 0) + amount;
    const newMonthlyXP = (userData.monthlyXP || 0) + amount;

    // Determine new level
    const levels = [
      { name: "Shepherd", threshold: 12000 },
      { name: "Apostle", threshold: 5000 },
      { name: "Disciple", threshold: 2000 },
      { name: "Seeker", threshold: 500 },
      { name: "Novice", threshold: 0 },
    ];
    const newLevel =
      levels.find((l) => newTotalXP >= l.threshold)?.name || "Novice";

    transaction.update(userRef, {
      totalXP: newTotalXP,
      weeklyXP: newWeeklyXP,
      monthlyXP: newMonthlyXP,
      level: newLevel,
      lastActive: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Contribute to challenge if provided
    if (challengeID) {
      const challengeRef = db.collection("challenges").doc(challengeID);
      transaction.update(challengeRef, {
        communityXPCurrent: admin.firestore.FieldValue.increment(amount),
      });
    }
  });

  return { success: true };
});

// ──────────────────────────────────────
// 5. Challenge Completion Check (triggered on challenge update)
// ──────────────────────────────────────

exports.checkChallengeCompletion = functions.firestore
  .document("challenges/{challengeId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Check if community goal was just met
    if (
      before.communityXPCurrent < after.communityXPGoal &&
      after.communityXPCurrent >= after.communityXPGoal &&
      !after.isCompleted
    ) {
      // Mark as completed
      await change.after.ref.update({ isCompleted: true });

      // Award bonus XP to all participants
      const participantsSnapshot = await change.after.ref
        .collection("participants")
        .get();

      const batch = db.batch();
      for (const participantDoc of participantsSnapshot.docs) {
        const userRef = db.collection("users").doc(participantDoc.id);
        batch.update(userRef, {
          totalXP: admin.firestore.FieldValue.increment(
            after.bonusXP || 50
          ),
          weeklyXP: admin.firestore.FieldValue.increment(
            after.bonusXP || 50
          ),
          monthlyXP: admin.firestore.FieldValue.increment(
            after.bonusXP || 50
          ),
        });
      }
      await batch.commit();

      console.log(
        `Challenge ${context.params.challengeId} completed! Bonus XP awarded to ${participantsSnapshot.size} participants.`
      );
    }

    return null;
  });

// ──────────────────────────────────────
// 6. New User Setup (triggered on user creation)
// ──────────────────────────────────────

exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
  await db.collection("users").doc(user.uid).set({
    displayName: user.displayName || "Pilgrim",
    email: user.email || "",
    totalXP: 0,
    weeklyXP: 0,
    monthlyXP: 0,
    currentStreak: 0,
    longestStreak: 0,
    level: "Novice",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastActive: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log(`New user document created for ${user.uid}`);
  return null;
});
