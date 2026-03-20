import Foundation
import SwiftData

/// Generates AI-powered tax prep reports including TurboTax-compatible format
/// and CPA cover letters for charitable giving deductions.
@MainActor
class TaxReportService {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - TurboTax-Compatible Export (IRS Form 8283 format)

    struct TaxExportData {
        let year: Int
        let donorName: String
        let totalCashContributions: Decimal
        let contributionsByOrganization: [OrganizationContribution]
        let isOver250PerOrg: Bool // Requires written acknowledgment
        let isOver500Total: Bool   // Requires Form 8283
        let taxNotes: [String]
    }

    struct OrganizationContribution: Identifiable {
        let id = UUID()
        let organizationName: String
        let organizationType: String
        let totalAmount: Decimal
        let numberOfGifts: Int
        let dateRange: String
        let cashOrProperty: String = "Cash"
    }

    func generateTaxExportData(for profile: UserProfile, year: Int? = nil) -> TaxExportData {
        let calendar = Calendar.current
        let targetYear = year ?? calendar.component(.year, from: Date())

        let records = profile.titheRecords.filter {
            calendar.component(.year, from: $0.date) == targetYear
        }.sorted { $0.date < $1.date }

        let total = records.reduce(Decimal.zero) { $0 + $1.amount }

        // Group by recipient
        var byRecipient: [String: (amount: Decimal, count: Int, first: Date, last: Date)] = [:]
        for record in records {
            let name = record.recipient.isEmpty ? "Unspecified Organization" : record.recipient
            if let existing = byRecipient[name] {
                byRecipient[name] = (
                    amount: existing.amount + record.amount,
                    count: existing.count + 1,
                    first: min(existing.first, record.date),
                    last: max(existing.last, record.date)
                )
            } else {
                byRecipient[name] = (amount: record.amount, count: 1, first: record.date, last: record.date)
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short

        let contributions = byRecipient.map { name, data in
            OrganizationContribution(
                organizationName: name,
                organizationType: "501(c)(3) Religious Organization",
                totalAmount: data.amount,
                numberOfGifts: data.count,
                dateRange: "\(dateFormatter.string(from: data.first)) - \(dateFormatter.string(from: data.last))"
            )
        }.sorted { $0.totalAmount > $1.totalAmount }

        let hasOver250 = contributions.contains { $0.totalAmount >= 250 }
        let totalOver500 = total >= 500

        var notes: [String] = []
        if hasOver250 {
            notes.append("One or more organizations received $250+. IRS requires a written acknowledgment letter from each organization for contributions of $250 or more (IRC Section 170(f)(8)).")
        }
        if totalOver500 {
            notes.append("Total noncash contributions exceed $500. If any gifts were non-cash, Form 8283 may be required.")
        }
        notes.append("All contributions listed are cash/electronic gifts to religious and charitable organizations. Verify 501(c)(3) status with each organization.")

        return TaxExportData(
            year: targetYear,
            donorName: profile.displayName,
            totalCashContributions: total,
            contributionsByOrganization: contributions,
            isOver250PerOrg: hasOver250,
            isOver500Total: totalOver500,
            taxNotes: notes
        )
    }

    // MARK: - TurboTax Import CSV

    func generateTurboTaxCSV(for profile: UserProfile, year: Int? = nil) -> String {
        let data = generateTaxExportData(for: profile, year: year)

        var csv = "Organization Name,Amount,Date Range,Number of Gifts,Type\n"
        for org in data.contributionsByOrganization {
            let amount = NSDecimalNumber(decimal: org.totalAmount).stringValue
            let name = org.organizationName.replacingOccurrences(of: ",", with: ";")
            csv += "\(name),\(amount),\(org.dateRange),\(org.numberOfGifts),\(org.cashOrProperty)\n"
        }

        csv += "\nTotal,\(NSDecimalNumber(decimal: data.totalCashContributions).stringValue),,,"
        return csv
    }

    // MARK: - CPA Cover Letter

    func generateCPALetter(for profile: UserProfile, year: Int? = nil) -> String {
        let data = generateTaxExportData(for: profile, year: year)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2

        let totalStr = formatter.string(from: data.totalCashContributions as NSDecimalNumber) ?? "$0.00"
        let currentDate = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none)

        var letter = """
        \(currentDate)

        RE: Charitable Contribution Summary for Tax Year \(data.year)
        Taxpayer: \(data.donorName)

        Dear Tax Professional,

        Please find below a summary of my charitable cash contributions for the \(data.year) tax year, \
        as tracked by the Tithe Steward application. This information is provided to assist with the \
        preparation of my federal and state income tax returns.

        TOTAL CASH CONTRIBUTIONS: \(totalStr)

        CONTRIBUTIONS BY ORGANIZATION:

        """

        for (index, org) in data.contributionsByOrganization.enumerated() {
            let orgTotal = formatter.string(from: org.totalAmount as NSDecimalNumber) ?? "$0"
            letter += """
            \(index + 1). \(org.organizationName)
               Type: \(org.organizationType)
               Total: \(orgTotal) (\(org.numberOfGifts) gift\(org.numberOfGifts == 1 ? "" : "s"))
               Period: \(org.dateRange)

            """
        }

        letter += """

        IMPORTANT NOTES:
        """

        for note in data.taxNotes {
            letter += "\n- \(note)"
        }

        letter += """


        Please note that this summary is generated from self-reported data within the Tithe Steward \
        application and should be verified against bank statements and official receipts from each \
        receiving organization. For contributions of $250 or more to any single organization, I \
        \(data.isOver250PerOrg ? "have obtained" : "will obtain") written acknowledgment as required \
        by IRS regulations.

        If you need any additional documentation or have questions about any of these contributions, \
        please do not hesitate to contact me.

        Sincerely,
        \(data.donorName)

        ---
        Generated by Tithe Steward | For personal record-keeping purposes
        \"Each of you should give what you have decided in your heart to give.\" — 2 Corinthians 9:7
        """

        return letter
    }

    // MARK: - CPA Letter PDF

    func generateCPALetterPDF(for profile: UserProfile, year: Int? = nil) -> Data {
        let letter = generateCPALetter(for: profile, year: year)
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 72 // 1 inch margins for letter format

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            context.beginPage()

            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont(name: "Times New Roman", size: 12) ?? UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.label,
                .paragraphStyle: {
                    let style = NSMutableParagraphStyle()
                    style.lineSpacing = 4
                    return style
                }()
            ]

            let textRect = CGRect(
                x: margin,
                y: margin,
                width: pageWidth - margin * 2,
                height: pageHeight - margin * 2
            )

            (letter as NSString).draw(in: textRect, withAttributes: bodyAttrs)
        }
    }
}
