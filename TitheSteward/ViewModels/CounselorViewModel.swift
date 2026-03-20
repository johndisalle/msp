import Foundation

@MainActor
class CounselorViewModel: ObservableObject {
    @Published var inputText = ""
    @Published var counselorService = AICounselorService()

    var messages: [ChatMessage] {
        counselorService.messages
    }

    var isLoading: Bool {
        counselorService.isLoading
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
    }

    func sendSuggestedQuestion(_ question: String) async {
        inputText = ""
        await counselorService.sendMessage(question)
    }

    func clearChat() {
        counselorService.clearChat()
    }
}
