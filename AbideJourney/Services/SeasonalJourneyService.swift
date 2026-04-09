import Foundation
import SwiftUI

// MARK: - Seasonal Journey Model

struct SeasonalJourney: Identifiable {
    let id = UUID()
    let season: ChurchSeason
    let title: String
    let subtitle: String
    let totalDays: Int
    let icon: String
    let gradient: [Color]
    let startDate: Date
    let endDate: Date
    let description: String
    let themes: [String]

    var isCurrentlyActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }

    var daysUntilStart: Int? {
        let now = Date()
        let days = Calendar.current.dateComponents([.day], from: now, to: startDate).day ?? 0
        return days > 0 ? days : nil
    }

    var hasEnded: Bool {
        Date() > endDate
    }
}

enum ChurchSeason: String, CaseIterable {
    case advent = "Advent"
    case lent = "Lent"
    case holyWeek = "Holy Week"
    case newYear = "New Year"
    case summer = "Summer of Faith"
    case spring = "Spring Renewal"

    var tagline: String {
        switch self {
        case .advent: return "Prepare your heart for Christmas"
        case .lent: return "40 days of reflection and repentance"
        case .holyWeek: return "Walk with Jesus to the cross and beyond"
        case .newYear: return "Reset your faith for the year ahead"
        case .summer: return "Deepen your roots in the warm season"
        case .spring: return "New life, new growth, new beginnings"
        }
    }
}

// MARK: - Service

final class SeasonalJourneyService {
    static let shared = SeasonalJourneyService()
    private init() {}

    private let dismissedKey = "seasonalJourney_dismissed"

    // MARK: - Easter Calculation (Computus Algorithm)

    /// Calculates Easter Sunday for a given year using the Anonymous Gregorian algorithm.
    private func easterDate(year: Int) -> Date {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1
        return Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    // MARK: - All Seasonal Journeys

    var allSeasons: [SeasonalJourney] {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let easter = easterDate(year: year)

        // Holy Week: Palm Sunday (6 days before Easter) through Easter Sunday
        let palmSunday = calendar.date(byAdding: .day, value: -6, to: easter) ?? easter

        // Lent: Ash Wednesday (46 days before Easter) through day before Palm Sunday
        let ashWednesday = calendar.date(byAdding: .day, value: -46, to: easter) ?? easter
        let lentEnd = calendar.date(byAdding: .day, value: -7, to: easter) ?? easter

        return [
            SeasonalJourney(
                season: .advent,
                title: "Advent: The Coming King",
                subtitle: "25 days preparing your heart for the Savior's birth",
                totalDays: 25,
                icon: "star.fill",
                gradient: [Color(red: 0.5, green: 0.0, blue: 0.13), Color(red: 0.15, green: 0.05, blue: 0.15)],
                startDate: makeDate(year: year, month: 12, day: 1),
                endDate: makeDate(year: year, month: 12, day: 25),
                description: "Journey through the prophecies, promises, and fulfillment of Christ's birth. Each day brings you closer to the manger through Scripture, reflection, and worship.",
                themes: ["Hope", "Peace", "Joy", "Love", "The Incarnation", "Emmanuel", "Prophecy Fulfilled", "The Shepherds", "The Wise Men", "Heavenly Host"]
            ),
            SeasonalJourney(
                season: .lent,
                title: "Lenten Journey: Road to the Cross",
                subtitle: "40 days of fasting, prayer, and self-examination",
                totalDays: 40,
                icon: "cross.fill",
                gradient: [Color(red: 0.3, green: 0.15, blue: 0.4), Color(red: 0.1, green: 0.05, blue: 0.2)],
                startDate: ashWednesday,
                endDate: lentEnd,
                description: "Walk the ancient path of Lent. Through daily Scripture, fasting reflections, and intentional prayer, prepare your heart for the depth of Easter's joy.",
                themes: ["Repentance", "Fasting", "Surrender", "Humility", "The Beatitudes", "Sermon on the Mount", "Forgiveness", "Sacrifice", "The Cross", "Dying to Self"]
            ),
            SeasonalJourney(
                season: .holyWeek,
                title: "Holy Week: Seven Sacred Days",
                subtitle: "Walk hour by hour with Jesus through Passion Week",
                totalDays: 7,
                icon: "laurel.leading",
                gradient: [Color(red: 0.55, green: 0.27, blue: 0.07), Color(red: 0.2, green: 0.1, blue: 0.05)],
                startDate: palmSunday,
                endDate: easter,
                description: "From the Triumphal Entry to the Empty Tomb. Experience each day of Holy Week with vivid Scripture, guided prayer, and deep reflection on what Jesus endured for you.",
                themes: ["Palm Sunday", "Cleansing the Temple", "Teaching in the Temple", "Passover & Betrayal", "Good Friday", "Silent Saturday", "Resurrection Sunday"]
            ),
            SeasonalJourney(
                season: .newYear,
                title: "New Year Faith Reset",
                subtitle: "21 days to renew your mind, heart, and habits",
                totalDays: 21,
                icon: "sparkles",
                gradient: [Color(red: 0.0, green: 0.3, blue: 0.5), Color(red: 0.0, green: 0.2, blue: 0.1)],
                startDate: makeDate(year: year, month: 1, day: 1),
                endDate: makeDate(year: year, month: 1, day: 21),
                description: "Start the year anchored in God's Word. Build spiritual habits that last: daily Bible reading, prayer rhythms, gratitude practice, and intentional living.",
                themes: ["New Beginnings", "Setting Intentions", "Identity in Christ", "Spiritual Disciplines", "Purpose", "Gratitude", "Daily Prayer", "Fasting", "Community", "Faithfulness"]
            ),
            SeasonalJourney(
                season: .summer,
                title: "Summer of Faith",
                subtitle: "30 days to grow deep roots while the sun shines",
                totalDays: 30,
                icon: "sun.max.fill",
                gradient: [Color(red: 0.95, green: 0.6, blue: 0.1), Color(red: 0.85, green: 0.2, blue: 0.1)],
                startDate: makeDate(year: year, month: 6, day: 1),
                endDate: makeDate(year: year, month: 8, day: 31),
                description: "Summer is a season of growth. Use these longer days to deepen your understanding of God's creation, His faithfulness, and your call to adventure with Him.",
                themes: ["Creation", "Adventure", "Rest", "Sabbath", "Psalms of Nature", "The Promised Land", "God's Provision", "Joy", "Freedom", "Sending"]
            ),
            SeasonalJourney(
                season: .spring,
                title: "Spring Renewal",
                subtitle: "21 days of new life and fresh starts",
                totalDays: 21,
                icon: "leaf.fill",
                gradient: [Color(red: 0.2, green: 0.6, blue: 0.3), Color(red: 0.1, green: 0.35, blue: 0.15)],
                startDate: makeDate(year: year, month: 3, day: 20),
                endDate: makeDate(year: year, month: 5, day: 31),
                description: "As creation springs to life, let your spirit be renewed. Explore themes of resurrection, new growth, and the Holy Spirit's transforming power.",
                themes: ["New Life", "Resurrection Power", "The Holy Spirit", "Renewal", "Transformation", "Growth", "Abiding", "Bearing Fruit", "Living Water", "Fresh Fire"]
            )
        ]
    }

    // MARK: - Active Season Detection

    func currentActiveSeason() -> SeasonalJourney? {
        allSeasons.first { $0.isCurrentlyActive && !isDismissed($0) }
    }

    // MARK: - Dismissal

    func isDismissed(_ season: SeasonalJourney) -> Bool {
        let key = "\(dismissedKey)_\(season.season.rawValue)_\(currentYear())"
        return UserDefaults.standard.bool(forKey: key)
    }

    func dismiss(_ season: SeasonalJourney) {
        let key = "\(dismissedKey)_\(season.season.rawValue)_\(currentYear())"
        UserDefaults.standard.set(true, forKey: key)
    }

    private func currentYear() -> Int {
        Calendar.current.component(.year, from: Date())
    }

    // MARK: - Content Generation

    func generateDayContent(for season: SeasonalJourney, dayNumber: Int) -> (scripture: String, scriptureRef: String, devotional: String, prayer: String, title: String) {
        // Return themed content based on season
        let themeIndex = (dayNumber - 1) % season.themes.count
        let theme = season.themes[themeIndex]

        switch season.season {
        case .advent:
            return adventContent(day: dayNumber, theme: theme)
        case .lent:
            return lentenContent(day: dayNumber, theme: theme)
        case .holyWeek:
            return holyWeekContent(day: dayNumber, theme: theme)
        case .newYear:
            return newYearContent(day: dayNumber, theme: theme)
        case .summer:
            return summerContent(day: dayNumber, theme: theme)
        case .spring:
            return springContent(day: dayNumber, theme: theme)
        }
    }

    // MARK: - Season-Specific Content

    private func adventContent(day: Int, theme: String) -> (String, String, String, String, String) {
        let scriptures: [(text: String, ref: String)] = [
            ("For to us a child is born, to us a son is given, and the government will be on his shoulders. And he will be called Wonderful Counselor, Mighty God, Everlasting Father, Prince of Peace.", "Isaiah 9:6"),
            ("The people walking in darkness have seen a great light; on those living in the land of deep darkness a light has dawned.", "Isaiah 9:2"),
            ("Therefore the Lord himself will give you a sign: The virgin will conceive and give birth to a son, and will call him Immanuel.", "Isaiah 7:14"),
            ("But you, Bethlehem Ephrathah, though you are small among the clans of Judah, out of you will come for me one who will be ruler over Israel, whose origins are from of old, from ancient times.", "Micah 5:2"),
            ("The Word became flesh and made his dwelling among us. We have seen his glory, the glory of the one and only Son, who came from the Father, full of grace and truth.", "John 1:14"),
            ("For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.", "John 3:16"),
            ("Today in the town of David a Savior has been born to you; he is the Messiah, the Lord.", "Luke 2:11"),
            ("Glory to God in the highest heaven, and on earth peace to those on whom his favor rests.", "Luke 2:14"),
            ("She will give birth to a son, and you are to give him the name Jesus, because he will save his people from their sins.", "Matthew 1:21"),
            ("Do not be afraid. I bring you good news that will cause great joy for all the people.", "Luke 2:10"),
        ]

        let idx = (day - 1) % scriptures.count
        let s = scriptures[idx]

        return (
            s.text,
            s.ref,
            "In this Advent season, we pause to reflect on the theme of \(theme). The coming of Christ was not an afterthought — it was planned from the foundation of the world. As you meditate on today's Scripture, consider how God has been preparing your heart for encounter with Him, just as He prepared the world for the coming of His Son.",
            "Lord Jesus, in this season of waiting and anticipation, prepare my heart to receive You afresh. As the world celebrated Your first coming, let me live in light of Your promised return. Fill me with \(theme.lowercased()) today. Amen.",
            "Advent Day \(day): \(theme)"
        )
    }

    private func lentenContent(day: Int, theme: String) -> (String, String, String, String, String) {
        let scriptures: [(text: String, ref: String)] = [
            ("Create in me a pure heart, O God, and renew a steadfast spirit within me.", "Psalm 51:10"),
            ("Yet even now, declares the Lord, return to me with all your heart, with fasting, with weeping, and with mourning.", "Joel 2:12"),
            ("If we confess our sins, he is faithful and just and will forgive us our sins and purify us from all unrighteousness.", "1 John 1:9"),
            ("He was pierced for our transgressions, he was crushed for our iniquities; the punishment that brought us peace was on him, and by his wounds we are healed.", "Isaiah 53:5"),
            ("Then he said to them all: Whoever wants to be my disciple must deny themselves and take up their cross daily and follow me.", "Luke 9:23"),
            ("Search me, God, and know my heart; test me and know my anxious thoughts. See if there is any offensive way in me, and lead me in the way everlasting.", "Psalm 139:23-24"),
            ("Blessed are the poor in spirit, for theirs is the kingdom of heaven.", "Matthew 5:3"),
            ("But he said to me, My grace is sufficient for you, for my power is made perfect in weakness.", "2 Corinthians 12:9"),
            ("Come to me, all you who are weary and burdened, and I will give you rest.", "Matthew 11:28"),
            ("I have been crucified with Christ and I no longer live, but Christ lives in me.", "Galatians 2:20"),
        ]

        let idx = (day - 1) % scriptures.count
        let s = scriptures[idx]

        return (
            s.text,
            s.ref,
            "Day \(day) of Lent calls us to the practice of \(theme.lowercased()). The Lenten journey strips away the distractions and pretenses that keep us from seeing ourselves — and God — clearly. Today's Scripture invites you into honest reflection. Where have you been relying on your own strength? Where is God inviting you to let go?",
            "Father, in this Lenten season I lay down my pride and self-sufficiency. Teach me the way of \(theme.lowercased()). Let the cross reshape my desires and draw me closer to Your heart. In Jesus' name, Amen.",
            "Lent Day \(day): \(theme)"
        )
    }

    private func holyWeekContent(day: Int, theme: String) -> (String, String, String, String, String) {
        let days: [(text: String, ref: String, devotional: String, prayer: String)] = [
            ("Rejoice greatly, Daughter Zion! Shout, Daughter Jerusalem! See, your king comes to you, righteous and victorious, lowly and riding on a donkey.", "Zechariah 9:9",
             "Palm Sunday: Jesus enters Jerusalem as King — but not the kind of king anyone expected. He comes in humility, on a donkey, fulfilling ancient prophecy. The crowds shout Hosanna, yet within days their cries will change. Today, examine whether you welcome Jesus as He is, or only as you wish Him to be.",
             "Lord Jesus, I lay down my expectations and welcome You as You truly are — humble King, suffering servant, risen Lord. Hosanna! Blessed is He who comes in the name of the Lord. Amen."),
            ("On reaching Jerusalem, Jesus entered the temple courts and began driving out those who were buying and selling there.", "Mark 11:15",
             "Monday: Jesus cleanses the temple. His righteous anger reveals how seriously God takes worship. The temple was meant to be a house of prayer for all nations, but it had become a marketplace. What has cluttered the temple of your heart? What needs to be overturned so God can dwell freely?",
             "Holy God, cleanse the temple of my heart. Remove anything that distracts me from pure worship — greed, pride, complacency. Make my heart a house of prayer. Amen."),
            ("He sat down, called the Twelve and said, Anyone who wants to be first must be the very last, and the servant of all.", "Mark 9:35",
             "Tuesday: Jesus teaches in the temple courts. His words are sharp and tender — warning the religious leaders, comforting the broken. He teaches about the greatest commandment: love God, love neighbor. His authority comes not from position but from truth. Let His words cut through your assumptions today.",
             "Teacher, speak Your truth into my life today. Give me ears to hear, even when Your words challenge me. Let love be the law of my life. Amen."),
            ("While they were eating, Jesus took bread, and when he had given thanks, he broke it and gave it to his disciples, saying, Take it; this is my body.", "Mark 14:22",
             "Thursday: The Last Supper. Jesus gathers His closest friends for a final meal. He washes their feet — the King becomes a servant. He breaks bread and pours wine, giving us a covenant meal to remember Him by. Judas slips away into the night. In the Garden of Gethsemane, Jesus prays until His sweat becomes like drops of blood.",
             "Jesus, You knelt to wash feet. You broke bread for betrayers. Help me to serve with that same selfless love. In my own Gethsemane moments, let me pray as You did: not my will, but Yours be done. Amen."),
            ("And at three in the afternoon Jesus cried out in a loud voice, My God, my God, why have you forsaken me?", "Mark 15:34",
             "Good Friday: The sky goes dark. The Son of God hangs between heaven and earth, bearing the full weight of human sin. He who knew no sin became sin for us. The curtain in the temple tears from top to bottom — the barrier between God and humanity is destroyed forever. It is finished.",
             "Jesus, I stand at the foot of Your cross in awe. You chose this — for me. Let me never take lightly the price You paid. Thank You for bearing what I could not bear. It is finished. Amen."),
            ("Joseph took the body, wrapped it in a clean linen cloth, and placed it in his own new tomb.", "Matthew 27:59-60",
             "Silent Saturday: The world holds its breath. Jesus lies in a tomb. His followers are scattered, grieving, confused. All hope seems lost. Yet in the silence, something is happening that no one can see. God's greatest work often happens in our darkest, most silent moments. Wait. Hope. Trust.",
             "God of the impossible, in my seasons of silence and waiting, remind me that You are still at work. Even when I cannot see, even when hope feels buried — You are faithful. Amen."),
            ("He is not here; he has risen, just as he said. Come and see the place where he lay.", "Matthew 28:6",
             "Resurrection Sunday: The stone is rolled away. The tomb is empty. Death has been swallowed up in victory! Mary sees Him first — not a ghost, not a vision, but the living Jesus. Everything changes. Every promise God has ever made is confirmed by this empty tomb. He is risen. He is risen indeed!",
             "Risen Lord, hallelujah! You conquered death, sin, and the grave. Because You live, I can face tomorrow. Fill me with resurrection power — power to forgive, to hope, to love, to live boldly. He is risen! Amen.")
        ]

        let idx = min(day - 1, days.count - 1)
        let d = days[idx]

        return (d.text, d.ref, d.devotional, d.prayer, theme)
    }

    private func newYearContent(day: Int, theme: String) -> (String, String, String, String, String) {
        let scriptures: [(text: String, ref: String)] = [
            ("See, I am doing a new thing! Now it springs up; do you not perceive it? I am making a way in the wilderness and streams in the wasteland.", "Isaiah 43:19"),
            ("Forget the former things; do not dwell on the past.", "Isaiah 43:18"),
            ("Therefore, if anyone is in Christ, the new creation has come: The old has gone, the new is here!", "2 Corinthians 5:17"),
            ("For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.", "Jeremiah 29:11"),
            ("Commit to the Lord whatever you do, and he will establish your plans.", "Proverbs 16:3"),
            ("Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.", "Proverbs 3:5-6"),
            ("Give thanks in all circumstances; for this is God's will for you in Christ Jesus.", "1 Thessalonians 5:18"),
            ("But seek first his kingdom and his righteousness, and all these things will be given to you as well.", "Matthew 6:33"),
            ("He has shown you, O mortal, what is good. And what does the Lord require of you? To act justly and to love mercy and to walk humbly with your God.", "Micah 6:8"),
            ("Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.", "Joshua 1:9"),
        ]

        let idx = (day - 1) % scriptures.count
        let s = scriptures[idx]

        return (
            s.text,
            s.ref,
            "As you begin this new year, today's focus is \(theme.lowercased()). A fresh calendar is more than new dates — it's an invitation from God to align your life with His purposes. Don't rush past this moment. Let God speak to you about what He wants to build in your life this year.",
            "Father, I surrender this new year to You. Guide my steps, refine my desires, and fill me with purpose. Help me walk in \(theme.lowercased()) every single day. In Jesus' name, Amen.",
            "New Year Day \(day): \(theme)"
        )
    }

    private func summerContent(day: Int, theme: String) -> (String, String, String, String, String) {
        let scriptures: [(text: String, ref: String)] = [
            ("The heavens declare the glory of God; the skies proclaim the work of his hands.", "Psalm 19:1"),
            ("He makes me lie down in green pastures, he leads me beside quiet waters, he refreshes my soul.", "Psalm 23:2-3"),
            ("Be still, and know that I am God.", "Psalm 46:10"),
            ("Remember the Sabbath day by keeping it holy.", "Exodus 20:8"),
            ("I will sing to the Lord all my life; I will sing praise to my God as long as I live.", "Psalm 104:33"),
            ("The Lord your God is with you, the Mighty Warrior who saves. He will take great delight in you; in his love he will no longer rebuke you, but will rejoice over you with singing.", "Zephaniah 3:17"),
            ("He has made everything beautiful in its time.", "Ecclesiastes 3:11"),
            ("The Lord is my shepherd, I lack nothing.", "Psalm 23:1"),
            ("It is for freedom that Christ has set us free. Stand firm, then, and do not let yourselves be burdened again by a yoke of slavery.", "Galatians 5:1"),
            ("Go therefore and make disciples of all nations, baptizing them in the name of the Father and of the Son and of the Holy Spirit.", "Matthew 28:19"),
        ]

        let idx = (day - 1) % scriptures.count
        let s = scriptures[idx]

        return (
            s.text,
            s.ref,
            "Summer is a gift — longer days, warmer light, a pace that invites us to slow down. Today's theme of \(theme.lowercased()) reminds us that God didn't design us for constant hustle. He built rest, wonder, and delight into the fabric of creation. Take a moment today to step outside and notice His handiwork.",
            "Creator God, thank You for this season of warmth and light. Open my eyes to see Your glory in creation. Teach me the rhythm of \(theme.lowercased()). Let this summer be a season of deep spiritual growth. Amen.",
            "Summer Day \(day): \(theme)"
        )
    }

    private func springContent(day: Int, theme: String) -> (String, String, String, String, String) {
        let scriptures: [(text: String, ref: String)] = [
            ("I am the vine; you are the branches. If you remain in me and I in you, you will bear much fruit; apart from me you can do nothing.", "John 15:5"),
            ("I will put my Spirit in you and you will live, and I will settle you in your own land. Then you will know that I the Lord have spoken, and I have done it, declares the Lord.", "Ezekiel 37:14"),
            ("And we all, who with unveiled faces contemplate the Lord's glory, are being transformed into his image with ever-increasing glory, which comes from the Lord, who is the Spirit.", "2 Corinthians 3:18"),
            ("He who was seated on the throne said, I am making everything new!", "Revelation 21:5"),
            ("But the fruit of the Spirit is love, joy, peace, forbearance, kindness, goodness, faithfulness, gentleness and self-control.", "Galatians 5:22-23"),
            ("Whoever believes in me, as Scripture has said, rivers of living water will flow from within them.", "John 7:38"),
            ("Do not conform to the pattern of this world, but be transformed by the renewing of your mind.", "Romans 12:2"),
            ("He cuts off every branch in me that bears no fruit, while every branch that does bear fruit he prunes so that it will be even more fruitful.", "John 15:2"),
            ("Not by might nor by power, but by my Spirit, says the Lord Almighty.", "Zechariah 4:6"),
            ("I will give you a new heart and put a new spirit in you; I will remove from you your heart of stone and give you a heart of flesh.", "Ezekiel 36:26"),
        ]

        let idx = (day - 1) % scriptures.count
        let s = scriptures[idx]

        return (
            s.text,
            s.ref,
            "Spring is God's annual sermon on resurrection. Dead branches burst with blossoms. Frozen ground gives way to green. Today's theme of \(theme.lowercased()) mirrors what God wants to do in your spirit — not just improvement, but genuine transformation. The same power that raised Jesus from the dead is alive in you.",
            "Holy Spirit, breathe new life into every dry and dormant area of my soul. I welcome Your transforming work. Produce in me the fruit of \(theme.lowercased()). Like the earth in spring, let new growth burst forth from every place You touch. Amen.",
            "Spring Day \(day): \(theme)"
        )
    }
}
