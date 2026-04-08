#!/usr/bin/env python3
"""
AbideJourney Audio Generator
Generates devotional audio using ElevenLabs API.

Usage:
    python3 generate_audio.py --api-key YOUR_KEY --voice-id VOICE_ID

Setup:
    pip3 install requests

The script reads devotional content from the app's ContentLibrary
and generates audio files for each day's Scripture + Devotional + Prayer.
"""

import os
import sys
import json
import time
import argparse
import requests

ELEVENLABS_API = "https://api.elevenlabs.io/v1"


def generate_audio(api_key, voice_id, text, output_path, model="eleven_multilingual_v2"):
    """Generate audio from text using ElevenLabs API."""
    url = f"{ELEVENLABS_API}/text-to-speech/{voice_id}"

    headers = {
        "xi-api-key": api_key,
        "Content-Type": "application/json",
    }

    payload = {
        "text": text,
        "model_id": model,
        "voice_settings": {
            "stability": 0.65,       # Slightly varied for natural feel
            "similarity_boost": 0.80, # Keep close to voice but not robotic
            "style": 0.35,           # Gentle expression
            "use_speaker_boost": True,
        },
    }

    response = requests.post(url, json=payload, headers=headers)

    if response.status_code == 200:
        os.makedirs(os.path.dirname(output_path), exist_ok=True)
        with open(output_path, "wb") as f:
            f.write(response.content)
        print(f"  ✓ Generated: {output_path}")
        return True
    else:
        print(f"  ✗ Error {response.status_code}: {response.text[:200]}")
        return False


def format_devotional_script(scripture_ref, scripture_text, title, devotional, prayer):
    """Format devotional content into a natural narration script."""
    script = f"""
{title}.

Today's Scripture comes from {scripture_ref}.

{scripture_text}

{devotional}

Let us pray together.

{prayer}

Amen.
""".strip()
    return script


def get_sample_content():
    """Sample content for testing. Replace with actual content loading."""
    return [
        {
            "day": 1,
            "theme": "knowingGod",
            "scriptureRef": "John 1:1-3",
            "scriptureText": "In the beginning was the Word, and the Word was with God, and the Word was God. He was with God in the beginning. Through him all things were made; without him nothing was made that has been made.",
            "title": "Day 1: In the Beginning",
            "devotional": "Before time began, before the first star ignited in the vast darkness, there was the Word. Not just any word, but the living, breathing, creative Word of God. John opens his Gospel not with a birth announcement or a genealogy, but with a cosmic declaration: Jesus is eternal. He didn't begin in Bethlehem. He has always been. Today, as you begin this journey, let that truth settle deep. The God who spoke galaxies into existence is the same God who speaks to you right now, in the quiet of this moment.",
            "prayer": "Father, as I begin this journey, open my eyes to see You more clearly. Help me know You not just as a concept, but as the living God who has always been and always will be. Speak to me through Your Word today.",
        },
        {
            "day": 2,
            "theme": "knowingGod",
            "scriptureRef": "Psalm 139:1-4",
            "scriptureText": "You have searched me, Lord, and you know me. You know when I sit and when I rise; you perceive my thoughts from afar. You discern my going out and my lying down; you are familiar with all my ways. Before a word is on my tongue you, Lord, know it completely.",
            "title": "Day 2: Fully Known",
            "devotional": "There is nothing about you that surprises God. Not your doubts. Not your failures. Not the thoughts you'd never say out loud. David writes that God perceives our thoughts from afar, that He is familiar with all our ways. This isn't surveillance. This is intimacy. The Creator of the universe knows you completely, and He still chose you. He still loves you. Let that truth dismantle every fear of rejection today.",
            "prayer": "Lord, You know me completely, and yet You love me anyway. Help me stop hiding from You. Give me the courage to bring my whole self, the messy parts and the beautiful parts, into Your presence today.",
        },
    ]


def main():
    parser = argparse.ArgumentParser(description="Generate devotional audio with ElevenLabs")
    parser.add_argument("--api-key", required=True, help="ElevenLabs API key")
    parser.add_argument("--voice-id", required=True, help="ElevenLabs voice ID")
    parser.add_argument("--output-dir", default="./audio_output", help="Output directory")
    parser.add_argument("--theme", default="all", help="Theme to generate (or 'all')")
    parser.add_argument("--days", type=int, default=0, help="Number of days to generate (0 = all)")
    parser.add_argument("--test", action="store_true", help="Generate 2 sample days only")
    args = parser.parse_args()

    print("🎙️  AbideJourney Audio Generator")
    print("=" * 40)

    # Load content
    content = get_sample_content()
    if args.test:
        content = content[:2]
        print(f"Test mode: generating {len(content)} sample days\n")
    elif args.days > 0:
        content = content[:args.days]

    # Check API key
    print("Checking ElevenLabs API connection...")
    user_resp = requests.get(f"{ELEVENLABS_API}/user", headers={"xi-api-key": args.api_key})
    if user_resp.status_code != 200:
        print(f"✗ Invalid API key. Status: {user_resp.status_code}")
        sys.exit(1)

    user_data = user_resp.json()
    remaining = user_data.get("subscription", {}).get("character_count", 0)
    limit = user_data.get("subscription", {}).get("character_limit", 0)
    print(f"✓ Connected. Characters remaining: {remaining:,} / {limit:,}\n")

    # Estimate characters needed
    total_chars = sum(
        len(format_devotional_script(
            d["scriptureRef"], d["scriptureText"],
            d["title"], d["devotional"], d["prayer"]
        ))
        for d in content
    )
    print(f"📊 Estimated characters needed: {total_chars:,}")
    if total_chars > remaining:
        print(f"⚠️  Warning: Not enough characters. Need {total_chars:,}, have {remaining:,}")
        print("   Consider upgrading your plan or generating fewer days.")
        response = input("Continue anyway? (y/n): ")
        if response.lower() != "y":
            sys.exit(0)

    # Generate audio
    print(f"\n🔊 Generating audio for {len(content)} days...\n")

    success_count = 0
    for day_content in content:
        day_num = day_content["day"]
        theme = day_content["theme"]
        print(f"Day {day_num} ({theme}):")

        script = format_devotional_script(
            day_content["scriptureRef"],
            day_content["scriptureText"],
            day_content["title"],
            day_content["devotional"],
            day_content["prayer"],
        )

        output_path = os.path.join(
            args.output_dir, theme, f"day_{day_num:02d}.mp3"
        )

        if generate_audio(args.api_key, args.voice_id, script, output_path):
            success_count += 1

        # Rate limiting: ElevenLabs allows ~3 requests/sec on Starter
        time.sleep(0.5)

    print(f"\n{'=' * 40}")
    print(f"✓ Generated {success_count}/{len(content)} audio files")
    print(f"📁 Output: {os.path.abspath(args.output_dir)}")
    print(f"\nNext steps:")
    print(f"  1. Review the audio files for quality")
    print(f"  2. Copy the audio_output/ folder into your Xcode project")
    print(f"  3. Or upload to Firebase Storage for streaming")


if __name__ == "__main__":
    main()
