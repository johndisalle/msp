import SwiftUI

struct TitheTrackerView: View {
    @StateObject private var viewModel = TitheViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Tithe Progress Circle
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(Color(.systemGray5), lineWidth: 10)
                                .frame(width: 120, height: 120)

                            Circle()
                                .trim(from: 0, to: viewModel.titheProgress)
                                .stroke(Color("AccentGold"), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut, value: viewModel.titheProgress)

                            VStack {
                                Text("\(Int(viewModel.titheProgress * 100))%")
                                    .font(.title2.bold())
                                Text("of tithe")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack(spacing: 24) {
                            VStack {
                                Text(viewModel.formatCurrency(viewModel.totalGivenThisMonth))
                                    .font(.headline)
                                Text("Given")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                Text(viewModel.formatCurrency(viewModel.suggestedTithe))
                                    .font(.headline)
                                Text("Goal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                Text(viewModel.formatCurrency(viewModel.remainingToTithe))
                                    .font(.headline)
                                Text("Remaining")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                    .padding(.horizontal)

                    // Category Breakdown
                    if !viewModel.categoryTotals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("By Category")
                                .font(.headline)

                            ForEach(viewModel.categoryTotals, id: \.category) { item in
                                HStack {
                                    Image(systemName: item.category.icon)
                                        .foregroundColor(Color("AccentGold"))
                                        .frame(width: 24)
                                    Text(item.category.rawValue)
                                        .font(.subheadline)
                                    Spacer()
                                    Text(viewModel.formatCurrency(item.total))
                                        .font(.subheadline.bold())
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                        .padding(.horizontal)
                    }

                    // Records List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This Month's Giving")
                            .font(.headline)

                        if viewModel.monthlyRecords.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "heart.slash")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                                Text("No giving recorded yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Tap + to log your first gift")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                        } else {
                            ForEach(viewModel.monthlyRecords) { record in
                                HStack {
                                    Image(systemName: record.category.icon)
                                        .foregroundColor(Color("AccentGold"))
                                        .frame(width: 24)

                                    VStack(alignment: .leading) {
                                        Text(record.category.rawValue)
                                            .font(.subheadline)
                                        Text(record.date, style: .date)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text(viewModel.formatCurrency(record.amount))
                                        .font(.subheadline.bold())
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Tithe Tracker")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingAddRecord = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color("AccentGold"))
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddRecord) {
                AddTitheRecordSheet(viewModel: viewModel)
            }
        }
    }
}

struct AddTitheRecordSheet: View {
    @ObservedObject var viewModel: TitheViewModel
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
                        ForEach(GivingCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }

                Section("Details") {
                    TextField("Recipient (optional)", text: $viewModel.newRecipient)
                    TextField("Note (optional)", text: $viewModel.newNote)

                    Picker("Payment Method", selection: $viewModel.newPaymentMethod) {
                        ForEach(PaymentMethod.allCases, id: \.self) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                }
            }
            .navigationTitle("Log Gift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addRecord()
                        dismiss()
                    }
                    .disabled(viewModel.newAmount.isEmpty)
                }
            }
        }
    }
}

#Preview {
    TitheTrackerView()
}
