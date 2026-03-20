import Foundation
import SwiftData

@Model
final class ChatSession {
    var createdAt: Date
    var updatedAt: Date
    var title: String
    var messagesData: Data

    var userProfile: UserProfile?

    var messages: [ChatMessage] {
        get {
            (try? JSONDecoder().decode([ChatMessage].self, from: messagesData)) ?? []
        }
        set {
            messagesData = (try? JSONEncoder().encode(newValue)) ?? Data()
            updatedAt = Date()
        }
    }

    init(
        title: String = "New Conversation",
        messages: [ChatMessage] = [],
        createdAt: Date = Date()
    ) {
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.title = title
        self.messagesData = (try? JSONEncoder().encode(messages)) ?? Data()
    }

    func appendMessage(_ message: ChatMessage) {
        var current = messages
        current.append(message)
        messages = current
    }

    /// Generate a title from the first user message
    func generateTitle() {
        if let firstUserMessage = messages.first(where: { $0.role == .user }) {
            let text = firstUserMessage.content
            title = String(text.prefix(40)) + (text.count > 40 ? "..." : "")
        }
    }
}
