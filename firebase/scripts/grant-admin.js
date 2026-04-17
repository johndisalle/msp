// firebase/scripts/grant-admin.js
// Grant or revoke the `admin: true` custom claim on a Firebase Auth user.
//
// Usage:
//   node scripts/grant-admin.js <uid>           # grant admin
//   node scripts/grant-admin.js <uid> --revoke  # revoke admin
//   node scripts/grant-admin.js --list          # list current admins
//
// Requires GOOGLE_APPLICATION_CREDENTIALS pointing at a service account JSON,
// or being logged in via `gcloud auth application-default login`.
//
// IMPORTANT: After granting/revoking, the affected user must sign out and back in
// (or restart the app) for the change to take effect — Firebase ID tokens are
// cached for ~1 hour. AuthService.bootstrap() forces a token refresh on every
// app launch, so a relaunch is sufficient.

const admin = require("firebase-admin");

const projectId = process.env.GCLOUD_PROJECT || "abidejourney-81288";
admin.initializeApp({ projectId });

async function listAdmins() {
  console.log(`Listing admins in ${projectId}...\n`);
  let count = 0;
  let nextPageToken;
  do {
    const result = await admin.auth().listUsers(1000, nextPageToken);
    for (const user of result.users) {
      if (user.customClaims?.admin === true) {
        const display = user.email || user.providerData[0]?.email || user.providerData[0]?.uid || "(no email)";
        console.log(`  ${user.uid}  ${display}`);
        count++;
      }
    }
    nextPageToken = result.pageToken;
  } while (nextPageToken);
  console.log(`\n${count} admin${count === 1 ? "" : "s"}.`);
}

async function setAdmin(uid, isAdmin) {
  let user;
  try {
    user = await admin.auth().getUser(uid);
  } catch (e) {
    console.error(`User not found: ${uid}`);
    console.error(e.message);
    process.exit(1);
  }

  // Preserve any other custom claims; just touch `admin`.
  const existing = user.customClaims || {};
  const newClaims = { ...existing, admin: isAdmin };
  if (!isAdmin) delete newClaims.admin;

  await admin.auth().setCustomUserClaims(uid, newClaims);

  const display = user.email || user.providerData[0]?.email || "(no email)";
  console.log(`${isAdmin ? "Granted" : "Revoked"} admin for:`);
  console.log(`  uid:   ${uid}`);
  console.log(`  email: ${display}`);
  console.log("\nUser must restart the app for the change to take effect.");
}

async function main() {
  const args = process.argv.slice(2);

  if (args.length === 0 || args[0] === "--help" || args[0] === "-h") {
    console.log("Usage:");
    console.log("  node scripts/grant-admin.js <uid>           # grant admin");
    console.log("  node scripts/grant-admin.js <uid> --revoke  # revoke admin");
    console.log("  node scripts/grant-admin.js --list          # list current admins");
    process.exit(0);
  }

  if (args[0] === "--list") {
    await listAdmins();
    process.exit(0);
  }

  const uid = args[0];
  const revoke = args.includes("--revoke");
  await setAdmin(uid, !revoke);
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
