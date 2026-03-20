// AIQuestSettingsView.swift
// FaithForge
//
// Settings screen for AI quest generation: API key, model, preferences.

import SwiftUI

struct AIQuestSettingsView: View {
    @Bindable var aiService: AIQuestService
    @Bindable var profile: UserProfile

    @State private var showAPIKeyField = false

    var body: some View {
        Form {
            // Status
            Section {
                HStack {
                    Label("AI Quests", systemImage: "sparkles")
                    Spacer()
                    Text(aiService.isEnabled ? "Active" : "Inactive")
                        .font(.subheadline)
                        .foregroundStyle(aiService.isEnabled ? Color("FaithGreen") : .secondary)
                }

                if aiService.isGenerating {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Generating quests...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                if let error = aiService.lastError {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("Status")
            } footer: {
                Text("When enabled, FaithForge generates personalized quests using AI based on your faith assessment and progress. Requires an API key.")
            }

            // API Configuration
            Section("API Configuration") {
                Button {
                    showAPIKeyField.toggle()
                } label: {
                    HStack {
                        Label("API Key", systemImage: "key.fill")
                        Spacer()
                        Text(aiService.apiKey.isEmpty ? "Not set" : "••••••••")
                            .foregroundStyle(.secondary)
                    }
                }

                if showAPIKeyField {
                    SecureField("Enter API Key", text: $aiService.apiKey)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                Picker("Model", selection: $aiService.modelID) {
                    Text("Claude Sonnet").tag("claude-sonnet-4-20250514")
                    Text("Claude Haiku").tag("claude-haiku-4-5-20251001")
                    Text("Claude Opus").tag("claude-opus-4-20250514")
                }
            }

            // Quest Preferences
            Section("Quest Preferences") {
                // Daily goal affects quest count
                Picker("Daily Intensity", selection: Binding(
                    get: { profile.dailyGoal },
                    set: { profile.dailyGoal = $0 }
                )) {
                    ForEach(DailyGoalIntensity.allCases, id: \.rawValue) { intensity in
                        Text("\(intensity.rawValue) (\(intensity.questCount) quests)")
                            .tag(intensity)
                    }
                }

                // Weak areas (tap to toggle)
                NavigationLink {
                    weakAreasEditor
                } label: {
                    HStack {
                        Label("Focus Areas", systemImage: "target")
                        Spacer()
                        Text("\(profile.weakAreas.count) selected")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Info
            Section("About AI Quests") {
                infoRow(icon: "brain", title: "Personalized", detail: "Quests adapt to your weak areas and growth")
                infoRow(icon: "wifi.slash", title: "Offline Fallback", detail: "Hardcoded quests used when AI is unavailable")
                infoRow(icon: "lock.shield", title: "Private", detail: "Your data stays on-device; only anonymized context sent to AI")
                infoRow(icon: "arrow.triangle.2.circlepath", title: "Variety", detail: "AI avoids repeating recent quests")
            }
        }
        .navigationTitle("AI Quests")
    }

    // MARK: - Weak Areas Editor

    private var weakAreasEditor: some View {
        List {
            ForEach(FaithCategory.allCases) { category in
                let isSelected = profile.weakAreas.contains(category.rawValue)
                Button {
                    if isSelected {
                        profile.weakAreas.removeAll { $0 == category.rawValue }
                    } else {
                        profile.weakAreas.append(category.rawValue)
                    }
                } label: {
                    HStack {
                        Label(category.rawValue, systemImage: category.icon)
                            .foregroundStyle(Color("TextPrimary"))
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color("FaithBlue"))
                        }
                    }
                }
            }
        }
        .navigationTitle("Focus Areas")
    }

    // MARK: - Info Row

    private func infoRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Color("FaithBlue"))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color("TextPrimary"))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
