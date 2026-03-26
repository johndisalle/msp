import Foundation

// MARK: - Extended Content Data
// Full 40-day devotional content organized by discipleship area.
// Each area has 6+ entries, and themes cycle through areas weekly,
// giving 40 unique days per journey.

extension ContentLibrary {

    // MARK: - Prayer Content (8 entries)

    static let prayerContent: [DayContent] = [
        DayContent(
            scriptureReference: "Jeremiah 29:12-13",
            scriptureText: "Then you will call on me and come and pray to me, and I will listen to you. You will seek me and find me when you seek me with all your heart.",
            devotionalTitle: "He Hears You",
            devotionalText: "Prayer isn't shouting into the void. God makes an extraordinary promise here: when you seek Him wholeheartedly, you will find Him. Not might. Will. The God of the universe bends His ear to hear your whispered prayers. Whether you're eloquent or stumbling over words, He's listening. Today, come to Him not with a performance, but with your whole heart.",
            prayerText: "Lord, I come to You today with my whole heart. Thank You for the promise that when I seek You, I will find You. Open my ears to hear Your voice and my heart to receive Your presence. I don't need perfect words — I just need You. Help me to trust that You are always listening, always near, and always faithful. In Jesus' name, amen.",
            reflectionPrompt: "What would change if you truly believed God hears every prayer?",
            actionSteps: ["Set a 5-minute prayer timer and talk to God honestly about your day", "Write a one-sentence prayer you can return to throughout the day"]
        ),
        DayContent(
            scriptureReference: "Philippians 4:6-7",
            scriptureText: "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God. And the peace of God, which transcends all understanding, will guard your hearts and your minds in Christ Jesus.",
            devotionalTitle: "Trading Anxiety for Peace",
            devotionalText: "Paul doesn't say 'don't worry about the big things.' He says don't be anxious about anything. That's a tall order—but he pairs it with a powerful strategy: prayer with thanksgiving. When we bring our worries to God and simultaneously thank Him for His faithfulness, something supernatural happens. Peace—the kind that doesn't make logical sense—settles over our hearts like a guard standing watch.",
            prayerText: "Father, I bring my worries to You right now — every anxious thought, every heavy burden. I choose thanksgiving over fear. Thank You for Your faithfulness in the past. Thank You for holding my future. I ask for Your peace — the kind that doesn't make sense but guards my heart and mind. Replace my anxiety with trust, and my fear with worship. In Jesus' name, amen.",
            reflectionPrompt: "What anxiety are you carrying that you haven't fully given to God?",
            actionSteps: ["List three worries, then write a prayer of thanksgiving next to each one", "Practice the 'prayer breath': inhale saying 'God,' exhale saying 'I trust You'"]
        ),
        DayContent(
            scriptureReference: "1 Thessalonians 5:16-18",
            scriptureText: "Rejoice always, pray continually, give thanks in all circumstances; for this is God's will for you in Christ Jesus.",
            devotionalTitle: "Pray Without Ceasing",
            devotionalText: "Continual prayer doesn't mean spending every moment on your knees. It means maintaining an ongoing conversation with God throughout your day—thanking Him in the good moments, asking for help in the hard ones, and simply being aware of His presence. Today, try turning every idle moment into a prayer moment: waiting in line, driving, before meals. Let prayer become as natural as breathing.",
            prayerText: "God, teach me to pray without ceasing — not as a burden, but as a joy. Help me see every moment as an invitation to talk with You. When I'm waiting, remind me to pray. When I'm grateful, help me praise. When I'm struggling, draw me close. Let my whole day become a conversation with You. I give You every moment — the ordinary and the extraordinary. In Jesus' name, amen.",
            reflectionPrompt: "What would your day look like if you maintained an ongoing conversation with God?",
            actionSteps: ["Set three phone reminders to pause and pray for 1 minute each", "End your day by listing 3 things you're thankful for"]
        ),
        DayContent(
            scriptureReference: "Psalm 46:10",
            scriptureText: "He says, 'Be still, and know that I am God; I will be exalted among the nations, I will be exalted in the earth.'",
            devotionalTitle: "The Power of Stillness",
            devotionalText: "In a world that never stops moving, God's command to 'be still' feels almost countercultural. But this isn't passive—it's an active choice to stop striving and trust that God is in control. Stillness before God isn't emptying your mind; it's filling it with the truth of who He is. Today, practice the radical act of doing nothing but resting in His presence.",
            prayerText: "Lord, quiet my restless heart. Still the noise around me and within me. I release my need to control, my need to fix, my need to understand everything. You are God, and I am not. In this stillness, I choose to trust You. Speak, Lord — I'm listening. Help me rest in the truth that You are in control of all things. In Jesus' name, amen.",
            reflectionPrompt: "What makes it hardest for you to be still before God?",
            actionSteps: ["Sit in silence for 3 minutes, focusing on the phrase 'You are God'", "Identify one thing you're trying to control and consciously release it to God"]
        ),
        DayContent(
            scriptureReference: "Matthew 6:9-13",
            scriptureText: "This, then, is how you should pray: 'Our Father in heaven, hallowed be your name, your kingdom come, your will be done, on earth as it is in heaven.'",
            devotionalTitle: "The Lord's Prayer as a Blueprint",
            devotionalText: "When the disciples asked Jesus how to pray, He didn't give them a formula—He gave them a framework. The Lord's Prayer teaches us the rhythm of prayer: start with worship ('hallowed be your name'), align with God's purposes ('your kingdom come'), bring your daily needs ('give us today'), seek forgiveness and extend it ('forgive us... as we forgive'), and ask for protection ('deliver us'). Today, use this prayer as a scaffold for your own conversation with God.",
            prayerText: "Our Father in heaven, holy is Your name. Let Your kingdom come and Your will be done in my life today — on earth as it is in heaven. Provide for my needs today, Lord. Forgive me where I have fallen short, and help me to forgive those who have hurt me. Lead me away from temptation and deliver me from evil. For Yours is the kingdom, the power, and the glory forever. Amen.",
            reflectionPrompt: "Which part of the Lord's Prayer resonates most with where you are right now?",
            actionSteps: ["Pray through the Lord's Prayer slowly, personalizing each line", "Write your own version of the Lord's Prayer in your own words"]
        ),
        DayContent(
            scriptureReference: "Romans 8:26-27",
            scriptureText: "In the same way, the Spirit helps us in our weakness. We do not know what we ought to pray for, but the Spirit himself intercedes for us through wordless groans.",
            devotionalTitle: "When Words Fail",
            devotionalText: "There are moments when pain is too deep, confusion too thick, or exhaustion too heavy for words. In those moments, the Holy Spirit steps in. He doesn't need your eloquence or your theology—He prays on your behalf with groans that words can't capture. If you feel unable to pray today, know this: you are still being prayed for. The Spirit knows exactly what you need, even when you don't.",
            prayerText: "Holy Spirit, I don't have the right words today — and that's okay. You know what I need even when I can't express it. Intercede for me with groans too deep for words. Carry what I cannot carry. Pray what I cannot pray. I surrender my weakness to You and trust that You are speaking on my behalf before the Father right now. Thank You for never leaving me alone. In Jesus' name, amen.",
            reflectionPrompt: "Have you ever been in a place where you couldn't find words to pray? What happened?",
            actionSteps: ["Spend 5 minutes in silent prayer, inviting the Spirit to pray through you", "Journal about a time God answered a prayer you didn't know how to articulate"]
        ),
        DayContent(
            scriptureReference: "James 5:16",
            scriptureText: "Therefore confess your sins to each other and pray for each other so that you may be healed. The prayer of a righteous person is powerful and effective.",
            devotionalTitle: "The Power of Shared Prayer",
            devotionalText: "Prayer was never meant to be entirely private. James connects confession, community prayer, and healing in a single verse. There's something powerful about letting another person carry your burden in prayer—and something transformative about praying for someone else. Vulnerability before God and others brings healing that solitude often can't. Today, take the brave step of asking someone to pray with you—or offering to pray for them.",
            prayerText: "Father, thank You for the gift of community and shared prayer. Give me the courage to be vulnerable — to let someone else carry this burden with me. I lift up those around me who are hurting. Bring healing where there is brokenness. Strengthen the bonds of fellowship among Your people. Help me to be both honest in my needs and faithful in praying for others. In Jesus' name, amen.",
            reflectionPrompt: "Is there something you've been carrying alone that you could share with a trusted prayer partner?",
            actionSteps: ["Ask someone to pray for a specific need in your life", "Pray specifically for one person by name today"]
        ),
        DayContent(
            scriptureReference: "Psalm 62:8",
            scriptureText: "Trust in him at all times, you people; pour out your hearts to him, for God is our refuge.",
            devotionalTitle: "Pour It All Out",
            devotionalText: "God doesn't want your polished prayers—He wants your honest heart. The psalmist uses vivid language: pour out your hearts. Not carefully measure, not neatly arrange, but pour. Like tipping a cup upside down until nothing is left inside. God can handle your anger, your doubt, your confusion, your joy, your mess. He's your refuge, not your judge. Today, hold nothing back.",
            prayerText: "God, I pour out my heart to You right now — every fear, every frustration, every joy, every doubt. I hold nothing back. You are my refuge, my safe place. I don't need to perform or pretend with You. Receive all of me — the messy parts, the broken parts, the grateful parts. Thank You for being a God who can handle my honesty. I trust You with all of it. In Jesus' name, amen.",
            reflectionPrompt: "What have you been holding back from God in prayer?",
            actionSteps: ["Write an uncensored prayer to God—no editing, no filtering", "Set a timer for 10 minutes of unstructured, honest prayer"]
        ),
    ]

    // MARK: - Scripture Content (8 entries)

    static let scriptureContent: [DayContent] = [
        DayContent(
            scriptureReference: "Psalm 119:105",
            scriptureText: "Your word is a lamp for my feet, a light on my path.",
            devotionalTitle: "A Light for the Journey",
            devotionalText: "God's Word isn't just ancient text—it's a living guide that illuminates every step you take. When the path ahead seems dark or uncertain, Scripture provides clarity and direction. Today, consider how God's Word has guided a specific decision or moment in your life. The psalmist didn't say it lights the whole road—just the next step. That's enough. Trust the lamp He's given you and take the next step forward.",
            prayerText: "Lord, thank You for Your Word — a lamp to my feet and a light to my path. When I can't see what's ahead, help me trust the next step You've illuminated. Give me a hunger for Scripture and eyes to see the guidance You've placed within it. I don't need to see the whole road — just the next step with You. Lead me, Lord. In Jesus' name, amen.",
            reflectionPrompt: "When was the last time a Bible verse directly guided a decision you made?",
            actionSteps: ["Read Psalm 119:97-112 slowly, underlining phrases that stand out", "Choose one verse to memorize this week"]
        ),
        DayContent(
            scriptureReference: "2 Timothy 3:16-17",
            scriptureText: "All Scripture is God-breathed and is useful for teaching, rebuking, correcting and training in righteousness, so that the servant of God may be thoroughly equipped for every good work.",
            devotionalTitle: "God-Breathed Words",
            devotionalText: "Imagine the Creator of the universe breathing life into words specifically for you. That's what Scripture is—not merely human wisdom, but divine revelation. Paul reminds Timothy that the Bible serves multiple purposes: it teaches us truth, reveals where we've gone wrong, shows us how to get back on track, and trains us to live God's way. Every page is practical, purposeful, and personal.",
            prayerText: "Father, thank You for breathing life into Your Word. Use Scripture to teach me where I need wisdom, correct me where I've gone astray, and train me in the way I should go. I open my heart to receive whatever You want to show me today — even the parts that are uncomfortable. Equip me through Your Word to do every good work You've prepared for me. In Jesus' name, amen.",
            reflectionPrompt: "Which purpose of Scripture (teaching, rebuking, correcting, training) do you need most right now?",
            actionSteps: ["Identify one area where you need God's correction or training", "Share what you're learning with a friend or family member"]
        ),
        DayContent(
            scriptureReference: "Hebrews 4:12",
            scriptureText: "For the word of God is alive and active. Sharper than any double-edged sword, it penetrates even to dividing soul and spirit, joints and marrow; it judges the thoughts and attitudes of the heart.",
            devotionalTitle: "The Living Word",
            devotionalText: "The Bible is not a dusty relic—it's alive. It has the power to reach into the deepest parts of who you are and bring both conviction and healing. When you read Scripture and feel a stirring in your heart, that's the Holy Spirit using the Word to shape you. Don't shy away from that discomfort. It's the surgical precision of a loving God who wants to make you whole.",
            prayerText: "God, Your Word is alive and active — sharper than any sword. I invite You to search my heart today through Scripture. Reveal what needs healing, convict what needs changing, and confirm what is true. I'm not afraid of Your Word because I know it comes from a Father who loves me. Cut away anything that doesn't belong, and make me whole. In Jesus' name, amen.",
            reflectionPrompt: "Has a passage of Scripture ever convicted you deeply? What happened next?",
            actionSteps: ["Spend 10 minutes in silent reading, asking God to speak through His Word", "Write down any thoughts or feelings that arise during your reading"]
        ),
        DayContent(
            scriptureReference: "Joshua 1:8",
            scriptureText: "Keep this Book of the Law always on your lips; meditate on it day and night, so that you may be careful to do everything written in it. Then you will be prosperous and successful.",
            devotionalTitle: "Meditate Day and Night",
            devotionalText: "Biblical meditation isn't emptying your mind—it's filling it with God's truth. Joshua was about to lead an entire nation into unknown territory. God's strategy for his success? Soak in the Word. When Scripture saturates your thinking, it shapes your decisions, your reactions, and your character. Success in God's kingdom starts with a mind anchored in His Word.",
            prayerText: "Lord, help me to meditate on Your Word day and night — not as a chore, but as my strategy for life. Let Scripture saturate my thinking so deeply that it shapes my decisions, my reactions, and my character. As I face the unknown, anchor me in the truth of who You are. I choose to soak in Your Word and trust that it will bear fruit in my life. In Jesus' name, amen.",
            reflectionPrompt: "How might meditating on Scripture change the way you approach tomorrow's challenges?",
            actionSteps: ["Choose one verse and read it 5 times slowly, emphasizing a different word each time", "Write the verse on a sticky note and place it where you'll see it throughout the day"]
        ),
        DayContent(
            scriptureReference: "Isaiah 55:10-11",
            scriptureText: "As the rain and the snow come down from heaven, and do not return to it without watering the earth... so is my word that goes out from my mouth: It will not return to me empty, but will accomplish what I desire and achieve the purpose for which I sent it.",
            devotionalTitle: "Words That Never Fail",
            devotionalText: "God's Word always accomplishes its purpose. It never returns void. When you feel like your Bible reading isn't 'working' or you're not getting anything out of it, remember this promise. Every verse you read is doing something—even when you can't see it. Like rain soaking into soil before anything sprouts, God's Word is working beneath the surface of your life. Keep reading. Keep soaking. The harvest is coming.",
            prayerText: "Father, I trust that Your Word never returns void. Even when I can't see the results, I believe You are working beneath the surface of my life. Like rain soaking into dry ground, let Your truth sink deep into my heart. Give me patience to keep reading, keep seeking, and keep believing that the harvest is coming. Your promises never fail. In Jesus' name, amen.",
            reflectionPrompt: "Can you think of a time when a Scripture you read long ago suddenly became meaningful?",
            actionSteps: ["Read a chapter of Proverbs corresponding to today's date", "Listen to an audio Bible passage during a routine task today"]
        ),
        DayContent(
            scriptureReference: "Psalm 1:1-3",
            scriptureText: "Blessed is the one who does not walk in step with the wicked... but whose delight is in the law of the Lord, and who meditates on his law day and night. That person is like a tree planted by streams of water, which yields its fruit in season.",
            devotionalTitle: "Planted by the Water",
            devotionalText: "The psalmist paints a picture of two lives: one tossed about by the winds of culture, and one deeply rooted by streams of living water. The difference? Delighting in God's Word. Notice it doesn't say 'dutiful reading' but 'delight.' When Scripture moves from obligation to joy, you become like that tree—stable, fruitful, and refreshed. How do you get there? Start by asking God to give you a love for His Word.",
            prayerText: "Lord, I want to delight in Your Word — not read it out of obligation, but out of genuine love. Plant me by streams of living water. Give me roots that go deep into Your truth so that I can bear fruit in every season. Transform my Bible reading from duty into delight. Help me see Your Word as the gift it truly is. In Jesus' name, amen.",
            reflectionPrompt: "Does reading the Bible feel more like delight or duty right now? What could shift that?",
            actionSteps: ["Ask God to give you genuine delight in His Word before you read today", "Find a beautiful place—outside, a cozy corner—and read Scripture there"]
        ),
        DayContent(
            scriptureReference: "Matthew 4:4",
            scriptureText: "Jesus answered, 'It is written: Man shall not live on bread alone, but on every word that comes from the mouth of God.'",
            devotionalTitle: "Daily Bread",
            devotionalText: "Jesus, facing the ultimate temptation in the wilderness, reached for Scripture as His weapon and His sustenance. He compared God's Word to food—something essential for survival, not optional for comfort. Just as your body weakens without food, your spirit weakens without the Word. Today, treat Scripture not as a checkbox but as a meal. Come hungry. Feast on truth. Let it nourish you from the inside out.",
            prayerText: "Jesus, You said that we don't live on bread alone, but on every word from the mouth of God. I come to You hungry today — hungry for truth, hungry for direction, hungry for You. Feed me with Your Word. Let it nourish my spirit the way food nourishes my body. I choose Scripture over distraction, truth over noise, and Your voice over the world's. In Your name, amen.",
            reflectionPrompt: "How 'hungry' are you for God's Word right now? What feeds that hunger?",
            actionSteps: ["Before reading Scripture today, tell God you're hungry for His truth", "Replace 10 minutes of screen time today with Bible reading"]
        ),
        DayContent(
            scriptureReference: "Psalm 119:11",
            scriptureText: "I have hidden your word in my heart that I might not sin against you.",
            devotionalTitle: "Hidden in Your Heart",
            devotionalText: "Memorizing Scripture isn't about impressing others with your knowledge—it's about equipping your heart for battle. When temptation strikes, you don't always have time to open your Bible. But a verse hidden in your heart is instantly available—a shield, a sword, a reminder of who you are and whose you are. The psalmist understood that sin loses its power when truth occupies the space it wants to fill.",
            prayerText: "God, help me to hide Your Word in my heart — not just in my mind, but deep in the core of who I am. When temptation comes, let Your truth be my shield. When doubt whispers, let Your promises be louder. Write Your Word on my heart so that it becomes part of me — ready, available, and alive in every moment I need it. In Jesus' name, amen.",
            reflectionPrompt: "What verse would be most helpful for you to have memorized for your current struggles?",
            actionSteps: ["Choose one verse to memorize today—write it, say it, repeat it", "Set it as your phone lock screen or wallpaper"]
        ),
    ]

    // MARK: - Obedience Content (8 entries)

    static let obedienceContent: [DayContent] = [
        DayContent(
            scriptureReference: "James 1:22",
            scriptureText: "Do not merely listen to the word, and so deceive yourselves. Do what it says.",
            devotionalTitle: "Beyond Hearing",
            devotionalText: "It's possible to fill notebooks with sermon notes, memorize chapters of the Bible, and still miss the point entirely. James cuts through religious pretense with a simple challenge: do what it says. Knowledge of God's Word without application is self-deception. True discipleship is measured not by what we know, but by how we live. Today, pick one thing you know God is asking of you—and do it.",
            prayerText: "Lord, I don't want to just hear Your Word — I want to live it. Show me where my life doesn't match what I believe. Give me the courage to move from knowing to doing. I surrender my excuses and ask for the strength to obey today — not perfectly, but faithfully. Help me take the next right step. In Jesus' name, amen.",
            reflectionPrompt: "What is one thing you know God wants you to do that you've been putting off?",
            actionSteps: ["Identify one specific command from Scripture and obey it today", "Ask a trusted friend: 'Is there an area where my actions don't match my beliefs?'"]
        ),
        DayContent(
            scriptureReference: "John 14:15",
            scriptureText: "If you love me, keep my commands.",
            devotionalTitle: "Love in Action",
            devotionalText: "Jesus draws a straight line between love and obedience. This isn't about earning God's favor through rule-following—it's about love expressing itself through action. When you love someone, you naturally want to honor them. Obedience to God flows from a heart that loves Him, not from fear or obligation. Today, let your obedience be an act of love, not a burden to bear.",
            prayerText: "Jesus, I love You. Let my obedience flow from that love — not from guilt or fear, but from a heart that genuinely wants to honor You. Where I've held back, forgive me. Where I've gone my own way, redirect me. I want my actions to match my affection for You. Teach me that obedience is not a burden but a beautiful response to Your grace. In Your name, amen.",
            reflectionPrompt: "Does your obedience to God feel more like love or obligation? Why?",
            actionSteps: ["Choose one of Jesus' commands (forgive, serve, love) and practice it intentionally today", "Confess a specific area of disobedience to God in prayer"]
        ),
        DayContent(
            scriptureReference: "Matthew 7:24-25",
            scriptureText: "Therefore everyone who hears these words of mine and puts them into practice is like a wise man who built his house on the rock.",
            devotionalTitle: "Built on the Rock",
            devotionalText: "Jesus tells two stories with identical storms but different outcomes. The difference? Not knowledge, but obedience. Both builders heard the words—only one acted on them. The storms of life will come regardless. The question isn't whether you'll face trials, but whether your foundation will hold. Every act of obedience is another stone in your foundation. Build wisely today.",
            prayerText: "Father, I want to build my life on the rock of Your Word. Help me not just to hear Your truth but to put it into practice — especially when the storms come. Strengthen my foundation today with every act of obedience, no matter how small. I trust that what I build on You will stand. In Jesus' name, amen.",
            reflectionPrompt: "Where in your life do you feel your foundation is strong? Where does it feel shaky?",
            actionSteps: ["Identify one 'storm' you're facing and find a Scripture that speaks to it", "Take one concrete step of obedience you've been postponing"]
        ),
        DayContent(
            scriptureReference: "Luke 6:46",
            scriptureText: "Why do you call me, 'Lord, Lord,' and do not do what I say?",
            devotionalTitle: "Lord of Your Life",
            devotionalText: "Jesus asks a piercing question that cuts through all religious performance. Calling Him 'Lord' means He has authority over your life—your decisions, your relationships, your finances, your time. If we acknowledge His lordship with our lips but not our lives, we're living a contradiction. Today, examine the gap between what you say you believe and how you actually live. Invite Jesus to be Lord of those in-between spaces.",
            prayerText: "Lord Jesus, I don't just want to call You Lord with my lips — I want You to be Lord of my whole life. Show me the areas where I've been holding back control. I surrender my plans, my comfort, and my preferences to You. Be the authority over my decisions, my relationships, and my time. I choose Your way over my own. In Your name, amen.",
            reflectionPrompt: "In what area of your life is Jesus Lord in name but not in practice?",
            actionSteps: ["Identify one area where you need to surrender control to Jesus", "Make one decision today based solely on what you believe Jesus would want"]
        ),
        DayContent(
            scriptureReference: "1 Samuel 15:22",
            scriptureText: "Does the Lord delight in burnt offerings and sacrifices as much as in obeying the Lord? To obey is better than sacrifice, and to heed is better than the fat of rams.",
            devotionalTitle: "Obedience Over Sacrifice",
            devotionalText: "King Saul thought he could substitute religious activity for obedience—keeping the best sheep for a 'sacrifice' instead of destroying them as God commanded. Samuel's response cuts to the heart: God doesn't want your impressive offerings if you're ignoring His clear instructions. We can volunteer at church, give generously, and attend every service—but if we're avoiding the specific thing God is asking of us, we've missed the point.",
            prayerText: "God, I don't want to substitute busyness for obedience. Strip away any religious performance that hides from what You're actually asking of me. Give me ears to hear Your specific instruction and the courage to follow through — even when it costs me something. I choose obedience over sacrifice, because that is what You desire. In Jesus' name, amen.",
            reflectionPrompt: "Are there any 'sacrifices' you offer God while avoiding specific obedience He's asked of you?",
            actionSteps: ["Ask God: 'What specific thing are You asking me to do right now?'", "Write down the answer and take the first step toward it today"]
        ),
        DayContent(
            scriptureReference: "Deuteronomy 30:19-20",
            scriptureText: "I have set before you life and death, blessings and curses. Now choose life, so that you and your children may live and that you may love the Lord your God, listen to his voice, and hold fast to him.",
            devotionalTitle: "Choose Life",
            devotionalText: "Every day presents a series of choices—some obvious, some subtle. God lays out the options with stunning clarity: life or death, blessings or curses. Obedience leads to life; disobedience leads to destruction. This isn't about perfection—it's about direction. Which way are you facing? Today, in every small decision, choose the path of life. Choose love. Choose obedience. Choose God.",
            prayerText: "Father, today I choose life. In every decision — big and small — help me choose the path that leads to blessing, not destruction. When I'm tempted to take the easy road, remind me of Your way. I love You, Lord. I want to listen to Your voice and hold fast to You, because You are my life. Guide my steps today. In Jesus' name, amen.",
            reflectionPrompt: "What does 'choosing life' look like in your current circumstances?",
            actionSteps: ["Before each decision today, ask: 'Does this lead toward life or away from it?'", "Share this verse with someone who might need encouragement"]
        ),
        DayContent(
            scriptureReference: "John 15:10",
            scriptureText: "If you keep my commands, you will remain in my love, just as I have kept my Father's commands and remain in his love.",
            devotionalTitle: "Remaining in Love",
            devotionalText: "Obedience and love are not opposites—they're partners. Jesus models this perfectly: He obeyed the Father and remained in the Father's love. Obedience isn't about trying harder to earn approval; it's about staying close to the source of love. When we keep His commands, we position ourselves to experience the fullness of His affection. Think of obedience not as a cage, but as the path that keeps you near the One who loves you most.",
            prayerText: "Jesus, I want to remain in Your love. Help me see obedience not as a cage but as the path that keeps me close to You. I abide in You today — like a branch connected to the vine. Apart from You I can do nothing, but with You, I can bear fruit that lasts. Keep me close, Lord. I don't want to wander. In Your name, amen.",
            reflectionPrompt: "How does understanding obedience as 'remaining in love' change your perspective?",
            actionSteps: ["Meditate on John 15:1-11 and note every mention of 'remain'", "Choose one act of obedience today as an expression of love for Jesus"]
        ),
        DayContent(
            scriptureReference: "Micah 6:8",
            scriptureText: "He has shown you, O mortal, what is good. And what does the Lord require of you? To act justly and to love mercy and to walk humbly with your God.",
            devotionalTitle: "What God Requires",
            devotionalText: "When the complexity of faith feels overwhelming, Micah brings it back to essentials. God's requirements aren't a thousand rules—they're three beautiful rhythms: justice in how you treat others, mercy in how you respond to brokenness, and humility in how you walk with God. These aren't occasional grand gestures; they're daily postures. In your conversations, your reactions, your decisions—act justly, love mercy, walk humbly.",
            prayerText: "Lord, You have shown me what is good. Help me to act justly in how I treat others — especially those who can't repay me. Help me to love mercy — to be quick to forgive and slow to judge. Help me to walk humbly with You — not leaning on my own understanding but trusting Yours. These three things, Lord — let them define my life today. In Jesus' name, amen.",
            reflectionPrompt: "Which of these three—justice, mercy, humility—is most natural for you? Which needs the most growth?",
            actionSteps: ["Do one thing today that reflects justice, one that reflects mercy, and one that reflects humility", "Pray through Micah 6:8, asking God to develop each quality in you"]
        ),
    ]

    // MARK: - Worship Content (6 entries)

    static let worshipContent: [DayContent] = [
        DayContent(
            scriptureReference: "Psalm 100:1-2",
            scriptureText: "Shout for joy to the Lord, all the earth. Worship the Lord with gladness; come before him with joyful songs.",
            devotionalTitle: "Worship with Gladness",
            devotionalText: "Worship isn't reserved for Sunday mornings or perfectly tuned voices. The psalmist invites all the earth—every person, in every situation—to come before God with joy. Worship is a posture of the heart that recognizes God's goodness and responds with gratitude. Whether you sing, whisper, dance, or simply sit in awe, let your heart overflow with praise today.",
            prayerText: "Lord, I come before You with joy today. I worship You — not because everything is perfect, but because You are. You are good. You are faithful. You are worthy of all my praise. Open my heart to worship You freely, without holding back. Let my praise rise to You like a joyful song, no matter what my circumstances look like. In Jesus' name, amen.",
            reflectionPrompt: "When do you feel most connected to God in worship?",
            actionSteps: ["Listen to a worship song and sing along, even if imperfectly", "Take a walk and thank God for 10 specific things you see"]
        ),
        DayContent(
            scriptureReference: "John 4:23-24",
            scriptureText: "Yet a time is coming and has now come when the true worshipers will worship the Father in the Spirit and in truth, for they are the kind of worshipers the Father seeks.",
            devotionalTitle: "Spirit and Truth",
            devotionalText: "Jesus redefines worship for the Samaritan woman—and for us. It's not about the right location, the right music style, or the right tradition. True worship happens in Spirit (authentic, Spirit-led engagement) and in truth (grounded in who God really is). The Father is actively seeking people who worship this way. Not performers. Not professionals. Just people who come to Him authentically, with hearts wide open.",
            prayerText: "Father, I want to worship You in Spirit and in truth — with an authentic heart and a mind anchored in who You really are. Deepen my worship beyond routine and performance. Meet me here, right now, as I open my heart to You. You are seeking true worshippers, Lord — let me be one of them. In Jesus' name, amen.",
            reflectionPrompt: "Is your worship more focused on 'Spirit' (emotional connection) or 'truth' (theological depth)? How can you grow in both?",
            actionSteps: ["Worship God in a way that's different from your usual style today", "Read a psalm of praise aloud as an act of worship"]
        ),
        DayContent(
            scriptureReference: "Romans 12:1",
            scriptureText: "Therefore, I urge you, brothers and sisters, in view of God's mercy, to offer your bodies as a living sacrifice, holy and pleasing to God—this is your true and proper worship.",
            devotionalTitle: "Your Life as Worship",
            devotionalText: "Paul expands worship far beyond singing. Your entire life—how you use your body, your time, your energy, your talents—is an act of worship. Every meal prepared with love, every honest day's work, every act of kindness is an offering to God. Worship isn't just something you do on Sunday; it's something you are every day. Today, view every ordinary moment as an opportunity to honor God.",
            prayerText: "God, I offer my body, my time, and my energy as a living sacrifice to You today. Let everything I do be an act of worship — not just the spiritual moments, but the ordinary ones too. When I work, let it glorify You. When I rest, let it honor You. My whole life is Yours, Lord. I worship You with all that I am. In Jesus' name, amen.",
            reflectionPrompt: "How can your daily routine become an act of worship?",
            actionSteps: ["Dedicate one ordinary task today as an act of worship to God", "Before each activity, silently say: 'I do this for Your glory'"]
        ),
        DayContent(
            scriptureReference: "Psalm 95:1-2",
            scriptureText: "Come, let us sing for joy to the Lord; let us shout aloud to the Rock of our salvation. Let us come before him with thanksgiving and extol him with music and song.",
            devotionalTitle: "Come With Thanksgiving",
            devotionalText: "The psalmist doesn't suggest worship—he commands it with enthusiasm. Come! Sing! Shout! These aren't reserved, polite suggestions. True worship is expressive, grateful, and bold. Thanksgiving is the gateway to worship: when you start counting blessings, your heart naturally lifts to the One who gives them. Don't wait until you feel like worshipping—start with gratitude, and worship will follow.",
            prayerText: "Lord, I come before You with thanksgiving in my heart. Thank You for waking me up today. Thank You for Your love that never fails. Thank You for provision, for protection, for presence. I choose gratitude over grumbling. I choose praise over complaint. You are the Rock of my salvation, and I shout for joy because of who You are. In Jesus' name, amen.",
            reflectionPrompt: "What are five things you're grateful for right now?",
            actionSteps: ["Start your prayer time today with 5 minutes of pure thanksgiving—no requests", "Create a playlist of worship songs that reflect your gratitude"]
        ),
        DayContent(
            scriptureReference: "Psalm 34:1",
            scriptureText: "I will extol the Lord at all times; his praise will always be on my lips.",
            devotionalTitle: "Worship in Every Season",
            devotionalText: "David wrote this psalm while pretending to be insane to escape from a hostile king. It wasn't written from a place of comfort—it was written in crisis. And yet: 'I will extol the Lord at all times.' Worship isn't dependent on circumstances. The hardest—and most powerful—worship happens when everything in you wants to complain. Today, choose praise regardless of how you feel.",
            prayerText: "God, I choose to praise You even when my circumstances don't feel praise-worthy. You are good — not because everything is easy, but because Your character never changes. In the valley and on the mountain, You are faithful. I will extol You at all times. Your praise will always be on my lips — in joy and in sorrow, in plenty and in need. You are worthy. In Jesus' name, amen.",
            reflectionPrompt: "Can you worship God authentically even when circumstances are difficult? What makes that hard?",
            actionSteps: ["Write a prayer of praise despite any current difficulty you're facing", "Speak three truths about God's character aloud right now"]
        ),
        DayContent(
            scriptureReference: "Revelation 4:11",
            scriptureText: "You are worthy, our Lord and God, to receive glory and honor and power, for you created all things, and by your will they were created and have their being.",
            devotionalTitle: "He Is Worthy",
            devotionalText: "In the throne room of heaven, worship never stops. The twenty-four elders and living creatures declare God's worthiness not because of what He does for them, but because of who He is. He is the Creator. He is sovereign. He is good. Today, shift your worship from what God has done to who God is. He is worthy of your praise simply because He exists.",
            prayerText: "Lord God, You are worthy to receive glory, honor, and power. You created all things, and by Your will they exist. I stand in awe of who You are — not just what You do, but who You are. You are holy. You are sovereign. You are beautiful beyond description. I join with heaven in declaring: You are worthy, our Lord and God. All praise and honor belong to You forever. Amen.",
            reflectionPrompt: "What attribute of God fills you with the most awe?",
            actionSteps: ["Spend 5 minutes praising God for who He is—not for what He's done", "Read Revelation 4 and imagine yourself in the throne room"]
        ),
    ]

    // MARK: - Community Content (6 entries)

    static let communityContent: [DayContent] = [
        DayContent(
            scriptureReference: "Hebrews 10:24-25",
            scriptureText: "And let us consider how we may spur one another on toward love and good deeds, not giving up meeting together, as some are in the habit of doing, but encouraging one another.",
            devotionalTitle: "Better Together",
            devotionalText: "Faith was never meant to be a solo journey. God designed us to grow in community—sharpening, encouraging, and carrying one another through life's ups and downs. The writer of Hebrews urges us not to abandon gathering together, because isolation is where faith often withers. You need others, and they need you. Reach out today.",
            prayerText: "Father, thank You for the gift of community. I was never meant to walk this journey alone. Surround me with people who sharpen my faith and encourage my heart. Help me to be that person for someone else today. Where I've been isolated, draw me back into fellowship. Where I've been distant, give me the courage to show up. We are better together. In Jesus' name, amen.",
            reflectionPrompt: "Who in your life encourages your faith the most? Have you told them?",
            actionSteps: ["Send an encouraging text to a fellow believer today", "Make plans to connect with a faith community this week"]
        ),
        DayContent(
            scriptureReference: "Ecclesiastes 4:9-10",
            scriptureText: "Two are better than one, because they have a good return for their labor: If either of them falls down, one can help the other up. But pity anyone who falls and has no one to help them up.",
            devotionalTitle: "Don't Walk Alone",
            devotionalText: "Solomon, the wisest man who ever lived, understood a fundamental truth: we need each other. Two are better than one—not just for productivity, but for protection. When you fall (and you will), who's there to help you up? Isolation isn't independence; it's vulnerability. The enemy loves to pick off lone sheep. Today, take a step toward deeper connection with someone who shares your faith.",
            prayerText: "Lord, I don't want to walk alone. Give me the humility to let others in and the vulnerability to admit when I need help. Bring people into my life who will walk alongside me — and help me be someone who lifts others up when they fall. Protect me from the lie that I'm better off on my own. Two are better than one, Lord. Help me live that truth. In Jesus' name, amen.",
            reflectionPrompt: "Do you have someone who would pick you up if you fell? If not, what's stopping you from finding that person?",
            actionSteps: ["Reach out to someone you trust and share one thing you're struggling with", "Invite someone to coffee or lunch this week to talk about faith"]
        ),
        DayContent(
            scriptureReference: "Galatians 6:2",
            scriptureText: "Carry each other's burdens, and in this way you will fulfill the law of Christ.",
            devotionalTitle: "Burden Bearers",
            devotionalText: "The 'law of Christ' is love—and love in action means carrying weight that isn't yours. It means listening when you'd rather scroll. It means showing up when it's inconvenient. It means praying for someone else's problem as if it were your own. Burden-bearing is costly, but it's the essence of Christian community. Today, look around. Who near you is carrying something heavy? Step in.",
            prayerText: "Jesus, You carried the ultimate burden for me on the cross. Help me to carry the burdens of those around me. Open my eyes to see who is struggling. Give me the compassion to step in and the selflessness to stay. Teach me to love in action — not just in words. Let me fulfill the law of Christ by bearing one another's burdens today. In Your name, amen.",
            reflectionPrompt: "Whose burden could you help carry this week? What would that look like practically?",
            actionSteps: ["Ask someone today: 'How are you really doing?'—and wait for the honest answer", "Offer to help with a specific, practical need someone has"]
        ),
        DayContent(
            scriptureReference: "Proverbs 27:17",
            scriptureText: "As iron sharpens iron, so one person sharpens another.",
            devotionalTitle: "Sharpened Together",
            devotionalText: "Iron sharpening iron isn't gentle—there's friction, heat, and sparks. Real spiritual growth in community isn't always comfortable. It means being honest enough to challenge each other, humble enough to receive correction, and committed enough to stay in relationship when it's hard. The friendships that sharpen you most are rarely the easiest ones. Seek people who love you enough to tell you the truth.",
            prayerText: "God, give me relationships that sharpen me — not just comfortable ones, but honest ones. Help me to be humble enough to receive correction and courageous enough to speak truth in love. I don't want to stay the same. Surround me with iron that sharpens iron, and make me someone who sharpens others in return. In Jesus' name, amen.",
            reflectionPrompt: "Do you have someone in your life who sharpens you spiritually? Are you open to being sharpened?",
            actionSteps: ["Identify one person who challenges you to grow and thank them", "Ask a trusted friend for honest feedback about your spiritual life"]
        ),
        DayContent(
            scriptureReference: "Acts 2:42-47",
            scriptureText: "They devoted themselves to the apostles' teaching and to fellowship, to the breaking of bread and to prayer... Every day they continued to meet together in the temple courts. They broke bread in their homes and ate together with glad and sincere hearts.",
            devotionalTitle: "The First Community",
            devotionalText: "The early church wasn't a program—it was a family. They shared meals, shared resources, prayed together, learned together, and praised God together. Their fellowship was daily, not weekly. It was in homes, not just in temples. It was glad and sincere, not forced or formal. This is the vision of community God has for us. It starts with showing up consistently and sharing life authentically.",
            prayerText: "Lord, give me a taste of the Acts 2 church — a community devoted to learning, fellowship, breaking bread, and prayer. Help me to show up consistently, share generously, and love authentically. I want to be part of something bigger than myself. Build a community around me that reflects Your heart — glad, sincere, and growing together. In Jesus' name, amen.",
            reflectionPrompt: "How does your experience of Christian community compare to Acts 2? What's missing?",
            actionSteps: ["Invite someone to share a meal with you this week—keep it simple", "Commit to attending your small group or church gathering consistently for the next month"]
        ),
        DayContent(
            scriptureReference: "1 John 1:7",
            scriptureText: "But if we walk in the light, as he is in the light, we have fellowship with one another, and the blood of Jesus, his Son, purifies us from all sin.",
            devotionalTitle: "Walking in the Light",
            devotionalText: "True fellowship requires transparency. When we 'walk in the light,' we stop hiding—our struggles, our failures, our doubts. Paradoxically, it's vulnerability that creates the deepest bonds. When you let someone see the real you—not the curated, Sunday-morning version—genuine fellowship becomes possible. The light doesn't just expose; it also heals. Step out of the shadows today.",
            prayerText: "Father, help me to walk in the light — to stop hiding behind a mask of perfection. Give me the courage to be honest about my struggles and the faith to believe I'll be loved anyway. Let transparency become my strength, not my weakness. Where there is darkness, bring light. Where there is isolation, bring fellowship. I step out of the shadows and into Your presence today. In Jesus' name, amen.",
            reflectionPrompt: "What would it look like to be more transparent with your faith community?",
            actionSteps: ["Share one honest struggle with a trusted Christian friend today", "Practice vulnerability by admitting 'I don't know' or 'I'm struggling' when it's true"]
        ),
    ]

    // MARK: - Evangelism Content (6 entries)

    static let evangelismContent: [DayContent] = [
        DayContent(
            scriptureReference: "1 Peter 3:15",
            scriptureText: "But in your hearts revere Christ as Lord. Always be prepared to give an answer to everyone who asks you to give the reason for the hope that you have. But do this with gentleness and respect.",
            devotionalTitle: "Ready to Share",
            devotionalText: "Sharing your faith doesn't require a theology degree or a perfect life story. Peter says to simply be ready to explain your hope—with gentleness and respect. The most powerful testimony is often the simplest: 'Here's what God has done in my life.' People aren't looking for perfect arguments; they're looking for authentic hope. You have that. Be ready to share it.",
            prayerText: "Lord, make me ready to share the hope I have in You — with gentleness and respect. Give me the words when the moment comes. Remove my fear of rejection and replace it with love for others. Help me see every conversation as an opportunity to point someone toward You. I don't need a perfect testimony — I just need to be honest about what You've done in my life. In Jesus' name, amen.",
            reflectionPrompt: "If someone asked you today why you have hope, what would you say?",
            actionSteps: ["Write out your faith story in 3 sentences: before, encounter, after", "Pray for one person you know who doesn't know Jesus"]
        ),
        DayContent(
            scriptureReference: "Matthew 28:19-20",
            scriptureText: "Therefore go and make disciples of all nations, baptizing them in the name of the Father and of the Son and of the Holy Spirit, and teaching them to obey everything I have commanded you.",
            devotionalTitle: "The Great Commission",
            devotionalText: "Jesus' final command wasn't to build buildings or programs—it was to make disciples. This isn't reserved for pastors and missionaries. Every believer is called to share the good news and help others grow. Discipleship starts with one conversation, one act of love, one invitation. You don't need all the answers. You just need to be willing to share what God has done for you.",
            prayerText: "Jesus, You told us to go and make disciples. I don't take that lightly. Open doors for me to share Your love with someone today. Give me eyes to see the people around me who are searching for something real. Help me to be a faithful witness — not through arguments, but through love, kindness, and genuine care. Use my life to draw others to You. In Your name, amen.",
            reflectionPrompt: "Who is one person in your life who might be open to hearing about your faith?",
            actionSteps: ["Pray specifically for an opportunity to share your faith this week", "Invite someone to church, a Bible study, or simply to coffee"]
        ),
        DayContent(
            scriptureReference: "Romans 1:16",
            scriptureText: "For I am not ashamed of the gospel, because it is the power of God that brings salvation to everyone who believes: first to the Jew, then to the Gentile.",
            devotionalTitle: "Unashamed",
            devotionalText: "Paul declares boldly: the gospel is the power of God. Not a helpful suggestion. Not a nice philosophy. Power. The same power that raised Jesus from the dead is contained in the message you carry. When fear or embarrassment tempts you to stay silent, remember what you hold—it's dynamite wrapped in grace. You don't need to be ashamed of something that can literally save lives. Be bold today.",
            prayerText: "God, I am not ashamed of the gospel — it is Your power for salvation. Remove any embarrassment, any hesitation, any fear that keeps me from sharing what You've done. Fill me with holy boldness. Remind me that the message I carry is not a suggestion — it is life-changing power. Help me to speak up when I'm tempted to stay silent. In Jesus' name, amen.",
            reflectionPrompt: "What makes you hesitant to share your faith? How does knowing it's 'the power of God' change that?",
            actionSteps: ["Tell one person today something God has done in your life recently", "Write down your biggest fear about sharing your faith and pray over it"]
        ),
        DayContent(
            scriptureReference: "2 Corinthians 5:20",
            scriptureText: "We are therefore Christ's ambassadors, as though God were making his appeal through us. We implore you on Christ's behalf: Be reconciled to God.",
            devotionalTitle: "Ambassador of Heaven",
            devotionalText: "An ambassador represents their home country in a foreign land. That's exactly what you are—a representative of heaven, living in a world that desperately needs to know the King. God has chosen to make His appeal through you. Not through angels, not through skywriting—through you. Your words, your kindness, your life is the vehicle through which others encounter Jesus. What kind of ambassador will you be today?",
            prayerText: "Father, I am Your ambassador on this earth. Help me to represent Your kingdom well today — in my words, my actions, and my attitude. Let people see Jesus in me before I ever say His name. I carry a message of reconciliation, and I don't take that responsibility lightly. Use me as a bridge between a hurting world and a loving God. In Jesus' name, amen.",
            reflectionPrompt: "How well does your daily life represent the kingdom of God to those around you?",
            actionSteps: ["Act as an 'ambassador' today—let every interaction reflect Christ", "Identify one person who sees your life regularly and pray they see Jesus in you"]
        ),
        DayContent(
            scriptureReference: "Matthew 5:14-16",
            scriptureText: "You are the light of the world. A town built on a hill cannot be hidden. Neither do people light a lamp and put it under a bowl. Instead they put it on its stand, and it gives light to everyone in the house.",
            devotionalTitle: "Let Your Light Shine",
            devotionalText: "Jesus doesn't say 'try to be a light'—He says you are the light. It's already in you through the Holy Spirit. The question isn't whether you have light, but whether you're hiding it. Fear, insecurity, and desire to fit in can make us dim our light. But a hidden light helps no one. Today, let your faith be visible—not obnoxiously, but authentically. People in darkness are drawn to light.",
            prayerText: "Jesus, You called me the light of the world. Help me to stop hiding — to let my faith be visible, authentic, and inviting. Not obnoxious, but undeniable. Let my life shine in a way that draws others to You. Remove the fear of standing out and replace it with the joy of being Yours. I will not put my light under a bowl. I will let it shine. In Your name, amen.",
            reflectionPrompt: "In what situations are you tempted to hide your faith? Why?",
            actionSteps: ["Do something today that makes your faith visible without being pushy", "Thank someone who was a 'light' in your life and tell them how they impacted you"]
        ),
        DayContent(
            scriptureReference: "Acts 1:8",
            scriptureText: "But you will receive power when the Holy Spirit comes on you; and you will be my witnesses in Jerusalem, and in all Judea and Samaria, and to the ends of the earth.",
            devotionalTitle: "Empowered to Witness",
            devotionalText: "Jesus doesn't send you out empty-handed. Before the Great Commission, there's a great empowerment. The Holy Spirit gives you the power, the words, and the courage to be His witness. Notice the expanding circles: Jerusalem (your immediate world), Judea (your region), Samaria (uncomfortable places), the ends of the earth. Start where you are. The Spirit will expand your reach as you're faithful in your 'Jerusalem.'",
            prayerText: "Holy Spirit, empower me to be Your witness — starting right where I am. In my home, my workplace, my neighborhood — let me be faithful in my Jerusalem before I dream about the ends of the earth. Give me boldness, give me compassion, and give me the right words at the right time. I rely not on my own strength but on Your power working through me. In Jesus' name, amen.",
            reflectionPrompt: "Who is in your 'Jerusalem'—your immediate sphere of influence?",
            actionSteps: ["List 5 people in your daily life who don't know Jesus and commit to praying for them", "Ask the Holy Spirit to give you boldness and the right words this week"]
        ),
    ]

    // MARK: - Service Content (6 entries)

    static let serviceContent: [DayContent] = [
        DayContent(
            scriptureReference: "Galatians 5:22-23",
            scriptureText: "But the fruit of the Spirit is love, joy, peace, forbearance, kindness, goodness, faithfulness, gentleness and self-control. Against such things there is no law.",
            devotionalTitle: "The Fruit Test",
            devotionalText: "You can't manufacture spiritual fruit through willpower any more than a tree can force itself to bloom. Fruit is the natural result of being connected to the vine—to Jesus. When you abide in Him, these qualities begin to grow organically in your life. Today, rather than trying harder to be kind or patient, focus on drawing closer to Jesus. The fruit will follow the abiding.",
            prayerText: "Holy Spirit, grow Your fruit in me — love where there is indifference, joy where there is heaviness, peace where there is chaos. Cultivate patience, kindness, and goodness in my heart. Help me to be faithful, gentle, and self-controlled — not through striving, but through abiding in You. I can't produce this fruit on my own. I need You, Lord. Grow what only You can grow. In Jesus' name, amen.",
            reflectionPrompt: "Which fruit of the Spirit is most evident in your life? Which is least?",
            actionSteps: ["Pick the fruit you struggle with most and ask God specifically to grow it in you", "Do one act of unexpected kindness for someone today"]
        ),
        DayContent(
            scriptureReference: "Mark 10:45",
            scriptureText: "For even the Son of Man did not come to be served, but to serve, and to give his life as a ransom for many.",
            devotionalTitle: "The Servant King",
            devotionalText: "Jesus—King of Kings, Creator of the universe—chose the path of service. If the Son of God washed feet and served meals, how much more should we? Service isn't beneath us; it's the very heart of Christlikeness. When you serve others, you reflect the character of Jesus to a watching world. Look for opportunities today to put someone else's needs before your own.",
            prayerText: "Jesus, You came not to be served but to serve. Give me a servant's heart like Yours. Help me to see every act of service — no matter how small — as an act of worship. Where pride tells me to seek recognition, teach me the beauty of quiet faithfulness. I want to follow Your example today, putting others before myself. In Your name, amen.",
            reflectionPrompt: "What does serving others look like in your daily life?",
            actionSteps: ["Do one act of service for someone without being asked", "Volunteer for something at your church or in your community this week"]
        ),
        DayContent(
            scriptureReference: "Philippians 2:3-4",
            scriptureText: "Do nothing out of selfish ambition or vain conceit. Rather, in humility value others above yourselves, not looking to your own interests but each of you to the interests of the others.",
            devotionalTitle: "Others Before Self",
            devotionalText: "Paul's instruction goes against every instinct of our self-centered nature: value others above yourself. This isn't about self-hatred or doormat theology—it's about Christlike humility. It's choosing to notice what others need instead of obsessing over what you want. It's asking 'How can I help?' more than 'What's in it for me?' This radical others-focus is what made the early church so magnetic.",
            prayerText: "Father, break through my selfishness today. Help me to value others above myself — not out of guilt, but out of genuine love. Open my eyes to what the people around me need. Give me the humility to put their interests before my own. I want to reflect the heart of Christ in how I treat every person I encounter today. In Jesus' name, amen.",
            reflectionPrompt: "In what relationship do you most need to practice putting the other person first?",
            actionSteps: ["In every conversation today, ask the other person about themselves before talking about yourself", "Do one thing for your family or roommate that you normally wouldn't"]
        ),
        DayContent(
            scriptureReference: "Matthew 25:35-36, 40",
            scriptureText: "For I was hungry and you gave me something to eat, I was thirsty and you gave me something to drink, I was a stranger and you invited me in... Truly I tell you, whatever you did for one of the least of these brothers and sisters of mine, you did for me.",
            devotionalTitle: "Serving Jesus in Others",
            devotionalText: "Jesus makes a staggering claim: when you serve the hungry, the thirsty, the stranger, the sick, the imprisoned—you're serving Him. Every act of compassion is an encounter with Christ Himself. This reframes service entirely. The homeless person isn't an inconvenience; they're an invitation to meet Jesus. The struggling neighbor isn't a burden; they're a divine appointment. Open your eyes today to see Jesus in the faces around you.",
            prayerText: "Lord Jesus, help me to see Your face in every person I serve today. When I feed the hungry, clothe the needy, or comfort the hurting — remind me that I am serving You. Open my eyes to the divine appointments all around me. Give me compassion that moves beyond feeling to action. Whatever I do for the least of these, I do for You. In Your name, amen.",
            reflectionPrompt: "When have you seen Jesus in someone unexpected?",
            actionSteps: ["Find one way to serve 'the least of these' in your community today", "Donate to or volunteer at a local shelter, food bank, or outreach ministry"]
        ),
        DayContent(
            scriptureReference: "1 Peter 4:10",
            scriptureText: "Each of you should use whatever gift you have received to serve others, as faithful stewards of God's grace in its various forms.",
            devotionalTitle: "Your Unique Service",
            devotionalText: "God has given you specific gifts—not for your own benefit, but for serving others. You are a steward of grace, uniquely equipped to make a difference in ways no one else can. Your gift might be teaching, hospitality, encouragement, administration, or simply being present. Whatever it is, it's needed. The body of Christ functions best when every member uses their gift. Don't hold back.",
            prayerText: "God, thank You for the unique gifts You've placed in me. Show me how to use them — not for my own glory, but for the good of others and the building up of Your church. I am a steward of Your grace, and I don't want to waste what You've given me. Help me to serve faithfully with the gifts I have, right where I am. In Jesus' name, amen.",
            reflectionPrompt: "What gifts has God given you? How are you currently using them to serve others?",
            actionSteps: ["Identify your top spiritual gift and find one way to use it this week", "Ask someone who knows you well: 'What do you think my gifts are?'"]
        ),
        DayContent(
            scriptureReference: "Colossians 3:23-24",
            scriptureText: "Whatever you do, work at it with all your heart, as working for the Lord, not for human masters, since you know that you will receive an inheritance from the Lord as a reward. It is the Lord Christ you are serving.",
            devotionalTitle: "Working for the Lord",
            devotionalText: "Every job, every chore, every mundane task becomes sacred when you do it for God. Paul transforms our understanding of work: your boss isn't your ultimate audience—Jesus is. Whether you're coding, cooking, cleaning, or caring for children, you're serving the Lord. This perspective doesn't just change your work ethic; it changes your whole attitude. Excellence becomes worship. Faithfulness becomes service. Monday becomes as holy as Sunday.",
            prayerText: "Lord, whatever I do today, I do it for You. Transform my work into worship and my tasks into service. Whether anyone notices or not, I choose to give my best because You are my audience. Help me work with excellence, serve with joy, and finish with faithfulness. You are the Lord I am serving — and that changes everything. In Jesus' name, amen.",
            reflectionPrompt: "How would your approach to your daily work change if you truly saw it as service to God?",
            actionSteps: ["Before starting your work today, pray: 'Lord, I do this for You'", "Find one way to serve a coworker, classmate, or neighbor without recognition"]
        ),
    ]
}
