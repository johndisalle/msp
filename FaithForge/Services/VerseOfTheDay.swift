// VerseOfTheDay.swift
// FaithForge
//
// Hardcoded motivational verses. Cycles based on day-of-year.

import Foundation

struct VerseOfTheDay {
    let text: String
    let reference: String

    /// Returns today's verse, cycling through the set.
    static var today: VerseOfTheDay {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = (dayOfYear - 1) % verses.count
        return verses[index]
    }

    static let verses: [VerseOfTheDay] = [
        VerseOfTheDay(
            text: "For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.",
            reference: "Jeremiah 29:11"
        ),
        VerseOfTheDay(
            text: "I can do all things through Christ who strengthens me.",
            reference: "Philippians 4:13"
        ),
        VerseOfTheDay(
            text: "Trust in the Lord with all your heart and lean not on your own understanding.",
            reference: "Proverbs 3:5"
        ),
        VerseOfTheDay(
            text: "Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.",
            reference: "Joshua 1:9"
        ),
        VerseOfTheDay(
            text: "But those who hope in the Lord will renew their strength. They will soar on wings like eagles.",
            reference: "Isaiah 40:31"
        ),
        VerseOfTheDay(
            text: "The Lord is my shepherd; I shall not want. He makes me lie down in green pastures.",
            reference: "Psalm 23:1-2"
        ),
        VerseOfTheDay(
            text: "And we know that in all things God works for the good of those who love him.",
            reference: "Romans 8:28"
        ),
        VerseOfTheDay(
            text: "Come to me, all you who are weary and burdened, and I will give you rest.",
            reference: "Matthew 11:28"
        ),
        VerseOfTheDay(
            text: "The steadfast love of the Lord never ceases; his mercies never come to an end; they are new every morning.",
            reference: "Lamentations 3:22-23"
        ),
        VerseOfTheDay(
            text: "Delight yourself in the Lord, and he will give you the desires of your heart.",
            reference: "Psalm 37:4"
        ),
    ]
}
