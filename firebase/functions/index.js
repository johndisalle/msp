const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
const crypto = require("crypto");
const { defineString } = require("firebase-functions/params");

admin.initializeApp();
const db = admin.firestore();

// ============================================================
// Environment parameters (set via .env file)
// ============================================================

const claudeApiKey = defineString("CLAUDE_API_KEY");
const appSecret = defineString("APP_SECRET");           // legacy — remove after client saturation
const elevenLabsKey = defineString("ELEVENLABS_API_KEY");
const elevenLabsFemaleVoice = defineString("ELEVENLABS_FEMALE_VOICE_ID");
const elevenLabsMaleVoice = defineString("ELEVENLABS_MALE_VOICE_ID");

// ============================================================
// Auth: dual-path resolver
// ============================================================
// Returns { uid, isLegacy } or null.
//   - Authorization: Bearer <Firebase ID token>  → real uid
//   - X-App-Secret + body.deviceId  → legacy_<deviceId> (transition path)
//
// Once your new app build hits saturation, delete the legacy branch.
// ============================================================

async function resolveUserId(req) {
  const auth = req.headers.authorization;
  if (auth && auth.startsWith("Bearer ")) {
    const token = auth.slice(7).trim();
    try {
      const decoded = await admin.auth().verifyIdToken(token);
      return { uid: decoded.uid, isLegacy: false };
    } catch (e) {
      console.warn("verifyIdToken failed:", e.message);
      return null;
    }
  }

  // Legacy path — to be removed after v1.4.2 attrition.
  const secret = req.headers["x-app-secret"] || req.body?.appSecret;
  const deviceId = req.body?.deviceId;
  if (secret && secret === appSecret.value() && deviceId) {
    return { uid: `legacy_${deviceId}`, isLegacy: true };
  }
  return null;
}

// ============================================================
// 1. CLAUDE API PROXY (HTTP) — keeps API key off the client
// ============================================================

exports.generateJourneyHTTP = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type, X-App-Secret, Authorization");
    return res.status(204).send("");
  }
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const auth = await resolveUserId(req);
  if (!auth) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  const { description, theme } = req.body;
  if (!description?.trim() || description.length > 500) {
    return res.status(400).json({ error: "Description is required and must be under 500 characters." });
  }

  // Rate limit by uid: max 3 per day
  const today = new Date().toISOString().split("T")[0];
  const rateLimitRef = db.collection("rateLimits").doc(`gen_${auth.uid}_${today}`);
  const rateLimitDoc = await rateLimitRef.get();
  const currentCount = rateLimitDoc.exists ? (rateLimitDoc.data().count || 0) : 0;
  if (currentCount >= 3) {
    return res.status(429).json({
      error: "You can generate up to 3 custom journeys per day. Please try again tomorrow.",
    });
  }

  const apiKey = claudeApiKey.value();
  if (!apiKey || apiKey === "YOUR_CLAUDE_API_KEY") {
    return res.status(500).json({ error: "AI service is not configured." });
  }

  const systemPrompt = `You are a Christian devotional content creator. Generate a 40-day spiritual journey based on the user's description.

Return ONLY valid JSON matching this schema:
{
  "title": "string",
  "theme": "string",
  "focusAreas": ["string"],
  "days": [
    {
      "dayNumber": 1,
      "scriptureReference": "string",
      "scriptureText": "string",
      "devotionalTitle": "string",
      "devotionalText": "string",
      "prayerText": "string",
      "reflectionPrompt": "string",
      "actionSteps": ["string"]
    }
  ]
}

Generate all 40 days. Each devotional should be ~150 words. Each prayer ~80 words. Be theologically sound, Scripture-grounded, and pastorally warm.`;

  try {
    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-5",
        max_tokens: 16000,
        system: systemPrompt,
        messages: [{ role: "user", content: description }],
      }),
    });

    if (!response.ok) {
      const errText = await response.text();
      console.error("Claude API error:", response.status, errText);
      return res.status(502).json({ error: "AI service is temporarily unavailable." });
    }

    const data = await response.json();
    const text = data.content?.[0]?.text;
    if (!text) {
      return res.status(502).json({ error: "AI service returned empty response." });
    }

    const cleaned = text.replace(/```json\s*|\s*```/g, "").trim();
    let plan;
    try {
      plan = JSON.parse(cleaned);
    } catch (e) {
      console.error("JSON parse failed:", e.message);
      return res.status(502).json({ error: "AI service returned invalid response." });
    }

    // Increment rate limit + log generation
    await rateLimitRef.set(
      { count: currentCount + 1, lastUsed: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true }
    );
    await db.collection("journeyGenerations").add({
      uid: auth.uid,
      isLegacy: auth.isLegacy,
      descriptionPreview: description.slice(0, 100),
      theme: theme || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.status(200).json(plan);
  } catch (error) {
    console.error("generateJourneyHTTP error:", error.message || error);
    return res.status(500).json({ error: error.message || "Unexpected error." });
  }
});

// ============================================================
// 2. ELEVENLABS AUDIO PROXY
// ============================================================

exports.generateAudioHTTP = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type, X-App-Secret, Authorization");
    return res.status(204).send("");
  }
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const auth = await resolveUserId(req);
  if (!auth) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  const { text, voice } = req.body;
  if (!text?.trim() || text.length > 5000) {
    return res.status(400).json({ error: "Text is required and must be under 5000 characters." });
  }
  if (voice && !["male", "female"].includes(voice)) {
    return res.status(400).json({ error: "Voice must be 'male' or 'female'." });
  }

  // Rate limit: max 20 audio generations per uid per day
  const today = new Date().toISOString().split("T")[0];
  const rateLimitRef = db.collection("rateLimits").doc(`audio_${auth.uid}_${today}`);
  const rateLimitDoc = await rateLimitRef.get();
  const currentCount = rateLimitDoc.exists ? (rateLimitDoc.data().count || 0) : 0;

  if (currentCount >= 20) {
    return res.status(429).json({
      error: "Daily audio limit reached. Please try again tomorrow.",
    });
  }

  // Cache check — first user pays ElevenLabs cost, others get cached MP3
  const cacheKey = crypto
    .createHash("sha256")
    .update(`${voice || "female"}|${text}`)
    .digest("hex");
  const cachePath = `audio-cache/${cacheKey}.mp3`;

  try {
    const bucket = admin.storage().bucket();
    const file = bucket.file(cachePath);
    const [exists] = await file.exists();
    if (exists) {
      res.set("Content-Type", "audio/mpeg");
      res.set("X-Cache", "HIT");
      file.createReadStream().pipe(res);
      return;
    }
  } catch (err) {
    console.error("Cache check failed, falling through:", err);
  }

  const apiKey = elevenLabsKey.value();
  if (!apiKey || apiKey === "YOUR_ELEVENLABS_API_KEY") {
    return res.status(500).json({ error: "Audio service is not configured." });
  }

  const voiceId = voice === "male"
    ? elevenLabsMaleVoice.value()
    : elevenLabsFemaleVoice.value();

  try {
    const response = await fetch(
      `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`,
      {
        method: "POST",
        headers: {
          "xi-api-key": apiKey,
          "Content-Type": "application/json",
          Accept: "audio/mpeg",
        },
        body: JSON.stringify({
          text,
          model_id: "eleven_multilingual_v2",
          voice_settings: {
            stability: 0.65,
            similarity_boost: 0.8,
            style: 0.35,
            use_speaker_boost: true,
          },
        }),
      }
    );

    if (!response.ok) {
      const errorText = await response.text();
      console.error("ElevenLabs error:", errorText);
      return res.status(502).json({ error: "Failed to generate audio. Please try again." });
    }

    // Update rate limit (only counts cache misses — hits are free)
    await rateLimitRef.set({ count: currentCount + 1, date: today });

    const arrayBuf = await response.arrayBuffer();
    const audioBuffer = Buffer.from(arrayBuf);

    // Save to Storage cache for future requests
    try {
      const bucket = admin.storage().bucket();
      const file = bucket.file(cachePath);
      await file.save(audioBuffer, {
        contentType: "audio/mpeg",
        metadata: {
          cacheControl: "public, max-age=31536000",
          metadata: { voice: voice || "female", textLength: String(text.length) },
        },
      });
    } catch (err) {
      console.error("Cache save failed (audio still served):", err);
    }

    res.set("X-Cache", "MISS");
    res.set("Content-Type", "audio/mpeg");
    res.set("Content-Length", audioBuffer.length.toString());
    return res.status(200).send(audioBuffer);
  } catch (error) {
    console.error("Audio generation error:", error.message || error);
    return res.status(500).json({ error: error.message || "An unexpected error occurred." });
  }
});

// ============================================================
// 3. COMMUNITY FEATURES — Prayer Wall & Testimony Wall
// ============================================================

exports.communityHTTP = functions.https.onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type, X-App-Secret, Authorization");
    return res.status(204).send("");
  }
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const auth = await resolveUserId(req);
  if (!auth) {
    return res.status(401).json({ error: "Unauthorized" });
  }
  const userId = auth.uid;

  const { action } = req.body;

  const containsProfanity = (text) => {
    if (!text) return false;
    const lowered = text.toLowerCase();
    const patterns = [
      /\bf+u+c+k/i, /\bs+h+i+t/i, /\ba+s+s+h+o+l+e/i, /\bb+i+t+c+h/i,
      /\bn+i+g+g/i, /\bf+a+g+g/i, /\bc+u+n+t/i,
      /\bkill\s+(your|my|him|her)self/i, /\bsuicid/i,
    ];
    return patterns.some((p) => p.test(lowered));
  };

  try {
    switch (action) {
      // ---- PRAYERS ----
      case "getPrayers": {
        const limit = Math.min(req.body.limit || 50, 100);
        const snapshot = await db
          .collection("communityPrayers")
          .where("isRemoved", "!=", true)
          .orderBy("createdAt", "desc")
          .limit(limit)
          .get();
        const prayers = snapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
          createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || null,
        }));
        return res.status(200).json({ prayers });
      }

      case "submitPrayer": {
        const { text, category, authorName, isAnonymous } = req.body;
        if (!text || text.length > 500) {
          return res.status(400).json({ error: "Prayer text required (max 500 chars)." });
        }
        if (containsProfanity(text)) {
          return res.status(400).json({
            error: "Your prayer contains language that isn't appropriate for this community. Please revise and try again.",
          });
        }
        const prayer = {
          text: text.trim(),
          category: category || "Personal",
          authorId: userId,
          authorName: isAnonymous ? "Anonymous" : (authorName || "A Fellow Believer"),
          isAnonymous: isAnonymous || false,
          prayerCount: 0,
          isAnswered: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        const ref = await db.collection("communityPrayers").add(prayer);
        return res.status(200).json({
          id: ref.id, ...prayer, createdAt: new Date().toISOString(),
        });
      }

      case "prayForRequest": {
        const { prayerId } = req.body;
        if (!prayerId) return res.status(400).json({ error: "prayerId required." });
        await db.collection("communityPrayers").doc(prayerId).update({
          prayerCount: admin.firestore.FieldValue.increment(1),
        });
        return res.status(200).json({ success: true });
      }

      // ---- TESTIMONIES ----
      case "getTestimonies": {
        const tLimit = Math.min(req.body.limit || 50, 100);
        const tSnapshot = await db
          .collection("communityTestimonies")
          .where("isRemoved", "!=", true)
          .orderBy("createdAt", "desc")
          .limit(tLimit)
          .get();
        const testimonies = tSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
          createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || null,
        }));
        return res.status(200).json({ testimonies });
      }

      case "submitTestimony": {
        const {
          title, story, category: tCat, authorName: tAuthor, journeyTheme, dayCount,
        } = req.body;
        if (!title || !story || story.length > 2000) {
          return res.status(400).json({ error: "Title and story required (max 2000 chars)." });
        }
        if (containsProfanity(title) || containsProfanity(story)) {
          return res.status(400).json({
            error: "Your testimony contains language that isn't appropriate for this community. Please revise and try again.",
          });
        }
        const testimony = {
          title: title.trim(),
          story: story.trim(),
          category: tCat || "Faith & Doubt",
          authorId: userId,
          authorName: tAuthor || "A Fellow Believer",
          journeyTheme: journeyTheme || "",
          dayCount: dayCount || 40,
          prayerCount: 0,
          // NOTE: Once admin panel ships, default to false and require admin approval.
          isApproved: true,
          isFeatured: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        const tRef = await db.collection("communityTestimonies").add(testimony);
        return res.status(200).json({
          id: tRef.id, ...testimony, createdAt: new Date().toISOString(),
        });
      }

      case "prayForTestimony": {
        const { testimonyId } = req.body;
        if (!testimonyId) return res.status(400).json({ error: "testimonyId required." });
        await db.collection("communityTestimonies").doc(testimonyId).update({
          prayerCount: admin.firestore.FieldValue.increment(1),
        });
        return res.status(200).json({ success: true });
      }

      case "reportPrayer": {
        const { prayerId, reason } = req.body;
        if (!prayerId) return res.status(400).json({ error: "prayerId required." });
        await db.collection("communityReports").add({
          type: "prayer",
          contentId: prayerId,
          reportedBy: userId,
          reason: reason || "unspecified",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        const reportCount = (await db.collection("communityReports")
          .where("contentId", "==", prayerId).get()).size;
        if (reportCount >= 3) {
          await db.collection("communityPrayers").doc(prayerId).update({ isRemoved: true });
        }
        return res.status(200).json({ success: true });
      }

      case "reportTestimony": {
        const { testimonyId, reason: tReason } = req.body;
        if (!testimonyId) return res.status(400).json({ error: "testimonyId required." });
        await db.collection("communityReports").add({
          type: "testimony",
          contentId: testimonyId,
          reportedBy: userId,
          reason: tReason || "unspecified",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        const tReportCount = (await db.collection("communityReports")
          .where("contentId", "==", testimonyId).get()).size;
        if (tReportCount >= 3) {
          await db.collection("communityTestimonies").doc(testimonyId).update({ isRemoved: true });
        }
        return res.status(200).json({ success: true });
      }

      case "deleteUserContent": {
        const batch = db.batch();
        const prayerSnap = await db.collection("communityPrayers")
          .where("authorId", "==", userId).get();
        prayerSnap.docs.forEach((doc) => batch.delete(doc.ref));

        const testimonySnap = await db.collection("communityTestimonies")
          .where("authorId", "==", userId).get();
        testimonySnap.docs.forEach((doc) => batch.delete(doc.ref));

        const reportSnap = await db.collection("communityReports")
          .where("reportedBy", "==", userId).get();
        reportSnap.docs.forEach((doc) => batch.delete(doc.ref));

        const genSnap = await db.collection("journeyGenerations")
          .where("uid", "==", userId).get();
        genSnap.docs.forEach((doc) => batch.delete(doc.ref));

        const today = new Date().toISOString().split("T")[0];
        const rlPrefixes = [`gen_${userId}_${today}`, `audio_${userId}_${today}`];
        for (const prefix of rlPrefixes) {
          batch.delete(db.collection("rateLimits").doc(prefix));
        }

        await batch.commit();
        return res.status(200).json({ success: true });
      }

      default:
        return res.status(400).json({ error: `Unknown action: ${action}` });
    }
  } catch (error) {
    console.error("Community error:", error.message || error);
    return res.status(500).json({ error: error.message || "An unexpected error occurred." });
  }
});
