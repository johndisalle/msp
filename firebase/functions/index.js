const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
const { defineString } = require("firebase-functions/params");

admin.initializeApp();
const db = admin.firestore();

// Environment parameters (set via .env file)
const claudeApiKey = defineString("CLAUDE_API_KEY");
const appSecret = defineString("APP_SECRET");
const elevenLabsKey = defineString("ELEVENLABS_API_KEY");
const elevenLabsFemaleVoice = defineString("ELEVENLABS_FEMALE_VOICE_ID");
const elevenLabsMaleVoice = defineString("ELEVENLABS_MALE_VOICE_ID");

// ============================================================
// 1. CLAUDE API PROXY (HTTP) — keeps API key off the client
// ============================================================

exports.generateJourneyHTTP = functions.https.onRequest(async (req, res) => {
  // CORS
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type, X-App-Secret");
    return res.status(204).send("");
  }

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  // Verify app secret to prevent unauthorized access
  const secret = req.headers["x-app-secret"] || req.body?.appSecret;
  if (!secret || secret !== appSecret.value()) {
    return res.status(403).json({ error: "Unauthorized" });
  }

  const { description, theme, deviceId } = req.body;
  if (!description?.trim() || description.length > 500) {
    return res
      .status(400)
      .json({ error: "Description is required and must be under 500 characters." });
  }

  // Rate limit by deviceId: max 3 per day
  const identifier = deviceId || "unknown";
  const today = new Date().toISOString().split("T")[0];
  const rateLimitRef = db
    .collection("rateLimits")
    .doc(`device_${identifier}_${today}`);
  const rateLimitDoc = await rateLimitRef.get();
  const currentCount = rateLimitDoc.exists
    ? rateLimitDoc.data().count || 0
    : 0;

  if (currentCount >= 3) {
    return res.status(429).json({
      error:
        "You can generate up to 3 custom journeys per day. Please try again tomorrow.",
    });
  }

  const apiKey = claudeApiKey.value();
  if (!apiKey || apiKey === "YOUR_CLAUDE_API_KEY") {
    return res.status(500).json({ error: "AI service is not configured." });
  }

  const systemPrompt = `You are a Christian devotional content creator. Generate a 40-day spiritual journey based on the user's description. Return valid JSON only.`;

  const userPrompt = `Create a personalized 40-day devotional journey for someone going through: "${description}"

Theme preference: ${theme || "Spiritual Growth"}

Return a JSON object with this exact structure:
{
  "title": "Journey Title",
  "subtitle": "Brief subtitle",
  "days": [
    {
      "dayNumber": 1,
      "focusArea": "Prayer|Scripture|Obedience|Worship|Community|Evangelism|Service",
      "scriptureReference": "Book Chapter:Verse",
      "scriptureText": "Full verse text",
      "devotionalTitle": "Day title",
      "devotionalText": "3-5 paragraph devotional (400-600 words)",
      "prayerText": "Guided prayer (2-3 sentences)",
      "reflectionPrompt": "Personal reflection question",
      "actionSteps": ["Step 1", "Step 2"]
    }
  ]
}

Requirements:
- Use real, accurate Bible verses (NIV preferred)
- Never repeat the same Scripture passage
- Make devotionals deeply personal and relevant to their situation
- Include a mix of all 7 focus areas across the 40 days
- Action steps should be practical and doable
- Prayers should be heartfelt and specific to the day's theme`;

  try {
    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-20250514",
        max_tokens: 8192,
        system: systemPrompt,
        messages: [{ role: "user", content: userPrompt }],
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("Claude API error:", errorText);
      return res
        .status(502)
        .json({ error: "Failed to generate journey. Please try again." });
    }

    const result = await response.json();
    const content = result.content?.[0]?.text;

    if (!content) {
      return res.status(502).json({ error: "No content received from AI." });
    }

    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (!jsonMatch || jsonMatch.length === 0) {
      return res.status(502).json({ error: "Invalid response format." });
    }

    let journey;
    try {
      journey = JSON.parse(jsonMatch[0]);
    } catch (parseError) {
      console.error("JSON parse error:", parseError.message);
      return res.status(502).json({ error: "Failed to parse AI response. Please try again." });
    }

    if (!journey.title || !journey.days || journey.days.length < 40) {
      return res
        .status(502)
        .json({ error: "Generated journey is incomplete. Please try again." });
    }

    // Update rate limit
    await rateLimitRef.set({ count: currentCount + 1, date: today });

    // Log generation
    await db.collection("journeyGenerations").add({
      deviceId: identifier,
      description: description.substring(0, 100),
      theme,
      title: journey.title,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.status(200).json(journey);
  } catch (error) {
    console.error("Journey generation error:", error);
    return res
      .status(500)
      .json({ error: "An unexpected error occurred. Please try again." });
  }
});

// ============================================================
// 2. ELEVENLABS AUDIO NARRATION — premium voice for Listen Mode
// ============================================================

exports.generateAudioHTTP = functions.https.onRequest(async (req, res) => {
    // CORS
    res.set("Access-Control-Allow-Origin", "*");
    if (req.method === "OPTIONS") {
      res.set("Access-Control-Allow-Methods", "POST");
      res.set("Access-Control-Allow-Headers", "Content-Type, X-App-Secret");
      return res.status(204).send("");
    }

    if (req.method !== "POST") {
      return res.status(405).json({ error: "Method not allowed" });
    }

    // Verify app secret
    const secret = req.headers["x-app-secret"] || req.body?.appSecret;
    if (!secret || secret !== appSecret.value()) {
      return res.status(403).json({ error: "Unauthorized" });
    }

    const { text, voice, deviceId } = req.body;
    if (!text?.trim() || text.length > 5000) {
      return res
        .status(400)
        .json({ error: "Text is required and must be under 5000 characters." });
    }
    if (voice && !["male", "female"].includes(voice)) {
      return res.status(400).json({ error: "Voice must be 'male' or 'female'." });
    }

    // Rate limit: max 20 audio generations per device per day
    const identifier = deviceId || "unknown";
    const today = new Date().toISOString().split("T")[0];
    const rateLimitRef = db
      .collection("rateLimits")
      .doc(`audio_${identifier}_${today}`);
    const rateLimitDoc = await rateLimitRef.get();
    const currentCount = rateLimitDoc.exists
      ? rateLimitDoc.data().count || 0
      : 0;

    if (currentCount >= 20) {
      return res.status(429).json({
        error: "Daily audio limit reached. Please try again tomorrow.",
      });
    }

    const apiKey = elevenLabsKey.value();
    if (!apiKey || apiKey === "YOUR_ELEVENLABS_API_KEY") {
      return res.status(500).json({ error: "Audio service is not configured." });
    }

    // Select voice
    const voiceId =
      voice === "male"
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
        return res
          .status(502)
          .json({ error: "Failed to generate audio. Please try again." });
      }

      // Update rate limit
      await rateLimitRef.set({ count: currentCount + 1, date: today });

      // Stream the MP3 audio back to the client
      const arrayBuf = await response.arrayBuffer();
      const audioBuffer = Buffer.from(arrayBuf);
      res.set("Content-Type", "audio/mpeg");
      res.set("Content-Length", audioBuffer.length.toString());
      return res.status(200).send(audioBuffer);
    } catch (error) {
      console.error("Audio generation error:", error.message || error);
      return res
        .status(500)
        .json({ error: error.message || "An unexpected error occurred." });
    }
  });

// ============================================================
// 3. COMMUNITY FEATURES — Prayer Wall & Testimony Wall
// ============================================================

exports.communityHTTP = functions.https.onRequest(async (req, res) => {
  // CORS
  res.set("Access-Control-Allow-Origin", "*");
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Methods", "POST");
    res.set("Access-Control-Allow-Headers", "Content-Type, X-App-Secret");
    return res.status(204).send("");
  }

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const secret = req.headers["x-app-secret"] || req.body?.appSecret;
  if (!secret || secret !== appSecret.value()) {
    return res.status(403).json({ error: "Unauthorized" });
  }

  const { action, deviceId } = req.body;
  const userId = deviceId || "anonymous";

  // Basic server-side content filter
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
          return res.status(400).json({ error: "Your prayer contains language that isn't appropriate for this community. Please revise and try again." });
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
        return res.status(200).json({ id: ref.id, ...prayer, createdAt: new Date().toISOString() });
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
        const { title, story, category: tCat, authorName: tAuthor, journeyTheme, dayCount } = req.body;
        if (!title || !story || story.length > 2000) {
          return res.status(400).json({ error: "Title and story required (max 2000 chars)." });
        }
        if (containsProfanity(title) || containsProfanity(story)) {
          return res.status(400).json({ error: "Your testimony contains language that isn't appropriate for this community. Please revise and try again." });
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
          isApproved: false,
          isFeatured: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        const tRef = await db.collection("communityTestimonies").add(testimony);
        return res.status(200).json({ id: tRef.id, ...testimony, createdAt: new Date().toISOString() });
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
        // Auto-hide after 3 reports
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
        // Delete all community content for a user (for account deletion)
        const prayerSnap = await db.collection("communityPrayers")
          .where("authorId", "==", userId).get();
        const testimonySnap = await db.collection("communityTestimonies")
          .where("authorId", "==", userId).get();
        const batch = db.batch();
        prayerSnap.docs.forEach((doc) => batch.delete(doc.ref));
        testimonySnap.docs.forEach((doc) => batch.delete(doc.ref));
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
