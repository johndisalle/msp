import SwiftUI
import SwiftData

struct TaxPrepView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var exportData: TaxReportService.TaxExportData?
    @State private var selectedYear: Int
    @State private var showingTurboTaxShare = false
    @State private var showingCPALetterShare = false
    @State private var showingCPAPDFShare = false
    @State private var turboTaxURL: URL?
    @State private var cpaLetterURL: URL?
    @State private var cpaPDFURL: URL?
    @State private var showingPreview = false
    @State private var previewText = ""

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
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(Color("AccentGold"))

                    Text("Tax Prep Export")
                        .font(.title2.bold())

                    Text("Generate reports for your tax professional or import directly into tax software.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Year picker
                Picker("Tax Year", selection: $selectedYear) {
                    ForEach(availableYears, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if let data = exportData {
                    // Summary
                    VStack(spacing: 8) {
                        Text("Total Deductible Giving")
                            .font(.headline)
                        Text(data.totalCashContributions.currencyFormatted)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(Color("AccentGold"))
                        Text("\(data.contributionsByOrganization.count) organizations  |  \(data.contributionsByOrganization.reduce(0) { $0 + $1.numberOfGifts }) gifts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .cardStyle()
                    .padding(.horizontal)

                    // IRS Alerts
                    if data.isOver250PerOrg || data.isOver500Total {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("IRS Requirements", systemImage: "exclamationmark.triangle.fill")
                                .font(.subheadline.bold())
                                .foregroundColor(.orange)

                            ForEach(data.taxNotes, id: \.self) { note in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "info.circle")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    Text(note)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .cardStyle()
                        .padding(.horizontal)
                    }

                    // Organizations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("By Organization")
                            .font(.headline)

                        ForEach(data.contributionsByOrganization) { org in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(org.organizationName)
                                        .font(.subheadline.bold())
                                    Text("\(org.numberOfGifts) gifts  |  \(org.dateRange)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text(org.totalAmount.currencyFormatted)
                                    .font(.subheadline.bold())
                                    .foregroundColor(Color("AccentGold"))
                            }
                            if org.totalAmount >= 250 {
                                Label("Written acknowledgment required ($250+)", systemImage: "doc.text")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .cardStyle()
                    .padding(.horizontal)

                    // Export Options
                    VStack(spacing: 12) {
                        Text("Export Options")
                            .font(.headline)

                        Button {
                            exportTurboTaxCSV()
                        } label: {
                            HStack {
                                Image(systemName: "tablecells")
                                VStack(alignment: .leading) {
                                    Text("TurboTax / Tax Software CSV")
                                        .font(.subheadline.bold())
                                    Text("Import-ready charitable contributions format")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundColor(Color("AccentGold"))
                            }
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }

                        Button {
                            previewCPALetter()
                        } label: {
                            HStack {
                                Image(systemName: "doc.richtext")
                                VStack(alignment: .leading) {
                                    Text("CPA Cover Letter")
                                        .font(.subheadline.bold())
                                    Text("Professional letter for your tax preparer")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "eye")
                                    .foregroundColor(Color("AccentGold"))
                            }
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }

                        Button {
                            exportCPALetterPDF()
                        } label: {
                            Label("Export CPA Letter as PDF", systemImage: "doc.fill")
                                .accentButtonStyle()
                        }
                    }
                    .padding(.horizontal)

                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No giving records for \(String(selectedYear))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                }

                // Scripture
                VStack(spacing: 4) {
                    Text("\"Render to Caesar the things that are Caesar's, and to God the things that are God's.\"")
                        .font(.caption.italic())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Text("— Mark 12:17")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .padding(.vertical)
        }
        .navigationTitle("Tax Prep")
        .onAppear { loadData() }
        .onChange(of: selectedYear) { _, _ in loadData() }
        .sheet(isPresented: $showingTurboTaxShare) {
            if let url = turboTaxURL {
                ShareFileActivityView(url: url)
            }
        }
        .sheet(isPresented: $showingCPAPDFShare) {
            if let url = cpaPDFURL {
                ShareFileActivityView(url: url)
            }
        }
        .sheet(isPresented: $showingPreview) {
            NavigationStack {
                ScrollView {
                    Text(previewText)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
                .navigationTitle("CPA Letter Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { showingPreview = false }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingPreview = false
                            exportCPALetterPDF()
                        } label: {
                            Label("Export PDF", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }

    private func loadData() {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = (try? modelContext.fetch(descriptor))?.first else { return }

        let service = TaxReportService(modelContext: modelContext)
        let data = service.generateTaxExportData(for: profile, year: selectedYear)
        exportData = data.contributionsByOrganization.isEmpty ? nil : data
    }

    private func exportTurboTaxCSV() {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = (try? modelContext.fetch(descriptor))?.first else { return }

        let service = TaxReportService(modelContext: modelContext)
        let csv = service.generateTurboTaxCSV(for: profile, year: selectedYear)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TitheSteward_TaxExport_\(selectedYear).csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        turboTaxURL = url
        showingTurboTaxShare = true
    }

    private func previewCPALetter() {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = (try? modelContext.fetch(descriptor))?.first else { return }

        let service = TaxReportService(modelContext: modelContext)
        previewText = service.generateCPALetter(for: profile, year: selectedYear)
        showingPreview = true
    }

    private func exportCPALetterPDF() {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = (try? modelContext.fetch(descriptor))?.first else { return }

        let service = TaxReportService(modelContext: modelContext)
        let data = service.generateCPALetterPDF(for: profile, year: selectedYear)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("TitheSteward_CPA_Letter_\(selectedYear).pdf")
        try? data.write(to: url)
        cpaPDFURL = url
        showingCPAPDFShare = true
    }
}

#Preview {
    NavigationStack {
        TaxPrepView()
    }
}
