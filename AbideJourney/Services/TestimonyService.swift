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

    // Seed testimonies (simulating approved/featured content)
    private let seedTestimonies: [Testimony] = [
        Testimony(
            authorName: "Sarah M.",
            journeyTheme: "Overcoming Anxiety",
            category: .anxiety,
            title: "From Panic Attacks to Peace",
            story: "I started this journey having panic attacks every single day. I couldn't sleep, couldn't focus at work, couldn't be present with my kids. By Day 10, the breathing exercises and daily scripture started to rewire my thinking. By Day 30, I realized I hadn't had a panic attack in two weeks. God used this app to teach me that His peace isn't the absence of storms — it's His presence in them. I still have hard days, but now I have tools and a God who meets me in them.",
            dayCount: 40
        ),
        Testimony(
            authorName: "Marcus & Denise T.",
            journeyTheme: "Healing Relationships",
            category: .marriage,
            title: "We Almost Gave Up",
            story: "My wife and I were two weeks from signing divorce papers when a friend suggested we try a couples journey together. We almost didn't. But something about doing the same devotional every day and having those reflection prompts forced us to actually talk — really talk — for the first time in years. We cried together on Day 7. We prayed together on Day 14 for the first time in our marriage. We renewed our vows on Day 40. God saved our marriage through 40 days of showing up.",
            dayCount: 40
        ),
        Testimony(
            authorName: "James R.",
            journeyTheme: "Knowing God",
            category: .faith,
            title: "I Was an Atheist for 15 Years",
            story: "A coworker challenged me to try this app for 40 days. I said yes just to prove him wrong. But somewhere around Day 12, the scriptures started making sense in a way they never had in church growing up. The journal prompts made me honest with myself for the first time. By Day 25, I was praying — actually praying — and meaning it. I gave my life to Christ on Day 33, alone in my apartment, tears streaming down my face. This app didn't convert me. God did. But this app put me in the room with Him.",
            dayCount: 40
        ),
        Testimony(
            authorName: "Priya K.",
            journeyTheme: "Walking Through Grief",
            category: .grief,
            title: "After Losing My Mom",
            story: "I lost my mother to cancer and I was angry at God. A friend sent me a gift journey and I almost deleted it. But I opened it one sleepless night at 3am. The devotional that day was about how Jesus wept at Lazarus's tomb — even though He knew He was about to raise him. That broke me open. God wasn't asking me not to grieve. He was grieving with me. I completed all 40 days and while the pain hasn't disappeared, I found a God who holds me in it.",
            dayCount: 40
        ),
        Testimony(
            authorName: "David L.",
            journeyTheme: "Spiritual Growth",
            category: .purpose,
            title: "From Sunday Christian to Everyday Disciple",
            story: "I'd been going to church for 20 years but my faith felt hollow. I was going through the motions. This app challenged me to actually DO something with my faith every single day. The action steps were small but they changed everything — praying for a stranger, texting encouragement to a friend, memorizing scripture on my commute. 40 days turned a passive faith into an active one. I'm now leading a small group at my church for the first time.",
            dayCount: 40
        ),
        Testimony(
            authorName: "Leah W.",
            journeyTheme: "Overcoming Anxiety",
            category: .healing,
            title: "God Healed What Medicine Couldn't",
            story: "I'm not against medicine — I still take mine. But the anxiety that medicine managed, God actually healed. The daily breathing exercises with scripture became my anchor. The prayer wall became my lifeline. I wrote down every anxious thought and watched God answer prayer after prayer. Some He answered with 'yes,' some with 'wait,' but none with silence. I am not the same person I was 40 days ago.",
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
