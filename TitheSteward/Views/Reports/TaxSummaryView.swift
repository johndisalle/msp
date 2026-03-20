import SwiftUI
import SwiftData

struct TaxSummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var summary: ReportService.TaxSummary?
    @State private var selectedYear: Int
    @State private var showingCSVShare = false
    @State private var showingPDFShare = false
    @State private var csvURL: URL?
    @State private var pdfURL: URL?

    init() {
        _selectedYear = State(initialValue: Calendar.current.component(.year, from: Date()))
    }

    var availableYears: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 5)...current).reversed()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Year Picker
                Picker("Tax Year", selection: $selectedYear) {
                    ForEach(availableYears, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if let summary = summary {
                    // Total Card
                    VStack(spacing: 12) {
                        Text("Total Tax-Deductible Giving")
                            .font(.headline)

                        Text(summary.totalDeductible.currencyFormatted)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(Color("AccentGold"))

                        Text("\(summary.recordCount) gifts  |  \(summary.dateRange)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .cardStyle()
                    .padding(.horizontal)

                    // By Category
                    if !summary.byCategory.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("By Category")
                                .font(.headline)

                            ForEach(summary.byCategory) { cat in
                                HStack {
                                    Image(systemName: cat.category.icon)
                                        .foregroundColor(Color("AccentGold"))
                                        .frame(width: 24)
                                    Text(cat.category.rawValue)
                                        .font(.subheadline)
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text(cat.total.currencyFormatted)
                                            .font(.subheadline.bold())
                                        Text("\(cat.recordCount) gifts")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .cardStyle()
                        .padding(.horizontal)
                    }

                    // By Recipient
                    if !summary.byRecipient.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("By Recipient")
                                .font(.headline)

                            ForEach(summary.byRecipient) { recipient in
                                HStack {
                                    Image(systemName: "building.columns.fill")
                                        .foregroundColor(Color("AccentGold"))
                                        .frame(width: 24)
                                    Text(recipient.name)
                                        .font(.subheadline)
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text(recipient.total.currencyFormatted)
                                            .font(.subheadline.bold())
                                        Text("\(recipient.recordCount) gifts")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .cardStyle()
                        .padding(.horizontal)
                    }

                    // Export Buttons
                    VStack(spacing: 12) {
                        Button {
                            exportPDF()
                        } label: {
                            Label("Export PDF Report", systemImage: "doc.fill")
                                .accentButtonStyle()
                        }

                        Button {
                            exportCSV()
                        } label: {
                            Label("Export CSV Spreadsheet", systemImage: "tablecells")
                                .font(.headline)
                                .foregroundColor(Color("AccentGold"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color("AccentGold").opacity(0.1))
                                .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal)

                    // Disclaimer
                    VStack(spacing: 8) {
                        Text("Tax Disclaimer")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        Text("This report is for personal record-keeping only. Charitable contribution deductions may be subject to AGI limitations and require written acknowledgment from the receiving organization. Consult a qualified tax professional.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()

                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No giving records for \(String(selectedYear))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 60)
                }

                // Scripture
                VStack(spacing: 4) {
                    Text("\"Each of you should give what you have decided in your heart to give.\"")
                        .font(.caption.italic())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Text("— 2 Corinthians 9:7")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .padding(.vertical)
        }
        .navigationTitle("Tax Summary")
        .onAppear { loadData() }
        .onChange(of: selectedYear) { _, _ in loadData() }
        .sheet(isPresented: $showingPDFShare) {
            if let url = pdfURL {
                ShareFileActivityView(url: url)
            }
        }
        .sheet(isPresented: $showingCSVShare) {
            if let url = csvURL {
                ShareFileActivityView(url: url)
            }
        }
    }

    private func loadData() {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = (try? modelContext.fetch(descriptor))?.first else { return }

        let service = ReportService(modelContext: modelContext)
        let result = service.taxSummary(for: profile, year: selectedYear)
        summary = result.recordCount > 0 ? result : nil
    }

    private func exportPDF() {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = (try? modelContext.fetch(descriptor))?.first else { return }

        let service = ReportService(modelContext: modelContext)
        let data = service.generatePDFReport(for: profile, year: selectedYear)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TitheSteward_GivingReport_\(selectedYear).pdf")
        try? data.write(to: url)
        pdfURL = url
        showingPDFShare = true
    }

    private func exportCSV() {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = (try? modelContext.fetch(descriptor))?.first else { return }

        let service = ReportService(modelContext: modelContext)
        let csv = service.generateCSV(for: profile, year: selectedYear)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TitheSteward_Giving_\(selectedYear).csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        csvURL = url
        showingCSVShare = true
    }
}

// MARK: - File Share

struct ShareFileActivityView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        TaxSummaryView()
    }
}
