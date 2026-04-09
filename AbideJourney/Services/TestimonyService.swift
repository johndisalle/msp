import SwiftUI

// MARK: - Testimony Model

struct Testimony: Identifiable, Codable {
    let id: UUID
    let authorName: String
    let journeyTheme: String
    let category: TestimonyCategory
    let title: String
    let story: String
    let dayCount: Int
    let dateSubmitted: Date
    var isApproved: Bool
    var isFeatured: Bool
    var prayerCount: Int

    init(authorName: String, journeyTheme: String, category: TestimonyCategory, title: String, story: String, dayCount: Int) {
        self.id = UUID()
        self.authorName = authorName
        self.journeyTheme = journeyTheme
        self.category = category
        self.title = title
        self.story = story
        self.dayCount = dayCount
        self.dateSubmitted = Date()
        self.isApproved = false
        self.isFeatured = false
        self.prayerCount = 0
    }
}

enum TestimonyCategory: String, Codable, CaseIterable {
    case anxiety = "Anxiety & Peace"
    case marriage = "Marriage & Relationships"
    case faith = "Faith & Doubt"
    case healing = "Healing & Restoration"
    case purpose = "Purpose & Calling"
    case addiction = "Freedom & Breakthrough"
    case grief = "Grief & Comfort"
    case gratitude = "Gratitude & Joy"

    var icon: String {
        switch self {
        case .anxiety: return "heart.circle.fill"
        case .marriage: return "heart.fill"
        case .faith: return "flame.fill"
        case .healing: return "cross.circle.fill"
        case .purpose: return "star.fill"
        case .addiction: return "bolt.circle.fill"
        case .grief: return "drop.fill"
        case .gratitude: return "sun.max.fill"
        }
    }

    var color: Color {
        switch self {
        case .anxiety: return .blue
        case .marriage: return .pink
        case .faith: return .orange
        case .healing: return .green
        case .purpose: return .purple
        case .addiction: return .red
        case .grief: return .indigo
        case .gratitude: return .yellow
        }
    }
}

// MARK: - Testimony Service

final class TestimonyService {
    static let shared = TestimonyService()
    private let key = "saved_testimonies"
    private let prayedKey = "prayed_testimony_ids"
    private init() {}

    // Seed testimonies — real-style Christian testimonies about encountering Jesus
    private let seedTestimonies: [Testimony] = [
        Testimony(
            authorName: "Marcus T.",
            journeyTheme: "Finding Faith",
            category: .faith,
            title: "From the Streets to the Cross",
            story: "I grew up in a home where God was never mentioned. By 19 I was selling drugs, sleeping in my car, and thought my life was already over. One night a stranger at a gas station looked me dead in the eyes and said, 'Jesus loves you and He's not done with you yet.' I laughed it off. But I couldn't stop hearing those words. Two weeks later I walked into a church for the first time in my life. When the pastor gave the altar call, my legs moved before my brain could talk me out of it. I fell on my knees and wept like a child. That was three years ago. I'm sober, I'm employed, and I'm alive — because Jesus met me in a gas station parking lot.",
            dayCount: 40
        ),
        Testimony(
            authorName: "Priya K.",
            journeyTheme: "Knowing God",
            category: .faith,
            title: "A Hindu Girl Who Found Jesus",
            story: "I grew up Hindu in a devout family. I loved my culture, but there was always an emptiness I couldn't name. In college, a roommate invited me to a Bible study. I went out of curiosity, not belief. But when I read John 4 — Jesus talking to the Samaritan woman at the well — I started crying. Here was a God who pursued a woman everyone else rejected. Who saw her. Who offered her living water. I felt seen for the first time. It took me a year of quietly reading Scripture before I gave my life to Christ. My family struggled with it. Some still do. But I know the One who found me at my own well, and I'll never go back to being thirsty.",
            dayCount: 40
        ),
        Testimony(
            authorName: "James R.",
            journeyTheme: "Knowing God",
            category: .faith,
            title: "I Was an Atheist for 15 Years",
            story: "I was a proud atheist. I had all the arguments, all the rebuttals, all the intellectual armor. Then my daughter was born premature at 26 weeks. She was 1 pound, 12 ounces, and the doctors gave her a 30% chance. Standing over that incubator, all my arguments meant nothing. I didn't have a prayer to pray because I didn't believe in the One who hears them. But I prayed anyway. 'God, if You're real, save my little girl.' She's five now. She runs, she laughs, she drives me crazy in the best way. I can't explain it with science. I can only explain it with Jesus. He didn't just save my daughter. He saved me.",
            dayCount: 40
        ),
        Testimony(
            authorName: "Sarah M.",
            journeyTheme: "Freedom in Christ",
            category: .addiction,
            title: "He Broke Every Chain",
            story: "I was addicted to pills for seven years. I lost my nursing license, my apartment, and nearly my children. I checked into rehab four times and relapsed four times. The fifth time, a counselor who was a believer said something I'll never forget: 'You keep trying to save yourself. What if you let Someone else do it?' She handed me a Bible opened to Isaiah 61 — 'He has sent me to bind up the brokenhearted, to proclaim freedom for the captives.' I read it and something broke inside me. Not broke as in damaged — broke as in broke open. I surrendered my addiction to Jesus that night. It wasn't magic. Recovery was still hard. But for the first time, I wasn't fighting alone. I've been clean for two years. My kids are home. And I know who set me free.",
            dayCount: 40
        ),
        Testimony(
            authorName: "David & Michelle L.",
            journeyTheme: "Healing Relationships",
            category: .marriage,
            title: "God Rebuilt What We Destroyed",
            story: "Our marriage was over. Not legally — but in every way that mattered. Years of bitterness, unforgiveness, and silence had turned us into strangers sharing a house. We went to a marriage retreat as a last resort, mostly for the kids. On the second night, the pastor asked us to wash each other's feet like Jesus washed His disciples'. I looked at my wife — really looked at her — for the first time in years. We both broke down. In that moment, Jesus showed me that marriage isn't about being right. It's about laying down your life. We rededicated our marriage to Christ that weekend. It's been two years and we're more in love than the day we met, because now we love each other the way Jesus loves us.",
            dayCount: 40
        ),
        Testimony(
            authorName: "Leah W.",
            journeyTheme: "Walking Through Grief",
            category: .grief,
            title: "He Carried Me Through the Valley",
            story: "When my son passed away in a car accident at 17, I wanted to die too. I screamed at God. I told Him I hated Him. I stopped going to church. For six months I lived in complete darkness. Then one morning I found my son's Bible under his bed. It fell open to a page he had underlined: 'The Lord is close to the brokenhearted and saves those who are crushed in spirit' — Psalm 34:18. In his handwriting in the margin he had written: 'This is true, Mom.' I collapsed on his bedroom floor and cried out to Jesus for the first time since the funeral. He met me there. He didn't explain why. He didn't give me answers. He just held me. And He hasn't let go since. My son knew Jesus. And because of that, I know I'll see him again.",
            dayCount: 40
        ),
    ]

    func loadTestimonies() -> [Testimony] {
        var all = loadUserTestimonies()
        // Add seed testimonies that aren't duplicates
        let userIDs = Set(all.map { $0.id })
        let seeds = seedTestimonies.map { seed -> Testimony in
            var t = seed
            t.isApproved = true
            t.isFeatured = true
            t.prayerCount = Int.random(in: 24...340)
            return t
        }.filter { !userIDs.contains($0.id) }
        all.append(contentsOf: seeds)
        return all.sorted { $0.isFeatured && !$1.isFeatured }
    }

    func loadUserTestimonies() -> [Testimony] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([Testimony].self, from: data) else {
            return []
        }
        return items
    }

    func submitTestimony(_ testimony: Testimony) {
        var items = loadUserTestimonies()
        items.append(testimony)
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func prayForTestimony(id: UUID) {
        var prayed = prayedIDs
        prayed.insert(id.uuidString)
        UserDefaults.standard.set(Array(prayed), forKey: prayedKey)
    }

    func hasPrayed(for id: UUID) -> Bool {
        prayedIDs.contains(id.uuidString)
    }

    private var prayedIDs: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: prayedKey) ?? [])
    }
}
