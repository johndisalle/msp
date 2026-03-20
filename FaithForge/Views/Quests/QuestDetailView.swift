// QuestDetailView.swift
// FaithForge
//
// Detail/completion sheet for a quest. Handles timer, reflection, check-in, and quick-log types.

import SwiftUI

struct QuestDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var quest: DailyQuest
    @Bindable var profile: UserProfile
    @Bindable var questManager: QuestManager
    @Bindable var xpManager: XPManager

    @State private var reflectionText: String = ""
    @State private var timerRemaining: Int = 0
    @State private var timerActive: Bool = false
    @State private var showCompletion: Bool = false
    @State private var xpEarned: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Quest Header
                    headerSection

                    // Interaction Area
                    if quest.isCompleted {
                        completedBanner
                    } else {
                        interactionSection
                    }
                }
                .padding(16)
            }
            .background(Color("BackgroundPrimary"))
            .navigationTitle("Quest")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay {
                if showCompletion {
                    completionOverlay
                }
            }
            .onAppear {
                timerRemaining = quest.timerDuration
                reflectionText = quest.reflectionText
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: quest.category.icon)
                .font(.system(size: 48))
                .foregroundStyle(categoryColor)
                .frame(width: 80, height: 80)
                .background(categoryColor.opacity(0.15))
                .clipShape(Circle())

            VStack(spacing: 6) {
                Text(quest.title)
                    .font(.title2.bold())
                    .foregroundStyle(Color("TextPrimary"))
                    .multilineTextAlignment(.center)

                Text(quest.questDescription)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 16) {
                Label(quest.category.rawValue, systemImage: quest.category.icon)
                Label(quest.type.rawValue, systemImage: quest.type.icon)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text("+\(quest.xpReward) XP")
                .font(.headline)
                .foregroundStyle(Color("FaithGold"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color("FaithGold").opacity(0.15))
                .clipShape(Capsule())
        }
        .faithCard()
    }

    // MARK: - Interaction Section (varies by quest type)

    @ViewBuilder
    private var interactionSection: some View {
        switch quest.type {
        case .timer:
            timerView
        case .reflection:
            reflectionView
        case .checkIn:
            checkInView
        case .quickLog:
            quickLogView
        }
    }

    // MARK: Timer View

    private var timerView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 180, height: 180)

                Circle()
                    .trim(from: 0, to: timerProgress)
                    .stroke(categoryColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 180, height: 180)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: timerRemaining)

                VStack(spacing: 4) {
                    Text(timerRemaining.timerFormatted)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("TextPrimary"))
                        .contentTransition(.numericText())

                    Text(timerActive ? "In Progress" : "Ready")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 16) {
                if timerActive {
                    Button("Pause") {
                        timerActive = false
                    }
                    .buttonStyle(.bordered)

                    Button("Complete Early") {
                        completeQuest()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("FaithGreen"))
                } else if timerRemaining > 0 && timerRemaining < quest.timerDuration {
                    Button("Resume") {
                        timerActive = true
                        startTimer()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(categoryColor)
                } else if timerRemaining <= 0 {
                    Button("Complete Quest") {
                        completeQuest()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("FaithGreen"))
                } else {
                    Button("Start Timer") {
                        timerActive = true
                        startTimer()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(categoryColor)
                }
            }
            .font(.headline)
        }
        .faithCard()
    }

    private var timerProgress: CGFloat {
        guard quest.timerDuration > 0 else { return 0 }
        return 1.0 - CGFloat(timerRemaining) / CGFloat(quest.timerDuration)
    }

    private func startTimer() {
        Task {
            while timerActive && timerRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                if timerActive {
                    timerRemaining -= 1
                    if timerRemaining <= 0 {
                        timerActive = false
                    }
                }
            }
        }
    }

    // MARK: Reflection View

    private var reflectionView: some View {
        VStack(spacing: 16) {
            Text("Write your reflection:")
                .font(.headline)
                .foregroundStyle(Color("TextPrimary"))
                .frame(maxWidth: .infinity, alignment: .leading)

            TextEditor(text: $reflectionText)
                .frame(minHeight: 150)
                .padding(8)
                .background(Color("BackgroundPrimary"))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            Button {
                completeQuest()
            } label: {
                Text("Submit Reflection")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("FaithGreen"))
            .disabled(reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .faithCard()
    }

    // MARK: Check-In View

    private var checkInView: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.thumbsup.fill")
                .font(.system(size: 44))
                .foregroundStyle(categoryColor)

            Text("Tap to confirm you've completed this quest.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                completeQuest()
            } label: {
                Text("Check In")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("FaithGreen"))
        }
        .faithCard()
    }

    // MARK: Quick Log View

    private var quickLogView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 44))
                .foregroundStyle(Color("FaithGold"))

            Text("Quick log — one tap and you're done!")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                completeQuest()
            } label: {
                Text("Log It!")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("FaithGold"))
        }
        .faithCard()
    }

    // MARK: - Completed Banner

    private var completedBanner: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color("FaithGreen"))

            Text("Quest Completed!")
                .font(.title3.bold())
                .foregroundStyle(Color("FaithGreen"))

            if !quest.reflectionText.isEmpty {
                Text(quest.reflectionText)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .faithCard()
    }

    // MARK: - Completion Overlay

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "star.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color("FaithGold"))
                    .symbolEffect(.bounce)

                Text("+\(xpEarned) XP!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color("FaithGold"))

                Text("Well done, faithful servant!")
                    .font(.body)
                    .foregroundStyle(.white)

                Button("Continue") {
                    showCompletion = false
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("FaithGreen"))
            }
            .padding(32)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .padding(32)
        }
        .transition(.opacity)
    }

    // MARK: - Complete Quest Action

    private func completeQuest() {
        let xp = questManager.completeQuest(quest, reflectionText: reflectionText)
        xpManager.awardXP(amount: xp, questCategory: quest.category, profile: profile)
        xpEarned = xp
        withAnimation {
            showCompletion = true
        }
    }

    private var categoryColor: Color {
        switch quest.category {
        case .theWord:   return Color("FaithBlue")
        case .prayer:    return Color("FaithGold")
        case .mission:   return Color("FaithWarm")
        case .restInGod: return Color("FaithGreen")
        }
    }
}
