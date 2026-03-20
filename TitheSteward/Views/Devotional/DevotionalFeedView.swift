import SwiftUI

struct DevotionalFeedView: View {
    @StateObject private var viewModel = DevotionalViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Streak Card
                    HStack {
                        Image(systemName: "flame.fill")
                            .font(.title2)
                            .foregroundColor(.orange)

                        VStack(alignment: .leading) {
                            Text("Devotional Streak")
                                .font(.subheadline.bold())
                            Text(viewModel.streakText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if viewModel.isCompletedToday {
                            Label("Done", systemImage: "checkmark.circle.fill")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                    .padding(.horizontal)

                    // Today's Devotional
                    if let devotional = viewModel.todaysDevotional {
                        DevotionalDetailView(devotional: devotional)
                            .padding(.horizontal)
                    }

                    // All Devotionals
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All Stewardship Devotionals")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(viewModel.allDevotionals) { devotional in
                            NavigationLink(destination: DevotionalDetailView(devotional: devotional)) {
                                HStack {
                                    Image(systemName: devotional.category.icon)
                                        .foregroundColor(Color("AccentGold"))
                                        .frame(width: 24)

                                    VStack(alignment: .leading) {
                                        Text(devotional.title)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                        Text(devotional.verseReference)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Devotional")
        }
    }
}

struct DevotionalDetailView: View {
    let devotional: Devotional
    @State private var showingPrayerSheet = false
    @State private var personalNote = ""
    @State private var didPray = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Category badge
            HStack {
                Label(devotional.category.rawValue, systemImage: devotional.category.icon)
                    .font(.caption.bold())
                    .foregroundColor(Color("AccentGold"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color("AccentGold").opacity(0.1))
                    .clipShape(Capsule())

                Spacer()

                Text("Day \(devotional.dayOfCycle)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(devotional.title)
                .font(.title2.bold())

            // Scripture
            VStack(alignment: .leading, spacing: 8) {
                Text("\"\(devotional.verse)\"")
                    .font(.body.italic())
                    .foregroundColor(.secondary)

                Text("— \(devotional.verseReference)")
                    .font(.caption.bold())
                    .foregroundColor(Color("AccentGold"))
            }
            .padding()
            .background(Color("AccentGold").opacity(0.05))
            .cornerRadius(12)

            // Reflection
            Text("Reflection")
                .font(.headline)

            Text(devotional.reflection)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)

            // Prayer Prompt
            VStack(alignment: .leading, spacing: 8) {
                Label("Prayer", systemImage: "hands.sparkles.fill")
                    .font(.headline)
                    .foregroundColor(Color("AccentGold"))

                Text(devotional.prayerPrompt)
                    .font(.body.italic())
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Mark Complete Button
            Button {
                showingPrayerSheet = true
            } label: {
                Label("I've Read & Prayed", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("AccentGold"))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .sheet(isPresented: $showingPrayerSheet) {
            NavigationStack {
                Form {
                    Section("How was your time?") {
                        Toggle("I prayed today", isOn: $didPray)
                    }
                    Section("Personal Reflection") {
                        TextEditor(text: $personalNote)
                            .frame(minHeight: 80)
                    }
                }
                .navigationTitle("Complete Devotional")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            showingPrayerSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

#Preview {
    DevotionalFeedView()
}
