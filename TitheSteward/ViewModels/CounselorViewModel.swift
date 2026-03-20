import Foundation
import SwiftData

@MainActor
class CounselorViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var counselorService = AICounselorService()
    @Published var showingHistory = false

    func configure(modelContext: ModelContext) {
        counselorService.configure(modelContext: modelContext)
    }

    var messages: [ChatMessage] {
        counselorService.messages
    }

    var isLoading: Bool {
        counselorService.isLoading
    }

    var sessions: [ChatSession] {
        counselorService.sessions
    }

    var hasHistory: Bool {
        !sessions.isEmpty
    }

    var suggestedQuestions: [String] {
        [
            "How should I start tithing if I'm in debt?",
            "What does the Bible say about budgeting?",
            "How can I teach my kids about generosity?",
            "I feel anxious about my finances. What should I do?",
            "Is tithing still relevant for Christians today?",
            "How do I create a biblical budget?",
        ]
    }

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        await counselorService.sendMessage(text)
        objectWillChange.send()
    }

    func sendSuggestedQuestion(_ question: String) async {
        inputText = ""
        await counselorService.sendMessage(question)
        objectWillChange.send()
    }

    func startNewChat() {
        counselorService.startNewSession()
        objectWillChange.send()
    }

    func loadSession(_ session: ChatSession) {
        counselorService.loadSession(session)
        showingHistory = false
        objectWillChange.send()
    }

    func deleteSession(_ session: ChatSession) {
        counselorService.deleteSession(session)
        objectWillChange.send()
    }

    func clearChat() {
        counselorService.clearChat()
        objectWillChange.send()
    }
}
