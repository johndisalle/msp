import SwiftUI

struct DebtDashboardView: View {
    @StateObject private var debtService = DebtService()
    @State private var showingAddDebt = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overall Progress
                VStack(spacing: 12) {
                    HStack {
                        Text("Debt Freedom Progress")
                            .font(.headline)
                        Spacer()
                    }

                    if debtService.debts.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 40))
                                .foregroundColor(Color("AccentGold"))

                            Text("No debts tracked yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("Add your debts to create a biblical plan for financial freedom")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 24)
                    } else {
                        // Progress circle
                        ZStack {
                            Circle()
                                .stroke(Color(.systemGray5), lineWidth: 10)
                                .frame(width: 120, height: 120)

                            Circle()
                                .trim(from: 0, to: debtService.overallProgress)
                                .stroke(Color.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))

                            VStack {
                                Text("\(Int(debtService.overallProgress * 100))%")
                                    .font(.title2.bold())
                                Text("Free")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack(spacing: 20) {
                            VStack {
                                Text(formatCurrency(debtService.totalDebt))
                                    .font(.headline)
                                    .foregroundColor(.red)
                                Text("Remaining")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                Text(formatCurrency(debtService.totalMinimumPayments))
                                    .font(.headline)
                                Text("Min/Month")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                .padding(.horizontal)

                // Snowball Order
                if !debtService.debts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Debt Snowball Order")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                        }

                        Text("Pay minimums on all, then attack the smallest balance first")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        ForEach(Array(debtService.snowballOrder().enumerated()), id: \.element.id) { index, debt in
                            HStack {
                                Text("#\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                                    .background(index == 0 ? Color("AccentGold") : Color(.systemGray4))
                                    .clipShape(Circle())

                                Image(systemName: debt.type.icon)
                                    .foregroundColor(Color("AccentGold"))

                                VStack(alignment: .leading) {
                                    Text(debt.name)
                                        .font(.subheadline)
                                    Text(formatCurrency(debt.currentBalance))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                // Progress bar
                                VStack(alignment: .trailing) {
                                    Text("\(Int(debt.percentPaid * 100))%")
                                        .font(.caption2.bold())
                                        .foregroundColor(.green)

                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(Color(.systemGray5))
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(Color.green)
                                                .frame(width: geo.size.width * debt.percentPaid)
                                        }
                                    }
                                    .frame(width: 60, height: 6)
                                }
                            }
                            .padding(.vertical, 4)

                            if index == 0 {
                                Text(debt.type.encouragementVerse)
                                    .font(.caption.italic())
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 36)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                    .padding(.horizontal)
                }

                // Scripture
                VStack(spacing: 8) {
                    Text("\"The rich rule over the poor, and the borrower is slave to the lender.\"")
                        .font(.callout.italic())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Text("— Proverbs 22:7")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Freedom is coming. Stay faithful.")
                        .font(.caption.bold())
                        .foregroundColor(Color("AccentGold"))
                }
                .padding()
            }
            .padding(.vertical)
        }
        .navigationTitle("Debt Freedom")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddDebt = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color("AccentGold"))
                }
            }
        }
        .sheet(isPresented: $showingAddDebt) {
            AddDebtSheet(debtService: debtService)
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

struct AddDebtSheet: View {
    @ObservedObject var debtService: DebtService
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var balance = ""
    @State private var interestRate = ""
    @State private var minimumPayment = ""
    @State private var type: DebtType = .creditCard

    var body: some View {
        NavigationStack {
            Form {
                Section("Debt Info") {
                    TextField("Name (e.g., Chase Visa)", text: $name)

                    Picker("Type", selection: $type) {
                        ForEach(DebtType.allCases, id: \.self) { debtType in
                            Label(debtType.rawValue, systemImage: debtType.icon).tag(debtType)
                        }
                    }
                }

                Section("Amounts") {
                    HStack {
                        Text("Balance $")
                        TextField("0", text: $balance)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Interest Rate %")
                        TextField("0", text: $interestRate)
                            .keyboardType(.decimalPad)
                    }
                    HStack {
                        Text("Min Payment $")
                        TextField("0", text: $minimumPayment)
                            .keyboardType(.decimalPad)
                    }
                }

                Section {
                    Text(type.encouragementVerse)
                        .font(.caption.italic())
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Debt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let bal = Double(balance) ?? 0
                        let debt = DebtItem(
                            name: name,
                            originalBalance: bal,
                            currentBalance: bal,
                            interestRate: Double(interestRate) ?? 0,
                            minimumPayment: Double(minimumPayment) ?? 0,
                            type: type
                        )
                        debtService.addDebt(debt)
                        dismiss()
                    }
                    .disabled(name.isEmpty || balance.isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DebtDashboardView()
    }
}
