const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");
const { defineString } = require("firebase-functions/params");

admin.initializeApp();
const db = admin.firestore();

// Environment parameters (set via .env file)
const claudeApiKey = defineString("CLAUDE_API_KEY");
const appSecret = defineString("APP_SECRET");

// ============================================================
// 1. CLAUDE API PROXY — keeps API key off the client
// ============================================================

exports.generateJourney = functions.https.onCall(async (data, context) => {
  // Require authenticated user
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "You must be signed in to generate a journey."
    );
  }

  const { description, theme } = data;
  if (!description || description.length > 500) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Description is required and must be under 500 characters."
    );
  }

  // Rate limit: max 3 generations per user per day
  const userId = context.auth.uid;
  const today = new Date().toISOString().split("T")[0];
  const rateLimitRef = db
    .collection("rateLimits")
    .doc(`${userId}_journey_${today}`);
  const rateLimitDoc = await rateLimitRef.get();
  const currentCount = rateLimitDoc.exists
    ? rateLimitDoc.data().count || 0
    : 0;

  if (currentCount >= 3) {
    throw new functions.https.HttpsError(
      "resource-exhausted",
      "You can generate up to 3 custom journeys per day. Please try again tomorrow."
    );
  }

  // Get Claude API key from environment parameter
  const apiKey = claudeApiKey.value();
  if (!apiKey || apiKey === "YOUR_CLAUDE_API_KEY") {
    throw new functions.https.HttpsError(
      "internal",
      "AI service is not configured."
    );
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
      throw new functions.https.HttpsError(
        "internal",
        "Failed to generate journey. Please try again."
      );
    }

    const result = await response.json();
    const content = result.content?.[0]?.text;

    if (!content) {
      throw new functions.https.HttpsError(
        "internal",
        "No content received from AI."
      );
    }

    // Parse and validate JSON
    const jsonMatch = content.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      throw new functions.https.HttpsError(
        "internal",
        "Invalid response format."
      );
    }

    const journey = JSON.parse(jsonMatch[0]);

    // Basic validation
    if (!journey.title || !journey.days || journey.days.length < 40) {
      throw new functions.https.HttpsError(
        "internal",
        "Generated journey is incomplete. Please try again."
      );
    }

    // Update rate limit
    await rateLimitRef.set({ count: currentCount + 1, date: today });

    // Log generation for analytics
    await db.collection("journeyGenerations").add({
      userId,
      description: description.substring(0, 100),
      theme,
      title: journey.title,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return journey;
  } catch (error) {
    if (error instanceof functions.https.HttpsError) throw error;
    console.error("Journey generation error:", error);
    throw new functions.https.HttpsError(
      "internal",
      "An unexpected error occurred. Please try again."
    );
  }
});

// ============================================================
// 1b. CLAUDE API PROXY (HTTP) — works without Firebase iOS SDK
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
  if (!description || description.length > 500) {
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
    if (!jsonMatch) {
      return res.status(502).json({ error: "Invalid response format." });
    }

    const journey = JSON.parse(jsonMatch[0]);

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
// 2. COMMUNITY PRAYER WALL — shared prayers across all users
// ============================================================

exports.submitPrayer = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in required.");
  }

  const { text, category, isAnonymous } = data;
  if (!text || text.length > 500) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Prayer text is required (max 500 chars)."
    );
  }

  const prayer = {
    text: text.trim(),
    category: category || "general",
    authorId: context.auth.uid,
    authorName: isAnonymous ? "Anonymous" : (context.auth.token.name || "A Fellow Believer"),
    isAnonymous: isAnonymous || false,
    prayerCount: 0,
    isAnswered: false,
    answeredNote: null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const ref = await db.collection("communityPrayers").add(prayer);
  return { id: ref.id, ...prayer };
});

exports.prayForRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in required.");
  }

  const { prayerId } = data;
  if (!prayerId) {
    throw new functions.https.HttpsError("invalid-argument", "Prayer ID required.");
  }

  const prayerRef = db.collection("communityPrayers").doc(prayerId);
  await prayerRef.update({
    prayerCount: admin.firestore.FieldValue.increment(1),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Record who prayed (for "X people prayed for you" notifications)
  await db.collection("prayerInteractions").add({
    prayerId,
    userId: context.auth.uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});

// ============================================================
// 3. COMMUNITY TESTIMONIES — shared faith stories
// ============================================================

exports.submitTestimony = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Sign in required.");
  }

  const { title, story, category, isAnonymous } = data;
  if (!title || !story || story.length > 2000) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Title and story are required (max 2000 chars)."
    );
  }

  const testimony = {
    title: title.trim(),
    story: story.trim(),
    category: category || "general",
    authorId: context.auth.uid,
    authorName: isAnonymous ? "Anonymous" : (context.auth.token.name || "A Fellow Believer"),
    isAnonymous: isAnonymous || false,
    prayerCount: 0,
    isFeatured: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  const ref = await db.collection("communityTestimonies").add(testimony);
  return { id: ref.id, ...testimony };
});

// ============================================================
// 4. PUSH NOTIFICATION TRIGGERS
// ============================================================

// When someone prays for your request, send a notification
exports.onPrayerInteraction = functions.firestore
  .document("prayerInteractions/{interactionId}")
  .onCreate(async (snap) => {
    const interaction = snap.data();
    const prayerDoc = await db
      .collection("communityPrayers")
      .doc(interaction.prayerId)
      .get();

    if (!prayerDoc.exists) return;
    const prayer = prayerDoc.data();

    // Don't notify if user prayed for their own request
    if (prayer.authorId === interaction.userId) return;

    // Get author's FCM token
    const tokenDoc = await db
      .collection("userTokens")
      .doc(prayer.authorId)
      .get();
    if (!tokenDoc.exists || !tokenDoc.data().fcmToken) return;

    await admin.messaging().send({
      token: tokenDoc.data().fcmToken,
      notification: {
        title: "Someone Prayed for You",
        body: `A fellow believer just lifted up your prayer request.`,
      },
      data: {
        type: "prayer_interaction",
        prayerId: interaction.prayerId,
      },
    });
  });
