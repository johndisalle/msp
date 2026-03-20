import XCTest
import SwiftData
@testable import TitheSteward

@MainActor
final class ReportServiceTests: XCTestCase {
    var modelContext: ModelContext!
    var service: ReportService!
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
            displayName: "Test User",
            monthlyIncome: 5000
        )
        modelContext.insert(profile)
        try modelContext.save()

        service = ReportService(modelContext: modelContext)
    }

    private func addRecord(amount: Decimal, category: GivingCategory = .tithe, recipient: String = "Church", date: Date = Date()) {
        let record = TitheRecord(date: date, amount: amount, category: category, recipient: recipient)
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)
    }

    // MARK: - Monthly Trends

    func testMonthlyTrendsReturnsCorrectMonths() {
        addRecord(amount: 500)
        let trends = service.monthlyTrends(for: profile, months: 6)
        XCTAssertEqual(trends.count, 6)
    }

    func testMonthlyTrendsCurrentMonthHasData() {
        addRecord(amount: 500, category: .tithe)
        addRecord(amount: 100, category: .offering)

        let trends = service.monthlyTrends(for: profile, months: 1)
        XCTAssertEqual(trends.count, 1)
        XCTAssertEqual(trends.first?.totalGiven, 600)
        XCTAssertEqual(trends.first?.titheAmount, 500)
        XCTAssertEqual(trends.first?.offeringAmount, 100)
    }

    func testMonthlyTrendsTithePercentage() {
        addRecord(amount: 500) // 10% of $5000

        let trends = service.monthlyTrends(for: profile, months: 1)
        XCTAssertEqual(trends.first?.tithePercentOfIncome ?? 0, 10, accuracy: 0.1)
    }

    // MARK: - Category Breakdown

    func testCategoryBreakdown() {
        addRecord(amount: 500, category: .tithe)
        addRecord(amount: 200, category: .offering)
        addRecord(amount: 100, category: .missions)

        let categories = service.categoryBreakdown(for: profile)
        XCTAssertEqual(categories.count, 3)

        let tithe = categories.first { $0.category == .tithe }
        XCTAssertNotNil(tithe)
        XCTAssertEqual(tithe?.total, 500)
        // 500/800 = 62.5%
        XCTAssertEqual(tithe?.percentage ?? 0, 62.5, accuracy: 0.1)
    }

    func testCategoryBreakdownEmptyReturnsEmpty() {
        let categories = service.categoryBreakdown(for: profile)
        XCTAssertTrue(categories.isEmpty)
    }

    // MARK: - Projection

    func testProjectionWithData() {
        // Add records for current month
        addRecord(amount: 500)
        addRecord(amount: 200)

        let projection = service.projection(for: profile)
        XCTAssertGreaterThan(projection.projectedMonthly, 0)
        XCTAssertEqual(projection.projectedAnnual, projection.projectedMonthly * 12)
        XCTAssertGreaterThan(projection.monthsOfData, 0)
    }

    func testProjectionWithNoDataReturnsZeroes() {
        let projection = service.projection(for: profile)
        XCTAssertEqual(projection.projectedMonthly, 0)
        XCTAssertEqual(projection.projectedAnnual, 0)
        XCTAssertEqual(projection.monthsOfData, 0)
        XCTAssertEqual(projection.trend, .stable)
    }

    // MARK: - Tax Summary

    func testTaxSummaryTotals() {
        addRecord(amount: 500, category: .tithe, recipient: "Church A")
        addRecord(amount: 200, category: .offering, recipient: "Church A")
        addRecord(amount: 100, category: .missions, recipient: "Mission Org")

        let summary = service.taxSummary(for: profile)
        XCTAssertEqual(summary.totalDeductible, 800)
        XCTAssertEqual(summary.recordCount, 3)
    }

    func testTaxSummaryByRecipient() {
        addRecord(amount: 500, recipient: "Church A")
        addRecord(amount: 200, recipient: "Church A")
        addRecord(amount: 100, recipient: "Mission Org")

        let summary = service.taxSummary(for: profile)
        XCTAssertEqual(summary.byRecipient.count, 2)

        let churchA = summary.byRecipient.first { $0.name == "Church A" }
        XCTAssertEqual(churchA?.total, 700)
        XCTAssertEqual(churchA?.recordCount, 2)
    }

    func testTaxSummaryFiltersByYear() {
        let calendar = Calendar.current
        let lastYear = calendar.date(byAdding: .year, value: -1, to: Date())!

        addRecord(amount: 500, date: Date())
        addRecord(amount: 300, date: lastYear)

        let currentYear = calendar.component(.year, from: Date())
        let thisYearSummary = service.taxSummary(for: profile, year: currentYear)
        XCTAssertEqual(thisYearSummary.totalDeductible, 500)

        let lastYearSummary = service.taxSummary(for: profile, year: currentYear - 1)
        XCTAssertEqual(lastYearSummary.totalDeductible, 300)
    }

    // MARK: - CSV Export

    func testCSVExportFormat() {
        addRecord(amount: 500, category: .tithe, recipient: "My Church")

        let csv = service.generateCSV(for: profile)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }

        XCTAssertEqual(lines.count, 2) // header + 1 row
        XCTAssertTrue(lines[0].hasPrefix("Date,Amount,Category,Recipient"))
        XCTAssertTrue(lines[1].contains("500"))
        XCTAssertTrue(lines[1].contains("Tithe"))
        XCTAssertTrue(lines[1].contains("My Church"))
    }

    func testCSVExportMultipleRecords() {
        addRecord(amount: 500, category: .tithe)
        addRecord(amount: 200, category: .offering)
        addRecord(amount: 100, category: .missions)

        let csv = service.generateCSV(for: profile)
        let lines = csv.components(separatedBy: "\n").filter { !$0.isEmpty }
        XCTAssertEqual(lines.count, 4) // header + 3 rows
    }

    func testCSVExportEscapesCommas() {
        addRecord(amount: 500, category: .tithe, recipient: "Church, Inc")

        let csv = service.generateCSV(for: profile)
        // Commas in recipient should be replaced with semicolons
        XCTAssertTrue(csv.contains("Church; Inc"))
    }

    // MARK: - PDF Export

    func testPDFExportGeneratesData() {
        addRecord(amount: 500, category: .tithe, recipient: "Church")

        let data = service.generatePDFReport(for: profile)
        XCTAssertGreaterThan(data.count, 0, "PDF data should not be empty")

        // Verify it starts with PDF magic bytes
        let prefix = data.prefix(5)
        let pdfHeader = String(data: prefix, encoding: .ascii)
        XCTAssertEqual(pdfHeader, "%PDF-")
    }

    func testPDFExportWithNoRecords() {
        let data = service.generatePDFReport(for: profile)
        XCTAssertGreaterThan(data.count, 0, "PDF should still generate even with no records")
    }
}
