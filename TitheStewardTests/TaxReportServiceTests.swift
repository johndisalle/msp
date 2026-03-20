import XCTest
import SwiftData
@testable import TitheSteward

@MainActor
final class TaxReportServiceTests: XCTestCase {
    var modelContext: ModelContext!
    var service: TaxReportService!
    var profile: UserProfile!

    override func setUp() async throws {
        let schema = Schema([
            UserProfile.self, TitheRecord.self, BudgetCategory.self,
            BudgetTransaction.self, DebtItem.self, DebtPayment.self,
            DevotionalCompletion.self, GivingRecipient.self, RecurringGift.self, ChatSession.self, GenerosityBadge.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        modelContext = container.mainContext

        profile = UserProfile(
            displayName: "John Smith",
            monthlyIncome: 5000
        )
        modelContext.insert(profile)
        try modelContext.save()

        service = TaxReportService(modelContext: modelContext)
    }

    private func addRecord(amount: Decimal, category: GivingCategory = .tithe, recipient: String = "Church", date: Date = Date()) {
        let record = TitheRecord(date: date, amount: amount, category: category, recipient: recipient)
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)
    }

    // MARK: - Tax Export Data

    func testTaxExportTotals() {
        addRecord(amount: 500, recipient: "Church A")
        addRecord(amount: 200, recipient: "Church A")
        addRecord(amount: 100, recipient: "Charity B")

        let data = service.generateTaxExportData(for: profile)
        XCTAssertEqual(data.totalCashContributions, 800)
        XCTAssertEqual(data.contributionsByOrganization.count, 2)
        XCTAssertEqual(data.donorName, "John Smith")
    }

    func testTaxExportGroupsByRecipient() {
        addRecord(amount: 500, recipient: "My Church")
        addRecord(amount: 300, recipient: "My Church")
        addRecord(amount: 100, recipient: "Red Cross")

        let data = service.generateTaxExportData(for: profile)
        let church = data.contributionsByOrganization.first { $0.organizationName == "My Church" }
        XCTAssertEqual(church?.totalAmount, 800)
        XCTAssertEqual(church?.numberOfGifts, 2)
    }

    func testTaxExportOver250Flag() {
        addRecord(amount: 250, recipient: "Church")

        let data = service.generateTaxExportData(for: profile)
        XCTAssertTrue(data.isOver250PerOrg)
    }

    func testTaxExportUnder250Flag() {
        addRecord(amount: 200, recipient: "Church")

        let data = service.generateTaxExportData(for: profile)
        XCTAssertFalse(data.isOver250PerOrg)
    }

    func testTaxExportOver500TotalFlag() {
        addRecord(amount: 300, recipient: "Church A")
        addRecord(amount: 201, recipient: "Church B")

        let data = service.generateTaxExportData(for: profile)
        XCTAssertTrue(data.isOver500Total)
    }

    func testTaxExportNotesNonEmpty() {
        addRecord(amount: 100, recipient: "Church")

        let data = service.generateTaxExportData(for: profile)
        XCTAssertFalse(data.taxNotes.isEmpty)
    }

    // MARK: - TurboTax CSV

    func testTurboTaxCSVFormat() {
        addRecord(amount: 500, recipient: "My Church")

        let csv = service.generateTurboTaxCSV(for: profile)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        XCTAssertTrue(lines[0].contains("Organization Name"))
        XCTAssertTrue(csv.contains("My Church"))
        XCTAssertTrue(csv.contains("500"))
        XCTAssertTrue(csv.contains("Total"))
    }

    func testTurboTaxCSVMultipleOrgs() {
        addRecord(amount: 500, recipient: "Church A")
        addRecord(amount: 200, recipient: "Charity B")

        let csv = service.generateTurboTaxCSV(for: profile)
        XCTAssertTrue(csv.contains("Church A"))
        XCTAssertTrue(csv.contains("Charity B"))
    }

    // MARK: - CPA Letter

    func testCPALetterContainsDonorName() {
        addRecord(amount: 500, recipient: "Church")

        let letter = service.generateCPALetter(for: profile)
        XCTAssertTrue(letter.contains("John Smith"))
    }

    func testCPALetterContainsYear() {
        addRecord(amount: 500, recipient: "Church")

        let year = Calendar.current.component(.year, from: Date())
        let letter = service.generateCPALetter(for: profile, year: year)
        XCTAssertTrue(letter.contains(String(year)))
    }

    func testCPALetterContainsOrganizations() {
        addRecord(amount: 500, recipient: "Grace Church")
        addRecord(amount: 200, recipient: "Mercy Ministries")

        let letter = service.generateCPALetter(for: profile)
        XCTAssertTrue(letter.contains("Grace Church"))
        XCTAssertTrue(letter.contains("Mercy Ministries"))
    }

    func testCPALetterContainsDisclaimer() {
        addRecord(amount: 500, recipient: "Church")

        let letter = service.generateCPALetter(for: profile)
        XCTAssertTrue(letter.contains("self-reported data"))
    }

    func testCPALetterContainsScripture() {
        addRecord(amount: 500, recipient: "Church")

        let letter = service.generateCPALetter(for: profile)
        XCTAssertTrue(letter.contains("2 Corinthians 9:7"))
    }

    // MARK: - CPA Letter PDF

    func testCPALetterPDFGenerates() {
        addRecord(amount: 500, recipient: "Church")

        let data = service.generateCPALetterPDF(for: profile)
        XCTAssertGreaterThan(data.count, 0)

        let prefix = data.prefix(5)
        let header = String(data: prefix, encoding: .ascii)
        XCTAssertEqual(header, "%PDF-")
    }

    // MARK: - Year Filtering

    func testTaxExportFiltersByYear() {
        let calendar = Calendar.current
        let lastYear = calendar.date(byAdding: .year, value: -1, to: Date())!

        addRecord(amount: 500, recipient: "Church", date: Date())
        addRecord(amount: 300, recipient: "Church", date: lastYear)

        let currentYear = calendar.component(.year, from: Date())
        let thisYearData = service.generateTaxExportData(for: profile, year: currentYear)
        XCTAssertEqual(thisYearData.totalCashContributions, 500)

        let lastYearData = service.generateTaxExportData(for: profile, year: currentYear - 1)
        XCTAssertEqual(lastYearData.totalCashContributions, 300)
    }
}
