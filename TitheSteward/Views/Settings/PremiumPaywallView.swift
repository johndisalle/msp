import SwiftUI

struct PremiumPaywallView: View {
    @StateObject private var storeService = StoreKitService()
    @Environment(\.dismiss) var dismiss
    @State private var selectedPlan: PremiumPlan = .yearly

    enum PremiumPlan {
        case monthly, yearly
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Color("AccentGold"))

                        Text("Tithe Steward Premium")
                            .font(.title.bold())

                        Text("Unlock the full stewardship experience")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Features List
                    VStack(alignment: .leading, spacing: 16) {
                        PremiumFeatureRow(icon: "bell.badge.fill", title: "Auto-Tithe Setup", description: "Smart reminders and allocation before paydays")
                        PremiumFeatureRow(icon: "chart.line.downtrend.xyaxis", title: "Debt Snowball Tools", description: "Biblical debt-free plan with Proverbs motivation")
                        PremiumFeatureRow(icon: "bubble.left.and.bubble.right.fill", title: "AI Counselor", description: "Scripture-based financial guidance and prayer")
                        PremiumFeatureRow(icon: "trophy.fill", title: "Generosity Badges", description: "Celebrate milestones with shareable achievements")
                        PremiumFeatureRow(icon: "arrow.triangle.2.circlepath", title: "Recurring Giving", description: "Schedule automatic Apple Pay donations")
                        PremiumFeatureRow(icon: "chart.bar.fill", title: "Advanced Reports", description: "Trends, projections, and Scripture overlays")
                        PremiumFeatureRow(icon: "rectangle.3.group.fill", title: "Premium Widgets", description: "Generosity streak & debt freedom progress")
                    }
                    .padding(.horizontal)

                    // Plan Selection
                    VStack(spacing: 12) {
                        // Yearly Plan
                        Button {
                            selectedPlan = .yearly
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text("Annual")
                                            .font(.headline)
                                        Text("SAVE 17%")
                                            .font(.caption2.bold())
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(Color.green)
                                            .clipShape(Capsule())
                                    }
                                    Text("$99.99/year ($8.33/mo)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: selectedPlan == .yearly ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedPlan == .yearly ? Color("AccentGold") : .secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedPlan == .yearly ? Color("AccentGold").opacity(0.1) : Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedPlan == .yearly ? Color("AccentGold") : .clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)

                        // Monthly Plan
                        Button {
                            selectedPlan = .monthly
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Monthly")
                                        .font(.headline)
                                    Text("$9.99/month")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: selectedPlan == .monthly ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedPlan == .monthly ? Color("AccentGold") : .secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedPlan == .monthly ? Color("AccentGold").opacity(0.1) : Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedPlan == .monthly ? Color("AccentGold") : .clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    // Subscribe Button
                    Button {
                        Task {
                            let product = selectedPlan == .yearly ? storeService.yearlyProduct : storeService.monthlyProduct
                            if let product = product {
                                _ = try? await storeService.purchase(product)
                            }
                        }
                    } label: {
                        Text("Start Premium")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("AccentGold"))
                            .cornerRadius(14)
                    }
                    .padding(.horizontal)

                    // Restore & Terms
                    VStack(spacing: 8) {
                        Button("Restore Purchases") {
                            Task { await storeService.restorePurchases() }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)

                        Text("Cancel anytime. Subscription auto-renews.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    // Scripture
                    VStack(spacing: 4) {
                        Text("\"Give, and it will be given to you. A good measure, pressed down, shaken together and running over.\"")
                            .font(.caption.italic())
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Text("— Luke 6:38")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color("AccentGold"))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    PremiumPaywallView()
}
