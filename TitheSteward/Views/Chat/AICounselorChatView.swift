import SwiftUI
import SwiftData

struct AICounselorChatView: View {
    @StateObject private var viewModel = CounselorViewModel()
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Welcome header
                        if viewModel.messages.isEmpty {
                            welcomeHeader
                            suggestedQuestions
                        }

                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }

                        if viewModel.isLoading {
                            HStack {
                                TypingIndicator()
                                Spacer()
                            }
                            .padding(.horizontal)
                            .id("typing")
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    withAnimation {
                        proxy.scrollTo(viewModel.messages.last?.id ?? "typing", anchor: .bottom)
                    }
                }
            }

            Divider()

            // Input bar
            HStack(spacing: 12) {
                TextField("Ask about stewardship...", text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .focused($isInputFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)

                Button {
                    Task { await viewModel.sendMessage() }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(
                            viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? .gray : Color("AccentGold")
                        )
                }
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .navigationTitle("AI Counselor")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        viewModel.startNewChat()
                    } label: {
                        Label("New Chat", systemImage: "plus.bubble")
                    }

                    if viewModel.hasHistory {
                        Button {
                            viewModel.showingHistory = true
                        } label: {
                            Label("Chat History", systemImage: "clock.arrow.circlepath")
                        }
                    }

                    if !viewModel.messages.isEmpty {
                        Divider()

                        Button(role: .destructive) {
                            viewModel.clearChat()
                        } label: {
                            Label("Delete Chat", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
        .onAppear {
            viewModel.configure(modelContext: modelContext)
        }
        .sheet(isPresented: $viewModel.showingHistory) {
            ChatHistorySheet(viewModel: viewModel)
        }
    }

    var welcomeHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 50))
                .foregroundColor(Color("AccentGold"))

            Text("Stewardship Counselor")
                .font(.title2.bold())

            Text("Scripture-based guidance for your financial journey. Ask about tithing, budgeting, debt freedom, or generous living.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("\"If any of you lacks wisdom, you should ask God, who gives generously to all.\"")
                .font(.caption.italic())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Text("— James 1:5")
                .font(.caption2)
                .foregroundColor(.secondary)

            if viewModel.hasHistory {
                Button {
                    viewModel.showingHistory = true
                } label: {
                    Label("View Past Conversations", systemImage: "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundColor(Color("AccentGold"))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color("AccentGold").opacity(0.1))
                        .cornerRadius(16)
                }
            }
        }
        .padding(.vertical, 24)
    }

    var suggestedQuestions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Try asking:")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.suggestedQuestions, id: \.self) { question in
                        Button {
                            Task { await viewModel.sendSuggestedQuestion(question) }
                        } label: {
                            Text(question)
                                .font(.caption)
                                .foregroundColor(Color("AccentGold"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color("AccentGold").opacity(0.1))
                                .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Chat History Sheet

struct ChatHistorySheet: View {
    @ObservedObject var viewModel: CounselorViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                if viewModel.sessions.isEmpty {
                    ContentUnavailableView(
                        "No Conversations Yet",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Your chat history will appear here.")
                    )
                } else {
                    ForEach(viewModel.sessions) { session in
                        Button {
                            viewModel.loadSession(session)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.title)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                HStack {
                                    Text(session.updatedAt, style: .relative)
                                    Text("·")
                                    Text("\(session.messages.count) messages")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            viewModel.deleteSession(viewModel.sessions[index])
                        }
                    }
                }
            }
            .navigationTitle("Chat History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(isUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isUser ? Color("AccentGold") : Color(.systemGray6))
                    .cornerRadius(20)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !isUser { Spacer(minLength: 60) }
        }
        .padding(.horizontal)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var dotCount = 0
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color(.systemGray3))
                    .frame(width: 8, height: 8)
                    .opacity(dotCount % 3 == index ? 1 : 0.4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(20)
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                dotCount += 1
            }
        }
    }
}

#Preview {
    NavigationStack {
        AICounselorChatView()
    }
}
