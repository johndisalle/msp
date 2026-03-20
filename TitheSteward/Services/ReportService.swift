import Foundation
import SwiftData
import PDFKit

@MainActor
class ReportService {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Monthly Trend Data

    struct MonthlyTrend: Identifiable {
        let id = UUID()
        let month: Date
        let monthLabel: String
        let totalGiven: Decimal
        let titheAmount: Decimal
        let offeringAmount: Decimal
        let otherAmount: Decimal
        let tithePercentOfIncome: Double
    }

    func monthlyTrends(for profile: UserProfile, months: Int = 12) -> [MonthlyTrend] {
        let calendar = Calendar.current
        let now = Date()
        var trends: [MonthlyTrend] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"

        for i in (0..<months).reversed() {
            guard let monthDate = calendar.date(byAdding: .month, value: -i, to: now),
                  let interval = calendar.dateInterval(of: .month, for: monthDate) else { continue }

            let records = profile.titheRecords.filter {
                $0.date >= interval.start && $0.date < interval.end
            }

            let total = records.reduce(Decimal.zero) { $0 + $1.amount }
            let tithe = records.filter { $0.category == .tithe }.reduce(Decimal.zero) { $0 + $1.amount }
            let offering = records.filter { $0.category == .offering }.reduce(Decimal.zero) { $0 + $1.amount }
            let other = total - tithe - offering

            let percent: Double = profile.monthlyIncome > 0
                ? NSDecimalNumber(decimal: total / profile.monthlyIncome * 100).doubleValue
                : 0

            trends.append(MonthlyTrend(
                month: monthDate,
                monthLabel: dateFormatter.string(from: monthDate),
                totalGiven: total,
                titheAmount: tithe,
                offeringAmount: offering,
                otherAmount: other,
                tithePercentOfIncome: percent
            ))
        }

        return trends
    }

    // MARK: - Category Breakdown

    struct CategorySummary: Identifiable {
        let id = UUID()
        let category: GivingCategory
        let total: Decimal
        let percentage: Double
        let recordCount: Int
    }

    func categoryBreakdown(for profile: UserProfile, year: Int? = nil) -> [CategorySummary] {
        let calendar = Calendar.current
        let targetYear = year ?? calendar.component(.year, from: Date())

        let records = profile.titheRecords.filter {
            calendar.component(.year, from: $0.date) == targetYear
        }

        let grandTotal = records.reduce(Decimal.zero) { $0 + $1.amount }
        guard grandTotal > 0 else { return [] }

        var byCategory: [GivingCategory: (total: Decimal, count: Int)] = [:]
        for record in records {
            let existing = byCategory[record.category] ?? (total: 0, count: 0)
            byCategory[record.category] = (total: existing.total + record.amount, count: existing.count + 1)
        }

        return byCategory.map { cat, data in
            CategorySummary(
                category: cat,
                total: data.total,
                percentage: NSDecimalNumber(decimal: data.total / grandTotal * 100).doubleValue,
                recordCount: data.count
            )
        }.sorted { $0.total > $1.total }
    }

    // MARK: - Projection

    struct GivingProjection {
        let projectedMonthly: Decimal
        let projectedAnnual: Decimal
        let projectedTithePercentage: Double
        let monthsOfData: Int
        let trend: TrendDirection
    }

    enum TrendDirection: String {
        case increasing = "Increasing"
        case stable = "Stable"
        case decreasing = "Decreasing"
    }

    func projection(for profile: UserProfile) -> GivingProjection {
        let trends = monthlyTrends(for: profile, months: 6)
        let nonZero = trends.filter { $0.totalGiven > 0 }
        guard !nonZero.isEmpty else {
            return GivingProjection(
                projectedMonthly: 0,
                projectedAnnual: 0,
                projectedTithePercentage: 0,
                monthsOfData: 0,
                trend: .stable
            )
        }

        let average = nonZero.reduce(Decimal.zero) { $0 + $1.totalGiven } / Decimal(nonZero.count)
        let annual = average * 12

        let tithePercent: Double = profile.monthlyIncome > 0
            ? NSDecimalNumber(decimal: average / profile.monthlyIncome * 100).doubleValue
            : 0

        // Determine trend from last 3 months
        var direction: TrendDirection = .stable
        if nonZero.count >= 3 {
            let recent = Array(nonZero.suffix(3))
            if recent.last!.totalGiven > recent.first!.totalGiven * Decimal(string: "1.05")! {
                direction = .increasing
            } else if recent.last!.totalGiven < recent.first!.totalGiven * Decimal(string: "0.95")! {
                direction = .decreasing
            }
        }

        return GivingProjection(
            projectedMonthly: average,
            projectedAnnual: annual,
            projectedTithePercentage: tithePercent,
            monthsOfData: nonZero.count,
            trend: direction
        )
    }

    // MARK: - Tax Summary

    struct TaxSummary {
        let year: Int
        let totalDeductible: Decimal
        let byCategory: [CategorySummary]
        let byRecipient: [RecipientSummary]
        let recordCount: Int
        let dateRange: String
    }

    struct RecipientSummary: Identifiable {
        let id = UUID()
        let name: String
        let total: Decimal
        let recordCount: Int
    }

    func taxSummary(for profile: UserProfile, year: Int? = nil) -> TaxSummary {
        let calendar = Calendar.current
        let targetYear = year ?? calendar.component(.year, from: Date())

        let records = profile.titheRecords.filter {
            calendar.component(.year, from: $0.date) == targetYear
        }.sorted { $0.date < $1.date }

        let total = records.reduce(Decimal.zero) { $0 + $1.amount }
        let categories = categoryBreakdown(for: profile, year: targetYear)

        // By recipient
        var recipientTotals: [String: (total: Decimal, count: Int)] = [:]
        for record in records {
            let name = record.recipient.isEmpty ? "Unspecified" : record.recipient
            let existing = recipientTotals[name] ?? (total: 0, count: 0)
            recipientTotals[name] = (total: existing.total + record.amount, count: existing.count + 1)
        }

        let recipientSummaries = recipientTotals.map { name, data in
            RecipientSummary(name: name, total: data.total, recordCount: data.count)
        }.sorted { $0.total > $1.total }

        let dateRange: String
        if let first = records.first, let last = records.last {
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            dateRange = "\(fmt.string(from: first.date)) — \(fmt.string(from: last.date))"
        } else {
            dateRange = "No records"
        }

        return TaxSummary(
            year: targetYear,
            totalDeductible: total,
            byCategory: categories,
            byRecipient: recipientSummaries,
            recordCount: records.count,
            dateRange: dateRange
        )
    }

    // MARK: - CSV Export

    func generateCSV(for profile: UserProfile, year: Int? = nil) -> String {
        let calendar = Calendar.current
        let targetYear = year ?? calendar.component(.year, from: Date())

        let records = profile.titheRecords.filter {
            calendar.component(.year, from: $0.date) == targetYear
        }.sorted { $0.date < $1.date }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        var csv = "Date,Amount,Category,Recipient,Note,Payment Method,Recurring\n"
        for record in records {
            let date = dateFormatter.string(from: record.date)
            let amount = NSDecimalNumber(decimal: record.amount).stringValue
            let category = record.category.rawValue
            let recipient = record.recipient.replacingOccurrences(of: ",", with: ";")
            let note = (record.note ?? "").replacingOccurrences(of: ",", with: ";")
            let payment = record.paymentMethod.rawValue
            let recurring = record.isRecurring ? "Yes" : "No"
            csv += "\(date),\(amount),\(category),\(recipient),\(note),\(payment),\(recurring)\n"
        }

        return csv
    }

    // MARK: - PDF Report

    func generatePDFReport(for profile: UserProfile, year: Int? = nil) -> Data {
        let summary = taxSummary(for: profile, year: year)
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2

        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return pdfRenderer.pdfData { context in
            context.beginPage()
            var y: CGFloat = margin

            // Title
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 22),
                .foregroundColor: UIColor.label
            ]
            let title = "Tithe Steward — Giving Report \(summary.year)"
            title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
            y += 35

            // Subtitle
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.secondaryLabel
            ]
            "Prepared for \(profile.displayName)".draw(at: CGPoint(x: margin, y: y), withAttributes: subAttrs)
            y += 18
            "Period: \(summary.dateRange)".draw(at: CGPoint(x: margin, y: y), withAttributes: subAttrs)
            y += 30

            // Summary Box
            let boxAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ]
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 13),
                .foregroundColor: UIColor.label
            ]

            "Total Tax-Deductible Giving".draw(at: CGPoint(x: margin, y: y), withAttributes: boxAttrs)
            y += 22
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.maximumFractionDigits = 2
            let totalStr = formatter.string(from: summary.totalDeductible as NSDecimalNumber) ?? "$0.00"
            totalStr.draw(at: CGPoint(x: margin, y: y), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 28),
                .foregroundColor: UIColor.label
            ])
            y += 40
            "\(summary.recordCount) gifts recorded".draw(at: CGPoint(x: margin, y: y), withAttributes: subAttrs)
            y += 30

            // Divider
            let dividerPath = UIBezierPath()
            dividerPath.move(to: CGPoint(x: margin, y: y))
            dividerPath.addLine(to: CGPoint(x: margin + contentWidth, y: y))
            UIColor.separator.setStroke()
            dividerPath.stroke()
            y += 20

            // By Category
            "Giving by Category".draw(at: CGPoint(x: margin, y: y), withAttributes: boxAttrs)
            y += 24
            for cat in summary.byCategory {
                let catTotal = formatter.string(from: cat.total as NSDecimalNumber) ?? "$0"
                "\(cat.category.rawValue): \(catTotal) (\(cat.recordCount) gifts)".draw(
                    at: CGPoint(x: margin + 10, y: y), withAttributes: bodyAttrs)
                y += 20
            }
            y += 15

            // By Recipient
            "Giving by Recipient".draw(at: CGPoint(x: margin, y: y), withAttributes: boxAttrs)
            y += 24
            for recipient in summary.byRecipient {
                let recTotal = formatter.string(from: recipient.total as NSDecimalNumber) ?? "$0"
                "\(recipient.name): \(recTotal) (\(recipient.recordCount) gifts)".draw(
                    at: CGPoint(x: margin + 10, y: y), withAttributes: bodyAttrs)
                y += 20

                // Start new page if needed
                if y > pageHeight - margin - 60 {
                    context.beginPage()
                    y = margin
                }
            }
            y += 20

            // Scripture footer
            let verseAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 11),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let verse = "\"Each of you should give what you have decided in your heart to give, not reluctantly or under compulsion, for God loves a cheerful giver.\" — 2 Corinthians 9:7"
            let verseRect = CGRect(x: margin, y: pageHeight - margin - 40, width: contentWidth, height: 40)
            (verse as NSString).draw(in: verseRect, withAttributes: verseAttrs)

            // Disclaimer
            let disclaimerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.tertiaryLabel
            ]
            let disclaimer = "This report is for personal record-keeping. Consult your tax advisor for deduction eligibility. Generated by Tithe Steward."
            let disclaimerRect = CGRect(x: margin, y: pageHeight - margin - 10, width: contentWidth, height: 14)
            (disclaimer as NSString).draw(in: disclaimerRect, withAttributes: disclaimerAttrs)
        }
    }
}
