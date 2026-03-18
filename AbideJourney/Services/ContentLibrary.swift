import Foundation

/// Provides devotional content for journey days
final class ContentLibrary {
    static let shared = ContentLibrary()

    private init() {}

    struct DayContent {
        let scriptureReference: String
        let scriptureText: String
        let devotionalTitle: String
        let devotionalText: String
        let reflectionPrompt: String
        let actionSteps: [String]
    }

    func content(for theme: JourneyTheme, area: DiscipleshipArea, dayInArea: Int) -> DayContent {
        let scriptures = scriptureBank(for: theme, area: area)
        let index = (dayInArea - 1) % scriptures.count

        return scriptures[index]
    }

    // MARK: - Scripture & Content Bank

    private func scriptureBank(for theme: JourneyTheme, area: DiscipleshipArea) -> [DayContent] {
        // Core content organized by theme with cross-cutting discipleship areas
        switch (theme, area) {
        case (.knowingGod, .scripture):
            return [
                DayContent(
                    scriptureReference: "Psalm 119:105",
                    scriptureText: "Your word is a lamp for my feet, a light on my path.",
                    devotionalTitle: "A Light for the Journey",
                    devotionalText: "God's Word isn't just ancient text—it's a living guide that illuminates every step you take. When the path ahead seems dark or uncertain, Scripture provides clarity and direction. Today, consider how God's Word has guided a specific decision or moment in your life. The psalmist didn't say it lights the whole road—just the next step. That's enough. Trust the lamp He's given you and take the next step forward.",
                    reflectionPrompt: "When was the last time a Bible verse directly guided a decision you made?",
                    actionSteps: ["Read Psalm 119:97-112 slowly, underlining phrases that stand out", "Choose one verse to memorize this week"]
                ),
                DayContent(
                    scriptureReference: "2 Timothy 3:16-17",
                    scriptureText: "All Scripture is God-breathed and is useful for teaching, rebuking, correcting and training in righteousness, so that the servant of God may be thoroughly equipped for every good work.",
                    devotionalTitle: "God-Breathed Words",
                    devotionalText: "Imagine the Creator of the universe breathing life into words specifically for you. That's what Scripture is—not merely human wisdom, but divine revelation. Paul reminds Timothy that the Bible serves multiple purposes: it teaches us truth, reveals where we've gone wrong, shows us how to get back on track, and trains us to live God's way. Every page is practical, purposeful, and personal.",
                    reflectionPrompt: "Which purpose of Scripture (teaching, rebuking, correcting, training) do you need most right now?",
                    actionSteps: ["Identify one area where you need God's correction or training", "Share what you're learning with a friend or family member"]
                ),
                DayContent(
                    scriptureReference: "Hebrews 4:12",
                    scriptureText: "For the word of God is alive and active. Sharper than any double-edged sword, it penetrates even to dividing soul and spirit, joints and marrow; it judges the thoughts and attitudes of the heart.",
                    devotionalTitle: "The Living Word",
                    devotionalText: "The Bible is not a dusty relic—it's alive. It has the power to reach into the deepest parts of who you are and bring both conviction and healing. When you read Scripture and feel a stirring in your heart, that's the Holy Spirit using the Word to shape you. Don't shy away from that discomfort. It's the surgical precision of a loving God who wants to make you whole.",
                    reflectionPrompt: "Has a passage of Scripture ever convicted you deeply? What happened next?",
                    actionSteps: ["Spend 10 minutes in silent reading, asking God to speak through His Word", "Write down any thoughts or feelings that arise during your reading"]
                )
            ]

        case (.knowingGod, .prayer):
            return [
                DayContent(
                    scriptureReference: "Jeremiah 29:12-13",
                    scriptureText: "Then you will call on me and come and pray to me, and I will listen to you. You will seek me and find me when you seek me with all your heart.",
                    devotionalTitle: "He Hears You",
                    devotionalText: "Prayer isn't shouting into the void. God makes an extraordinary promise here: when you seek Him wholeheartedly, you will find Him. Not might. Will. The God of the universe bends His ear to hear your whispered prayers. Whether you're eloquent or stumbling over words, He's listening. Today, come to Him not with a performance, but with your whole heart.",
                    reflectionPrompt: "What would change if you truly believed God hears every prayer?",
                    actionSteps: ["Set a 5-minute prayer timer and talk to God honestly about your day", "Write a one-sentence prayer you can return to throughout the day"]
                ),
                DayContent(
                    scriptureReference: "Philippians 4:6-7",
                    scriptureText: "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God. And the peace of God, which transcends all understanding, will guard your hearts and your minds in Christ Jesus.",
                    devotionalTitle: "Trading Anxiety for Peace",
                    devotionalText: "Paul doesn't say 'don't worry about the big things.' He says don't be anxious about anything. That's a tall order—but he pairs it with a powerful strategy: prayer with thanksgiving. When we bring our worries to God and simultaneously thank Him for His faithfulness, something supernatural happens. Peace—the kind that doesn't make logical sense—settles over our hearts like a guard standing watch.",
                    reflectionPrompt: "What anxiety are you carrying that you haven't fully given to God?",
                    actionSteps: ["List three worries, then write a prayer of thanksgiving next to each one", "Practice the 'prayer breath': inhale saying 'God,' exhale saying 'I trust You'"]
                )
            ]

        case (.findingPeace, .prayer):
            return [
                DayContent(
                    scriptureReference: "Psalm 46:10",
                    scriptureText: "He says, 'Be still, and know that I am God; I will be exalted among the nations, I will be exalted in the earth.'",
                    devotionalTitle: "The Power of Stillness",
                    devotionalText: "In a world that never stops moving, God's command to 'be still' feels almost countercultural. But this isn't passive—it's an active choice to stop striving and trust that God is in control. Stillness before God isn't emptying your mind; it's filling it with the truth of who He is. Today, practice the radical act of doing nothing but resting in His presence.",
                    reflectionPrompt: "What makes it hardest for you to be still before God?",
                    actionSteps: ["Sit in silence for 3 minutes, focusing on the phrase 'You are God'", "Identify one thing you're trying to control and consciously release it to God"]
                ),
                DayContent(
                    scriptureReference: "John 14:27",
                    scriptureText: "Peace I leave with you; my peace I give you. I do not give to you as the world gives. Do not let your hearts be troubled and do not be afraid.",
                    devotionalTitle: "A Different Kind of Peace",
                    devotionalText: "The world's peace is fragile—dependent on circumstances, health, finances, relationships. Jesus offers something radically different: a peace that persists even when everything around you is falling apart. This peace isn't the absence of trouble; it's the presence of God in the midst of trouble. Jesus spoke these words knowing the cross was hours away. If He could offer peace then, He can give it to you now.",
                    reflectionPrompt: "How is Jesus' peace different from what the world offers you?",
                    actionSteps: ["When you feel anxious today, pause and say 'Jesus, give me Your peace'", "Text someone who might need encouragement using John 14:27"]
                )
            ]

        case (.obeyingGod, .obedience):
            return [
                DayContent(
                    scriptureReference: "James 1:22",
                    scriptureText: "Do not merely listen to the word, and so deceive yourselves. Do what it says.",
                    devotionalTitle: "Beyond Hearing",
                    devotionalText: "It's possible to fill notebooks with sermon notes, memorize chapters of the Bible, and still miss the point entirely. James cuts through religious pretense with a simple challenge: do what it says. Knowledge of God's Word without application is self-deception. True discipleship is measured not by what we know, but by how we live. Today, pick one thing you know God is asking of you—and do it.",
                    reflectionPrompt: "What is one thing you know God wants you to do that you've been putting off?",
                    actionSteps: ["Identify one specific command from Scripture and obey it today", "Ask a trusted friend: 'Is there an area where my actions don't match my beliefs?'"]
                ),
                DayContent(
                    scriptureReference: "John 14:15",
                    scriptureText: "If you love me, keep my commands.",
                    devotionalTitle: "Love in Action",
                    devotionalText: "Jesus draws a straight line between love and obedience. This isn't about earning God's favor through rule-following—it's about love expressing itself through action. When you love someone, you naturally want to honor them. Obedience to God flows from a heart that loves Him, not from fear or obligation. Today, let your obedience be an act of love, not a burden to bear.",
                    reflectionPrompt: "Does your obedience to God feel more like love or obligation? Why?",
                    actionSteps: ["Choose one of Jesus' commands (forgive, serve, love) and practice it intentionally today", "Confess a specific area of disobedience to God in prayer"]
                )
            ]

        case (.sharingFaith, .evangelism):
            return [
                DayContent(
                    scriptureReference: "1 Peter 3:15",
                    scriptureText: "But in your hearts revere Christ as Lord. Always be prepared to give an answer to everyone who asks you to give the reason for the hope that you have. But do this with gentleness and respect.",
                    devotionalTitle: "Ready to Share",
                    devotionalText: "Sharing your faith doesn't require a theology degree or a perfect life story. Peter says to simply be ready to explain your hope—with gentleness and respect. The most powerful testimony is often the simplest: 'Here's what God has done in my life.' People aren't looking for perfect arguments; they're looking for authentic hope. You have that. Be ready to share it.",
                    reflectionPrompt: "If someone asked you today why you have hope, what would you say?",
                    actionSteps: ["Write out your faith story in 3 sentences: before, encounter, after", "Pray for one person you know who doesn't know Jesus"]
                )
            ]

        case (.bearingFruit, .service):
            return [
                DayContent(
                    scriptureReference: "Galatians 5:22-23",
                    scriptureText: "But the fruit of the Spirit is love, joy, peace, forbearance, kindness, goodness, faithfulness, gentleness and self-control. Against such things there is no law.",
                    devotionalTitle: "The Fruit Test",
                    devotionalText: "You can't manufacture spiritual fruit through willpower any more than a tree can force itself to bloom. Fruit is the natural result of being connected to the vine—to Jesus. When you abide in Him, these qualities begin to grow organically in your life. Today, rather than trying harder to be kind or patient, focus on drawing closer to Jesus. The fruit will follow the abiding.",
                    reflectionPrompt: "Which fruit of the Spirit is most evident in your life? Which is least?",
                    actionSteps: ["Pick the fruit you struggle with most and ask God specifically to grow it in you", "Do one act of unexpected kindness for someone today"]
                )
            ]

        default:
            return defaultContent(for: area)
        }
    }

    private func defaultContent(for area: DiscipleshipArea) -> [DayContent] {
        switch area {
        case .prayer:
            return [
                DayContent(
                    scriptureReference: "1 Thessalonians 5:16-18",
                    scriptureText: "Rejoice always, pray continually, give thanks in all circumstances; for this is God's will for you in Christ Jesus.",
                    devotionalTitle: "Pray Without Ceasing",
                    devotionalText: "Continual prayer doesn't mean spending every moment on your knees. It means maintaining an ongoing conversation with God throughout your day—thanking Him in the good moments, asking for help in the hard ones, and simply being aware of His presence. Today, try turning every idle moment into a prayer moment: waiting in line, driving, before meals. Let prayer become as natural as breathing.",
                    reflectionPrompt: "What would your day look like if you maintained an ongoing conversation with God?",
                    actionSteps: ["Set three phone reminders to pause and pray for 1 minute each", "End your day by listing 3 things you're thankful for"]
                )
            ]
        case .scripture:
            return [
                DayContent(
                    scriptureReference: "Joshua 1:8",
                    scriptureText: "Keep this Book of the Law always on your lips; meditate on it day and night, so that you may be careful to do everything written in it. Then you will be prosperous and successful.",
                    devotionalTitle: "Meditate Day and Night",
                    devotionalText: "Biblical meditation isn't emptying your mind—it's filling it with God's truth. Joshua was about to lead an entire nation into unknown territory. God's strategy for his success? Soak in the Word. When Scripture saturates your thinking, it shapes your decisions, your reactions, and your character. Success in God's kingdom starts with a mind anchored in His Word.",
                    reflectionPrompt: "How might meditating on Scripture change the way you approach tomorrow's challenges?",
                    actionSteps: ["Choose one verse and read it 5 times slowly, emphasizing a different word each time", "Write the verse on a sticky note and place it where you'll see it throughout the day"]
                )
            ]
        case .obedience:
            return [
                DayContent(
                    scriptureReference: "Matthew 7:24-25",
                    scriptureText: "Therefore everyone who hears these words of mine and puts them into practice is like a wise man who built his house on the rock. The rain came down, the streams rose, and the winds blew and beat against that house; yet it did not fall, because it had its foundation on the rock.",
                    devotionalTitle: "Built on the Rock",
                    devotionalText: "Jesus tells two stories with identical storms but different outcomes. The difference? Not knowledge, but obedience. Both builders heard the words—only one acted on them. The storms of life will come regardless. The question isn't whether you'll face trials, but whether your foundation will hold. Every act of obedience is another stone in your foundation. Build wisely today.",
                    reflectionPrompt: "Where in your life do you feel your foundation is strong? Where does it feel shaky?",
                    actionSteps: ["Identify one 'storm' you're facing and find a Scripture that speaks to it", "Take one concrete step of obedience you've been postponing"]
                )
            ]
        case .worship:
            return [
                DayContent(
                    scriptureReference: "Psalm 100:1-2",
                    scriptureText: "Shout for joy to the Lord, all the earth. Worship the Lord with gladness; come before him with joyful songs.",
                    devotionalTitle: "Worship with Gladness",
                    devotionalText: "Worship isn't reserved for Sunday mornings or perfectly tuned voices. The psalmist invites all the earth—every person, in every situation—to come before God with joy. Worship is a posture of the heart that recognizes God's goodness and responds with gratitude. Whether you sing, whisper, dance, or simply sit in awe, let your heart overflow with praise today.",
                    reflectionPrompt: "When do you feel most connected to God in worship?",
                    actionSteps: ["Listen to a worship song and sing along, even if imperfectly", "Take a walk and thank God for 10 specific things you see"]
                )
            ]
        case .community:
            return [
                DayContent(
                    scriptureReference: "Hebrews 10:24-25",
                    scriptureText: "And let us consider how we may spur one another on toward love and good deeds, not giving up meeting together, as some are in the habit of doing, but encouraging one another—and all the more as you see the Day approaching.",
                    devotionalTitle: "Better Together",
                    devotionalText: "Faith was never meant to be a solo journey. God designed us to grow in community—sharpening, encouraging, and carrying one another through life's ups and downs. The writer of Hebrews urges us not to abandon gathering together, because isolation is where faith often withers. You need others, and they need you. Reach out today.",
                    reflectionPrompt: "Who in your life encourages your faith the most? Have you told them?",
                    actionSteps: ["Send an encouraging text to a fellow believer today", "Make plans to connect with a faith community this week"]
                )
            ]
        case .evangelism:
            return [
                DayContent(
                    scriptureReference: "Matthew 28:19-20",
                    scriptureText: "Therefore go and make disciples of all nations, baptizing them in the name of the Father and of the Son and of the Holy Spirit, and teaching them to obey everything I have commanded you.",
                    devotionalTitle: "The Great Commission",
                    devotionalText: "Jesus' final command wasn't to build buildings or programs—it was to make disciples. This isn't reserved for pastors and missionaries. Every believer is called to share the good news and help others grow. Discipleship starts with one conversation, one act of love, one invitation. You don't need all the answers. You just need to be willing to share what God has done for you.",
                    reflectionPrompt: "Who is one person in your life who might be open to hearing about your faith?",
                    actionSteps: ["Pray specifically for an opportunity to share your faith this week", "Invite someone to church, a Bible study, or simply to coffee"]
                )
            ]
        case .service:
            return [
                DayContent(
                    scriptureReference: "Mark 10:45",
                    scriptureText: "For even the Son of Man did not come to be served, but to serve, and to give his life as a ransom for many.",
                    devotionalTitle: "The Servant King",
                    devotionalText: "Jesus—King of Kings, Creator of the universe—chose the path of service. If the Son of God washed feet and served meals, how much more should we? Service isn't beneath us; it's the very heart of Christlikeness. When you serve others, you reflect the character of Jesus to a watching world. Look for opportunities today to put someone else's needs before your own.",
                    reflectionPrompt: "What does serving others look like in your daily life?",
                    actionSteps: ["Do one act of service for someone without being asked", "Volunteer for something at your church or in your community this week"]
                )
            ]
        }
    }
}
