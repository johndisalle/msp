// firebase/scripts/wipe-community.js
// One-off cleanup: wipe community collections before cutting over to Firebase UID authorIds.
//
// Usage:
//   cd firebase
//   node scripts/wipe-community.js --confirm
//
// Requires GOOGLE_APPLICATION_CREDENTIALS pointing at a service account JSON,
// or being logged in via `gcloud auth application-default login`.
//
// SAFETY: Will refuse to run without --confirm. Will print collection sizes
// first and require a second --yes to actually delete.

const admin = require("firebase-admin");

const projectId = process.env.GCLOUD_PROJECT || "abidejourney-81288";

admin.initializeApp({ projectId });
const db = admin.firestore();

const COLLECTIONS_TO_WIPE = [
  "communityPrayers",
  "communityTestimonies",
  "communityReports",
  "journeyGenerations",
  "rateLimits",
];

async function deleteCollection(name, batchSize = 400) {
  const collRef = db.collection(name);
  let total = 0;
  while (true) {
    const snap = await collRef.limit(batchSize).get();
    if (snap.empty) break;
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
    total += snap.size;
    process.stdout.write(`\r  ${name}: deleted ${total}...`);
    if (snap.size < batchSize) break;
  }
  process.stdout.write(`\r  ${name}: deleted ${total} total\n`);
  return total;
}

async function countCollection(name) {
  const snap = await db.collection(name).count().get();
  return snap.data().count;
}

async function main() {
  const args = process.argv.slice(2);
  if (!args.includes("--confirm")) {
    console.log("Refusing to run without --confirm flag.");
    console.log("Usage: node scripts/wipe-community.js --confirm [--yes]");
    process.exit(1);
  }

  console.log(`Project: ${projectId}\n`);
  console.log("Current collection sizes:");
  for (const name of COLLECTIONS_TO_WIPE) {
    try {
      const count = await countCollection(name);
      console.log(`  ${name}: ${count}`);
    } catch (e) {
      console.log(`  ${name}: error (${e.message})`);
    }
  }

  if (!args.includes("--yes")) {
    console.log("\nDry run complete. Re-run with --confirm --yes to actually delete.");
    process.exit(0);
  }

  console.log("\nDeleting...\n");
  for (const name of COLLECTIONS_TO_WIPE) {
    await deleteCollection(name);
  }
  console.log("\nDone.");
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
