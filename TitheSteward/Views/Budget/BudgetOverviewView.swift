import SwiftUI
import SwiftData

struct BudgetOverviewView: View {
    @StateObject private var viewModel = BudgetViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Budget Summary
                    VStack(spacing: 12) {
                        HStack {
                            Text("Monthly Budget")
                                .font(.headline)
                            Spacer()
                        }

                        HStack(spacing: 24) {
                            VStack {
                                Text(viewModel.totalBudgeted.currencyWhole)
                                    .font(.title3.bold())
                                Text("Budgeted")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                Text(viewModel.totalSpent.currencyWhole)
                                    .font(.title3.bold())
                                    .foregroundColor(viewModel.totalSpent > viewModel.totalBudgeted ? .red : .primary)
                                Text("Spent")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                Text(viewModel.remainingBudget.currencyWhole)
                                    .font(.title3.bold())
                                    .foregroundColor(viewModel.remainingBudget < 0 ? .red : .green)
                                Text("Remaining")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Overall progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 12)

                                RoundedRectangle(cornerRadius: 6)
                                    .fill(viewModel.spendingPercentage > 0.9 ? Color.red : Color("AccentGold"))
                                    .frame(width: geometry.size.width * viewModel.spendingPercentage, height: 12)
                                    .animation(.easeInOut, value: viewModel.spendingPercentage)
                            }
                        }
                        .frame(height: 12)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                    .padding(.horizontal)

                    // Category Breakdown
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Categories")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(viewModel.categoryBreakdown, id: \.category.id) { item in
                            BudgetCategoryRow(
                                category: item.category,
                                spent: item.spent,
                                budgeted: item.budgeted
                            )
                        }
                    }

                    // Biblical wisdom
                    VStack(spacing: 8) {
                        Text("\"The plans of the diligent lead to profit as surely as haste leads to poverty.\"")
                            .font(.callout.italic())
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Text("— Proverbs 21:5")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                .padding(.vertical)
            }
            .navigationTitle("Budget")
            .onAppear {
                viewModel.configure(modelContext: modelContext)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingAddTransaction = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color("AccentGold"))
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddTransaction) {
                AddTransactionSheet(viewModel: viewModel)
            }
            .errorAlert($viewModel.error)
        }
    }
}

struct BudgetCategoryRow: View {
    let category: BudgetCategory
    let spent: Decimal
    let budgeted: Decimal

    var progress: Double {
        guard budgeted > 0 else { return 0 }
        let ratio = spent / budgeted
        return min(1.0, NSDecimalNumber(decimal: ratio).doubleValue)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(Color("AccentGold"))
                    .frame(width: 24)

                Text(category.name)
                    .font(.subheadline)

                Spacer()

                Text("\(spent.currencyWhole) / \(budgeted.currencyWhole)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(progress > 0.9 ? Color.red : Color("AccentGold"))
                        .frame(width: geometry.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal)
    }
}

struct AddTransactionSheet: View {
    @ObservedObject var viewModel: BudgetViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    HStack {
                        Text("$")
                        TextField("0.00", text: $viewModel.newAmount)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $viewModel.selectedCategory) {
                        Text("Select a category").tag(nil as BudgetCategory?)
                        ForEach(viewModel.categories) { category in
                            Label(category.name, systemImage: category.icon)
                                .tag(category as BudgetCategory?)
                        }
                    }
                }

                Section("Details") {
                    TextField("Description", text: $viewModel.newDescription)
                    TextField("Note (optional)", text: $viewModel.newNote)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addTransaction()
                        dismiss()
                    }
                    .disabled(viewModel.newAmount.isEmpty || viewModel.selectedCategory == nil)
                }
            }
        }
    }
}

#Preview {
    BudgetOverviewView()
}
