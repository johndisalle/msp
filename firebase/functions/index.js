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
// 2. ELEVENLABS AUDIO NARRATION — premium voice for Listen Mode
// ============================================================

exports.generateAudioHTTP = functions.https.onRequest(
  { timeoutSeconds: 120, memory: "512MiB" },
  async (req, res) => {
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
    if (!text || text.length > 5000) {
      return res
        .status(400)
        .json({ error: "Text is required and must be under 5000 characters." });
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
      const audioBuffer = await response.buffer();
      res.set("Content-Type", "audio/mpeg");
      res.set("Content-Length", audioBuffer.length.toString());
      return res.status(200).send(audioBuffer);
    } catch (error) {
      console.error("Audio generation error:", error);
      return res
        .status(500)
        .json({ error: "An unexpected error occurred. Please try again." });
    }
  }
);
