import UIKit

/// Generates a beautiful "Spotify Wrapped"-style annual faith report PDF.
final class FaithReportService {
    static let shared = FaithReportService()
    private init() {}

    struct ReportData {
        let userName: String
        let year: Int
        let totalDaysCompleted: Int
        let totalPrayerMinutes: Int
        let totalJournalEntries: Int
        let journeysCompleted: Int
        let longestStreak: Int
        let topMood: String
        let topFocusArea: String
        let versesRead: Int
        let actionStepsCompleted: Int
        let topTheme: String
        let monthlyDays: [Int] // 12 values, one per month
    }

    func generateReport(data: ReportData) -> Data {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        return renderer.pdfData { context in
            // --- Page 1: Title ---
            context.beginPage()
            var y: CGFloat = pageHeight * 0.25

            drawCentered("Your \(data.year)\nFaith Report", at: &y, width: contentWidth, margin: margin,
                        font: .systemFont(ofSize: 36, weight: .bold), color: .label)
            y += 12
            drawCentered(data.userName, at: &y, width: contentWidth, margin: margin,
                        font: .systemFont(ofSize: 18), color: .secondaryLabel)
            y += 8
            drawCentered("Abide Journey", at: &y, width: contentWidth, margin: margin,
                        font: .systemFont(ofSize: 14), color: .tertiaryLabel)

            // --- Page 2: Big Numbers ---
            context.beginPage()
            y = margin + 20

            drawCentered("The Year in Numbers", at: &y, width: contentWidth, margin: margin,
                        font: .systemFont(ofSize: 28, weight: .bold), color: .label)
            y += 40

            let stats: [(String, String)] = [
                ("\(data.totalDaysCompleted)", "Days with God"),
                ("\(data.totalPrayerMinutes)", "Minutes in Prayer"),
                ("\(data.totalJournalEntries)", "Journal Reflections"),
                ("\(data.journeysCompleted)", "Journeys Completed"),
                ("\(data.longestStreak)", "Longest Streak"),
                ("\(data.versesRead)", "Scriptures Read"),
                ("\(data.actionStepsCompleted)", "Action Steps Taken"),
            ]

            for (value, label) in stats {
                drawStat(value: value, label: label, at: &y, contentWidth: contentWidth, margin: margin)
                y += 8
            }

            // --- Page 3: Insights ---
            context.beginPage()
            y = margin + 20

            drawCentered("Your Spiritual Profile", at: &y, width: contentWidth, margin: margin,
                        font: .systemFont(ofSize: 28, weight: .bold), color: .label)
            y += 40

            drawInsight(title: "Most Common Mood", value: data.topMood, at: &y, contentWidth: contentWidth, margin: margin)
            drawInsight(title: "Strongest Focus Area", value: data.topFocusArea, at: &y, contentWidth: contentWidth, margin: margin)
            drawInsight(title: "Favorite Journey Theme", value: data.topTheme, at: &y, contentWidth: contentWidth, margin: margin)

            y += 30

            // Monthly activity bars
            drawCentered("Monthly Activity", at: &y, width: contentWidth, margin: margin,
                        font: .systemFont(ofSize: 20, weight: .bold), color: .label)
            y += 20
            drawMonthlyBars(data.monthlyDays, at: &y, contentWidth: contentWidth, margin: margin)

            // --- Page 4: Closing ---
            context.beginPage()
            y = pageHeight * 0.3

            drawCentered("\"Being confident of this,\nthat He who began a good\nwork in you will carry it on\nto completion.\"", at: &y, width: contentWidth, margin: margin,
                        font: .italicSystemFont(ofSize: 20), color: .label)
            y += 16
            drawCentered("Philippians 1:6", at: &y, width: contentWidth, margin: margin,
                        font: .systemFont(ofSize: 14, weight: .bold), color: .systemBlue)
            y += 40
            drawCentered("Keep walking. Keep growing.\nGod isn't done with you yet.", at: &y, width: contentWidth, margin: margin,
                        font: .systemFont(ofSize: 16), color: .secondaryLabel)
        }
    }

    // MARK: - Drawing Helpers

    private func drawCentered(_ text: String, at y: inout CGFloat, width: CGFloat, margin: CGFloat, font: UIFont, color: UIColor) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineSpacing = 6
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .paragraphStyle: style]
        let size = (text as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                                                    options: [.usesLineFragmentOrigin], attributes: attrs, context: nil)
        text.draw(in: CGRect(x: margin, y: y, width: width, height: size.height), withAttributes: attrs)
        y += size.height + 8
    }

    private func drawStat(value: String, label: String, at y: inout CGFloat, contentWidth: CGFloat, margin: CGFloat) {
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: UIColor.systemBlue
        ]
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.secondaryLabel
        ]

        value.draw(at: CGPoint(x: margin, y: y), withAttributes: valueAttrs)
        let valueSize = (value as NSString).size(withAttributes: valueAttrs)
        label.draw(at: CGPoint(x: margin + valueSize.width + 12, y: y + 8), withAttributes: labelAttrs)
        y += 50
    }

    private func drawInsight(title: String, value: String, at y: inout CGFloat, contentWidth: CGFloat, margin: CGFloat) {
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: UIColor.secondaryLabel
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor.label
        ]

        title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
        y += 22
        value.draw(at: CGPoint(x: margin, y: y), withAttributes: valueAttrs)
        y += 40
    }

    private func drawMonthlyBars(_ months: [Int], at y: inout CGFloat, contentWidth: CGFloat, margin: CGFloat) {
        let maxVal = max(1, months.max() ?? 1)
        let barWidth = contentWidth / 14
        let maxHeight: CGFloat = 120
        let monthNames = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]

        for (i, count) in months.prefix(12).enumerated() {
            let barHeight = CGFloat(count) / CGFloat(maxVal) * maxHeight
            let x = margin + CGFloat(i) * (barWidth + 2) + barWidth / 2
            let barY = y + maxHeight - barHeight

            let path = UIBezierPath(roundedRect: CGRect(x: x, y: barY, width: barWidth, height: barHeight), cornerRadius: 3)
            UIColor.systemBlue.withAlphaComponent(0.7).setFill()
            path.fill()

            // Month label
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10),
                .foregroundColor: UIColor.secondaryLabel
            ]
            let label = i < monthNames.count ? monthNames[i] : ""
            let labelSize = (label as NSString).size(withAttributes: labelAttrs)
            label.draw(at: CGPoint(x: x + barWidth / 2 - labelSize.width / 2, y: y + maxHeight + 4), withAttributes: labelAttrs)
        }

        y += maxHeight + 24
    }
}
