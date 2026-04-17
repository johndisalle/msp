// firebase/scripts/backfill-testimony-status.js
// One-off: any existing testimonies without a `status` field get marked
// "approved" — they were live before the schema change, so they should
// stay live.
//
// SAFE: idempotent. Only touches docs missing the field.
//
// Usage:
//   node scripts/backfill-testimony-status.js --confirm        # dry run, count only
//   node scripts/backfill-testimony-status.js --confirm --yes  # actually backfill

const admin = require("firebase-admin");

const projectId = process.env.GCLOUD_PROJECT || "abidejourney-81288";
admin.initializeApp({ projectId });
const db = admin.firestore();

async function main() {
  const args = process.argv.slice(2);
  if (!args.includes("--confirm")) {
    console.log("Refusing to run without --confirm flag.");
    console.log("Usage: node scripts/backfill-testimony-status.js --confirm [--yes]");
    process.exit(1);
  }

  console.log(`Project: ${projectId}\n`);
  const snap = await db.collection("communityTestimonies").get();
  const needsBackfill = snap.docs.filter((d) => !("status" in d.data()));
  console.log(`Total testimonies:       ${snap.size}`);
  console.log(`Missing status field:    ${needsBackfill.length}`);
  console.log(`Will mark as 'approved': ${needsBackfill.length}`);

  if (!args.includes("--yes")) {
    console.log("\nDry run complete. Re-run with --confirm --yes to backfill.");
    process.exit(0);
  }

  if (needsBackfill.length === 0) {
    console.log("\nNothing to backfill.");
    process.exit(0);
  }

  console.log("\nBackfilling...");
  for (let i = 0; i < needsBackfill.length; i += 400) {
    const batch = db.batch();
    needsBackfill.slice(i, i + 400).forEach((d) => {
      batch.update(d.ref, { status: "approved" });
    });
    await batch.commit();
    console.log(`  ${Math.min(i + 400, needsBackfill.length)} / ${needsBackfill.length}`);
  }
  console.log("\nDone.");
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
