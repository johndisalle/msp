import SwiftUI
import SwiftData

struct GivingPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var plan: GivingPlanService.GivingPlan?
    @State private var aiNarrative: String?
    @State private var isLoadingAI = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let plan = plan {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "map.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color("AccentGold"))

                        Text("Your Giving Plan")
                            .font(.title2.bold())

                        Text(plan.encouragement)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        if plan.estimatedMonthsToFullTithe > 0 {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(Color("AccentGold"))
                                Text("~\(plan.estimatedMonthsToFullTithe) months to full tithe")
                                    .font(.subheadline.bold())
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color("AccentGold").opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)

                    // Progress bar
                    VStack(spacing: 8) {
                        HStack {
                            Text("Currently: \(String(format: "%.1f%%", plan.startingPercentage))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Goal: \(String(format: "%.0f%%", plan.targetPercentage))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 12)

                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color("AccentGold"))
                                    .frame(width: geometry.size.width * min(1, plan.startingPercentage / plan.targetPercentage), height: 12)
                            }
                        }
                        .frame(height: 12)
                    }
                    .cardStyle()
                    .padding(.horizontal)

                    // Phases
                    ForEach(Array(plan.phases.enumerated()), id: \.element.id) { index, phase in
                        PhaseCard(phase: phase, phaseNumber: index + 1)
                            .padding(.horizontal)
                    }

                    // AI Narrative
                    if let narrative = aiNarrative {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(Color("AccentGold"))
                                Text("AI-Powered Insight")
                                    .font(.headline)
                            }

                            Text(narrative)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        .cardStyle()
                        .padding(.horizontal)
                    } else {
                        Button {
                            generateAINarrative()
                        } label: {
                            HStack {
                                if isLoadingAI {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text("Get AI-Powered Plan Insight")
                            }
                            .accentButtonStyle()
                        }
                        .disabled(isLoadingAI)
                        .padding(.horizontal)
                    }

                    // Scripture
                    VStack(spacing: 4) {
                        Text(plan.verse)
                            .font(.caption.italic())
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Giving Plan")
        .onAppear { loadPlan() }
    }

    private func loadPlan() {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = (try? modelContext.fetch(descriptor))?.first else { return }

        let service = GivingPlanService(modelContext: modelContext)
        plan = service.generatePlan(for: profile)
    }

    private func generateAINarrative() {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = (try? modelContext.fetch(descriptor))?.first else { return }

        isLoadingAI = true
        let service = GivingPlanService(modelContext: modelContext)
        let prompt = service.buildPlanPrompt(for: profile)

        let counselor = AICounselorService()
        counselor.configure(modelContext: modelContext)

        Task {
            // Use the counselor's API to generate the narrative
            await counselor.sendMessage("Based on my financial data, please give me a personalized giving plan. \(prompt)")
            if let lastMessage = counselor.messages.last, lastMessage.role == .assistant {
                aiNarrative = lastMessage.content
            }
            isLoadingAI = false
        }
    }
}

// MARK: - Phase Card

struct PhaseCard: View {
    let phase: GivingPlanService.Phase
    let phaseNumber: Int

    var statusColor: Color {
        if phase.isComplete { return .green }
        if phase.isCurrent { return Color("AccentGold") }
        return .secondary
    }

    var statusIcon: String {
        if phase.isComplete { return "checkmark.circle.fill" }
        if phase.isCurrent { return "arrow.right.circle.fill" }
        return "circle"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                VStack(alignment: .leading) {
                    Text(phase.title)
                        .font(.headline)
                    Text(phase.monthRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(String(format: "%.0f%%", phase.targetPercentage))")
                    .font(.title3.bold())
                    .foregroundColor(statusColor)
            }

            if phase.isComplete {
                Label("Completed!", systemImage: "checkmark.seal.fill")
                    .font(.caption.bold())
                    .foregroundColor(.green)
            }

            Text(phase.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(2)

            // Target
            HStack {
                Text("Target:")
                    .font(.caption.bold())
                Text(phase.targetAmount.currencyFormatted + "/month")
                    .font(.caption)
                    .foregroundColor(Color("AccentGold"))
            }

            // Actions
            VStack(alignment: .leading, spacing: 6) {
                ForEach(phase.actions, id: \.self) { action in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: phase.isComplete ? "checkmark.square.fill" : "square")
                            .font(.caption)
                            .foregroundColor(phase.isComplete ? .green : .secondary)
                        Text(action)
                            .font(.caption)
                            .foregroundColor(phase.isComplete ? .secondary : .primary)
                    }
                }
            }

            // Milestone verse
            Text(phase.milestoneVerse)
                .font(.caption2.italic())
                .foregroundColor(.secondary)
        }
        .padding()
        .background(phase.isCurrent ? Color("AccentGold").opacity(0.05) : Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(phase.isCurrent ? Color("AccentGold").opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

#Preview {
    NavigationStack {
        GivingPlanView()
    }
}
