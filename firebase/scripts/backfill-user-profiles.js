// firebase/scripts/backfill-user-profiles.js
// Creates a users/{uid} Firestore doc for every non-anonymous Firebase Auth user
// who doesn't already have one. Idempotent — safe to run repeatedly.
//
// Skips anonymous users (providerData is empty) to avoid bloating the collection
// with ephemeral sessions.
//
// Usage:
//   node scripts/backfill-user-profiles.js --confirm        # dry run, count only
//   node scripts/backfill-user-profiles.js --confirm --yes  # actually backfill

const admin = require("firebase-admin");

const projectId = process.env.GCLOUD_PROJECT || "abidejourney-81288";
admin.initializeApp({ projectId });
const db = admin.firestore();

async function main() {
  const args = process.argv.slice(2);
  if (!args.includes("--confirm")) {
    console.log("Refusing to run without --confirm flag.");
    console.log("Usage: node scripts/backfill-user-profiles.js --confirm [--yes]");
    process.exit(1);
  }
  const actuallyWrite = args.includes("--yes");

  console.log(`Project: ${projectId}\n`);

  // Step 1: Collect all auth users (non-anonymous)
  const authUsers = [];
  let skippedAnonymous = 0;
  let nextPageToken;
  do {
    const result = await admin.auth().listUsers(1000, nextPageToken);
    for (const u of result.users) {
      if (!u.providerData || u.providerData.length === 0) {
        skippedAnonymous++;
        continue;
      }
      authUsers.push(u);
    }
    nextPageToken = result.pageToken;
  } while (nextPageToken);

  console.log(`Auth users (non-anonymous):  ${authUsers.length}`);
  console.log(`Auth users (anonymous, skipped): ${skippedAnonymous}`);

  // Step 2: Determine which have no Firestore doc
  const missing = [];
  for (const u of authUsers) {
    const doc = await db.collection("users").doc(u.uid).get();
    if (!doc.exists) missing.push(u);
  }
  console.log(`Missing profile docs: ${missing.length}\n`);

  if (missing.length === 0) {
    console.log("Nothing to backfill.");
    process.exit(0);
  }

  if (!actuallyWrite) {
    console.log("Dry run. Re-run with --confirm --yes to create these profiles:");
    for (const u of missing) {
      const email = u.email || u.providerData[0]?.email || "(no email)";
      console.log(`  ${u.uid}  ${email}`);
    }
    process.exit(0);
  }

  console.log("Backfilling...");
  for (let i = 0; i < missing.length; i += 400) {
    const batch = db.batch();
    missing.slice(i, i + 400).forEach((u) => {
      const email = u.email || u.providerData[0]?.email || "";
      const name = u.displayName || "";
      const isAdmin = u.customClaims?.admin === true;
      const ref = db.collection("users").doc(u.uid);
      batch.set(ref, {
        email,
        emailLower: email.toLowerCase(),
        name,
        nameLower: name.toLowerCase(),
        createdAt: admin.firestore.Timestamp.fromDate(
          u.metadata.creationTime ? new Date(u.metadata.creationTime) : new Date()
        ),
        lastSyncedAt: admin.firestore.FieldValue.serverTimestamp(),
        isAdmin,
        premium: {
          granted: false,
        },
      });
    });
    await batch.commit();
    console.log(`  ${Math.min(i + 400, missing.length)} / ${missing.length}`);
  }
  console.log("\nDone.");
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
