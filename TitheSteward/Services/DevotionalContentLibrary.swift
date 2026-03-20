import Foundation

/// Static library of devotional content for the Tithe Steward app.
/// These cycle on a 30-day rotation based on the day of the year.
enum DevotionalContentLibrary {
    static let devotionals: [Devotional] = [
        // MARK: - Week 1: Foundations of Stewardship

        Devotional(
            title: "The Owner and the Manager",
            verse: "The earth is the LORD's, and everything in it, the world, and all who live in it.",
            verseReference: "Psalm 24:1",
            reflection: "Everything we have belongs to God. Our bank accounts, our homes, our careers — all of it is entrusted to us as managers, not owners. When we shift from an ownership mindset to a stewardship mindset, giving becomes natural. We're not losing what's ours; we're returning what's His. Today, consider how this perspective changes your relationship with money.",
            prayerPrompt: "Lord, help me see everything I have as Yours. Give me the heart of a faithful steward who manages Your resources with wisdom and generosity.",
            category: .stewardship,
            dayOfCycle: 1
        ),
        Devotional(
            title: "First Fruits, Not Leftovers",
            verse: "Honor the LORD with your wealth, with the firstfruits of all your crops; then your barns will be filled to overflowing.",
            verseReference: "Proverbs 3:9-10",
            reflection: "God doesn't ask for what's left over — He asks for the first portion. When we give first, before bills and wants, we declare that God is our priority. This isn't about earning blessings through a formula; it's about aligning our hearts with what matters most. Giving first is an act of trust that says, 'God, I believe You will provide for the rest.'",
            prayerPrompt: "Father, give me the courage to put You first in my finances. Help me trust that when I honor You with the firstfruits, You are faithful to provide.",
            category: .tithing,
            dayOfCycle: 2
        ),
        Devotional(
            title: "The Cheerful Giver",
            verse: "Each of you should give what you have decided in your heart to give, not reluctantly or under compulsion, for God loves a cheerful giver.",
            verseReference: "2 Corinthians 9:7",
            reflection: "God isn't interested in reluctant obedience. He wants joyful generosity that flows from a grateful heart. If giving feels like a burden, the issue isn't with the amount — it's with the heart behind it. Ask God to transform your perspective so that giving becomes one of the most joyful things you do. When you see giving as worship, everything changes.",
            prayerPrompt: "God, transform my heart so that I give cheerfully. Replace any reluctance with joy, and help me see every gift as an act of worship.",
            category: .generosity,
            dayOfCycle: 3
        ),
        Devotional(
            title: "Treasure and Heart",
            verse: "For where your treasure is, there your heart will be also.",
            verseReference: "Matthew 6:21",
            reflection: "Jesus makes a profound observation: your heart follows your money. If you want to care more about God's kingdom, invest in it. If you want to care more about your church, give to it. Our spending reveals our true priorities, and redirecting our treasure redirects our hearts. Look at your bank statement this week — what does it say about where your heart is?",
            prayerPrompt: "Jesus, align my treasure with Your kingdom. Help me invest in what matters eternally, knowing my heart will follow.",
            category: .stewardship,
            dayOfCycle: 4
        ),
        Devotional(
            title: "The Tithe: A Starting Point",
            verse: "Bring the whole tithe into the storehouse, that there may be food in my house. Test me in this, says the LORD Almighty, and see if I will not throw open the floodgates of heaven and pour out so much blessing that there will not be room enough to store it.",
            verseReference: "Malachi 3:10",
            reflection: "This is the only place in Scripture where God says, 'Test me.' He invites us to try Him — to step out in faith with our finances and watch what He does. The tithe (10%) isn't a ceiling for giving; it's a floor. It's the starting point of a generous life. If you've never tithed consistently, God is inviting you today: test Him and see.",
            prayerPrompt: "Lord, I accept Your invitation to test You. Give me faith to bring the whole tithe and trust You with the results.",
            category: .tithing,
            dayOfCycle: 5
        ),
        Devotional(
            title: "Contentment Is Freedom",
            verse: "But godliness with contentment is great gain. For we brought nothing into the world, and we can take nothing out of it.",
            verseReference: "1 Timothy 6:6-7",
            reflection: "Contentment isn't about having everything you want — it's about recognizing that what you have is enough. In a culture that constantly tells us we need more, contentment is a radical act of faith. When we're content, we're free to give generously because we're not clinging to what we have. True wealth isn't measured in dollars but in the peace that comes from trusting God.",
            prayerPrompt: "Father, teach me contentment. Free me from the lie that I need more to be happy. Help me find my satisfaction in You alone.",
            category: .contentment,
            dayOfCycle: 6
        ),
        Devotional(
            title: "God's Faithful Provision",
            verse: "And my God will meet all your needs according to the riches of his glory in Christ Jesus.",
            verseReference: "Philippians 4:19",
            reflection: "Notice it says 'needs,' not 'wants.' God promises to provide what we truly need. This doesn't mean we'll always have abundance by worldly standards, but it means we'll never lack what's essential. When fear about finances grips you, return to this promise. The God who owns the cattle on a thousand hills knows your needs and is faithful to meet them.",
            prayerPrompt: "God, thank You for Your faithful provision. When I'm tempted to worry, remind me that You know my needs and You are more than able to meet them.",
            category: .provision,
            dayOfCycle: 7
        ),

        // MARK: - Week 2: Wisdom with Money

        Devotional(
            title: "The Wise Planner",
            verse: "The plans of the diligent lead to profit as surely as haste leads to poverty.",
            verseReference: "Proverbs 21:5",
            reflection: "Financial planning isn't unspiritual — it's biblical wisdom. Creating a budget, tracking expenses, and planning for the future are all acts of faithful stewardship. God gave us minds to think strategically about the resources He provides. Being diligent with a plan doesn't mean we don't trust God; it means we're taking seriously the responsibility He's given us.",
            prayerPrompt: "Lord, give me wisdom to plan diligently with the resources You've given me. Help me be both faithful and strategic in my stewardship.",
            category: .wisdom,
            dayOfCycle: 8
        ),
        Devotional(
            title: "The Danger of Debt",
            verse: "The rich rule over the poor, and the borrower is slave to the lender.",
            verseReference: "Proverbs 22:7",
            reflection: "Debt limits our freedom to respond to God's leading. When we're buried in payments, we can't freely give, serve, or follow where God calls. This doesn't mean all debt is sinful, but Scripture is clear that it creates bondage. If you're in debt today, know that God wants you free. Create a plan, be patient, and trust that every payment brings you closer to the freedom God desires for you.",
            prayerPrompt: "Father, help me pursue financial freedom. Give me discipline to pay off debt and wisdom to avoid unnecessary borrowing. I want to be free to follow You.",
            category: .debt,
            dayOfCycle: 9
        ),
        Devotional(
            title: "Storing Up Wisely",
            verse: "The wise store up choice food and olive oil, but fools gulp theirs down.",
            verseReference: "Proverbs 21:20",
            reflection: "Saving isn't the opposite of generosity — it's a companion to it. When we save wisely, we're prepared for emergencies, positioned to help others in crisis, and free from the anxiety that comes from living paycheck to paycheck. The foolish person consumes everything immediately; the wise person prepares for tomorrow while being generous today.",
            prayerPrompt: "God, give me the discipline to save and the wisdom to balance saving with generosity. Help me prepare for the future while trusting You with today.",
            category: .wisdom,
            dayOfCycle: 10
        ),
        Devotional(
            title: "Faithful in Little",
            verse: "Whoever can be trusted with very little can also be trusted with much, and whoever is dishonest with very little will also be dishonest with much.",
            verseReference: "Luke 16:10",
            reflection: "How you handle $100 reveals how you'd handle $100,000. God tests our faithfulness in small things before entrusting us with greater responsibilities. Don't despise small beginnings in your financial journey. If you can tithe on a small income, you'll tithe on a large one. If you budget well when money is tight, you'll manage well when it's abundant. Start where you are.",
            prayerPrompt: "Lord, help me be faithful with what I have right now, no matter how small it seems. Prepare me for greater responsibility through today's obedience.",
            category: .stewardship,
            dayOfCycle: 11
        ),
        Devotional(
            title: "The Ant's Example",
            verse: "Go to the ant, you sluggard; consider its ways and be wise! It has no commander, no overseer or ruler, yet it stores its provisions in summer and gathers its food at harvest.",
            verseReference: "Proverbs 6:6-8",
            reflection: "The ant doesn't need someone standing over it to do the right thing. It works diligently and prepares for the future without being told. God calls us to that same self-discipline with our finances. We don't need the pressure of a crisis to start budgeting, saving, or giving. Wisdom means acting today to prepare for tomorrow.",
            prayerPrompt: "Father, give me the self-discipline of the ant. Help me work diligently, plan wisely, and prepare for the future without needing a crisis to motivate me.",
            category: .wisdom,
            dayOfCycle: 12
        ),
        Devotional(
            title: "Seeking First the Kingdom",
            verse: "But seek first his kingdom and his righteousness, and all these things will be given to you as well.",
            verseReference: "Matthew 6:33",
            reflection: "When God's kingdom is our first priority, everything else falls into proper order. This doesn't mean financial responsibilities disappear, but it means they take their rightful place behind our devotion to God. When we seek His kingdom first — in our giving, our spending, our career decisions — we find that He provides for our material needs in ways we couldn't have planned.",
            prayerPrompt: "Jesus, help me seek Your kingdom first in every financial decision. Reorder my priorities so that Your will comes before my wants.",
            category: .provision,
            dayOfCycle: 13
        ),
        Devotional(
            title: "The Generous Soul",
            verse: "A generous person will prosper; whoever refreshes others will be refreshed.",
            verseReference: "Proverbs 11:25",
            reflection: "Generosity creates a beautiful cycle. When we refresh others, we ourselves are refreshed. This isn't a prosperity gospel promise of guaranteed financial returns — it's a spiritual reality. Generous people experience a richness of life, community, and purpose that stingy people never know. Today, look for an opportunity to refresh someone, and watch how it refreshes your own soul.",
            prayerPrompt: "Lord, make me a generous soul. Show me someone I can refresh today, and open my eyes to the blessings that flow from a giving heart.",
            category: .generosity,
            dayOfCycle: 14
        ),

        // MARK: - Week 3: Overcoming Financial Fears

        Devotional(
            title: "Do Not Worry",
            verse: "Therefore I tell you, do not worry about your life, what you will eat or drink; or about your body, what you will wear. Is not life more than food, and the body more than clothes?",
            verseReference: "Matthew 6:25",
            reflection: "Jesus commands us not to worry — and He doesn't give commands without also giving the power to obey them. Financial anxiety is real, but it's not from God. When worry creeps in, it's an invitation to return to trust. Look at the birds of the air — they don't sow or reap, yet your heavenly Father feeds them. You are worth far more than they are.",
            prayerPrompt: "Jesus, I give You my financial worries today. Replace my anxiety with trust, and help me remember that You are my provider.",
            category: .provision,
            dayOfCycle: 15
        ),
        Devotional(
            title: "Breaking Free from Debt",
            verse: "Owe no one anything, except to love each other, for the one who loves another has fulfilled the law.",
            verseReference: "Romans 13:8",
            reflection: "The journey out of debt can feel overwhelming, but every journey begins with a single step. God isn't disappointed in where you are — He's excited about where you're heading. Each payment you make is an act of faithfulness. Each 'no' to unnecessary spending is an act of discipline. You're not just paying off debt; you're walking toward the financial freedom God designed for you.",
            prayerPrompt: "Father, give me perseverance on my debt-free journey. Help me celebrate small victories and keep my eyes on the freedom You have for me.",
            category: .debt,
            dayOfCycle: 16
        ),
        Devotional(
            title: "The Love of Money",
            verse: "For the love of money is a root of all kinds of evil. Some people, eager for money, have wandered from the faith and pierced themselves with many griefs.",
            verseReference: "1 Timothy 6:10",
            reflection: "Notice: it's not money itself that's evil — it's the love of money. Money is a tool; what matters is our relationship with it. When money becomes our security, our identity, or our obsession, it has become an idol. The antidote to the love of money is gratitude and generosity. When we give freely, we break money's grip on our hearts.",
            prayerPrompt: "God, search my heart for any unhealthy attachment to money. Free me from making it an idol, and help me use it as a tool for Your glory.",
            category: .contentment,
            dayOfCycle: 17
        ),
        Devotional(
            title: "God's Economy of Abundance",
            verse: "Now to him who is able to do immeasurably more than all we ask or imagine, according to his power that is at work within us.",
            verseReference: "Ephesians 3:20",
            reflection: "We often approach finances with a scarcity mindset: there's not enough, I can't afford to give, what if I run out? But God operates in an economy of abundance. He who fed five thousand with five loaves and two fish can certainly handle your finances. This doesn't mean we'll always have excess, but it means our God is never short on resources. Trust His ability, not your bank balance.",
            prayerPrompt: "Lord, replace my scarcity mindset with trust in Your abundant provision. Help me give and live with confidence in Your limitless resources.",
            category: .provision,
            dayOfCycle: 18
        ),
        Devotional(
            title: "The Widow's Offering",
            verse: "Truly I tell you, this poor widow has put more into the treasury than all the others. They all gave out of their wealth; but she, out of her poverty, put in everything — all she had to live on.",
            verseReference: "Mark 12:43-44",
            reflection: "Jesus measures giving not by the amount but by the sacrifice. The widow gave two small coins, yet Jesus called it the greatest gift of all. Don't let the size of your gift discourage you from giving. God sees your heart, not your wallet. A sacrificial gift from a willing heart is worth more to God than a comfortable gift from abundance.",
            prayerPrompt: "Jesus, help me give sacrificially, not just comfortably. Teach me that the value of my gift is measured by my heart, not by the dollar amount.",
            category: .generosity,
            dayOfCycle: 19
        ),
        Devotional(
            title: "Peace Beyond Understanding",
            verse: "And the peace of God, which transcends all understanding, will guard your hearts and your minds in Christ Jesus.",
            verseReference: "Philippians 4:7",
            reflection: "Financial peace doesn't come from having enough money — it comes from trusting the God who is enough. You can have a full bank account and an anxious heart, or you can have modest means and deep peace. The peace God offers doesn't make logical sense to the world — it transcends understanding. When you surrender your finances to Him, this supernatural peace guards your heart.",
            prayerPrompt: "Father, I choose Your peace today. Guard my heart and mind from financial anxiety. Help me trust that You are more than enough.",
            category: .contentment,
            dayOfCycle: 20
        ),
        Devotional(
            title: "Investing in Eternity",
            verse: "Do not store up for yourselves treasures on earth, where moths and vermin destroy, and where thieves break in and steal. But store up for yourselves treasures in heaven.",
            verseReference: "Matthew 6:19-20",
            reflection: "Every dollar you give to God's work is an investment in eternity. It can never be stolen, devalued, or destroyed. While we should be wise with earthly finances, we should be even more intentional about heavenly investments. Every life touched through your generosity, every soul reached through a ministry you support — these are eternal dividends that will far outlast any earthly portfolio.",
            prayerPrompt: "Lord, give me an eternal perspective with my finances. Help me invest generously in what will last forever.",
            category: .stewardship,
            dayOfCycle: 21
        ),

        // MARK: - Week 4: Living Generously

        Devotional(
            title: "The Blessing of Giving",
            verse: "In everything I did, I showed you that by this kind of hard work we must help the weak, remembering the words the Lord Jesus himself said: 'It is more blessed to give than to receive.'",
            verseReference: "Acts 20:35",
            reflection: "Jesus said it's more blessed to give than to receive, and those who practice generosity know this is true. There's a joy in giving that receiving can never match. When you help someone in need, support a ministry, or bless your church, something shifts in your spirit. You become more alive, more connected to God's purposes, more aware of His grace. Giving isn't a loss — it's a gain.",
            prayerPrompt: "Jesus, help me experience the truth that giving is more blessed than receiving. Open my eyes to opportunities to give today.",
            category: .generosity,
            dayOfCycle: 22
        ),
        Devotional(
            title: "Provision in the Desert",
            verse: "He humbled you, causing you to hunger and then feeding you with manna, which neither you nor your ancestors had known, to teach you that man does not live on bread alone but on every word that comes from the mouth of the LORD.",
            verseReference: "Deuteronomy 8:3",
            reflection: "Sometimes God allows seasons of financial tightness — not to punish us, but to teach us dependence on Him. The Israelites received manna daily; they couldn't stockpile it. God was teaching them to trust Him one day at a time. If you're in a financial desert right now, look for the manna. God is providing, perhaps in unexpected ways, and He's teaching you something precious about daily dependence.",
            prayerPrompt: "Father, even in tight seasons, help me see Your daily provision. Teach me to depend on You one day at a time.",
            category: .provision,
            dayOfCycle: 23
        ),
        Devotional(
            title: "The Good Steward's Reward",
            verse: "His master replied, 'Well done, good and faithful servant! You have been faithful with a few things; I will put you in charge of many things. Come and share your master's happiness!'",
            verseReference: "Matthew 25:21",
            reflection: "One day, we'll give an account of how we managed what God entrusted to us. The goal isn't perfection — it's faithfulness. God doesn't expect you to be a financial genius; He expects you to be a faithful steward. Use what you have wisely, give generously, plan carefully, and trust completely. The reward for faithfulness isn't just more stuff — it's sharing in the Master's happiness.",
            prayerPrompt: "Lord, I want to hear 'Well done, good and faithful servant.' Help me steward everything You've given me with faithfulness and joy.",
            category: .stewardship,
            dayOfCycle: 24
        ),
        Devotional(
            title: "Sowing and Reaping",
            verse: "Remember this: Whoever sows sparingly will also reap sparingly, and whoever sows generously will also reap generously.",
            verseReference: "2 Corinthians 9:6",
            reflection: "Farming teaches us about generosity. A farmer who plants few seeds gets a small harvest. A farmer who plants abundantly gets an abundant harvest. Our giving works the same way. This isn't about manipulating God for a return — it's about a spiritual principle woven into creation. When we sow generously with our time, talent, and treasure, we position ourselves to experience God's generous harvest in our lives.",
            prayerPrompt: "God, help me sow generously in every area of my life. Give me faith to plant seeds of generosity, trusting You for the harvest.",
            category: .generosity,
            dayOfCycle: 25
        ),
        Devotional(
            title: "Freedom from Comparison",
            verse: "Each one should test their own actions. Then they can take pride in themselves alone, without comparing themselves to someone else.",
            verseReference: "Galatians 6:4",
            reflection: "Comparison is the thief of contentment and the enemy of wise stewardship. When we compare our finances to others, we either become prideful or envious — both are destructive. Your financial journey is between you and God. Someone else's income, home, or lifestyle has no bearing on your faithfulness. Run your own race, steward your own resources, and celebrate your own progress.",
            prayerPrompt: "Father, free me from the trap of financial comparison. Help me focus on my own journey and celebrate the progress You're making in my life.",
            category: .contentment,
            dayOfCycle: 26
        ),
        Devotional(
            title: "Teaching the Next Generation",
            verse: "Start children off on the way they should go, and even when they are old they will not turn from it.",
            verseReference: "Proverbs 22:6",
            reflection: "One of the greatest gifts you can give the next generation is a model of faithful stewardship. When children see parents tithing, budgeting, giving generously, and trusting God with finances, it shapes their entire relationship with money. Your financial faithfulness today is an investment in generations to come. Every tithe you give, every budget you keep, every debt you pay off — your children are watching and learning.",
            prayerPrompt: "Lord, help me model faithful stewardship for the next generation. Let my financial decisions teach my family to trust You.",
            category: .wisdom,
            dayOfCycle: 27
        ),
        Devotional(
            title: "Generosity as Worship",
            verse: "Through Jesus, therefore, let us continually offer to God a sacrifice of praise — the fruit of lips that openly profess his name. And do not forget to do good and to share with others, for with such sacrifices God is pleased.",
            verseReference: "Hebrews 13:15-16",
            reflection: "Sharing with others is described as a sacrifice that pleases God — it's an act of worship just as meaningful as singing praise songs. When you write a tithe check, tap Apple Pay to give, or hand cash to someone in need, you are worshiping. Your generosity is a fragrant offering that rises to God like incense. Don't separate your financial life from your worship life — they are deeply connected.",
            prayerPrompt: "God, help me see every act of generosity as worship. May my giving be a fragrant offering that brings You joy.",
            category: .generosity,
            dayOfCycle: 28
        ),

        // MARK: - Days 29-30: Renewal and Commitment

        Devotional(
            title: "Renewing Your Mind About Money",
            verse: "Do not conform to the pattern of this world, but be transformed by the renewing of your mind. Then you will be able to test and approve what God's will is — his good, pleasing and perfect will.",
            verseReference: "Romans 12:2",
            reflection: "The world's financial advice often conflicts with God's principles. The world says hoard; God says give. The world says you earned it; God says He provided it. The world says more is better; God says enough is blessing. Renewing your mind about money means replacing worldly financial thinking with biblical truth. It's a daily process of choosing God's wisdom over culture's demands.",
            prayerPrompt: "Lord, renew my mind about money. Replace every worldly belief about finances with Your truth. Transform how I think, earn, spend, save, and give.",
            category: .wisdom,
            dayOfCycle: 29
        ),
        Devotional(
            title: "A Fresh Commitment",
            verse: "Commit to the LORD whatever you do, and he will establish your plans.",
            verseReference: "Proverbs 16:3",
            reflection: "As this devotional cycle comes to a close, it's time for a fresh commitment. Not a commitment born of guilt or obligation, but one born of gratitude and love. God has been faithful to you — in provision, in patience, in grace. Today, recommit your finances to Him. Whether you're just starting your tithing journey or you've been faithful for years, there's always room to grow in trust and generosity.",
            prayerPrompt: "Father, I recommit my finances to You today. Everything I have is Yours. Guide my earning, spending, saving, and giving. I trust You completely.",
            category: .stewardship,
            dayOfCycle: 30
        ),
    ]
}
