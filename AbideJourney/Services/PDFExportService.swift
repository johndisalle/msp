import UIKit
import SwiftUI

final class PDFExportService {
    static let shared = PDFExportService()

    private init() {}

    func generateJournalPDF(entries: [JournalEntry], userName: String) -> Data {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))

        let data = renderer.pdfData { context in
            var yPosition: CGFloat = 0

            // Helper to start a new page
            func newPage() {
                context.beginPage()
                yPosition = margin
            }

            // Helper to check if we need a new page
            func ensureSpace(_ needed: CGFloat) {
                if yPosition + needed > pageHeight - margin {
                    newPage()
                }
            }

            // --- Title Page ---
            newPage()
            yPosition = pageHeight * 0.3

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 32, weight: .bold),
                .foregroundColor: UIColor.label,
                .paragraphStyle: centeredParagraph()
            ]
            let title = "My Abide Journey\nJournal"
            let titleRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 100)
            title.draw(in: titleRect, withAttributes: titleAttrs)
            yPosition += 110

            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 16, weight: .regular),
                .foregroundColor: UIColor.secondaryLabel,
                .paragraphStyle: centeredParagraph()
            ]
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let subtitle = "\(userName)\n\(entries.count) reflections\nExported \(dateFormatter.string(from: Date()))"
            let subtitleRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: 80)
            subtitle.draw(in: subtitleRect, withAttributes: subtitleAttrs)

            // --- Entry Pages ---
            let sortedEntries = entries.sorted { $0.createdAt < $1.createdAt }

            for (index, entry) in sortedEntries.enumerated() {
                newPage()

                // Entry number and date
                let headerAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11, weight: .medium),
                    .foregroundColor: UIColor.secondaryLabel
                ]
                let dateStr = dateFormatter.string(from: entry.createdAt)
                let header = "Entry \(index + 1) of \(sortedEntries.count)  •  \(dateStr)"
                header.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: headerAttrs)
                yPosition += 24

                // Mood
                if let mood = entry.mood {
                    let moodAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 20)
                    ]
                    let moodLabel: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                        .foregroundColor: UIColor.secondaryLabel
                    ]
                    mood.label.draw(at: CGPoint(x: margin, y: yPosition + 4), withAttributes: moodLabel)
                    yPosition += 32
                }

                // Scripture reference (if linked to a day)
                if let day = entry.journeyDay {
                    let refAttrs: [NSAttributedString.Key: Any] = [
                        .font: UIFont.italicSystemFont(ofSize: 12),
                        .foregroundColor: UIColor.systemBlue
                    ]
                    let ref = "Day \(day.dayNumber) — \(day.scriptureReference)"
                    ref.draw(at: CGPoint(x: margin, y: yPosition), withAttributes: refAttrs)
                    yPosition += 22
                }

                // Divider line
                yPosition += 4
                let dividerPath = UIBezierPath()
                dividerPath.move(to: CGPoint(x: margin, y: yPosition))
                dividerPath.addLine(to: CGPoint(x: margin + contentWidth, y: yPosition))
                UIColor.separator.setStroke()
                dividerPath.lineWidth = 0.5
                dividerPath.stroke()
                yPosition += 16

                // Journal text
                let bodyAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 14, weight: .regular),
                    .foregroundColor: UIColor.label,
                    .paragraphStyle: bodyParagraph()
                ]
                let bodyText = entry.text as NSString
                let _ = bodyText.boundingRect(
                    with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: bodyAttrs,
                    context: nil
                )

                // Handle multi-page entries
                var remainingText = entry.text
                while !remainingText.isEmpty {
                    let availableHeight = pageHeight - margin - yPosition
                    let drawRect = CGRect(x: margin, y: yPosition, width: contentWidth, height: availableHeight)

                    let nsText = remainingText as NSString
                    let textStorage = NSTextStorage(string: remainingText, attributes: bodyAttrs)
                    let layoutManager = NSLayoutManager()
                    let textContainer = NSTextContainer(size: CGSize(width: contentWidth, height: availableHeight))
                    textContainer.lineFragmentPadding = 0
                    layoutManager.addTextContainer(textContainer)
                    textStorage.addLayoutManager(layoutManager)

                    let glyphRange = layoutManager.glyphRange(for: textContainer)
                    let characterRange = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)

                    let visibleText = nsText.substring(with: characterRange)
                    visibleText.draw(in: drawRect, withAttributes: bodyAttrs)

                    let drawnBounds = (visibleText as NSString).boundingRect(
                        with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                        attributes: bodyAttrs,
                        context: nil
                    )
                    yPosition += drawnBounds.height + 8

                    if characterRange.length >= nsText.length {
                        remainingText = ""
                    } else {
                        remainingText = nsText.substring(from: characterRange.location + characterRange.length)
                        newPage()
                    }
                }
            }
        }

        return data
    }

    private func centeredParagraph() -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        style.lineSpacing = 6
        return style
    }

    private func bodyParagraph() -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 6
        style.paragraphSpacing = 8
        return style
    }
}
