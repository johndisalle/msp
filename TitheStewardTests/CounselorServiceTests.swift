import XCTest
import SwiftData
@testable import TitheSteward

@MainActor
final class CounselorServiceTests: XCTestCase {
    var modelContext: ModelContext!
    var profile: UserProfile!

    override func setUp() async throws {
        let schema = Schema([
            UserProfile.self, TitheRecord.self, BudgetCategory.self,
            BudgetTransaction.self, DebtItem.self, DebtPayment.self,
            DevotionalCompletion.self, GivingRecipient.self, RecurringGift.self, ChatSession.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        modelContext = container.mainContext

        profile = UserProfile(
            displayName: "Test User",
            monthlyIncome: 5000
        )
        modelContext.insert(profile)
        try modelContext.save()
    }

    // MARK: - ChatSession Model

    func testChatSessionInit() {
        let session = ChatSession(title: "Test Chat")
        XCTAssertEqual(session.title, "Test Chat")
        XCTAssertTrue(session.messages.isEmpty)
    }

    func testChatSessionAppendMessage() {
        let session = ChatSession()
        let msg = ChatMessage(role: .user, content: "Hello")
        session.appendMessage(msg)

        XCTAssertEqual(session.messages.count, 1)
        XCTAssertEqual(session.messages.first?.content, "Hello")
        XCTAssertEqual(session.messages.first?.role, .user)
    }

    func testChatSessionMultipleMessages() {
        let session = ChatSession()
        session.appendMessage(ChatMessage(role: .user, content: "Q1"))
        session.appendMessage(ChatMessage(role: .assistant, content: "A1"))
        session.appendMessage(ChatMessage(role: .user, content: "Q2"))

        XCTAssertEqual(session.messages.count, 3)
        XCTAssertEqual(session.messages[0].role, .user)
        XCTAssertEqual(session.messages[1].role, .assistant)
        XCTAssertEqual(session.messages[2].content, "Q2")
    }

    func testChatSessionGenerateTitle() {
        let session = ChatSession()
        session.appendMessage(ChatMessage(role: .user, content: "How should I start tithing?"))
        session.generateTitle()

        XCTAssertEqual(session.title, "How should I start tithing?")
    }

    func testChatSessionGenerateTitleTruncatesLong() {
        let session = ChatSession()
        let longMessage = String(repeating: "a", count: 60)
        session.appendMessage(ChatMessage(role: .user, content: longMessage))
        session.generateTitle()

        XCTAssertTrue(session.title.count <= 43) // 40 chars + "..."
        XCTAssertTrue(session.title.hasSuffix("..."))
    }

    func testChatSessionUpdatesTimestamp() {
        let session = ChatSession()
        let originalUpdate = session.updatedAt

        // Small delay to ensure different timestamp
        session.appendMessage(ChatMessage(role: .user, content: "test"))

        XCTAssertTrue(session.updatedAt >= originalUpdate)
    }

    // MARK: - ChatSession Persistence

    func testChatSessionPersistsToSwiftData() {
        let session = ChatSession(title: "Persisted Chat")
        session.userProfile = profile
        session.appendMessage(ChatMessage(role: .user, content: "Saved message"))
        modelContext.insert(session)
        try? modelContext.save()

        let descriptor = FetchDescriptor<ChatSession>()
        let fetched = (try? modelContext.fetch(descriptor)) ?? []

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Persisted Chat")
        XCTAssertEqual(fetched.first?.messages.count, 1)
        XCTAssertEqual(fetched.first?.messages.first?.content, "Saved message")
    }

    func testChatSessionDeleteFromSwiftData() {
        let session = ChatSession(title: "To Delete")
        modelContext.insert(session)
        try? modelContext.save()

        modelContext.delete(session)
        try? modelContext.save()

        let descriptor = FetchDescriptor<ChatSession>()
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        XCTAssertEqual(fetched.count, 0)
    }

    func testMultipleSessionsPersist() {
        let s1 = ChatSession(title: "Chat 1")
        let s2 = ChatSession(title: "Chat 2")
        let s3 = ChatSession(title: "Chat 3")
        modelContext.insert(s1)
        modelContext.insert(s2)
        modelContext.insert(s3)
        try? modelContext.save()

        let descriptor = FetchDescriptor<ChatSession>()
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        XCTAssertEqual(fetched.count, 3)
    }

    // MARK: - AICounselorService Session Management

    func testServiceStartNewSession() {
        let service = AICounselorService()
        service.configure(modelContext: modelContext)

        service.startNewSession()

        XCTAssertNotNil(service.currentSession)
        XCTAssertTrue(service.messages.isEmpty)
        XCTAssertEqual(service.sessions.count, 1)
    }

    func testServiceLoadSession() {
        let service = AICounselorService()
        service.configure(modelContext: modelContext)

        // Create a session with messages
        let session = ChatSession(title: "Old Chat")
        session.appendMessage(ChatMessage(role: .user, content: "Previous Q"))
        session.appendMessage(ChatMessage(role: .assistant, content: "Previous A"))
        session.userProfile = profile
        modelContext.insert(session)
        try? modelContext.save()

        service.loadSessions()
        service.loadSession(service.sessions.first!)

        XCTAssertEqual(service.messages.count, 2)
        XCTAssertEqual(service.messages.first?.content, "Previous Q")
        XCTAssertEqual(service.currentSession?.title, "Old Chat")
    }

    func testServiceDeleteSession() {
        let service = AICounselorService()
        service.configure(modelContext: modelContext)

        service.startNewSession()
        XCTAssertEqual(service.sessions.count, 1)

        let session = service.currentSession!
        service.deleteSession(session)

        XCTAssertNil(service.currentSession)
        XCTAssertTrue(service.messages.isEmpty)
        XCTAssertEqual(service.sessions.count, 0)
    }

    func testServiceClearChat() {
        let service = AICounselorService()
        service.configure(modelContext: modelContext)

        service.startNewSession()
        service.currentSession?.appendMessage(ChatMessage(role: .user, content: "test"))
        try? modelContext.save()

        service.clearChat()

        XCTAssertNil(service.currentSession)
        XCTAssertTrue(service.messages.isEmpty)
        XCTAssertEqual(service.sessions.count, 0)
    }

    func testServiceMultipleSessions() {
        let service = AICounselorService()
        service.configure(modelContext: modelContext)

        // Create first session
        service.startNewSession()
        service.currentSession?.appendMessage(ChatMessage(role: .user, content: "First chat"))
        try? modelContext.save()

        // Create second session
        service.startNewSession()
        service.currentSession?.appendMessage(ChatMessage(role: .user, content: "Second chat"))
        try? modelContext.save()

        service.loadSessions()
        XCTAssertEqual(service.sessions.count, 2)
    }

    // MARK: - Personalized Context

    func testBuildPersonalizedPromptIncludesTitheData() {
        let service = AICounselorService()
        service.configure(modelContext: modelContext)

        let prompt = service.buildPersonalizedPrompt()

        XCTAssertTrue(prompt.contains("Monthly income"), "Should include income data")
        XCTAssertTrue(prompt.contains("$5,000"), "Should include formatted income")
        XCTAssertTrue(prompt.contains("Tithe target"), "Should include tithe target")
    }

    func testBuildPersonalizedPromptIncludesDebtData() {
        // Add a debt
        let debt = DebtItem(name: "Car Loan", originalBalance: 10000, currentBalance: 5000, interestRate: 5.0, minimumPayment: 200)
        debt.userProfile = profile
        profile.debts.append(debt)
        modelContext.insert(debt)
        try? modelContext.save()

        let service = AICounselorService()
        service.configure(modelContext: modelContext)

        let prompt = service.buildPersonalizedPrompt()

        XCTAssertTrue(prompt.contains("Debt Status"), "Should include debt section")
        XCTAssertTrue(prompt.contains("Number of debts: 1"), "Should include debt count")
    }

    func testBuildPersonalizedPromptDebtFree() {
        let service = AICounselorService()
        service.configure(modelContext: modelContext)

        let prompt = service.buildPersonalizedPrompt()

        XCTAssertTrue(prompt.contains("Debt-free"), "Should say debt-free when no debts")
    }

    func testBuildPersonalizedPromptWithGiving() {
        // Add a tithe record
        let record = TitheRecord(amount: 250, category: .tithe)
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)
        try? modelContext.save()

        let service = AICounselorService()
        service.configure(modelContext: modelContext)

        let prompt = service.buildPersonalizedPrompt()

        XCTAssertTrue(prompt.contains("Given this month"), "Should include giving data")
        XCTAssertTrue(prompt.contains("50%"), "Should show 50% progress for $250 of $500")
    }

    func testBuildPersonalizedPromptIncludesBudgetData() {
        // Create budget categories
        let budgetService = BudgetService(modelContext: modelContext)
        budgetService.ensureDefaultCategories(for: profile)

        let service = AICounselorService()
        service.configure(modelContext: modelContext)

        let prompt = service.buildPersonalizedPrompt()

        XCTAssertTrue(prompt.contains("Budget Status"), "Should include budget section")
        XCTAssertTrue(prompt.contains("Total budgeted"), "Should include budget total")
    }

    func testBuildPersonalizedPromptIncludesRecurringGiving() {
        let givingService = GivingService(modelContext: modelContext)
        let recipient = GivingRecipient(name: "Church", type: .church)
        givingService.addRecipient(recipient, to: profile)

        let gift = RecurringGift(amount: 500, frequency: .monthly, category: .tithe)
        givingService.addRecurringGift(gift, to: recipient)

        let service = AICounselorService()
        service.configure(modelContext: modelContext)

        let prompt = service.buildPersonalizedPrompt()

        XCTAssertTrue(prompt.contains("Recurring Giving"), "Should include recurring giving")
        XCTAssertTrue(prompt.contains("Active recurring gifts: 1"), "Should show 1 active gift")
    }

    // MARK: - Notification Permission Flow (Logic Only)

    func testFirstRecurringGiftCountDetection() {
        let givingService = GivingService(modelContext: modelContext)
        let recipient = GivingRecipient(name: "Church", type: .church)
        givingService.addRecipient(recipient, to: profile)

        // Before any gifts
        let giftsBeforeAdd = givingService.fetchRecurringGifts().filter { $0.isActive }
        XCTAssertEqual(giftsBeforeAdd.count, 0)

        // Add first gift
        let gift = RecurringGift(amount: 100, frequency: .monthly, category: .tithe)
        givingService.addRecurringGift(gift, to: recipient)

        let giftsAfterFirst = givingService.fetchRecurringGifts().filter { $0.isActive }
        XCTAssertEqual(giftsAfterFirst.count, 1, "First gift should trigger permission request")

        // Add second gift
        let gift2 = RecurringGift(amount: 50, frequency: .weekly, category: .offering)
        givingService.addRecurringGift(gift2, to: recipient)

        let giftsAfterSecond = givingService.fetchRecurringGifts().filter { $0.isActive }
        XCTAssertEqual(giftsAfterSecond.count, 2, "Second gift should NOT trigger permission request")
    }

    func testInactiveGiftDoesNotCountForPermission() {
        let givingService = GivingService(modelContext: modelContext)
        let recipient = GivingRecipient(name: "Church", type: .church)
        givingService.addRecipient(recipient, to: profile)

        // Add inactive gift
        let inactiveGift = RecurringGift(amount: 100, frequency: .monthly, category: .tithe, isActive: false)
        givingService.addRecurringGift(inactiveGift, to: recipient)

        let activeGifts = givingService.fetchRecurringGifts().filter { $0.isActive }
        XCTAssertEqual(activeGifts.count, 0, "Inactive gift should not count")

        // Now add active gift - this should be treated as "first"
        let activeGift = RecurringGift(amount: 200, frequency: .monthly, category: .tithe)
        givingService.addRecurringGift(activeGift, to: recipient)

        let activeGiftsAfter = givingService.fetchRecurringGifts().filter { $0.isActive }
        XCTAssertEqual(activeGiftsAfter.count, 1, "First active gift should trigger permission")
    }
}
