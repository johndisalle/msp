import Foundation

class DevotionalService: ObservableObject {
    @Published var todaysDevotional: Devotional?
    @Published var completions: [DevotionalCompletion] = []

    private let completionsKey = "devotional_completions"
    private let lastDevotionalDateKey = "last_devotional_date"

    init() {
        loadCompletions()
        loadTodaysDevotional()
    }

    // MARK: - Daily Devotional

    func loadTodaysDevotional() {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let cycleDay = (dayOfYear - 1) % devotionals.count
        todaysDevotional = devotionals[cycleDay]
    }

    func markComplete(devotionalId: UUID, didPray: Bool, note: String? = nil) {
        let completion = DevotionalCompletion(
            devotionalId: devotionalId,
            didPray: didPray,
            personalNote: note
        )
        completions.append(completion)
        saveCompletions()
    }

    func isCompletedToday() -> Bool {
        let calendar = Calendar.current
        return completions.contains { calendar.isDateInToday($0.date) }
    }

    func devotionalStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()

        while true {
            let hasCompletion = completions.contains {
                calendar.isDate($0.date, inSameDayAs: checkDate)
            }
            if hasCompletion {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return streak
    }

    // MARK: - Persistence

    private func saveCompletions() {
        if let data = try? JSONEncoder().encode(completions) {
            UserDefaults.standard.set(data, forKey: completionsKey)
        }
    }

    private func loadCompletions() {
        if let data = UserDefaults.standard.data(forKey: completionsKey),
           let items = try? JSONDecoder().decode([DevotionalCompletion].self, from: data) {
            completions = items
        }
    }

    // MARK: - Curated Devotionals

    let devotionals: [Devotional] = [
        Devotional(
            title: "Firstfruits of Faith",
            verse: "Honor the LORD with your wealth, with the firstfruits of all your crops; then your barns will be filled to overflowing, and your vats will brim over with new wine.",
            verseReference: "Proverbs 3:9-10",
            reflection: "God asks for our first, not our leftovers. When we give first—before bills, before wants—we declare that He is our provider. Tithing isn't about math; it's about trust.",
            prayerPrompt: "Lord, help me trust You with my finances. Give me the courage to put You first in my giving, knowing You will provide for all my needs.",
            category: .tithing,
            dayOfCycle: 1
        ),
        Devotional(
            title: "The Storehouse Promise",
            verse: "Bring the whole tithe into the storehouse, that there may be food in my house. Test me in this, says the LORD Almighty, and see if I will not throw open the floodgates of heaven and pour out so much blessing that there will not be room enough to store it.",
            verseReference: "Malachi 3:10",
            reflection: "This is the only place in Scripture where God invites us to test Him. He's so confident in His generosity that He dares us to try. What would it look like to take God at His word this month?",
            prayerPrompt: "Father, I accept Your challenge. I will bring my whole tithe and trust You to open the floodgates. Help my unbelief where I struggle to let go.",
            category: .tithing,
            dayOfCycle: 2
        ),
        Devotional(
            title: "Cheerful, Not Grudging",
            verse: "Each of you should give what you have decided in your heart to give, not reluctantly or under compulsion, for God loves a cheerful giver.",
            verseReference: "2 Corinthians 9:7",
            reflection: "Giving should never feel like a tax. It's an act of worship—a joyful response to a generous God. If giving feels heavy, pause and remember all He's already given you.",
            prayerPrompt: "Transform my heart, Lord, from reluctant to rejoicing. Let every gift I give be an overflow of gratitude for Your goodness in my life.",
            category: .generosity,
            dayOfCycle: 3
        ),
        Devotional(
            title: "Free from Debt's Chains",
            verse: "The rich rule over the poor, and the borrower is slave to the lender.",
            verseReference: "Proverbs 22:7",
            reflection: "Debt isn't just a financial burden—it limits our freedom to give, serve, and follow God's calling. Every payment toward freedom is a step toward the life God designed for you.",
            prayerPrompt: "God, give me wisdom and discipline to break free from debt. Help me see each payment as progress toward the freedom You desire for me.",
            category: .debt,
            dayOfCycle: 4
        ),
        Devotional(
            title: "The Faithful Steward",
            verse: "Whoever can be trusted with very little can also be trusted with much, and whoever is dishonest with very little will also be dishonest with much.",
            verseReference: "Luke 16:10",
            reflection: "Stewardship isn't about the size of your income—it's about faithfulness with whatever you have. God watches how we manage $100 before entrusting us with $10,000.",
            prayerPrompt: "Lord, make me faithful with what I have today. Whether it's little or much, I want to manage it in a way that honors You.",
            category: .stewardship,
            dayOfCycle: 5
        ),
        Devotional(
            title: "Content in Every Season",
            verse: "I know what it is to be in need, and I know what it is to have plenty. I have learned the secret of being content in any and every situation.",
            verseReference: "Philippians 4:12",
            reflection: "Contentment isn't about having enough—it's about knowing the One who is enough. When we find our security in Christ, money becomes a tool, not a source of anxiety.",
            prayerPrompt: "Jesus, teach me the secret of contentment. Free me from comparison and the endless desire for more. You are enough.",
            category: .contentment,
            dayOfCycle: 6
        ),
        Devotional(
            title: "God Will Provide",
            verse: "And my God will meet all your needs according to the riches of his glory in Christ Jesus.",
            verseReference: "Philippians 4:19",
            reflection: "This isn't a promise of luxury—it's a promise of provision. The same God who fed Israel in the wilderness and multiplied loaves and fish is watching over your finances today.",
            prayerPrompt: "Father, I release my financial anxiety to You. I trust that You see my needs and will provide. Help me to be generous even when it feels risky.",
            category: .provision,
            dayOfCycle: 7
        ),
    ]
}
